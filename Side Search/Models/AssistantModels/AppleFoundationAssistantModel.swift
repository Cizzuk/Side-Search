//
//  AppleFoundationAssistantModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation
import FoundationModels
import MergeCodablePackage

struct AppleFoundationAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "appleFoundationAssistantSettings"
    
    // Model Settings
    var customInstructions: String = ""
    var modelType: ModelType = .default
    var reasoningLevel: ReasoningLevel = .default
    
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

extension AppleFoundationAssistantModel {
    enum ModelType: String, CaseIterable, Identifiable, Codable {
        case system, pcc
        
        static var `default` = Self.system
        var id: String { self.rawValue }
        
        var displayName: LocalizedStringResource {
            switch self {
            case .system: return "On-Device Model"
            case .pcc: return "Private Cloud Compute"
            }
        }
        
        var isAvailable: Bool {
            switch self {
            case .system:
                return SystemLanguageModel().isAvailable
            case .pcc:
                if #available(anyAppleOS 27.0, *) {
                    return PrivateCloudComputeLanguageModel().isAvailable
                } else {
                    return false
                }
            }
        }
        
        @available(anyAppleOS 27.0, *)
        var model: any LanguageModel {
            switch self {
            case .system: return SystemLanguageModel()
            case .pcc: return PrivateCloudComputeLanguageModel()
            }
        }
    }
    
    enum ReasoningLevel: String, CaseIterable, Identifiable, Codable {
        case none, light, moderate, deep
        
        static var `default` = Self.none
        var id: String { self.rawValue }
        
        var displayName: LocalizedStringResource {
            switch self {
            case .none: return "None"
            case .light: return "Light"
            case .moderate: return "Moderate"
            case .deep: return "Deep"
            }
        }
        
        @available(anyAppleOS 27.0, *)
        var reasoningLevel: ContextOptions.ReasoningLevel? {
            switch self {
            case .none: return nil
            case .light: return .light
            case .moderate: return .moderate
            case .deep: return .deep
            }
        }
    }

}
