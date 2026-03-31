//
//  SetStandbyInBackground.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/31.
//

import AppIntents

struct SetStandbyInBackground: AppIntent {
    static let title: LocalizedStringResource = "Set Keep on Standby in Background"
    static let description: LocalizedStringResource = "Sets the Side Search setting."
    
    static let openAppWhenRun = false
    static let isDiscoverable = true
    
    @Parameter(title: "Keep on Standby", default: false)
    var value: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set Keep on Standby in Background to \(\.$value)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserSettings.shared.standbyInBackground = value
        return .result()
    }
}
