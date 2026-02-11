//
//  Side_SearchApp.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI

@main
struct Side_SearchApp: App {
    var body: some Scene {
        AssistiveAccess {
            AssistantView()
        }
        WindowGroup {
            MainView()
                .onOpenURL { url in
                    switch url.host {
                    case "assistant":
                        NotificationCenter.default.post(name: .activateIntentDidActivate, object: nil)
                    default:
                        break
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button {
                    NotificationCenter.default.post(name: .activateIntentDidActivate, object: nil)
                } label: {
                    Label("Start Assistant", image: "Sidefish")
                }
                .keyboardShortcut("N", modifiers: [.command])
            }
        }
    }
}
