//
//  AppleFoundationAssistantSettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import SwiftUI

struct AppleFoundationAssistantSettingsView: View {
    @State private var assistantModel: AppleFoundationAssistantModel = {
        if let rawData = UserDefaults.standard.data(forKey: AppleFoundationAssistant.userDefaultsKey),
           let model = AppleFoundationAssistantModel.fromJSON(rawData) {
            return model
        }
        return AppleFoundationAssistantModel()
    }()
    
    var body: some View {
        Group {
            // Custom Instructions Section
            Section {
                TextEditor(text: $assistantModel.customInstructions)
                    .submitLabel(.return)
                    .frame(maxHeight: 200)
            } header: { Text("Custom Instructions") }
        }
        .onChange(of: assistantModel) {
            saveSettings()
        }
        .onAppear {
            saveSettings()
        }
    }
    
    private func saveSettings() {
        if let data = assistantModel.toJSON() {
            UserDefaults.standard.set(data, forKey: AppleFoundationAssistant.userDefaultsKey)
        }
    }
}
