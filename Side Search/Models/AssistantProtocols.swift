//
//  AssistantProtocols.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import Foundation
import SwiftUI

protocol AssistantDescriptionProvider {
    // Metadata
    static var assistantName: LocalizedStringResource { get }
    static var assistantDescription: LocalizedStringResource { get }
    static var assistantSystemImage: String { get }
    
    // Settings
    static var settingsView: any View { get }
    static var userDefaultsKey: String { get }
    
    // Availability Check
    static func isAvailable() -> Bool
}

protocol AssistantModel: Codable {
    static func fromJSON(_ data: Data) -> Self?
    func toJSON() -> Data?
    func isValidSettings() -> Bool
}
