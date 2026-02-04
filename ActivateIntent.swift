//
//  ActivateIntent.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import AppIntents

extension Notification.Name {
    static let activateIntentDidActivate = Notification.Name("activateIntentDidActivate")
}

@AppIntent(schema: .assistant.activate)
struct ActivateIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Assistant"
    static let supportedModes: IntentModes = .foreground
    
    static var isDiscoverable = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .activateIntentDidActivate, object: nil)
        return .result()
    }
}
