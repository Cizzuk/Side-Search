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

    @Published var showAssistant = false
    @Published var showSafariView = false
    @Published var safariViewURL: URL?
    @Published var showTmpCurtain = false
    
    @Published var path: Route? = .assistantSettings

    enum Modals {
        case assistant
        case safari
        case tmpCurtain
    }
    
    enum Route: Hashable {
        case assistantSettings
        case help, chatHistory
        case about, changeIcon
    }
    
    func showModal(_ modal: Modals) {
        closeAllModals()
        switch modal {
        case .assistant:
            showAssistant = true
        case .safari:
            showSafariView = true
        case .tmpCurtain:
            showTmpCurtain = true
        }
    }

    func closeAllModals() {
        showAssistant = false
        showSafariView = false
        showTmpCurtain = false
    }
    
    // MARK: - Lifecycle
    
    func onChange(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            Side_SearchApp.validateAppState()
        case .inactive:
            break
        case .background:
            Side_SearchApp.validateAppState()
        @unknown default:
            break
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
