//
//  AppleFoundationAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation
import SwiftUI

struct AppleFoundationAssistant: AssistantDescriptionProvider {
    static var assistantName = LocalizedStringResource("Apple Foundation Models")
    static var assistantDescription = LocalizedStringResource("This is an assistant that can converse using Foundation Models provided by Apple. To use it, Apple Intelligence must be available on your device. This assistant cannot search the internet.")
    static var assistantSystemImage = "apple.intelligence"
    
    static var makeSettingsView: any View { AppleFoundationAssistantSettingsView() }
    static var userDefaultsKey = "appleFoundationAssistantSettings"
    
    // TODO: Create AppleFoundationAssistantViewModel
    static func makeAssistantViewModel() -> AssistantViewModel { AssistantViewModel() }
    static func isAvailable() -> Bool { return false }
}

struct AppleFoundationAssistantModel: AssistantModel {
    static func fromJSON(_ data: Data) -> AppleFoundationAssistantModel? {
        let decoder = JSONDecoder()
        let model = try? decoder.decode(AppleFoundationAssistantModel.self, from: data)
        return model
    }
    
    func toJSON() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    
    func isValidSettings() -> Bool {
        return false
    }
}

extension AppleFoundationAssistantModel {
}
