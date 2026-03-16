//
//  AssistantViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import AVFAudio
import Combine
import SwiftUI
import UIKit

class AssistantViewModel: ObservableObject {
    enum DetentOption: String, CaseIterable, Identifiable {
        case small
        case medium
        case large
        case fullScreen
        
        var id: String { rawValue }
        
        static var defaultDetent: Self = .fullScreen
        
        var displayName: LocalizedStringResource {
            switch self {
            case .small:
                return "Small"
            case .medium:
                return "Medium"
            case .large:
                return "Large"
            case .fullScreen:
                return "Full Screen"
            }
        }
        
        var presentationDetent: PresentationDetent {
            switch self {
            case .small:
                return .fraction(0.3)
            case .medium:
                return .medium
            case .large:
                return .large
            case .fullScreen:
                return .large
            }
        }
        
        static var allOption: Set<PresentationDetent> {
            return Set(DetentOption.allCases.map { $0.presentationDetent })
        }
    }
    
    // MARK: - Variables
    
    var assistantType: AssistantType
    var chatID = UUID()
    var chatDate = Date()
    
    var currentScenePhase: ScenePhase = .active
    var isDismissed = false
    @Published var shouldDismiss = false
    
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
        if AccessibilitySettings.isAssistiveAccessEnabled {
            return true
        }
        
        return UserDefaults.standard.bool(forKey: "startWithMicMuted")
    }
    
    // MARK: - Initialization
    
    init(assistantType: AssistantType) {
        self.assistantType = assistantType
        setupNotificationObservers()
        setupSpeechRecognizerBindings()
    }
    
    deinit {
        if !isDismissed { dismissAssistant() }
    }
    
    // MARK: - Notification Observers
    
    private static let endAssistantDarwinCallback: CFNotificationCallback = { _, observer, _, _, _ in
        guard let observer else { return }
        let viewModel = Unmanaged<AssistantViewModel>.fromOpaque(observer).takeUnretainedValue()
        
        // Check Flag
        if GroupUserDefaults.bool(forKey: CFNotificationFlags.shouldEndAssistant) {
            viewModel.dismissAssistant()
            GroupUserDefaults.set(false, forKey: CFNotificationFlags.shouldEndAssistant)
        }
    }
    
    func setupNotificationObservers() {
        // Observe Darwin Notification for ending assistant from Live Activity
        GroupUserDefaults.set(false, forKey: CFNotificationFlags.shouldEndAssistant)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            AssistantViewModel.endAssistantDarwinCallback,
            CFNotificationName.shouldEndAssistant.rawValue,
            nil,
            .deliverImmediately
        )
        
        // Observe AVAudioSession Interruptions
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                guard let userInfo = notification.userInfo,
                      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue),
                      type == .began
                else { return }
                
                self?.dismissAssistant()
            }
            .store(in: &cancellables)
        
        // Observe App Termination
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.dismissAssistant()
            }
            .store(in: &cancellables)
    }
    
    func removeNotificationObservers() {
        // Remove All Darwin Notification Observers
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil
        )
    }
    
    // MARK: - Variable Bindings
    
    func setupSpeechRecognizerBindings() {
        speechRecognizer.$recognizedText
            .sink { [weak self] text in
                self?.inputText = text
            }
            .store(in: &cancellables)
        
        speechRecognizer.$isRecording
            .sink { [weak self] recording in
                self?.isRecording = recording
                self?.updateIdleTimerDisabled()
                self?.updateActivateIntent()
                self?.updateLiveActivityStatus()
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
    
    // MARK: - Lifecycle
    
    func onChange(scenePhase: ScenePhase) {
        currentScenePhase = scenePhase
        switch scenePhase {
        case .active:
            updateLiveActivityStatus()
        case .inactive:
            break
        case .background:
            // Background support check
            Task {
                if await isBackgroundAvailable() && isRecording {
                    let _ = await UserNotificationSupport.requestAuthorization()
                } else {
                    stopRecording()
                }
            }
        @unknown default:
            break
        }
    }
    
    func isBackgroundAvailable() async -> Bool {
        if !UserDefaults.standard.bool(forKey: "continueInBackground") {
            return false
        }
        if !assistantType.DescriptionProviderType.backgroundSupports {
            return false
        }
        if AccessibilitySettings.isAssistiveAccessEnabled {
            return false
        }
        return true
    }
    
    // MARK: - Override Methods
    
    func startAssistant() {
        // MARK: Override in subclass if needed
        if !startWithMicMuted {
            startRecording()
        }
    }
    
    func confirmInput() {
        // MARK: Override in subclass
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        pauseRecognize()
        
        // Add user message to history
        let userInput = inputText
        let userMessage = AssistantMessage(from: .user, content: userInput)
        addMessage(userMessage)
        
        inputText = ""
        responseIsPreparing = false
        resumeRecognize()
    }
    
    // MARK: - View Actions
    
    func dismissAssistant(fromView: Bool = false) {
        guard !isDismissed else { return }
        isDismissed = true
        
        if !fromView { shouldDismiss = true }
        removeNotificationObservers()
        stopRecording()
        saveChatHistory()
        UIApplication.shared.isIdleTimerDisabled = false
        ActivateIntent.setShouldBackground(false)
        AssistantActivityManager.endAll()
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
    
    // MARK: - Message History Management
    
    func saveChatHistory() {
        guard UserDefaults.standard.bool(forKey: "chatHistoryEnabled"),
              !messageHistory.isEmpty
        else { return }
        
        let chat = ChatHistory.Chat(
            id: chatID,
            date: chatDate,
            assistantType: assistantType,
            messages: messageHistory
        )
        
        ChatHistory.add(chat)
    }
    
    func addMessage(_ message: AssistantMessage) {
        messageHistory.append(message)
        
        // Set last message date as chat date
        chatDate = Date()
        
        // Send user notification
        if message.from != .user && currentScenePhase != .active {
            Task {
                if await UserNotificationSupport.requestAuthorization() {
                    await UserNotificationSupport.sendAssistantMessage(message: message)
                }
            }
        }
    }
    
    // MARK: - Speech Recognizer Actions
    
    func startRecording() {
        guard !responseIsPreparing else { return }
        speechRecognizer.startRecording()
    }
    
    func stopRecording() {
        speechRecognizer.stopRecording()
    }
    
    func pauseRecognize() {
        speechRecognizer.stopRecognize()
    }
    
    func resumeRecognize() {
        speechRecognizer.startRecognize()
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    // MARK: - Handlers
    
    // Handle repressing the Side Button
    func handleActivateIntent() {
        updateActivateIntent()
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
    
    // MARK: - Helpers
    
    func updateIdleTimerDisabled() {
        if isRecording {
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    func updateActivateIntent() {
        guard assistantType.DescriptionProviderType.backgroundSupports else {
            ActivateIntent.setShouldBackground(false)
            return
        }
        
        if isRecording {
            ActivateIntent.setShouldBackground(true)
        } else {
            ActivateIntent.setShouldBackground(false)
        }
    }
    
    func updateLiveActivityStatus() {
        guard assistantType.DescriptionProviderType.backgroundSupports else { return }
        
        if isRecording {
            if !AssistantActivityManager.isActive() {
                AssistantActivityManager.start()
            }
        } else {
            AssistantActivityManager.endAll()
        }
    }
}
