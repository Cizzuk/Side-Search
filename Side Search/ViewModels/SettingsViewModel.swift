//
//  SettingsViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import UIKit
import Speech
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var showAssistant = false
    @Published var showSafariView = false
    @Published var showPresets = false
    @Published var showHelp = false
    @Published var showDummyCurtain = false
    
    @Published var shouldLockOpenInToDefaultApp: Bool = false
    
    init() {
        checkShouldLockOpenIn()
    }
    
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
        showPresets = false
        showHelp = false
        
        // Check if search url does not contain "%s"
        if !defaultSE.url.contains("%s") {
            switch openIn {
            case .inAppBrowser:
                showSafariView = true
            case .defaultApp:
                if let url = URL(string: defaultSE.url) {
                    // Show dummy curtain without animation
                    var transaction = Transaction(animation: .none)
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        showDummyCurtain = true
                    }
                    UIApplication.shared.open(url)
                }
            }
        } else {
            showAssistant = true
        }
    }
    
    // Check if search url scheme is not http/https, shouldLockOpenInToDefaultApp
    func checkShouldLockOpenIn() {
        if let scheme = URL(string: defaultSE.url)?.scheme?.lowercased(),
           scheme != "http" && scheme != "https" {
            shouldLockOpenInToDefaultApp = true
            openIn = .defaultApp
        } else {
            shouldLockOpenInToDefaultApp = false
        }
    }
    
    @Published var defaultSE: SearchEngineModel = {
        if let rawData = UserDefaults.standard.data(forKey: "defaultSearchEngine"),
           let engine = SearchEngineModel.fromJSON(rawData) {
            return engine
        }
        
        // Create Default
        let se = SearchEnginePresets.defaultSearchEngine
        if let data = se.toJSON() {
            UserDefaults.standard.set(data, forKey: "defaultSearchEngine")
        }
        return se
    }() {
        didSet {
            if let data = defaultSE.toJSON() {
                UserDefaults.standard.set(data, forKey: "defaultSearchEngine")
                checkShouldLockOpenIn()
            }
        }
    }
    
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
    
    // Auto Search on Silence
    @Published var autoSearchOnSilence: Bool = UserDefaults.standard.bool(forKey: "autoSearchOnSilence") {
        didSet {
            UserDefaults.standard.set(autoSearchOnSilence, forKey: "autoSearchOnSilence")
        }
    }
    
    @Published var silenceDuration: Double = {
        let value = UserDefaults.standard.double(forKey: "silenceDuration")
        return value > 0 ? value : 2.0
    }() {
        didSet {
            UserDefaults.standard.set(silenceDuration, forKey: "silenceDuration")
        }
    }
    
    // Start with Mic Muted
    @Published var startWithMicMuted: Bool = UserDefaults.standard.bool(forKey: "startWithMicMuted") {
        didSet {
            UserDefaults.standard.set(startWithMicMuted, forKey: "startWithMicMuted")
        }
    }
    
    // Open in...
    enum OpenInOption: String, CaseIterable {
        case inAppBrowser, defaultApp
        
        var localizedName: LocalizedStringResource {
            switch self {
            case .inAppBrowser:
                return "In-App Browser"
            case .defaultApp:
                return "Default App"
            }
        }
    }
    
    @Published var openIn: OpenInOption = {
        if let rawValue = UserDefaults.standard.string(forKey: "openIn"),
           let option = OpenInOption(rawValue: rawValue) {
            return option
        }
        return .inAppBrowser
    }() {
        didSet {
            UserDefaults.standard.set(openIn.rawValue, forKey: "openIn")
        }
    }
}
