//
//  ClaudeAPIAssistantSettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/06/16.
//

import SwiftUI

struct ClaudeAPIAssistantSettingsView: View {
    @State private var assistantModel = ClaudeAPIAssistantModel.load()
    @State private var apiKey: String = ClaudeAPIAssistantModel.loadAPIKey()
    
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
            } header: { Text("Claude API Key")
            } footer: {
                VStack(alignment: .leading) {
                    Text("Please get and enter your API key from Claude Platform.")
                    Spacer()
                    Link("Get API Key...", destination: URL(string: "https://platform.claude.com/settings/keys")!)
                        .font(.footnote)
                }
                .padding(.bottom, 10)
            }
            
            // Model Selection
            Section {
                Picker("Model", selection: $assistantModel.modelType) {
                    ForEach(ClaudeAPIAssistantModel.ModelType.allCases) { type in
                        Text(type.id).tag(type)
                    }
                }
            } header: { Text("Model Settings")
            } footer: {
                VStack(alignment: .leading) {
                    Link("Check pricing and available models...", destination: URL(string: "https://platform.claude.com/docs/en/about-claude/models/overview")!)
                        .font(.footnote)
                    Spacer()
                    Link("Check your usage...", destination: URL(string: "https://platform.claude.com/usage")!)
                        .font(.footnote)
                }
                .padding(.bottom, 10)
            }
            
            // Tools Section
            Section {
                HStack {
                    Text("Max Web Search")
                    Stepper(value: $assistantModel.maxWebSearchRequests, in: 0...100) {
                        Text("\(assistantModel.maxWebSearchRequests)")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                HStack {
                    Text("Max Web Fetch")
                    Stepper(value: $assistantModel.maxWebFetchRequests, in: 0...100) {
                        Text("\(assistantModel.maxWebFetchRequests)")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                Toggle("Allow Code Execution", isOn: $assistantModel.allowCodeExecution)
            } header: { Text("Tools") }
        }
        .onChange(of: assistantModel) { saveSettings() }
        .onChange(of: apiKey) { ClaudeAPIAssistantModel.saveAPIKey(key: apiKey) }
        .onAppear { saveSettings() }
    }
    
    private func saveSettings() {
        assistantModel.save()
    }
}
