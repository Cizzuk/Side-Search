//
//  AssistantType.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import AppIntents
import SwiftUI

enum AssistantType: String, CaseIterable, Codable, AppEnum {
    case urlBased
    case appleFoundation
    case geminiAPI
    case sideBridge
    
    static var `default`: AssistantType {
        return .urlBased
    }
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Assistants")
    }
    
    static let caseDisplayRepresentations: [Self : DisplayRepresentation] = [
        .urlBased: "URL Based Assistant",
        .appleFoundation: "Apple Foundation Models",
        .geminiAPI: "Google Gemini API",
        .sideBridge: "Side Bridge"
    ]
    
    var displayName: LocalizedStringResource {
        return Self.caseDisplayRepresentations[self]?.title ?? ""
    }
    
    var DescriptionProviderType: any AssistantDescriptionProvider.Type {
        switch self {
        case .urlBased:
            return URLBasedAssistant.self
        case .appleFoundation:
            return AppleFoundationAssistant.self
        case .geminiAPI:
            return GeminiAPIAssistant.self
        case .sideBridge:
            return SideBridgeAssistant.self
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
        case .sideBridge:
            return SideBridgeAssistantModel.self
        }
    }
    
    var AssistantServiceType: BaseAssistantService.Type {
        switch self {
        case .urlBased:
            return URLBasedAssistantService.self
        case .appleFoundation:
            return AppleFoundationAssistantService.self
        case .geminiAPI:
            return GeminiAPIAssistantService.self
        case .sideBridge:
            return SideBridgeAssistantService.self
        }
    }
    
    func makeSettingsView() -> any View {
        switch self {
        case .urlBased:
            return URLBasedAssistantSettingsView()
        case .appleFoundation:
            return AppleFoundationAssistantSettingsView()
        case .geminiAPI:
            return GeminiAPIAssistantSettingsView()
        case .sideBridge:
            return SideBridgeAssistantSettingsView()
        }
    }
}
