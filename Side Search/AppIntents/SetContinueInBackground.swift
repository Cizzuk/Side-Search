//
//  SetContinueInBackground.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/31.
//

import AppIntents

struct SetContinueInBackground: AppIntent {
    static let title: LocalizedStringResource = "Set Continue in Background"
    
    static let openAppWhenRun = false
    static let isDiscoverable = true
    
    @Parameter(title: "Continue in Background", default: true)
    var value: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set Continue in Background to \(\.$value)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserSettings.shared.continueInBackground = value
        return .result()
    }
}
