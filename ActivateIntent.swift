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
    static let description: LocalizedStringResource = "Start the Side Search assistant."
    static let isDiscoverable = true
    static var supportedModes: IntentModes = .foreground
    
    @MainActor
    static func setShouldBackground(_ value: Bool) {
        if value {
            Self.supportedModes = .background
        } else {
            Self.supportedModes = .foreground
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .activateIntentDidActivate, object: nil)
        return .result()
    }
}
