//
//  SideBridgeAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import FoundationModels
import SwiftUI
import MergeCodablePackage

struct SideBridgeAssistant: AssistantDescriptionProvider {
    static var assistantDescription = LocalizedStringResource("")
    static var assistantImage = Image("sidebridge")
    static var assistantGradient = Gradient(colors: [
        Color(red: 136/255, green: 51/255,  blue: 255/255),
        Color(red: 51/255, green: 102/255,  blue: 255/255),
        Color(red: 136/255, green: 51/255,  blue: 255/255),
    ])
    static var assistantShapeStyle: AnyShapeStyle {
        AnyShapeStyle(LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 51/255, green: 102/255,  blue: 255/255), location: 0.3),
                Gradient.Stop(color: Color(red: 119/255, green: 85/255,  blue: 255/255), location: 0.7),
            ],
            startPoint: .leading,
            endPoint: .trailing
        ))
    }
    
    static var assistantIsAI: Bool = false
    static var backgroundSupports: Bool = true
    
    static func isAvailable() -> Bool { return true }
}

struct SideBridgeAssistantModel: AssistantModel, MergeCodable {
    private static let userDefaultsKey = "sideBridgeAssistantSettings"
    
    init() { }
    
    static func load() -> Self {
        guard let rawData = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else { return Self() }
        return decode(from: rawData)
    }
    
    func save() {
        if let data = encode() {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}
