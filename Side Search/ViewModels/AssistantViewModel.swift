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
    static func make(chat: ChatHistory.Chat? = nil) -> AssistantViewModel {
        let chat = chat ?? ChatHistory.Chat(
            id: UUID(),
            date: Date(),
            assistantType: UserSettings.shared.currentAssistant,
            messages: []
        )
        return chat.assistantType.AssistantViewModelType.init(chat: chat)
    }
    
    private let appFlags = AppFlags.shared
    private let userSettings = UserSettings.shared

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
    
    @Published var chat: ChatHistory.Chat
    
    var currentScenePhase: ScenePhase = .active
    var isDismissed = false
    @Published var shouldDismiss = false
    
    @Published var detent = UserSettings.shared.assistantViewDetent.presentationDetent
    
    // Assistant State
    @Published var isRecording = false {
        didSet {
            updateIdleTimerDisabled()
            updateActivateIntent()
            updateLiveActivityStatus()
            if isRecording { shouldUnfocusInput = true }
        }
    }
    @Published var isRecognizing = false {
        didSet { updateLiveActivityStatus() }
    }
    @Published var responseIsPreparing = false {
        didSet { updateLiveActivityStatus() }
    }
    
    // Input Field
    @Published var inputText = ""
    @Published var shouldFocusInput = false
    @Published var shouldUnfocusInput = false
    
    // Web View
    @Published var searchURL: URL?
    @Published var showSafariView = false
    
    // Error Alert
    @Published var errorMessage: LocalizedStringResource = ""
    @Published var isCriticalError = false
    @Published var showError = false
    
    @Published var micLevel: Float = 0.0
    
    let speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()
    
    var startWithMicMuted: Bool {
        if AccessibilitySettings.isAssistiveAccessEnabled {
            return true
        }
        
        return userSettings.startWithMicMuted
    }
    
    // MARK: - Initialization
    
    required init(chat: ChatHistory.Chat) {
        self.chat = chat
        
        setupNotificationObservers()
        setupSpeechRecognizerBindings()
        assistantInitialize()
        appFlags.isAssistantActive = true
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
    
    private final func setupNotificationObservers() {
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
        
        // Observe App Termination
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.dismissAssistant()
            }
            .store(in: &cancellables)
    }
    
    private final func removeNotificationObservers() {
        // Remove All Darwin Notification Observers
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil
        )
    }
    
    // MARK: - Variable Bindings
    
    private final func setupSpeechRecognizerBindings() {
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
        
        speechRecognizer.$isRecognizing
            .sink { [weak self] recognizing in
                self?.isRecognizing = recognizing
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
    
    final func onChange(scenePhase: ScenePhase) {
        currentScenePhase = scenePhase
        switch scenePhase {
        case .active:
            if !responseIsPreparing && !isRecognizing && isRecording {
                stopRecording()
            }
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
    
    final func isBackgroundAvailable() async -> Bool {
        if !userSettings.continueInBackground {
            return false
        }
        if !chat.assistantType.DescriptionProviderType.backgroundSupports {
            return false
        }
        if AccessibilitySettings.isAssistiveAccessEnabled {
            return false
        }
        return true
    }
    
    // MARK: - Override Methods
    
    func assistantInitialize() {
        // MARK: Override in subclass
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
    
    final func activateAssistant() {
        updateActivateIntent()
        
        // Check availability
        guard chat.assistantType.canUse else {
            errorMessage = "This assistant is not available."
            isCriticalError = true
            showError = true
            return
        }
        
        guard !isCriticalError else { return }
        
        if isRecording {
            if isRecognizing {
                // Reset silence timer
                speechRecognizer.setFirstSilenceTimer()
            } else {
                // Resume recognition
                resumeRecognize()
            }
        } else {
            if startWithMicMuted {
                // Show keyboard
                shouldFocusInput = true
            } else {
                // Start recording
                startRecording()
            }
        }
    }
    
    final func dismissAssistant(fromView: Bool = false) {
        guard !isDismissed else { return }
        isDismissed = true
        
        if !fromView { shouldDismiss = true }
        removeNotificationObservers()
        stopRecording()
        saveChatHistory()
        UIApplication.shared.isIdleTimerDisabled = false
        ActivateIntent.setShouldBackground(false)
        AssistantActivityManager.endAll()
        appFlags.isAssistantActive = false
    }
    
    final func openSafariView(at url: URL) {
        if SafariView.checkAvailability(at: url) {
            searchURL = url
            showSafariView = true
        } else {
            // Fallback
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - Message History Management
    
    final func addMessage(_ message: AssistantMessage) {
        chat.messages.append(message)
        
        // Set last message date as chat date
        chat.date = Date()
        
        saveChatHistory()
        
        // Send user notification
        if message.from != .user && currentScenePhase != .active {
            Task {
                if await UserNotificationSupport.requestAuthorization() {
                    await UserNotificationSupport.sendAssistantMessage(message: message)
                }
            }
        }
    }
    
    final func saveChatHistory() {
        guard userSettings.chatHistoryEnabled,
              !chat.messages.isEmpty
        else { return }
        
        ChatHistory.save(chat)
    }
    
    // MARK: - Speech Recognizer Actions
    
    final func startRecording() {
        guard !responseIsPreparing, !isCriticalError else { return }
        speechRecognizer.startRecording()
    }
    
    final func stopRecording() {
        speechRecognizer.stopRecording()
    }
    
    final func pauseRecognize() {
        speechRecognizer.stopRecognize()
    }
    
    final func resumeRecognize() {
        guard !isCriticalError else { return }
        speechRecognizer.startRecognize()
    }
    
    final func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    // MARK: - Handlers
    
    // Handle Speech Recognizer Silence Timeout
    final func handleSilenceTimeout() {
        if !inputText.isEmpty {
            confirmInput()
            return
        }
        
        Task {
            if await isBackgroundAvailable() && currentScenePhase == .background && userSettings.standbyInBackground {
                // Enter standby in background
                pauseRecognize()
            } else {
                stopRecording()
            }
        }
    }
    
    // MARK: - Helpers
    
    private final func updateIdleTimerDisabled() {
        if isRecognizing {
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private final func updateActivateIntent() {
        guard chat.assistantType.DescriptionProviderType.backgroundSupports else {
            ActivateIntent.setShouldBackground(false)
            return
        }
        
        if isRecording {
            ActivateIntent.setShouldBackground(true)
        } else {
            ActivateIntent.setShouldBackground(false)
        }
    }
    
    private final func updateLiveActivityStatus() {
        guard chat.assistantType.DescriptionProviderType.backgroundSupports,
              !isDismissed
        else { return }
        
        let state = makeLiveActivityState()
        
        if AssistantActivityManager.isActive() {
            // If mic is off, end activity
            if state.state == .off {
                AssistantActivityManager.endAll()
                return
            }
            
            // Else, update activity
            AssistantActivityManager.update(state: state)
            return
        }
        
        // If recognizing started, start activity
        if state.state == .listening {
            AssistantActivityManager.start(state: state)
        }
    }
    
    private final func makeLiveActivityState() -> AssistantActivityAttributes.ContentState {
        if responseIsPreparing {
            return .init(state: .waitingForResponse)
        }
        
        if isRecording {
            if isRecognizing {
                return .init(state: .listening)
            } else {
                return .init(state: .pausingRecognition)
            }
        }
        
        return .init(state: .off)
    }
}
