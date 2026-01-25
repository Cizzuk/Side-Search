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
    static var assistantDescription = LocalizedStringResource("This can be used by setting URLs for AI assistants, search engines, etc. The assistant will open in the in-app browser or the default app. Side Search's speech recognition is optional.")
    static var assistantSystemImage = "apple.intelligence"
    
    static var makeSettingsView: any View { AppleFoundationAssistantSettingsView() }
    static var userDefaultsKey = "appleFoundationAssistantSettings"
    
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
