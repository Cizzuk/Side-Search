//
//  MainViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import UIKit
import Speech
import SwiftUI

class MainViewModel: ObservableObject {
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
            if assistantViewDetent == .fullScreen {
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
            if !showAssistant && AssistantActivityManager.isActive() {
                AssistantActivityManager.endAll()
            }
        case .inactive:
            break
        case .background:
            break
        @unknown default:
            break
        }
    }
    
    func activateAssistant() {
        // Close sheets and covers
        closeAllModals()
        
        // Check current assistant type
        if currentAssistant != .urlBased {
            showModal(.assistant)
            return
        }
        
        let SearchEngine = URLBasedAssistantModel.load()
        
        // Check if query input is needed
        if SearchEngine.needQueryInput() {
            showModal(.assistant)
            return
        }
        
        // Check if SafariView is available
        if SearchEngine.openIn == .inAppBrowser && SearchEngine.checkSafariViewAvailability() {
            safariViewURL = URL(string: SearchEngine.url)
            showModal(.safari)
            return
        }
        
        if let url = URL(string: SearchEngine.url) {
            showModal(.tmpCurtain)
            UIApplication.shared.open(url)
        }
    }
    
    @Published var currentAssistant: AssistantType = {
        return AssistantType.current
    }() {
        didSet {
            UserDefaults.standard.set(currentAssistant.rawValue, forKey: "currentAssistant")
        }
    }
    
    // MARK: - Speech Settings
    
    // Speech Recognition Locale
    @Published var speechLocale: Locale? = {
        let supportedLocales = SFSpeechRecognizer.supportedLocales()
        
        // If saved locale exists and is supported
        if let localeIdentifier = UserDefaults.standard.string(forKey: "speechLocale"),
           supportedLocales.contains(Locale(identifier: localeIdentifier)) {
            return Locale(identifier: localeIdentifier)
        }
        
        // Else find from preferred languages
        let preferredLanguages = Locale.preferredLanguages
        for lang in preferredLanguages {
            let locale = Locale(identifier: lang)
            if supportedLocales.contains(locale) {
                UserDefaults.standard.set(locale.identifier, forKey: "speechLocale")
                return locale
            }
            
            // Special case for English - if region is not specified, use en-US
            if let languageCode = locale.language.languageCode?.identifier, languageCode == "en" {
                let enUSLocale = Locale(identifier: "en-US")
                if supportedLocales.contains(enUSLocale) {
                    UserDefaults.standard.set(enUSLocale.identifier, forKey: "speechLocale")
                    return enUSLocale
                }
            }
        }
        
        return nil
    }() {
        didSet {
            if let locale = speechLocale {
                UserDefaults.standard.set(locale.identifier, forKey: "speechLocale")
            }
        }
    }
    
    // Manually Confirm Speech
    @Published var manuallyConfirmSpeech: Bool = UserDefaults.standard.bool(forKey: "manuallyConfirmSpeech") {
        didSet {
            UserDefaults.standard.set(manuallyConfirmSpeech, forKey: "manuallyConfirmSpeech")
        }
    }
    
    // Start with Mic Muted
    @Published var startWithMicMuted: Bool = UserDefaults.standard.bool(forKey: "startWithMicMuted") {
        didSet {
            UserDefaults.standard.set(startWithMicMuted, forKey: "startWithMicMuted")
        }
    }
    
    // Assistant View Detent
    @Published var assistantViewDetent: AssistantViewModel.DetentOption = {
        if let rawValue = UserDefaults.standard.string(forKey: "assistantViewDetent"),
           let option = AssistantViewModel.DetentOption(rawValue: rawValue) {
            return option
        }
        return .defaultDetent
    }() {
        didSet {
            UserDefaults.standard.set(assistantViewDetent.rawValue, forKey: "assistantViewDetent")
        }
    }
    
    // Disable Markdown Rendering
    @Published var disableMarkdownRendering: Bool = UserDefaults.standard.bool(forKey: "disableMarkdownRendering") {
        didSet {
            UserDefaults.standard.set(disableMarkdownRendering, forKey: "disableMarkdownRendering")
        }
    }
}
