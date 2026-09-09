//
//  BaseAssistantService.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import AVFAudio
import Combine
import SwiftUI
import UIKit

class BaseAssistantService: ObservableObject {
    private let appFlags = AppFlags.shared
    private let userSettings = UserSettings.shared
    
    // MARK: - Variables
    
    @Published var chat: ChatHistorySupport.Chat
    
    // View State
    var lastScenePhase: ScenePhase = .active
    private var isDismissed = false
    
    // Assistant State
    @Published var isEnded = false {
        didSet { if isEnded { stopRecording() } }
    }
    
    @Published var isRecording = false {
        didSet {
            updateIdleTimerDisabled()
            updateActivateIntent()
            updateLiveActivityStatus()
        }
    }
    
    @Published var isRecognizing = false {
        didSet {
            handleStartRecognitionFeedback()
            updateLiveActivityStatus()
        }
    }
    
    @Published var responseIsPreparing = false {
        didSet { updateLiveActivityStatus() }
    }
    
    @Published var micLevel: Float = 0.0
    
    // Input Field
    @Published var inputText = ""
    
    // Callbacks
    var dismissView: (() -> Void)?
    var openURL: ((URL) -> Void)?
    var onError: ((LocalizedStringResource) -> Void)? {
        didSet { setupSpeechRecognizerErrorHandling() }
    }
    
    private var speechRecognizer: SpeechRecognizerService? = SpeechRecognizerService() {
        didSet { setupSpeechRecognizerErrorHandling() }
    }
    
    private let soundEffect = SoundEffectService.shared
    private var shouldStartRecognitionFeedback = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    required init(chat: ChatHistorySupport.Chat) {
        self.chat = chat
        
        setupNotificationObservers()
        setupSpeechRecognizerBindings()
        assistantInitialize()
        appFlags.isAssistantActive = true
    }
    
    deinit {
        if !isDismissed { dismissAssistant() }
    }
    
    private func setupSpeechRecognizerErrorHandling() {
        speechRecognizer?.onError = { [weak self] error in
            self?.onError?(error)
        }
    }
    
    // MARK: - Notification Observers
    
    private static let endAssistantDarwinCallback: CFNotificationCallback = { _, observer, _, _, _ in
        guard let observer else { return }
        let instance = Unmanaged<BaseAssistantService>.fromOpaque(observer).takeUnretainedValue()
        
        // Check Flag
        if GroupUserDefaults.bool(forKey: CFNotificationFlags.shouldEndAssistant) {
            instance.dismissAssistant()
            GroupUserDefaults.set(false, forKey: CFNotificationFlags.shouldEndAssistant)
        }
    }
    
    private final func setupNotificationObservers() {
        // Observe Darwin Notification for ending assistant from Live Activity
        GroupUserDefaults.set(false, forKey: CFNotificationFlags.shouldEndAssistant)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            BaseAssistantService.endAssistantDarwinCallback,
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
        speechRecognizer?.$recognizedText
            .sink { [weak self] text in
                self?.inputText = text
            }
            .store(in: &cancellables)
        
        speechRecognizer?.$isRecording
            .sink { [weak self] recording in
                self?.isRecording = recording
            }
            .store(in: &cancellables)
        
        speechRecognizer?.$isRecognizing
            .sink { [weak self] recognizing in
                self?.isRecognizing = recognizing
            }
            .store(in: &cancellables)
        
        speechRecognizer?.$micLevel
            .sink { [weak self] level in
                self?.micLevel = level
            }
            .store(in: &cancellables)
        
        speechRecognizer?.onSilenceTimeout = { [weak self] in
            self?.handleSilenceTimeout()
        }
    }
    
    // MARK: - Lifecycle
    
    final func scenePhaseUpdate(_ scenePhase: ScenePhase) {
        lastScenePhase = scenePhase
        switch scenePhase {
        case .active:
            break
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
        // MARK: Override in subclass if needed
    }
    
    func processInput() {
        // MARK: Override in subclass
        guard !responseIsPreparing else { return }
        responseIsPreparing = true
        pauseRecognize()
        
        // Add user message to history
        let userInput = inputText
        let userMessage = AssistantMessage(from: .user, content: userInput)
        addMessage(userMessage)
        
        // Invalid assistant error
        let assistantResponse = "Error. This assistant is invalid."
        let assistantMessage = AssistantMessage(from: .system, content: assistantResponse)
        addMessage(assistantMessage)
        
        print("Assistant Service: processInput() should be overridden in subclass.")
        
        inputText = ""
        responseIsPreparing = false
        resumeRecognize()
    }
    
    // MARK: - View Actions
    
    final func confirmInput() {
        guard checkAvailability() else {
            if isRecording { stopRecording() }
            return
        }
        
        processInput()
    }
    
    final func activateAssistant() {
        updateActivateIntent()
        
        guard checkAvailability() else { return }
        
        if isRecording {
            if isRecognizing {
                if inputText.isEmpty {
                    // Reset silence timer
                    speechRecognizer?.setFirstSilenceTimer()
                } else {
                    // If input text exists, confirm it
                    soundEffect.play(.completeRecognition)
                    confirmInput()
                }
            } else {
                // Resume recognition
                shouldStartRecognitionFeedback = true
                resumeRecognize()
            }
        } else {
            if !userSettings.startWithMicMuted {
                // Start recording
                shouldStartRecognitionFeedback = true
                startRecording()
            }
        }
    }
    
    final func dismissAssistant() {
        guard !isDismissed else { return }
        isDismissed = true
        
        dismissView?()
        removeNotificationObservers()
        stopRecording()
        saveChatHistory()
        speechRecognizer = nil
        
        UIApplication.shared.isIdleTimerDisabled = false
        ActivateIntent.setShouldBackground(false)
        AssistantActivityManager.endAll()
        appFlags.isAssistantActive = false
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // MARK: - Message History Management
    
    final func addMessage(_ message: AssistantMessage) {
        // If id already exists, replace it, else append
        if let index = chat.messages.firstIndex(where: { $0.id == message.id }) {
            chat.messages[index] = message
        } else {
            chat.messages.append(message)
        }
        
        // Set last message date as chat date
        chat.date = Date()
        
        saveChatHistory()
        
        // Send user notification
        if message.from != .user && lastScenePhase != .active {
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
        
        ChatHistorySupport.save(chat)
    }
    
    // MARK: - Speech Recognizer Actions
    
    final func startRecording() {
        guard !responseIsPreparing, checkAvailability() else { return }
        speechRecognizer?.startRecording()
    }
    
    final func stopRecording() {
        speechRecognizer?.stopRecording()
    }
    
    final func pauseRecognize() {
        speechRecognizer?.stopRecognize()
    }
    
    final func resumeRecognize() {
        guard checkAvailability() else { return }
        speechRecognizer?.startRecognize()
    }
    
    // MARK: - Handlers
    
    // Handle Speech Recognizer Silence Timeout
    final func handleSilenceTimeout() {
        guard !userSettings.manuallyConfirmSpeech else { return }
        
        if !inputText.isEmpty {
            soundEffect.play(.completeRecognition)
            confirmInput()
            return
        }
        
        Task {
            if await isBackgroundAvailable() && lastScenePhase == .background && userSettings.standbyInBackground {
                // Enter standby in background
                pauseRecognize()
            } else {
                stopRecording()
            }
        }
    }
    
    final func handleStartRecognitionFeedback() {
        guard shouldStartRecognitionFeedback else { return }
        shouldStartRecognitionFeedback = false
        if isRecognizing {
            soundEffect.play(.startRecognition)
        }
    }
    
    // MARK: - Helpers
    
    final func checkAvailability(shouldShowError: Bool = true) -> Bool {
        if isEnded { return false }
        
        if !chat.assistantType.DescriptionProviderType.isAvailable() {
            if shouldShowError {
                onError?("This assistant is not available.")
            }
            return false
        }
        
        return true
    }
    
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
