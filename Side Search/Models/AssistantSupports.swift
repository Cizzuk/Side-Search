//
//  AssistantSupports.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import Foundation
import SwiftUI

enum AssistantType: String, CaseIterable {
    case urlBased
    case appleFoundation
    case geminiAPI
    // Tests
    case test_yamabico
    
    static var defaultType: AssistantType {
        return .urlBased
    }
    
    var DescriptionProviderType: any AssistantDescriptionProvider.Type {
        switch self {
        case .urlBased:
            return URLBasedAssistant.self
        case .appleFoundation:
            return AppleFoundationAssistant.self
        case .geminiAPI:
            return GeminiAPIAssistant.self
        case .test_yamabico:
            return TEST_YamabicoAssistant.self
        }
    }
    
    var ModelType: any AssistantModel.Type {
        switch self {
        case .urlBased:
            return URLBasedAssistantModel.self
        case .appleFoundation:
            return AppleFoundationAssistantModel.self
        case .geminiAPI:
            return GeminiAPIAssistantModel.self
        case .test_yamabico:
            return TEST_YamabicoAssistantModel.self
        }
    }
    
    func makeSettingsView() -> any View {
        return DescriptionProviderType.makeSettingsView
    }
    
    func makeAssistantViewModel() -> AssistantViewModel {
        return DescriptionProviderType.makeAssistantViewModel()
    }
    
    static var current: AssistantType {
        if let rawValue = UserDefaults.standard.string(forKey: "currentAssistant"),
           let type = AssistantType(rawValue: rawValue),
           (!type.DescriptionProviderType.isBlocked() && type.DescriptionProviderType.isAvailable()) {
            return type
        }
        return .defaultType
    }
}

protocol AssistantDescriptionProvider {
    // Metadata
    static var assistantName: LocalizedStringResource { get } // Keep this short
    static var assistantDescription: LocalizedStringResource { get }
    static var assistantSystemImage: String { get }
    static var assistantGradient: Gradient { get }
    
    // Settings
    static var makeSettingsView: any View { get }
    
    // AssistantViewModel
    static func makeAssistantViewModel() -> AssistantViewModel
    
    // Availability Check
    static func isAvailable() -> Bool
    static func isBlocked() -> Bool
}

protocol AssistantModel: Codable, Equatable {
    static func load() -> Self
    func save()
    
    func isValidSettings() -> Bool
}
