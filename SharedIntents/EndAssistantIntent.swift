//
//  EndAssistantIntent.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/18.
//

import AppIntents

struct EndAssistantIntent: AppIntent {
    static let title: LocalizedStringResource = "End Assistant"
    static let description: LocalizedStringResource = "End the Side Search assistant if it's active."
    static var isDiscoverable = true
    static var supportedModes: IntentModes = .foreground(.dynamic)
    
    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .shouldEndAssistant, object: nil)
        
        return .result()
    }
}
