//
//  AssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import AVFoundation
import Combine
import Speech
import UIKit

class AssistantViewModel: ObservableObject {
    var onDismiss: (() -> Void)?
    @Published var recognizedText = ""
    @Published var isRecording = false
    @Published var searchURL: URL?
    @Published var showSafariView = false
    
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var isCriticalError = false
    @Published var showError = false
    
    // Get SearchEngine Settings
    @Published var SearchEngine: SearchEngineModel = {
        if let rawData = UserDefaults.standard.data(forKey: "defaultSearchEngine"),
           let engine = SearchEngineModel.fromJSON(rawData) {
            return engine
        }
        return SearchEngineModel()
    }()
    
    // MARK: - Private Properties
    
    // Get Start with Mic Muted Setting
    private var startWithMicMuted: Bool {
        UserDefaults.standard.bool(forKey: "startWithMicMuted")
    }
    
    // Get OpenIn Setting
    private var openIn: SettingsViewModel.OpenInOption {
        if let rawValue = UserDefaults.standard.string(forKey: "openIn"),
           let option = SettingsViewModel.OpenInOption(rawValue: rawValue) {
            return option
        }
        return .inAppBrowser
    }
    
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
    private var autoSearchOnSilence: Bool {
        UserDefaults.standard.bool(forKey: "autoSearchOnSilence")
    }
    private var silenceDuration: Double {
        let val = UserDefaults.standard.double(forKey: "silenceDuration")
        return val > 0 ? val : 2.0
    }
    
    // MARK: - Public Methods
    
    func startAssistant() {
        if !AssistantSupport.checkURLAvailability() {
            return
        }
        if !startWithMicMuted {
            startRecording()
        }
    }
    
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
            
            // Configure the audio session
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .allowBluetoothA2DP)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                errorMessage = "Audio session setup failed: \(error.localizedDescription)"
                showError = true
                return
            }
            
            // Create the recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            // Ensure the recognition request is valid
            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "Unable to create a recognition request."
                showError = true
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
                    self.recognizedText = result.bestTranscription.formattedString
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
                    self.isRecording = false
                }
            }
            
            // Configure the microphone input
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            
            // Start audio engine
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                do {
                    try audioEngine.start()
                    isRecording = true
                    startSilenceTimer()
                } catch {
                    errorMessage = "Audio engine couldn't start: \(error.localizedDescription)"
                    showError = true
                    return
                }
            }
        }
    }
    
    func stopRecording() {
        stopSilenceTimer()
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isRecording = false
            
            // Deactivate the audio session
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
        }
    }
    
    func performSearch() {
        // Stop recording before searching
        stopRecording()
        
        if let url = AssistantSupport.makeSearchURL(query: recognizedText) {
            switch openIn {
            case .inAppBrowser:
                self.searchURL = url
                self.showSafariView = true
            case .defaultApp:
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                onDismiss?()
            }
        } else {
            // Handle invalid URL error
            self.errorMessage = "Invalid Search URL. Please check your settings."
            self.showError = true
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
    
    private func startSilenceTimer() {
        guard autoSearchOnSilence else { return }
        stopSilenceTimer()
        
        DispatchQueue.main.async {
            self.silenceTimer = Timer.scheduledTimer(withTimeInterval: self.silenceDuration, repeats: false) { [weak self] _ in
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
        if !recognizedText.isEmpty {
            performSearch()
        }
    }
}
