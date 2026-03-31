//
//  URLBasedAssistantSettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import SwiftUI

struct URLBasedAssistantSettingsView: View {
    @State private var assistantModel = URLBasedAssistantModel.load()
    
    @State private var showPresets = false
    
    var body: some View {
        Group {
            // URL Section
            Section {
                TextField("URL", text: $assistantModel.url, prompt: Text(verbatim: "https://example.com/search?q=%s"))
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .environment(\.layoutDirection, .leftToRight)
                    .submitLabel(.done)
            } header: {
                Text("Search URL")
            } footer: {
                Text("By setting the query part to \"%s\", you can use Side Search's speech recognition.")
            }
            
            Section {
                Button(action: { showPresets = true }) {
                    Label("Search URL Presets", systemImage: "sparkle.magnifyingglass")
                }
            }
            .sheet(isPresented: $showPresets) {
                SearchEnginePresetsView(searchEngine: $assistantModel)
            }
        }
        .onChange(of: assistantModel) {
            saveSettings()
        }
        .onAppear {
            saveSettings()
        }
    }
    
    private func saveSettings() {
        assistantModel.save()
    }
}
