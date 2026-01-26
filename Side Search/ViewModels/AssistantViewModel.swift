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
        // Override in subclass
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
        // Override in subclass
        stopRecording()
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
