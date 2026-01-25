//
//  AssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import UIKit

class AssistantViewModel: ObservableObject {
    var onDismiss: (() -> Void)?
    @Published var recognizedText = ""
    @Published var isRecording = false
    @Published var micLevel: Float = 0.0
    @Published var searchURL: URL?
    @Published var showSafariView = false
    
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var isCriticalError = false
    @Published var showError = false
    @Published var shouldInputFocused = false
    
    // Get SearchEngine Settings
    @Published var SearchEngine: SearchEngineModel = {
        if let rawData = UserDefaults.standard.data(forKey: "defaultSearchEngine"),
           let engine = SearchEngineModel.fromJSON(rawData) {
            return engine
        }
        return SearchEngineModel()
    }()
    
    // Speech Recognizer
    let speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()
    
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
    
    // MARK: - Initialization
    
    init() {
        setupSpeechRecognizerBindings()
    }
    
    private func setupSpeechRecognizerBindings() {
        speechRecognizer.$recognizedText
            .sink { [weak self] text in
                self?.recognizedText = text
            }
            .store(in: &cancellables)
        
        speechRecognizer.$isRecording
            .sink { [weak self] recording in
                self?.isRecording = recording
            }
            .store(in: &cancellables)
        
        speechRecognizer.$micLevel
            .sink { [weak self] level in
                self?.micLevel = level
            }
            .store(in: &cancellables)
        
        speechRecognizer.$errorMessage
            .sink { [weak self] message in
                self?.errorMessage = message
            }
            .store(in: &cancellables)
        
        speechRecognizer.$showError
            .sink { [weak self] show in
                self?.showError = show
            }
            .store(in: &cancellables)
        
        speechRecognizer.onSilenceTimeout = { [weak self] in
            self?.handleSilenceTimeout()
        }
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
        speechRecognizer.startRecording()
    }
    
    func stopRecording() {
        speechRecognizer.stopRecording()
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
    
    // MARK: - Private Methods
    
    private func handleSilenceTimeout() {
        guard speechRecognizer.isRecording else { return }
        if !recognizedText.isEmpty {
            performSearch()
        } else {
            stopRecording()
        }
    }
}
