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
    static var openAppWhenRun = false
    static var isDiscoverable = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        GroupUserDefaults.set(true, forKey: CFNotificationFlags.shouldEndAssistant)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            .shouldEndAssistant,
            nil,
            nil,
            true
        )
        
        return .result()
    }
}
