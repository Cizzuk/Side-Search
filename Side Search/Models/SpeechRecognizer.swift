//
//  SpeechRecognizer.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import AVFoundation
import Combine
import Speech
import UIKit

class SpeechRecognizer: ObservableObject {
    private let userSettings = UserSettings.shared

    @Published var isRecording = false
    @Published var isRecognizing = false
    
    @Published var recognizedText = ""
    @Published var micLevel: Float = 0.0 // For UI animation
    
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var showError = false
    
    // Callbacks
    var onSilenceTimeout: (() -> Void)?
    
    // MARK: - Private Properties
    
    private var isInBackground = false
    
    lazy private var audioSession = AVAudioSession.sharedInstance()
    lazy private var audioEngine = AVAudioEngine()
    lazy private var audioMixer = AVAudioMixerNode()
    
    private var speechRecognizer: SFSpeechRecognizer? {
        // Get a Locale Setting
        if let speechLocale = userSettings.speechLocale {
            return SFSpeechRecognizer(locale: speechLocale)
        }
        
        // Fallback if no locale is set
        return SFSpeechRecognizer()
    }
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Silence Detection Settings
    private var silenceTimer: Timer?
    private var manuallyConfirmSpeech: Bool {
        userSettings.manuallyConfirmSpeech
    }
    
    // MARK: - Initialization
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAvailableInputsChange),
            name: AVAudioSession.availableInputsChangeNotification,
            object: audioSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Recording Controls
    
    func startRecording() {
        Task {
            // Cancel any existing recognition task
            stopRecognize()
            
            // Check Availability
            guard await checkAvailability() else { return }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                // Reset audio engine and mixer
                audioEngine.reset()
                audioMixer.reset()
                
                // Check microphone availability
                guard isMicrophoneAvailable() else {
                    showErrorMessage("No microphone input available.")
                    return
                }
                
                // Configure the audio session
                do {
                    try audioSession.setCategory(
                        .playAndRecord,
                        mode: .measurement,
                        options: [.allowBluetoothA2DP, .mixWithOthers]
                    )
                    try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    showErrorMessage("Audio session setup failed: \(error.localizedDescription)")
                    return
                }
                
                let format = audioEngine.inputNode.inputFormat(forBus: 0)
                
                // Setup the mixer
                if audioEngine.attachedNodes.contains(audioMixer) {
                    audioEngine.disconnectNodeInput(audioMixer)
                    audioEngine.disconnectNodeOutput(audioMixer)
                    audioEngine.detach(audioMixer)
                }
                
                audioEngine.attach(audioMixer)
                audioEngine.connect(audioEngine.inputNode, to: audioMixer, format: format)
                audioEngine.connect(audioMixer, to: audioEngine.mainMixerNode, format: format)
                audioMixer.outputVolume = 0.0
                
                // Setup the microphone input
                audioEngine.inputNode.installTap(
                    onBus: 0,
                    bufferSize: 1024,
                    format: format
                ) { [weak self] (buffer, when) in
                    guard let self = self else { return }
                    recognitionRequest?.append(buffer)
                    calcMicLevel(from: buffer)
                }
                
                // Start audio engine
                audioEngine.prepare()
                
                do {
                    try audioEngine.start()
                    DispatchQueue.main.async {
                        self.isRecording = true
                        // Start speech recognition
                        self.startRecognize()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.stopRecording()
                    }
                    showErrorMessage("Audio engine couldn't start: \(error.localizedDescription)")
                    return
                }
            }
        }
    }
    
    func stopRecording() {
        stopRecognize()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            
            if isRecording {
                // Deactivate the audio session
                do {
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Failed to deactivate audio session: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.isRecording = false
                self.micLevel = 0.0
            }
        }
    }
    
    // MARK: - Speech Recognition Controls
    
    func stopRecognize() {
        guard isRecognizing else { return }
        
        stopSilenceTimer()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let recognitionRequest = recognitionRequest {
                recognitionRequest.endAudio()
                self.recognitionRequest = nil
            }
            
            if let recognitionTask = recognitionTask {
                recognitionTask.finish()
                self.recognitionTask = nil
            }
            
            DispatchQueue.main.async {
                self.isRecognizing = false
            }
        }
    }
    
    func startRecognize() {
        guard isRecording, !isRecognizing else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest.requiresOnDeviceRecognition = true
            recognitionRequest.shouldReportPartialResults = true
            self.recognitionRequest = recognitionRequest
            
            startRecognitionTask(request: recognitionRequest, inputNode: audioEngine.inputNode)
            setFirstSilenceTimer() // First wait
            
            DispatchQueue.main.async {
                self.isRecognizing = true
            }
        }
    }
    
    private func startRecognitionTask(
        request recognitionRequest: SFSpeechAudioBufferRecognitionRequest,
        inputNode: AVAudioInputNode
    ) {
        DispatchQueue.main.async {
            // Erase previous text
            self.recognizedText = ""
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            // Handle speech result
            if let result = result {
                let newText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    if self.isRecording && self.isRecognizing && !newText.isEmpty {
                        self.recognizedText = newText
                        // Wait after speech
                        if !self.manuallyConfirmSpeech {
                            self.startSilenceTimer(timeout: 1.0)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Availability Checks
    
    @MainActor
    func checkAvailability() async -> Bool {
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
                    DispatchQueue.main.async {
                        if !granted {
                            UserSettings.shared.startWithMicMuted = true
                        }
                    }
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
    
    func isMicrophoneAvailable() -> Bool {
        return audioSession.isInputAvailable && audioEngine.inputNode.numberOfInputs > 0
    }
        
    
    // MARK: - Silence Detection Timer
    
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
    
    func setFirstSilenceTimer() {
        guard isRecording else { return }
        startSilenceTimer(timeout: 10.0)
    }
    
    // MARK: - Handlers
    
    // Handle Audio Session Interruptions
    @objc private func handleInterruption(_ notification: Notification) {
        guard isRecording,
              let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        
        if type == .began {
            stopRecording()
        }
    }
    
    // Handle Available Inputs Change
    @objc private func handleAvailableInputsChange() {
        guard isRecording else { return }
        if !isMicrophoneAvailable() || !audioEngine.isRunning {
            stopRecording()
        }
    }
    
    // Handle App State Changes
    @objc private func handleAppStateChange() {
        isInBackground = UIApplication.shared.applicationState == .background
    }
    
    // MARK: - Helpers
    
    private func showErrorMessage(_ message: LocalizedStringResource) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
    
    private func calcMicLevel(from buffer: AVAudioPCMBuffer) {
        // Only calc in foreground
        guard !isInBackground && isRecognizing else { return }
        
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
}
