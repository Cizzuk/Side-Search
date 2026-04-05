//
//  SideBridgeAssistantSettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/04/05.
//

import SwiftUI

struct SideBridgeAssistantSettingsView: View {
    @State private var assistantModel = SideBridgeAssistantModel.load()
    @State private var authKey: String = SideBridgeAssistantModel.loadAuthKey()
    
    var body: some View {
        Group {
            // Endpoint
            Section {
                TextField("URL", text: $assistantModel.endpoint, prompt: Text(verbatim: "https://sidebridge.example.com/api"))
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .environment(\.layoutDirection, .leftToRight)
                    .submitLabel(.done)
            } header: {
                Text("Endpoint URL")
            } footer: {
                Text("Enter the URL for your custom Side Bridge endpoint.")
            }
            
            // Auth Key
            Section {
                SecureField("Authentication Key", text: $authKey)
                    .disableAutocorrection(true)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .environment(\.layoutDirection, .leftToRight)
                    .submitLabel(.done)
            } header: { Text("Authentication Key")
            } footer: {
                Text("Enter the authentication key if the endpoint requires authentication. Leave it blank if not required.")
                    .padding(.bottom, 10)
            }
        }
        .onChange(of: assistantModel) {
            saveSettings()
        }
        .onChange(of: authKey) {
            SideBridgeAssistantModel.saveAuthKey(key: authKey)
        }
        .onAppear {
            saveSettings()
        }
    }
    
    private func saveSettings() {
        assistantModel.save()
    }
}
