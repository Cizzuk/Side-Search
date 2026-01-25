//
//  URLBasedAssistantSettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import SwiftUI

struct URLBasedAssistantSettingsView: View {
    @State private var searchEngine: URLBasedAssistantModel = {
        if let rawData = UserDefaults.standard.data(forKey: URLBasedAssistant.userDefaultsKey),
           let engine = URLBasedAssistantModel.fromJSON(rawData) {
            return engine
        }
        return SearchEnginePresets.defaultSearchEngine
    }()
    
    @State private var showPresets = false
    
    var body: some View {
        // URL Section
        Section {
            TextField("URL", text: $searchEngine.url, prompt: Text(verbatim: "https://example.com/search?q=%s"))
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .environment(\.layoutDirection, .leftToRight)
                .submitLabel(.done)
        } header: { Text("Search URL")
        } footer: { Text("By setting the query part to \"%s\", you can use Side Search's speech recognition.") }
        
        Button(action: { showPresets = true }) {
            Label("Search URL Presets", systemImage: "sparkle.magnifyingglass")
        }
        .sheet(isPresented: $showPresets) {
            SearchEnginePresetsView(SearchEngine: $searchEngine)
        }
        
        // Open In Section
        Section {
            Picker("Open in", selection: $searchEngine.openIn) {
                ForEach(URLBasedAssistantModel.OpenInOption.allCases, id: \.self) { option in
                    Text(option.localizedName).tag(option)
                }
            }
        } footer: {
            Text("If you select Open in Default App, the app corresponding to the Search URL or the default browser will be opened.")
        }
        .onChange(of: searchEngine) {
            saveSettings()
        }
        .onAppear {
            migrateUserDefaults()
        }
    }
    
    private func saveSettings() {
        if let data = searchEngine.toJSON() {
            UserDefaults.standard.set(data, forKey: URLBasedAssistant.userDefaultsKey)
        }
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
            searchEngine.url = url
        }
        
        // Migrate OpenIn
        guard let previousOpenIn = UserDefaults.standard.string(forKey: "openIn"),
              let option = URLBasedAssistantModel.OpenInOption(rawValue: previousOpenIn)
        else { return }
        searchEngine.openIn = option
    }
}
