//
//  URLBasedAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI

struct URLBasedAssistant: AssistantDescriptionProvider {
    static var assistantDescription = LocalizedStringResource("This can be used by setting URLs for AI assistants, search engines, etc. The assistant will open in the in-app browser or the default app. Side Search's speech recognition is optional.")
    static var assistantImage = Image(systemName: "magnifyingglass")
    static var assistantGradient = Gradient(colors: [
        Color(red: 51/255, green: 102/255,  blue: 255/255),
        Color(red: 51/255, green: 153/255,  blue: 255/255),
        Color(red: 51/255, green: 102/255,  blue: 255/255),
    ])
    static var assistantShapeStyle: AnyShapeStyle {
        AnyShapeStyle(LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 51/255, green: 153/255,  blue: 255/255), location: 0.0),
                Gradient.Stop(color: Color(red: 51/255, green: 102/255,  blue: 255/255), location: 0.7),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
    }
    
    static var isBeta: Bool = false
    static var assistantIsAI: Bool = false
    static var backgroundSupports: Bool = false
    
    static func isAvailable() -> Bool { return true }
}
