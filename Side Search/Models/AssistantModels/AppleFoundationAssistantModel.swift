//
//  AppleFoundationAssistantModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation
import MergeCodablePackage

struct AppleFoundationAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "appleFoundationAssistantSettings"
    
    // Model Settings
    var customInstructions: String = ""
    
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
