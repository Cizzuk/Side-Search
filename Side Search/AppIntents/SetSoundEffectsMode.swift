//
//  SetSoundEffectsMode.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/31.
//

import AppIntents

struct SetSoundEffectsMode: AppIntent {
    static let title: LocalizedStringResource = "Set Sound Effects Mode"
    static let description: LocalizedStringResource = "Sets the Side Search setting."
    
    static let openAppWhenRun = false
    static let isDiscoverable = true
    
    @Parameter(title: "Mode", default: .always)
    var mode: SoundEffect.Mode
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set Sound Effects Mode to \(\.$mode)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserSettings.shared.soundEffectsMode = mode
        return .result()
    }
}
