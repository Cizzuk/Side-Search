//
//  SpeechRecognizer.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import AVFoundation
import Combine
import Speech

class SpeechRecognizer: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecording = false
    @Published var micLevel: Float = 0.0
    
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var showError = false
    
    // Callbacks
    var onSilenceTimeout: (() -> Void)?
    
    // MARK: - Private Properties
    
    private var speechRecognizer: SFSpeechRecognizer? {
        // Get a Locale Setting
        if let speechLocale = UserDefaults.standard.string(forKey: "speechLocale") {
            return SFSpeechRecognizer(locale: Locale(identifier: speechLocale))
        }
        
        // Fallback if no locale is set
        return SFSpeechRecognizer()
    }
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Silence Detection Settings
    private var silenceTimer: Timer?
    private var manuallyConfirmSpeech: Bool {
        UserDefaults.standard.bool(forKey: "manuallyConfirmSpeech")
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func startRecording() {
        Task {
            // Cancel any existing recognition task
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }
            
            // Check Availability
            if !(await checkMicAvailability()) {
                return
            }
            
            // Erase previous text
            recognizedText = ""
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                // Configure the audio session
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .allowBluetoothA2DP)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Audio session setup failed: \(error.localizedDescription)"
                        self.showError = true
                    }
                    return
                }
                
                // Create the recognition request
                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                
                // Ensure the recognition request is valid
                guard let recognitionRequest = recognitionRequest else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Unable to create a recognition request."
                        self.showError = true
                    }
                    return
                }
                
                // Configure recognition request
                recognitionRequest.requiresOnDeviceRecognition = true
                recognitionRequest.shouldReportPartialResults = true
                
                // Configure the input node
                let inputNode = audioEngine.inputNode
                
                // Start the recognition task
                recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    var isFinal = false
                    
                    // Handle speech result
                    if let result = result {
                        DispatchQueue.main.async {
                            let newText = result.bestTranscription.formattedString
                            if self.isRecording && !newText.isEmpty {
                                self.recognizedText = newText
                            }
                        }
                        isFinal = result.isFinal
                        self.startSilenceTimer()
                    }
                    
                    // Handle final
                    if error != nil || isFinal {
                        self.stopSilenceTimer()
                        self.audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                        
                        DispatchQueue.main.async {
                            self.isRecording = false
                        }
                    }
                }
                
                // Configure the microphone input
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                    self.recognitionRequest?.append(buffer)
                    
                    // bgIllumination update
                    guard let channelData = buffer.floatChannelData?[0] else { return }
                    let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelData[$0] }
                    let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
                    let avgPower = 20 * log10(rms)
                    let minDb: Float = -80.0
                    let normalizedPower = max(0.0, (avgPower - minDb) / -minDb)
                    DispatchQueue.main.async {
                        self.micLevel = normalizedPower
                    }
                }
                
                audioEngine.prepare()
                
                // Start audio engine
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    do {
                        try audioEngine.start()
                        DispatchQueue.main.async {
                            self.isRecording = true
                        }
                        startSilenceTimer(timeout: 10.0)
                    } catch {
                        DispatchQueue.main.async {
                            self.errorMessage = "Audio engine couldn't start: \(error.localizedDescription)"
                            self.showError = true
                        }
                        return
                    }
                }
            }
        }
    }
    
    func stopRecording() {
        stopSilenceTimer()
        
        if audioEngine.isRunning {
            isRecording = false
            micLevel = 0.0
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                audioEngine.stop()
                recognitionRequest?.endAudio()
                
                // Deactivate the audio session
                do {
                    try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Failed to deactivate audio session: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func checkMicAvailability() async -> Bool {
        // 1. Check Microphone Authorization
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            break
        case .denied:
            self.errorMessage = "Microphone access denied. Please enable it in Settings."
            self.showError = true
            return false
        case .undetermined:
            // Wait for user authorization
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !granted {
                self.errorMessage = "Microphone access denied. Please enable it in Settings."
                self.showError = true
                return false
            }
        default:
            self.errorMessage = "Unknown microphone authorization status."
            self.showError = true
            return false
        }
        
        
        // 2. Check Speech Recognition Availability
        
        // Check supported locales
        guard !SFSpeechRecognizer.supportedLocales().isEmpty else {
            self.errorMessage = "Speech recognition is currently unavailable on this device."
            self.showError = true
            return false
        }
        
        // Check supportsOnDeviceRecognition & initialization
        if let recognizer = speechRecognizer {
            if !recognizer.supportsOnDeviceRecognition {
                self.errorMessage = "Speech recognition is currently unavailable on this device."
                self.showError = true
                return false
            }
        } else {
            self.errorMessage = "Speech recognizer could not be initialized."
            self.showError = true
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func startSilenceTimer(timeout: Double? = nil) {
        guard !manuallyConfirmSpeech else { return }
        let interval = timeout ?? 1
        stopSilenceTimer()
        
        DispatchQueue.main.async {
            self.silenceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                self?.silenceTimerFired()
            }
        }
    }
    
    private func stopSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
    
    private func silenceTimerFired() {
        guard isRecording else { return }
        onSilenceTimeout?()
    }
}
