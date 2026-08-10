//
//  ClaudeAPIAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2026/06/15.
//

import FoundationModels
import SwiftUI

struct ClaudeAPIAssistant: AssistantDescriptionProvider {
    static var assistantDescription = LocalizedStringResource("This assistant can converse and search using Claude provided by Anthropic. To use it, you need to obtain an API key yourself from Claude Platform. You are responsible for managing the costs and agreements related to your usage.")
    static var assistantImage = Image(systemName: "brain.fill")
    static var assistantGradient = Gradient(colors: [
        Color(red: 217/255, green: 119/255,  blue: 87/255),
        Color(red: 231/255, green: 171/255,  blue: 151/255),
        Color(red: 217/255, green: 119/255,  blue: 87/255),
    ])
    static var assistantShapeStyle: AnyShapeStyle {
        AnyShapeStyle(LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 231/255, green: 171/255,  blue: 151/255), location: 0.2),
                Gradient.Stop(color: Color(red: 217/255, green: 119/255,  blue: 87/255), location: 0.8),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
    }
    
    static var isBeta: Bool = true
    static var assistantIsAI: Bool = true
    static var backgroundSupports: Bool = true
    
    static func isAvailable() -> Bool {
        if GeoHelper.currentRegion == "CN" {
            return false
        }
        
        return true
    }
}
