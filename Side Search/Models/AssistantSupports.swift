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
}

protocol AssistantDescriptionProvider {
    // Metadata
    static var assistantName: LocalizedStringResource { get } // Keep this short
    static var assistantDescription: LocalizedStringResource { get }
    static var assistantSystemImage: String { get }
    
    // Settings
    static var makeSettingsView: any View { get }
    static var userDefaultsKey: String { get }
    
    // Availability Check
    static func isAvailable() -> Bool
}

protocol AssistantModel: Codable, Equatable {
    static func fromJSON(_ data: Data) -> Self?
    func toJSON() -> Data?
    func isValidSettings() -> Bool
}
