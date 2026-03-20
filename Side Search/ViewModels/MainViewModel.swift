//
//  MainViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import UIKit
import SwiftUI

class MainViewModel: ObservableObject {
    private let userSettings = UserSettings.shared

    @Published var showSwitchAssistantView = false
    @Published var showAssistant = false
    @Published var showAssistantFullScreen = false
    @Published var showChatHistoryView = false
    @Published var showHelpView = false
    @Published var showChangeIconView = false
    @Published var showSafariView = false
    @Published var safariViewURL: URL?
    @Published var showTmpCurtain = false

    enum Modals {
        case switchAssistant
        case assistant
        case chatHistory
        case help
        case changeIcon
        case safari
        case tmpCurtain
    }
    
    func showModal(_ modal: Modals) {
        closeAllModals()
        switch modal {
        case .switchAssistant:
            showSwitchAssistantView = true
        case .assistant:
            if userSettings.assistantViewDetent == .fullScreen {
                showAssistant = false
                showAssistantFullScreen = true
            } else {
                showAssistantFullScreen = false
                showAssistant = true
            }
        case .chatHistory:
            showChatHistoryView = true
        case .help:
            showHelpView = true
        case .changeIcon:
            showChangeIconView = true
        case .safari:
            showSafariView = true
        case .tmpCurtain:
            showTmpCurtain = true
        }
    }

    func closeAllModals() {
        showSwitchAssistantView = false
        showAssistant = false
        showAssistantFullScreen = false
        showChatHistoryView = false
        showHelpView = false
        showChangeIconView = false
        showSafariView = false
        showTmpCurtain = false
    }
    
    // MARK: - Lifecycle
    
    func onChange(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            validateAppState()
        case .inactive:
            break
        case .background:
            validateAppState()
        @unknown default:
            break
        }
    }
    
    func validateAppState() {
        if userSettings.currentAssistant.DescriptionProviderType.isBlocked() ||
            !userSettings.currentAssistant.DescriptionProviderType.isAvailable() {
            userSettings.currentAssistant = .defaultType
        }
        
        if !(showAssistant || showAssistantFullScreen) {
            ActivateIntent.setShouldBackground(false)
            
            if AssistantActivityManager.isActive() {
                AssistantActivityManager.endAll()
            }
        }
    }
    
    // MARK: - Assistant
    
    func activateAssistant() {
        var transaction = Transaction()
        // Disable animations when activating assistant from background
        transaction.disablesAnimations = UIApplication.shared.applicationState != .active
        
        withTransaction(transaction) {
            // Close sheets and covers
            closeAllModals()
            
            // Check current assistant type
            if userSettings.currentAssistant != .urlBased {
                showModal(.assistant)
                return
            }
            
            let searchEngine = URLBasedAssistantModel.load()
            
            // Check if query input is needed
            if searchEngine.needQueryInput() {
                showModal(.assistant)
                return
            }
            
            // Check if SafariView is available
            if searchEngine.openIn == .inAppBrowser && searchEngine.checkSafariViewAvailability() {
                safariViewURL = URL(string: searchEngine.url)
                showModal(.safari)
                return
            }
            
            if let url = URL(string: searchEngine.url) {
                showModal(.tmpCurtain)
                UIApplication.shared.open(url)
            }
        }
    }
}
