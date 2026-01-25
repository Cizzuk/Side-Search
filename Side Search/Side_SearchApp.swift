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
    }
}
