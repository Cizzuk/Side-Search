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
    @Published var shouldShowSafari = false
    @Published var errorMessage = ""
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
        
        // Fallback to en-US if not available
        return SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
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
        if !startWithMicMuted {
            startRecording()
        }
    }
    
    func startRecording() {
        // Cancel any existing recognition task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Check Availability
        if !checkAssistantAvailability() {
            return
        }
        
        // Erase previous text
        recognizedText = ""
        
        // Configure the audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
            showError = true
            return
        }
        
        // Create the recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Configure the input node
        let inputNode = audioEngine.inputNode
        
        // Ensure the recognition request is valid
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create a recognition request."
            showError = true
            return
        }
        
        // Configure recognition request
        recognitionRequest.shouldReportPartialResults = true
        
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
        guard !recognizedText.isEmpty else { return }
        
        // Stop recording before searching
        stopRecording()
        
        if let url = makeSearchURL(query: recognizedText) {
            switch openIn {
            case .inAppBrowser:
                self.searchURL = url
                self.shouldShowSafari = true
            case .defaultApp:
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                onDismiss?()
            }
        } else {
            // Handle invalid URL error
            self.errorMessage = "Invalid URL. Please check your search engine settings."
            self.showError = true
        }
    }
    
    func checkAssistantAvailability() -> Bool {
        // 1. Check URL Validity
        guard makeSearchURL(query: "test") != nil else {
            self.errorMessage = "Invalid search engine URL. Please check your settings."
            self.showError = true
            return false
        }
        
        // 2. Check Microphone Authorization
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            break
        case .denied:
            self.errorMessage = "Microphone access denied. Please enable it in Settings."
            self.showError = true
            return false
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                if !granted {
                    self.errorMessage = "Microphone access denied. Please enable it in Settings."
                    self.showError = true
                }
            }
        default:
            self.errorMessage = "Unknown microphone authorization status."
            self.showError = true
            return false
        }
        
        // 3. Check Speech Recognition Authorization
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .denied:
            self.errorMessage = "Speech recognition authorization denied. Please enable it in Settings."
            self.showError = true
            return false
        case .restricted:
            self.errorMessage = "Speech recognition is restricted on this device."
            self.showError = true
            return false
        default:
            self.errorMessage = "Unknown speech recognition status."
            self.showError = true
            return false
        }
    }
    
    func makeSearchURL(query: String) -> URL? {
        var searchQuery = query
        
        // Handle Max Query Length
        if let maxLength = SearchEngine.maxQueryLength {
            if searchQuery.count > maxLength {
                searchQuery = String(searchQuery.prefix(maxLength))
            }
        }
        
        // Handle Percent Encoding
        if !SearchEngine.disablePercentEncoding {
            if let encoded = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                searchQuery = encoded
            }
        }
        
        // Prepare the URL
        var urlString = SearchEngine.url
        
        // Replace the placeholder with the query
        urlString = urlString.replacingOccurrences(of: "%s", with: searchQuery)
        
        // URL Validation
        if !urlString.lowercased().hasPrefix("https://") && !urlString.lowercased().hasPrefix("http://") {
            return nil
        }
        
        // Create a URL object
        return URL(string: urlString)
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
