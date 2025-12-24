//
//  SettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // URL
                Section {
                    TextField("URL", text: $viewModel.defaultSE.url, prompt: Text(verbatim: "https://example.com/search?q=%s"))
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .environment(\.layoutDirection, .leftToRight)
                        .submitLabel(.done)
                } header: { Text("Search URL")
                } footer: { Text("Replace query with %s") }
                
                Section {
                    Toggle("Disable Percent-encoding", isOn: $viewModel.defaultSE.disablePercentEncoding)
                    HStack {
                        Text("Max Query Length")
                        Spacer()
                        TextField("Max Query Length", value: $viewModel.defaultSE.maxQueryLength, format: .number, prompt: Text("32"))
                            .keyboardType(.numberPad)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                    }
                } header: { Text("Advanced Settings")
                } footer: { Text("Blank to disable") }
            }
            .navigationTitle("Side Search")
            .onReceive(NotificationCenter.default.publisher(for: .activateIntentDidActivate)) { _ in
                viewModel.isAssistantActivated = true
            }
            .fullScreenCover(isPresented: $viewModel.isAssistantActivated) {
                AssistantView()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                }
            }
        }
    }
}
