//
//  GeminiAPIAssistantModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/28.
//

import Foundation
import MergeCodablePackage

struct GeminiAPIAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "geminiAPIAssistantSettings"
    
    static var availableModels: [String] = []
    
    // Model Settings
    var model: String = "gemini-2.5-flash"
    var webSearch: Bool = true
    
    static func load() -> Self {
        guard let rawData = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else { return Self() }
        return decode(from: rawData)
    }
    
    func save() {
        if let data = encode() {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
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
