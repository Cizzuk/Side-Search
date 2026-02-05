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
    @Published var showAssistant = false
    @Published var showSafariView = false
    @Published var safariViewURL: URL?
    @Published var showHelp = false
    @Published var showDummyCurtain = false
    
    func onChange(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            break
        case .inactive:
            showDummyCurtain = false
        case .background:
            break
        @unknown default:
            break
        }
    }
    
    func activateAssistant() {
        // Check current assistant type
        if currentAssistant != .urlBased {
            showAssistant = true
            return
        }
        
        let SearchEngine = URLBasedAssistantModel.load()
        
        // Check if query input is needed
        if SearchEngine.needQueryInput() {
            showAssistant = true
            return
        }
        
        // Check if SafariView is available
        if SearchEngine.openIn == .inAppBrowser && SearchEngine.checkSafariViewAvailability() {
            safariViewURL = URL(string: SearchEngine.url)
            showSafariView = true
            return
        }
        
        if let url = URL(string: SearchEngine.url) {
            // Show dummy curtain without animation
            var transaction = Transaction(animation: .none)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                showDummyCurtain = true
            }
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
        return .normal
    }() {
        didSet {
            UserDefaults.standard.set(assistantViewDetent.rawValue, forKey: "assistantViewDetent")
        }
    }
}
