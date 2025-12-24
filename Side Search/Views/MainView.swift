//
//  MainView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI

struct MainView: View {
    @State var activatedCount = 0
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("Activated Count: \(activatedCount)")
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .activateIntentDidActivate)) { _ in
            activatedCount += 1
        }
    }
}
