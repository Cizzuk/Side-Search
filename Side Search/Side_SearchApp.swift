//
//  Side_SearchApp.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Combine
import SwiftUI
import UIKit

final class AppFlags: ObservableObject {
    static let shared = AppFlags()
    private init() {}
    
    @Published var isAssistantActive: Bool = false
}

@main
struct Side_SearchApp: App {
    init() {
        SettingsMigration.migrateChatHistory()
    }
    
    var body: some Scene {
        AssistiveAccess {
            NavigationStack {
                AssistantView(autoActivate: false)
            }
        }
        WindowGroup {
            MainView()
                .onOpenURL { url in
                    switch url.host {
                    case "assistant":
                        NotificationCenter.default.post(name: .assistantDidActivate, object: nil)
                    default:
                        break
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button {
                    NotificationCenter.default.post(name: .assistantDidActivate, object: nil)
                } label: {
                    Label("Start Assistant", image: "Sidefish")
                }
                .keyboardShortcut("N", modifiers: [.command])
            }
        }
    }
    
    static func validateAppState() {
        if !AppFlags.shared.isAssistantActive {
            UIApplication.shared.isIdleTimerDisabled = false
            ActivateIntent.setShouldBackground(false)
            if AssistantActivityManager.isActive() {
                AssistantActivityManager.endAll()
            }
        }
    }
}
