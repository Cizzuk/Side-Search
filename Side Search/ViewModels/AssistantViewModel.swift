//
//  AssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import UIKit
import SwiftUI

class AssistantViewModel: ObservableObject {
    enum DetentOption: String, CaseIterable, Identifiable {
        case small
        case normal
        case large
        
        var id: String { rawValue }
        
        static var defaultDetent: Self {
            if UIAccessibility.isVoiceOverRunning {
                return .large
            }
            return .normal
        }
        
        var displayName: LocalizedStringResource {
            switch self {
            case .small:
                return "Small"
            case .normal:
                return "Normal"
            case .large:
                return "Large"
            }
        }
        
        var presentationDetent: PresentationDetent {
            switch self {
            case .small:
                return .fraction(0.3)
            case .normal:
                return .medium
            case .large:
                return .large
            }
        }
        
        static var allOption: Set<PresentationDetent> {
            return Set(DetentOption.allCases.map { $0.presentationDetent })
        }
    }
    
    // MARK: - Variables
    
    var onDismiss: (() -> Void)?
    
    @Published var detent: PresentationDetent = {
        if let rawValue = UserDefaults.standard.string(forKey: "assistantViewDetent"),
           let option = DetentOption(rawValue: rawValue) {
            return option.presentationDetent
        }
        return DetentOption.defaultDetent.presentationDetent
    }()
    
    // Input Field
    @Published var inputText = ""
    @Published var shouldInputFocused = false
    
    @Published var messageHistory: [AssistantMessage] = []
    @Published var responseIsPreparing = false
    
    // Web View
    @Published var searchURL: URL?
    @Published var showSafariView = false
    
    // Error Alert
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var isCriticalError = false
    @Published var showError = false
    
    // Speech Recognizer
    @Published var isRecording = false
    @Published var micLevel: Float = 0.0
    
    let speechRecognizer = SpeechRecognizer()
    var cancellables = Set<AnyCancellable>()
    
    var startWithMicMuted: Bool {
        UserDefaults.standard.bool(forKey: "startWithMicMuted")
    }
    
    // MARK: - Initialization
    
    init() {
        setupSpeechRecognizerBindings()
    }
    
    func setupSpeechRecognizerBindings() {
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
    
    // MARK: - Methods
    
    func startAssistant() {
        // MARK: Override in subclass if needed
        if !startWithMicMuted {
            startRecording()
        }
    }
    
    func startRecording() {
        guard !responseIsPreparing else { return }
        speechRecognizer.startRecording()
    }
    
    func stopRecording() {
        speechRecognizer.stopRecording()
    }
    
    func confirmInput() {
        // MARK: Override in subclass
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        stopRecording()
        
        // Add user message to history
        let userInput = inputText
        let userMessage = AssistantMessage(from: .user, content: userInput)
        messageHistory.append(userMessage)
        
        inputText = ""
        responseIsPreparing = false
    }
    
    func openSafariView(at url: URL) {
        if SafariView.checkAvailability(at: url) {
            searchURL = url
            showSafariView = true
        } else {
            // Fallback
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // Handle repressing the Side Button
    func activateAssistant() {
        if !isRecording && !startWithMicMuted {
            startRecording()
        }
    }
    
    // Handle Speech Recognizer Silence Timeout
    func handleSilenceTimeout() {
        guard speechRecognizer.isRecording else { return }
        if !inputText.isEmpty {
            confirmInput()
        } else {
            stopRecording()
        }
    }
}
