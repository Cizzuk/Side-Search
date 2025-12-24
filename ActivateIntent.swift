//
//  ActivateIntent.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import AppIntents

@AppIntent(schema: .assistant.activate)
struct ActivateIntent: AppIntent {
    static let supportedModes: IntentModes = .foreground
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
