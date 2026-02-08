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
                    Text("Please get and enter your API key from Google AI Studio. You can also use a free tier API key.")
                    Spacer()
                    Link("Get API Key...", destination: URL(string: "https://aistudio.google.com/api-keys")!)
                        .font(.footnote)
                }
                .padding(.bottom, 10)
            }
            
            // Model Selection
            Section {
                Picker("Model", selection: $assistantModel.model) {
                    Text("Select a model").tag("")
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            } header: { Text("Model")
            } footer: {
                VStack(alignment: .leading) {
                    Text("Please check the available models and features for your plan.")
                    Spacer()
                    Link("Check pricing and available models...", destination: URL(string: "https://ai.google.dev/gemini-api/docs/pricing")!)
                        .font(.footnote)
                    Spacer()
                    Link("Check your rate limits...", destination: URL(string: "https://aistudio.google.com/usage?timeRange=last-7-days&tab=rate-limit")!)
                        .font(.footnote)
                }
                .padding(.bottom, 10)
            }
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
