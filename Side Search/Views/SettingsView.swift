//
//  SettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SwiftUI
import Speech

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @State private var isShowingHelp = false
    
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
                
                Button(action: { viewModel.isShowingRecommend = true }) {
                    Label("Recommended Assistants & Search Engines", systemImage: "sparkle.magnifyingglass")
                }
                
                // Speech Settings
                Section {
                    Picker("Speech Language", selection: Binding(
                        get: { viewModel.speechLocale },
                        set: { newValue in
                            viewModel.speechLocale = newValue
                        }
                    )) {
                        ForEach(SFSpeechRecognizer.supportedLocales().sorted(by: { $0.identifier < $1.identifier }), id: \.self) { locale in
                            Text("\(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)")
                                .tag(locale)
                        }
                    }
                    
                    Toggle("Auto Search on Silence", isOn: $viewModel.autoSearchOnSilence)
                    if viewModel.autoSearchOnSilence {
                        HStack {
                            Text("Silence Duration")
                            Spacer()
                            Text("\(viewModel.silenceDuration, specifier: "%.0f")s")
                            Stepper("", value: $viewModel.silenceDuration, in: 1...10, step: 1)
                                .labelsHidden()
                        }
                    }
                } header: { Text("Speech Settings") }
                
                // Advanced Settings
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
            .scrollDismissesKeyboard(.interactively)
            .fullScreenCover(isPresented: $viewModel.isAssistantActivated) {
                AssistantView()
            }
            .sheet(isPresented: $viewModel.isShowingRecommend) {
                RecommendedSEView(SearchEngine: $viewModel.defaultSE)
            }
            .sheet(isPresented: $isShowingHelp) {
                HelpView()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { viewModel.isAssistantActivated = true }) {
                        Label("Activate Assistant", systemImage: "mic")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isShowingHelp = true }) {
                        Label("Help", systemImage: "questionmark")
                    }
                }
                    
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .activateIntentDidActivate)) { _ in
                viewModel.isAssistantActivated = true
            }
        }
    }
}
