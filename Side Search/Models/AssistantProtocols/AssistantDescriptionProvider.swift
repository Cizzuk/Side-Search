//
//  AssistantDescriptionProvider.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import SwiftUI

protocol AssistantDescriptionProvider {
    // Metadata
    static var assistantDescription: LocalizedStringResource { get }
    static var assistantImage: Image { get }
    static var assistantGradient: Gradient { get }
    static var assistantShapeStyle: AnyShapeStyle { get }
    
    static var isBeta: Bool { get }
    static var assistantIsAI: Bool { get }
    static var backgroundSupports: Bool { get }
    
    // Availability Check
    static func isAvailable() -> Bool
}
