//
//  SetStartWithMicMuted.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/31.
//

import AppIntents

struct SetStartWithMicMuted: AppIntent {
    static let title: LocalizedStringResource = "Set Start with Mic Muted"
    
    static let openAppWhenRun = false
    static let isDiscoverable = true
    
    @Parameter(title: "Start with Mic Muted", default: false)
    var value: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set Start with Mic Muted to \(\.$value)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserSettings.shared.startWithMicMuted = value
        return .result()
    }
}
