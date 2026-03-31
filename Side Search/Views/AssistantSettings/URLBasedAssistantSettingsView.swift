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
            migrateUserDefaults()
            saveSettings()
        }
    }
    
    private func saveSettings() {
        assistantModel.save()
    }
    
    private func migrateUserDefaults() {
        guard let previousData = UserDefaults.standard.data(forKey: "defaultSearchEngine")
        else { return }
        defer {
            UserDefaults.standard.removeObject(forKey: "defaultSearchEngine")
            UserDefaults.standard.removeObject(forKey: "openIn")
        }
        
        // Migrate URL
        guard let jsonDict = try? JSONSerialization.jsonObject(with: previousData) as? [String: Any]
        else { return }
        if let url = jsonDict["url"] as? String {
            assistantModel.url = url
        }
        
        // Migrate OpenIn
        guard let previousOpenIn = UserDefaults.standard.string(forKey: "openIn"),
              let option = URLBasedAssistantModel.OpenInOption(rawValue: previousOpenIn)
        else { return }
        assistantModel.openIn = option
    }
}
