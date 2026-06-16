//
//  ClaudeAPIAssistantModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/06/15.
//

import Foundation
import FoundationModels
import ClaudeForFoundationModels
import MergeCodablePackage

struct ClaudeAPIAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "claudeAssistantSettings"
    
    // Model Settings
    var customInstructions: String = ""
    var modelType: ModelType = .default
    var effortLevel: String = ""
    var maxWebSearchRequests: Int = 3
    var maxWebFetchRequests: Int = 3
    var allowCodeExecution: Bool = false
    
    static func load() -> Self {
        guard let rawData = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else { return Self() }
        return decode(from: rawData)
    }
    
    func save() {
        if let data = encode() {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
    
    func makeLM(apiKey: String) -> ClaudeLanguageModel {
        var tools: Set<ClaudeServerTool> = []
        if self.maxWebSearchRequests > 0 {
            tools.insert(.webSearch(maxUses: self.maxWebSearchRequests))
        }
        if self.maxWebFetchRequests > 0 {
            tools.insert(.webFetch(maxUses: self.maxWebFetchRequests))
        }
        if self.allowCodeExecution {
            tools.insert(.codeExecution)
        }
        
        return ClaudeLanguageModel(
            name: self.modelType.claudeModel,
            auth: .apiKey(apiKey),
            serverTools: tools,
        )
    }
}

extension ClaudeAPIAssistantModel {
    // API Key in Keychain
    private static let keychainKey = "claudeAPIKey"
    
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
    
    enum ModelType: String, CaseIterable, Identifiable, Codable {
        case opus4_8 = "claude-opus-4-8"
        case opus4_7 = "claude-opus-4-7"
        case opus4_6 = "claude-opus-4-6"
        case sonnet4_6 = "claude-sonnet-4-6"
        case haiku4_5 = "claude-haiku-4-5"
        
        var id: String { self.rawValue }
        static var `default` = Self.haiku4_5
        
        var claudeModel: ClaudeModel {
            switch self {
            case .opus4_8: return .opus4_8
            case .opus4_7: return .opus4_7
            case .opus4_6: return .opus4_6
            case .sonnet4_6: return .sonnet4_6
            case .haiku4_5: return .haiku4_5
            }
        }
    }
}
