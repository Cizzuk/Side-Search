//
//  AssistantSupports.swift
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
    
    var AssistantViewModelType: AssistantViewModel.Type {
        switch self {
        case .urlBased:
            return URLBasedAssistantViewModel.self
        case .appleFoundation:
            return AppleFoundationAssistantViewModel.self
        case .geminiAPI:
            return GeminiAPIAssistantViewModel.self
        case .sideBridge:
            return SideBridgeAssistantViewModel.self
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
            return EmptyView()
        }
    }
}

protocol AssistantDescriptionProvider {
    // Metadata
    static var assistantDescription: LocalizedStringResource { get }
    static var assistantSystemImage: String { get }
    static var assistantGradient: Gradient { get }
    
    static var assistantIsAI: Bool { get }
    static var backgroundSupports: Bool { get }
    
    // Availability Check
    static func isAvailable() -> Bool
}

protocol AssistantModel: Codable, Equatable {
    static func load() -> Self
    func save()
}
