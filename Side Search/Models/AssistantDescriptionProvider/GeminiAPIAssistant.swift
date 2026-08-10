//
//  GeminiAPIAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/28.
//

import SwiftUI

struct GeminiAPIAssistant: AssistantDescriptionProvider {
    static var assistantDescription = LocalizedStringResource("This is an assistant that can converse and search using Gemini provided by Google. To use it, you need to obtain an API key yourself from Google AI Studio. You are responsible for managing the costs and agreements related to your usage.")
    static var assistantImage = Image(systemName: "sparkle")
    static var assistantGradient = Gradient(colors: [
        Color(red: 66/255,  green: 133/255, blue: 244/255),
        Color(red: 15/255,  green: 157/255, blue: 88/255),
        Color(red: 244/255,  green: 180/255, blue: 0/255),
        Color(red: 219/255, green: 68/255, blue: 55/255),
        Color(red: 66/255,  green: 133/255, blue: 244/255),
    ])
    static var assistantShapeStyle: AnyShapeStyle {
        AnyShapeStyle(AngularGradient(
            gradient: Self.assistantGradient,
            center: .center
        ))
    }
    
    static var isBeta: Bool = false
    static var assistantIsAI: Bool = true
    static var backgroundSupports: Bool = true
    
    static func isAvailable() -> Bool {
        if GeoHelper.currentRegion == "CN" {
            return false
        }
        
        return true
    }
}
