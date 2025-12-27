//
//  SettingsViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import UIKit
import Speech

class SettingsViewModel: ObservableObject {
    @Published var isAssistantActivated = false
    @Published var isShowingRecommend = false
    
    @Published var defaultSE: SearchEngineModel = {
        if let rawData = UserDefaults.standard.data(forKey: "defaultSearchEngine"),
           let engine = SearchEngineModel.fromJSON(rawData) {
            return engine
        }
        
        // Create Default
        let se = RecommendSEs.defaultSearchEngine
        if let data = se.toJSON() {
            UserDefaults.standard.set(data, forKey: "defaultSearchEngine")
        }
        return se
    }() {
        didSet {
            if let data = defaultSE.toJSON() {
                UserDefaults.standard.set(data, forKey: "defaultSearchEngine")
            }
        }
    }
    
    // Speech Recognition Locale
    @Published var speechLocale: Locale = {
        if let localeIdentifier = UserDefaults.standard.string(forKey: "speechLocale") {
            return Locale(identifier: localeIdentifier)
        }
        
        // Default Preferred Language
        let preferredLanguages = Locale.preferredLanguages
        for lang in preferredLanguages {
            let locale = Locale(identifier: lang)
            if SFSpeechRecognizer.supportedLocales().contains(locale) {
                UserDefaults.standard.set(locale.identifier, forKey: "speechLocale")
                return locale
            }
        }
        
        // Fallback to en-US if not available
        UserDefaults.standard.set("en-US", forKey: "speechLocale")
        return Locale(identifier: "en-US")
    }() {
        didSet {
            UserDefaults.standard.set(speechLocale.identifier, forKey: "speechLocale")
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
}
