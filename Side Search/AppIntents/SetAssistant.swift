//
//  SetAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/31.
//

import AppIntents

struct SetAssistant: AppIntent {
    static let title: LocalizedStringResource = "Set Assistant"
    static let description: LocalizedStringResource = "Sets the assistant to be used in Side Search."
    
    static let openAppWhenRun = false
    static let isDiscoverable = true
    
    @Parameter(title: "Assistant", default: .urlBased)
    var type: AssistantType
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set Assistant to \(\.$type)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserSettings.shared.currentAssistant = type
        return .result()
    }
}
