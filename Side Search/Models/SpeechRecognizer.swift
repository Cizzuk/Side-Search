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
    private var isAudioSessionActive = false
    private var isInputTapInstalled = false
    
    lazy private var audioSession = AVAudioSession.sharedInstance()
    lazy private var audioEngine = AVAudioEngine()
    
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
    
    private enum RecognizerError: LocalizedError {
        case microphoneUnavailable
        
        var errorDescription: String? {
            switch self {
            case .microphoneUnavailable:
                return "No microphone input available."
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(validateMicState(_:)),
            name: AVAudioSession.availableInputsChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(validateMicState(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
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
        stopSilenceTimer()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        stopAudioEngine()
        deactivateAudioSession()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Recording Controls
    
    func startRecording() {
        Task {
            guard await checkAvailability() else { return }
            
            guard !isRecording else { return }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                stopRecognize()
                
                do {
                    try configureAudioSession()
                    try configureAudioEngine()
                    try audioEngine.start()
                    
                    DispatchQueue.main.async {
                        self.isRecording = true
                        self.startRecognize()
                    }
                } catch {
                    stopRecording()
                    showErrorMessage("Failed to start recording: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func stopRecording() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            stopRecognize()
            stopAudioEngine()
            deactivateAudioSession()
            
            if isRecording {
                DispatchQueue.main.async {
                    self.isRecording = false
                    self.micLevel = 0.0
                }
            }
        }
    }
    
    // MARK: - Speech Recognition Controls
    
    func stopRecognize() {
        stopSilenceTimer()
        
        if let request = recognitionRequest {
            request.endAudio()
            recognitionRequest = nil
        }
        
        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
        }
        
        if isRecognizing {
            DispatchQueue.main.async {
                self.isRecognizing = false
            }
        }
    }
    
    func startRecognize() {
        guard isRecording, !isRecognizing else { return }
        
        guard let recognizer = speechRecognizer else {
            handleRecognitionError("Failed to prepare speech recognition.")
            return
        }
        
        guard recognizer.isAvailable else {
            handleRecognitionError("Speech recognition is currently unavailable on this device.")
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        recognitionRequest = request
        
        startRecognitionTask(request: request, recognizer: recognizer)
        setFirstSilenceTimer()
        
        DispatchQueue.main.async {
            self.isRecognizing = true
        }
    }
    
    private func startRecognitionTask(
        request recognitionRequest: SFSpeechAudioBufferRecognitionRequest,
        recognizer: SFSpeechRecognizer
    ) {
        // Erase previous text
        DispatchQueue.main.async {
            self.recognizedText = ""
        }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            // Handle speech result
            if let result = result {
                let newText = result.bestTranscription.formattedString
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if isRecording && isRecognizing && !newText.isEmpty {
                        recognizedText = newText
                        // Wait after speech
                        if !manuallyConfirmSpeech {
                            startSilenceTimer(timeout: 1.0)
                        }
                    }
                }
            }
            
            if let error = error {
                guard isRecognizing else { return }
                showErrorMessage("Speech recognition stopped: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Availability Checks
    
    @MainActor
    private func checkAvailability() async -> Bool {
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
    
    private func isMicrophoneAvailable() -> Bool {
        audioSession.isInputAvailable
        && audioEngine.inputNode.numberOfInputs > 0
        && audioEngine.inputNode.inputFormat(forBus: 0).channelCount > 0
    }
    
    // MARK: - Silence Detection Timer
    
    private func startSilenceTimer(timeout: Double) {
        stopSilenceTimer()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            silenceTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                self.silenceTimerFired()
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
    
    @objc private func handleMediaServicesReset() {
        stopRecording()
    }
    
    @objc private func handleAppStateChange() {
        isInBackground = UIApplication.shared.applicationState == .background
        validateMicState()
    }
    
    private func handleRecognitionError(_ message: LocalizedStringResource) {
        guard isRecognizing, recognitionTask != nil, recognitionRequest != nil else { return }
        
        // If record is already stopped, show error only
        
        guard isRecording else {
            showErrorMessage(message)
            return
        }
        
        // If should & can keep recording for background standby, only stop recognition
        
        let shouldKeepRecording = (
            userSettings.continueInBackground
            && userSettings.standbyInBackground
            && isInBackground
        )
        
        let canKeepRecording = (
            audioEngine.isRunning
            && isMicrophoneAvailable()
        )
        
        if shouldKeepRecording && canKeepRecording {
            stopRecognize()
            showErrorMessage(message)
            return
        }
        
        // Otherwise, stop recording
        
        stopRecording()
        showErrorMessage(message)
    }
    
    // MARK: - Helpers
    
    private func showErrorMessage(_ message: LocalizedStringResource) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
    
    @objc private func validateMicState(_ notification: Notification? = nil) {
        guard isRecording else { return }
        
        if !isMicrophoneAvailable() || !audioEngine.isRunning {
            stopRecording()
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
    
    private func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.mixWithOthers, .allowBluetoothA2DP]
        )
        try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        isAudioSessionActive = true
    }
    
    private func configureAudioEngine() throws {
        guard isMicrophoneAvailable() else {
            throw RecognizerError.microphoneUnavailable
        }
        
        audioEngine.stop()
        audioEngine.reset()
        
        if isInputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isInputTapInstalled = false
        }
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.channelCount > 0 else {
            throw RecognizerError.microphoneUnavailable
        }
        
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { [weak self] buffer, _ in
            guard let self = self else { return }
            recognitionRequest?.append(buffer)
            calcMicLevel(from: buffer)
        }
        
        isInputTapInstalled = true
        audioEngine.prepare()
    }
    
    private func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.reset()
        
        if isInputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isInputTapInstalled = false
        }
    }
    
    private func deactivateAudioSession() {
        guard isAudioSessionActive else { return }
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        isAudioSessionActive = false
    }
}
