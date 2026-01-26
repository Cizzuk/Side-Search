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
    
    var DescriptionProviderType: any AssistantDescriptionProvider.Type {
        switch self {
        case .urlBased:
            return URLBasedAssistant.self
        case .appleFoundation:
            return AppleFoundationAssistant.self
        }
    }
    
    var ModelType: any AssistantModel.Type {
        switch self {
        case .urlBased:
            return URLBasedAssistantModel.self
        case .appleFoundation:
            return AppleFoundationAssistantModel.self
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
           let type = AssistantType(rawValue: rawValue) {
            return type
        }
        return .urlBased
    }
}

protocol AssistantDescriptionProvider {
    // Metadata
    static var assistantName: LocalizedStringResource { get } // Keep this short
    static var assistantDescription: LocalizedStringResource { get }
    static var assistantSystemImage: String { get }
    
    // Settings
    static var makeSettingsView: any View { get }
    static var userDefaultsKey: String { get }
    
    // AssistantViewModel
    static func makeAssistantViewModel() -> AssistantViewModel
    
    // Availability Check
    static func isAvailable() -> Bool
    static func isBlocked() -> Bool
}

protocol AssistantModel: Codable, Equatable {
    static func fromJSON(_ data: Data) -> Self?
    func toJSON() -> Data?
    func isValidSettings() -> Bool
}
