//
//  SetOpenURLsIn.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/31.
//

import AppIntents

struct SetOpenURLsIn: AppIntent {
    static let title: LocalizedStringResource = "Set URL Opening Option"
    static let description: LocalizedStringResource = "Sets the Side Search setting."
    
    static let openAppWhenRun = false
    static let isDiscoverable = true
    
    @Parameter(title: "Option", default: .inAppBrowser)
    var option: UserSettings.URLOpeningOption
    
    static var parameterSummary: some ParameterSummary {
        Summary("Open URLs in \(\.$option)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserSettings.shared.openURLsIn = option
        return .result()
    }
}
