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
    
    static func makeAssistantViewModel() -> AssistantViewModel { GeminiAPIAssistantViewModel() }
    
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
    
    init() { }
    
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
        if !Self.existsAPIKey() {
            return false
        }
        if !Self.availableModels.contains(model) {
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
    
    static func existsAPIKey() -> Bool {
        return KeychainSupport.exists(key: keychainKey)
    }
    
    static func getModels(force: Bool = false) async {
        let apiKey = loadAPIKey()
        guard !apiKey.isEmpty,
              let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)") else {
            availableModels = []
            return
        }
        
        if !force, !availableModels.isEmpty {
            return
        }
        
        do {
            // Fetch models
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["models"] as? [[String: Any]] else { return }
            
            // Create model list
            let modelNames = models.compactMap { model -> String? in
                guard let name = model["name"] as? String,
                      let supportedMethods = model["supportedGenerationMethods"] as? [String],
                      // Filter only models that support text generation
                      supportedMethods.contains("generateContent") else { return nil }
                return name.replacingOccurrences(of: "models/", with: "")
            }
            
            await MainActor.run {
                availableModels = modelNames.sorted()
            }
        } catch {
            print("Error fetching Gemini models: \(error)")
            await MainActor.run {
                availableModels = []
            }
        }
    }
}
