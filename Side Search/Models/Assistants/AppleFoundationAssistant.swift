//
//  AppleFoundationAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import FoundationModels
import SwiftUI

struct AppleFoundationAssistant: AssistantDescriptionProvider {
    static var assistantName = LocalizedStringResource("Apple Foundation Models")
    static var assistantDescription = LocalizedStringResource("This is an assistant that can converse using Foundation Models provided by Apple. To use it, Apple Intelligence must be available on your device. This assistant cannot search the internet.")
    static var assistantSystemImage = "apple.intelligence"
    static var assistantGradient = Gradient(colors: [
        Color(red: 201/255, green: 89/255,  blue: 221/255),
        Color(red: 8/255,   green: 148/255, blue: 255/255),
        Color(red: 255/255, green: 144/255, blue: 4/255),
        Color(red: 255/255, green: 46/255,  blue: 84/255),
        Color(red: 201/255, green: 89/255,  blue: 221/255),
    ])
    static var assistantIsAI: Bool = true
    
    static var makeSettingsView: any View { AppleFoundationAssistantSettingsView() }

    static func makeAssistantViewModel() -> AssistantViewModel { AppleFoundationAssistantViewModel() }
    
    static func isAvailable() -> Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
    
    static func isBlocked() -> Bool {
        if GeoHelper.currentRegion == "CN" {
            return true
        }
        return false
    }
}

struct AppleFoundationAssistantModel: AssistantModel {
    private static let userDefaultsKey = "appleFoundationAssistantSettings"
    
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
}
