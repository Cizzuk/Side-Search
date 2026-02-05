//
//  StartAssistantControl.swift
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
            ControlWidgetButton(action: ActivateIntent()) {
                Label(StartAssistantControl.title, image: "Sidefish")
            }
        }
        .displayName(StartAssistantControl.title)
    }
}
