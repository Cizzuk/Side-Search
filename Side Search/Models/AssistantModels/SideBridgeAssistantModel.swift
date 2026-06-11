//
//  SideBridgeAssistantModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation
import MergeCodablePackage

struct SideBridgeAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "sideBridgeAssistantSettings"
    
    // Model Settings
    var endpoint: String = ""
    
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

extension SideBridgeAssistantModel {
    // Auth Key in Keychain
    private static let keychainKey = "sideBridgeAuthKey"
    
    static func loadAuthKey() -> String {
        return KeychainSupport.load(key: keychainKey) ?? ""
    }
    
    static func saveAuthKey(key: String) {
        KeychainSupport.save(key: keychainKey, value: key)
    }
    
    static func deleteAuthKey() {
        KeychainSupport.delete(key: keychainKey)
    }
    
    static func existsAuthKey() -> Bool {
        return KeychainSupport.exists(key: keychainKey)
    }
}
