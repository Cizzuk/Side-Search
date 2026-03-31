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
    private let appFlags = AppFlags.shared
    private let userSettings = UserSettings.shared

    @Published var showSwitchAssistantView = false
    @Published var showAssistant = false
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
            showAssistant = true
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
    
    private func validateAppState() {
        if !appFlags.isAssistantActive {
            UIApplication.shared.isIdleTimerDisabled = false
            ActivateIntent.setShouldBackground(false)
            if AssistantActivityManager.isActive() {
                AssistantActivityManager.endAll()
            }
        }
    }
    
    // MARK: - Assistant
    
    func activateAssistant(disableAnimations: Bool = false) {
        guard !appFlags.isAssistantActive else { return }
        
        var transaction = Transaction()
        transaction.disablesAnimations = disableAnimations || UIApplication.shared.applicationState != .active
        
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
            
            if let url = searchEngine.makeSearchURL() {
                switch userSettings.openURLsIn {
                case .inAppBrowser:
                    if SafariView.checkAvailability(at: url) {
                        safariViewURL = url
                        showModal(.safari)
                    } else {
                        // Fallback
                        showModal(.tmpCurtain)
                        UIApplication.shared.open(url)
                    }
                case .defaultApp:
                    showModal(.tmpCurtain)
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}
