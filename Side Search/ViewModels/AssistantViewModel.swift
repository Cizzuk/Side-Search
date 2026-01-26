//
//  AssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import UIKit

class AssistantViewModel: ObservableObject {
    enum MessageFrom {
        case user
        case assistant
        case system
    }
    
    enum MessageType {
        case text
    }
    
    // MARK: - Variables
    
    var onDismiss: (() -> Void)?
    
    // Input Field
    @Published var inputText = ""
    @Published var shouldInputFocused = false
    
    // Web View
    @Published var searchURL: URL?
    @Published var showSafariView = false
    
    // Error Alert
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var isCriticalError = false
    @Published var showError = false
    
    // Speech Recognizer=
    @Published var isRecording = false
    @Published var micLevel: Float = 0.0
    
    let speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()
    
    // URLBasedAssistant Settings
    @Published var assistantModel: URLBasedAssistantModel = {
        if let rawData = UserDefaults.standard.data(forKey: URLBasedAssistant.userDefaultsKey),
           let model = URLBasedAssistantModel.fromJSON(rawData) {
            return model
        }
        return URLBasedAssistantModel()
    }()
    
    // MARK: - Private Properties
    
    // Get Start with Mic Muted Setting
    private var startWithMicMuted: Bool {
        UserDefaults.standard.bool(forKey: "startWithMicMuted")
    }
    
    // MARK: - Initialization
    
    init() {
        setupSpeechRecognizerBindings()
    }
    
    private func setupSpeechRecognizerBindings() {
        speechRecognizer.$recognizedText
            .sink { [weak self] text in
                self?.inputText = text
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
        if !assistantModel.checkURLAvailability() {
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
    
    func confirmInput() {
        // Stop recording before searching
        stopRecording()
        
        if let url = assistantModel.makeSearchURL(query: inputText) {
            switch assistantModel.openIn {
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
        if !inputText.isEmpty {
            confirmInput()
        } else {
            stopRecording()
        }
    }
}
