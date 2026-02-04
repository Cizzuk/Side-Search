//
//  StartAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/05.
//

import WidgetKit
import AppIntents
import SwiftUI

struct StartAssistantControl: ControlWidget {
    static let kind = "net.cizzuk.cbnote.WidgetExtension.OpenAppAddNewNoteControl"
    static let title: LocalizedStringResource = "Start Assistant"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: StartAssistantControl.kind) {
            ControlWidgetButton(action: StartAssistantIntent()) {
                Label(StartAssistantControl.title, image: "Sidefish")
            }
        }
        .displayName(StartAssistantControl.title)
    }
}

struct StartAssistantIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Assistant"
    
    static var openAppWhenRun = true
    static var isDiscoverable = true

    @MainActor
    func perform() async throws -> some OpensIntent {
        NotificationCenter.default.post(name: .activateIntentDidActivate, object: nil)
        return .result()
    }
}
