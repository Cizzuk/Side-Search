//
//  AppleFoundationAssistantSettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import FoundationModels
import SwiftUI

struct AppleFoundationAssistantSettingsView: View {
    @State private var assistantModel = AppleFoundationAssistantModel.load()
    
    var body: some View {
        Group {
            // Model Settings Section
            Section {
                Picker("Model", selection: $assistantModel.modelType) {
                    ForEach(AppleFoundationAssistantModel.ModelType.allCases) { type in
                        Text(type.displayName)
                            .tag(type)
                            .selectionDisabled(!type.isAvailable)
                    }
                }
                
                if assistantModel.modelType.model.capabilities.contains(.reasoning) {
                    Picker("Reasoning Level", selection: $assistantModel.reasoningLevel) {
                        ForEach(AppleFoundationAssistantModel.ReasoningLevel.allCases) { level in
                            Text(level.displayName)
                                .tag(level)
                        }
                    }
                }
            } header: {
                Text("Model Settings")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    // PCC Quota Information
                    if assistantModel.modelType == .pcc {
                        let model = PrivateCloudComputeLanguageModel()
                        if model.quotaUsage.isLimitReached {
                            Text("You have reached your quota limit.")
                        }
                        if let resetDate = model.quotaUsage.resetDate {
                            Text("Quota will reset on \(resetDate, style: .date) at \(resetDate, style: .time).")
                        }
                        if let suggestion = model.quotaUsage.limitIncreaseSuggestion {
                            Button("Limit Increase Suggestion") {
                                suggestion.show()
                            }
                        }
                    }
                }
            }
            
            // Custom Instructions Section
            Section {
                TextEditor(text: $assistantModel.customInstructions)
                    .submitLabel(.return)
                    .frame(minHeight: 50, maxHeight: 200)
            } header: { Text("Custom Instructions") }
        }
        .onChange(of: assistantModel) { saveSettings() }
        .onAppear { saveSettings() }
    }
    
    private func saveSettings() {
        assistantModel.save()
    }
}
