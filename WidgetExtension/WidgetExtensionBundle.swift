//
//  WidgetExtensionBundle.swift
//  Side Search Widget Extension
//
//  Created by Cizzuk on 2026/02/05.
//

import SwiftUI
import WidgetKit

@main
struct WidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        StartAssistantControl()
        AssistantActivityWidget()
    }
}
