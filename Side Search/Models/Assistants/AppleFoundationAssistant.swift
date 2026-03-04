//
//  AppleFoundationAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import FoundationModels
import SwiftUI
import MergeCodablePackage

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
    static var backgroundSupports: Bool = true
    
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

struct AppleFoundationAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "appleFoundationAssistantSettings"
    
    // Model Settings
    var customInstructions: String
    static let customInstructions_default: String = ""
    
    init() {
        self.customInstructions = Self.customInstructions_default
    }

    init(customInstructions: String = Self.customInstructions_default) {
        self.customInstructions = customInstructions
    }
    
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
