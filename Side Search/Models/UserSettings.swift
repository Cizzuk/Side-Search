//
//  UserSettings.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/17.
//

import AppIntents
import Combine
import Speech

final class UserSettings: ObservableObject {
    static let shared = UserSettings()
    private init() { }

    private enum Keys {
        static let currentAssistant = "currentAssistant"
        static let chatHistoryEnabled = "chatHistoryEnabled"
        static let speechLocale = "speechLocale"
        static let manuallyConfirmSpeech = "manuallyConfirmSpeech"
        static let startWithMicMuted = "startWithMicMuted"
        static let openURLsIn = "openURLsIn"
        static let continueInBackground = "continueInBackground"
        static let standbyInBackground = "standbyInBackground"
        static let soundEffectsMode = "soundEffectsMode"
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
    
    // MARK: - URL Settings
    
    enum URLOpeningOption: String, CaseIterable {
        case inAppBrowser, defaultApp
        
        static var `default`: Self {
            return .inAppBrowser
        }
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            TypeDisplayRepresentation(name: "URL Opening Option")
        }
        
        static let caseDisplayRepresentations: [Self : DisplayRepresentation] = [
            .inAppBrowser: "In-App Browser",
            .defaultApp: "Default App"
        ]
        
        var displayName: LocalizedStringResource {
            return Self.caseDisplayRepresentations[self]?.title ?? ""
        }
    }
    
    @Published var openURLsIn: URLOpeningOption = {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.openURLsIn),
           let option = URLOpeningOption(rawValue: rawValue) {
            return option
        }
        
        if let oldOption = SettingsMigrator.migrateOpenURLsIn() {
            return oldOption
        }
        
        return .default
    }() {
        didSet {
            UserDefaults.standard.set(openURLsIn.rawValue, forKey: Keys.openURLsIn)
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
    
    @Published var soundEffectsMode: SoundEffect.Mode = {
        if let rawValue = UserDefaults.standard.string(forKey: Keys.soundEffectsMode),
           let mode = SoundEffect.Mode(rawValue: rawValue) {
            return mode
        }
        return .default
    }() {
        didSet {
            UserDefaults.standard.set(soundEffectsMode.rawValue, forKey: Keys.soundEffectsMode)
        }
    }
    
    @Published var disableMarkdownRendering: Bool = UserDefaults.standard.bool(forKey: Keys.disableMarkdownRendering) {
        didSet {
            UserDefaults.standard.set(disableMarkdownRendering, forKey: Keys.disableMarkdownRendering)
        }
    }
}
