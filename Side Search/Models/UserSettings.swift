//
//  UserSettings.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/17.
//

import Combine
import Speech

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    private init() { }

    private enum Keys {
        static let currentAssistant = "currentAssistant"
        static let chatHistoryEnabled = "chatHistoryEnabled"
        static let speechLocale = "speechLocale"
        static let manuallyConfirmSpeech = "manuallyConfirmSpeech"
        static let startWithMicMuted = "startWithMicMuted"
        static let continueInBackground = "continueInBackground"
        static let standbyInBackground = "standbyInBackground"
        static let disableMarkdownRendering = "disableMarkdownRendering"
    }

    @Published var currentAssistant: AssistantType = {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.currentAssistant),
           let storedAssistant = AssistantType(rawValue: rawValue) {
            return storedAssistant
        }
        return .default
    }() {
        didSet {
            UserDefaults.standard.set(currentAssistant.rawValue, forKey: Keys.currentAssistant)
        }
    }
    
    @Published var chatHistoryEnabled: Bool = UserDefaults.standard.bool(forKey: Keys.chatHistoryEnabled) {
        didSet {
            UserDefaults.standard.set(chatHistoryEnabled, forKey: Keys.chatHistoryEnabled)
        }
    }
    
    // MARK: - Speech Recognition Settings

    @Published var speechLocale: Locale? = {
        let supportedLocales = SFSpeechRecognizer.supportedLocales()

        if let localeIdentifier = UserDefaults.standard.string(forKey: Keys.speechLocale) {
            let savedLocale = Locale(identifier: localeIdentifier)
            if supportedLocales.contains(savedLocale) {
                return savedLocale
            }
        }

        for language in Locale.preferredLanguages {
            let preferredLocale = Locale(identifier: language)
            if supportedLocales.contains(preferredLocale) {
                UserDefaults.standard.set(preferredLocale.identifier, forKey: Keys.speechLocale)
                return preferredLocale
            }

            if let languageCode = preferredLocale.language.languageCode?.identifier,
               languageCode == "en" {
                let enUSLocale = Locale(identifier: "en-US")
                if supportedLocales.contains(enUSLocale) {
                    UserDefaults.standard.set(enUSLocale.identifier, forKey: Keys.speechLocale)
                    return enUSLocale
                }
            }
        }

        return nil
    }() {
        didSet {
            if let locale = speechLocale {
                UserDefaults.standard.set(locale.identifier, forKey: Keys.speechLocale)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.speechLocale)
            }
        }
    }

    @Published var manuallyConfirmSpeech: Bool = UserDefaults.standard.bool(forKey: Keys.manuallyConfirmSpeech) {
        didSet {
            UserDefaults.standard.set(manuallyConfirmSpeech, forKey: Keys.manuallyConfirmSpeech)
        }
    }

    @Published var startWithMicMuted: Bool = UserDefaults.standard.bool(forKey: Keys.startWithMicMuted) {
        didSet {
            UserDefaults.standard.set(startWithMicMuted, forKey: Keys.startWithMicMuted)
        }
    }
    
    // MARK: - Background Settings

    @Published var continueInBackground: Bool = {
        if UserDefaults.standard.object(forKey: Keys.continueInBackground) == nil {
            UserDefaults.standard.set(true, forKey: Keys.continueInBackground)
            return true
        }
        return UserDefaults.standard.bool(forKey: Keys.continueInBackground)
    }() {
        didSet {
            UserDefaults.standard.set(continueInBackground, forKey: Keys.continueInBackground)
        }
    }

    @Published var standbyInBackground: Bool = UserDefaults.standard.bool(forKey: Keys.standbyInBackground) {
        didSet {
            UserDefaults.standard.set(standbyInBackground, forKey: Keys.standbyInBackground)
        }
    }
    
    // MARK: - Other Settings
    
    @Published var disableMarkdownRendering: Bool = UserDefaults.standard.bool(forKey: Keys.disableMarkdownRendering) {
        didSet {
            UserDefaults.standard.set(disableMarkdownRendering, forKey: Keys.disableMarkdownRendering)
        }
    }
}
