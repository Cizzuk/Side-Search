//
//  GeminiAPIAssistantSettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/28.
//

import SwiftUI

struct GeminiAPIAssistantSettingsView: View {
    @State private var assistantModel = GeminiAPIAssistantModel.load()
    @State private var apiKey: String = GeminiAPIAssistantModel.loadAPIKey()
    @State private var availableModels: [String] = GeminiAPIAssistantModel.availableModels
    
    var body: some View {
        Group {
            // API Key
            Section {
                SecureField("API Key", text: $apiKey)
                    .disableAutocorrection(true)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .environment(\.layoutDirection, .leftToRight)
                    .submitLabel(.done)
            } header: { Text("Gemini API Key")
            } footer: {
                VStack(alignment: .leading) {
                    Text("Please get and enter your API key from Google AI Studio.")
                    Spacer()
                    Link("Get API Key...", destination: URL(string: "https://aistudio.google.com/api-keys")!)
                        .font(.footnote)
                }
            }
            
            // Model Selection
            Section {
                Picker("Model", selection: $assistantModel.model) {
                    Text("Select a model").tag("")
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            } header: { Text("Model") }
        }
        .onChange(of: assistantModel) {
            saveSettings()
        }
        .onChange(of: apiKey) {
            GeminiAPIAssistantModel.saveAPIKey(key: apiKey)
            Task { await updateAvailableModels() }
        }
        .onAppear {
            saveSettings()
            Task { await updateAvailableModels() }
        }
    }
    
    private func saveSettings() {
        assistantModel.save()
    }
    
    private func updateAvailableModels() async {
        await GeminiAPIAssistantModel.getModels()
        availableModels = GeminiAPIAssistantModel.availableModels
    }
}
