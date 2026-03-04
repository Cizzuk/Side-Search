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
    private var isRecognitionPaused = false
    
    // Silence Detection Settings
    private var silenceTimer: Timer?
    private var manuallyConfirmSpeech: Bool {
        UserDefaults.standard.bool(forKey: "manuallyConfirmSpeech")
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func startRecording() {
        Task {
            isRecognitionPaused = false
            
            // Cancel any existing recognition task
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }
            
            // Check Availability
            if !(await checkAvailability()) {
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
                
                // Configure the input node
                let inputNode = audioEngine.inputNode
                
                // Configure the microphone input
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.removeTap(onBus: 0)
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
                            self.isRecognitionPaused = true
                            self.startRecognize()
                        }
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
        stopRecognize()
        isRecognitionPaused = false
        
        isRecording = false
        micLevel = 0.0
        
        if audioEngine.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
                
                // Deactivate the audio session
                do {
                    try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Failed to deactivate audio session: \(error)")
                }
            }
        }
    }
    
    // MARK: - Recognition Controls
    
    func stopRecognize() {
        guard isRecording, !isRecognitionPaused else { return }
        
        isRecognitionPaused = true
        stopSilenceTimer()
        
        if let recognitionRequest = recognitionRequest {
            recognitionRequest.endAudio()
            self.recognitionRequest = nil
        }
        
        if let recognitionTask = recognitionTask {
            recognitionTask.finish()
            self.recognitionTask = nil
        }
    }
    
    func startRecognize() {
        guard isRecording, isRecognitionPaused, recognitionTask == nil else { return }
        
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.requiresOnDeviceRecognition = true
        recognitionRequest.shouldReportPartialResults = true
        self.recognitionRequest = recognitionRequest
        
        let inputNode = audioEngine.inputNode
        isRecognitionPaused = false
        startRecognitionTask(request: recognitionRequest, inputNode: inputNode)
        startSilenceTimer(timeout: 30.0) // First wait
    }
    
    // MARK: - Availability Checks
    
    @MainActor
    func checkAvailability() async -> Bool {
        func showErrorMessage(_ message: LocalizedStringResource) {
            self.errorMessage = message
            self.showError = true
        }
        
        // 1. Check Microphone Authorization
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            break
        case .denied:
            showErrorMessage("Microphone access denied. Please enable it in Settings.")
            return false
        case .undetermined:
            // Wait for user authorization
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !granted {
                showErrorMessage("Microphone access denied. Please enable it in Settings.")
                return false
            }
        default:
            showErrorMessage("Unknown microphone authorization status.")
            return false
        }
        
        
        // 2. Check Speech Recognition Availability
        
        // Check supported locales
        guard !SFSpeechRecognizer.supportedLocales().isEmpty else {
            showErrorMessage("Speech recognition is currently unavailable on this device.")
            return false
        }
        
        // Check supportsOnDeviceRecognition & initialization
        if let recognizer = speechRecognizer {
            if !recognizer.supportsOnDeviceRecognition {
                showErrorMessage("Speech recognition is currently unavailable on this device.")
                return false
            }
        } else {
            showErrorMessage("Speech recognizer could not be initialized.")
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func startRecognitionTask(
        request recognitionRequest: SFSpeechAudioBufferRecognitionRequest,
        inputNode: AVAudioInputNode
    ) {
        // Erase previous text
        recognizedText = ""
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            // Handle speech result
            if let result = result {
                DispatchQueue.main.async {
                    let newText = result.bestTranscription.formattedString
                    if self.isRecording && !self.isRecognitionPaused && !newText.isEmpty {
                        self.recognizedText = newText
                        // Wait after speech
                        if !self.manuallyConfirmSpeech {
                            self.startSilenceTimer(timeout: 1.0)
                        }
                    }
                }
                isFinal = result.isFinal
            }
            
            // Handle final
            if error != nil || isFinal {
                if self.isRecognitionPaused {
                    return
                }
                inputNode.removeTap(onBus: 0)
                self.stopRecording()
            }
        }
    }
    
    private func startSilenceTimer(timeout: Double) {
        stopSilenceTimer()
        
        DispatchQueue.main.async {
            self.silenceTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
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
