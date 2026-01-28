//
//  GeminiAPIAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/28.
//

import FoundationModels
import SwiftUI

struct GeminiAPIAssistant: AssistantDescriptionProvider {
    static var assistantName = LocalizedStringResource("Gemini API")
    static var assistantDescription = LocalizedStringResource("This is an assistant that can converse using Gemini provided by Google. To use it, you need to obtain an API key yourself from Google AI Studio. You are responsible for managing the costs and agreements related to your usage.")
    static var assistantSystemImage = "sparkle"
    
    static var assistantGradient = Gradient(colors: [
        Color(red: 66/255,  green: 133/255, blue: 244/255),
        Color(red: 15/255,  green: 157/255, blue: 88/255),
        Color(red: 244/255,  green: 180/255, blue: 0/255),
        Color(red: 219/255, green: 68/255, blue: 55/255),
        Color(red: 66/255,  green: 133/255, blue: 244/255),
    ])
    
    static var makeSettingsView: any View { GeminiAPIAssistantSettingsView() }
    
    static func makeAssistantViewModel() -> AssistantViewModel { AssistantViewModel() }
    
    static func isAvailable() -> Bool { return true }
    static func isBlocked() -> Bool {
        if GeoHelper.currentRegion == "CN" {
            return true
        }
        return false
    }
}

struct GeminiAPIAssistantModel: AssistantModel {
    private static let userDefaultsKey = "geminiAPIAssistantSettings"
    
    static var availableModels: [String] = []
    
    var model: String = ""
    var customInstructions: String = ""
    
    init() { }

    init(customInstructions: String) {
        self.customInstructions = customInstructions
    }
    
    static func load() -> Self {
        if let rawData = UserDefaults.standard.data(forKey: Self.userDefaultsKey) {
            let decoder = JSONDecoder()
            if let model = try? decoder.decode(Self.self, from: rawData) {
                return model
            }
        }
        return Self()
    }
    
    func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
    
    func isValidSettings() -> Bool {
        if model.isEmpty {
            return false
        }
        return true
    }
}

extension GeminiAPIAssistantModel {
    // API Key in Keychain
    private static let keychainKey = "geminiAPIKey"
    
    static func loadAPIKey() -> String {
        return KeychainSupport.load(key: keychainKey) ?? ""
    }
    
    static func saveAPIKey(key: String) {
        KeychainSupport.save(key: keychainKey, value: key)
    }
    
    static func deleteAPIKey() {
        KeychainSupport.delete(key: keychainKey)
    }
    
    static func getModels() { }
}
