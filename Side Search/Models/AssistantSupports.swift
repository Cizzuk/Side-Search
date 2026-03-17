//
//  AssistantSupports.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import Foundation
import SwiftUI

enum AssistantType: String, CaseIterable, Codable {
    case urlBased
    case appleFoundation
    case geminiAPI
    
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
        }
    }
    
    func makeSettingsView() -> any View {
        return DescriptionProviderType.makeSettingsView
    }
    
    func makeAssistantViewModel() -> AssistantViewModel {
        return DescriptionProviderType.makeAssistantViewModel()
    }
}

protocol AssistantDescriptionProvider {
    // Metadata
    static var assistantName: LocalizedStringResource { get } // Keep this short
    static var assistantDescription: LocalizedStringResource { get }
    static var assistantSystemImage: String { get }
    static var assistantGradient: Gradient { get }
    
    static var assistantIsAI: Bool { get }
    static var backgroundSupports: Bool { get }
    
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
}
