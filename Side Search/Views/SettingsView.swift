//
//  SettingsView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SafariServices
import Speech
import SwiftUI

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
                
                Button(action: { viewModel.isShowingPresets = true }) {
                    Label("Search URL Presets", systemImage: "sparkle.magnifyingglass")
                }
                
                // Assistant Settings
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
                    
                    Toggle("Stop Speech and Search", isOn: $viewModel.autoSearchOnSilence)
                    if viewModel.autoSearchOnSilence {
                        HStack {
                            Text("Silence Duration")
                            Spacer()
                            Text("\(viewModel.silenceDuration, specifier: "%.0f")s")
                            Stepper("", value: $viewModel.silenceDuration, in: 1...10, step: 1)
                                .labelsHidden()
                        }
                    }

                    Toggle("Start with Mic Muted", isOn: $viewModel.startWithMicMuted)
                    
                    Picker("Open in", selection: $viewModel.openIn) {
                        ForEach(SettingsViewModel.OpenInOption.allCases, id: \.self) { option in
                            Text(option.localizedName).tag(option)
                        }
                    }
                    .disabled(viewModel.shouldLockOpenInToDefaultApp)
                    
                    if viewModel.openIn == .inAppBrowser {
                        Button() {
                            SFSafariViewController.DataStore.default.clearWebsiteData()
                        } label: {
                            Text("Clear In-App Browser Data")
                        }
                    }
                } header: { Text("Assistant Settings") }
                footer: {
                    if viewModel.openIn == .defaultApp {
                        if viewModel.shouldLockOpenInToDefaultApp {
                            Text("This option is locked to Default App because the Search URL scheme is not http or https.")
                        } else {
                            Text("If you select Open in Default App, the app corresponding to the Search URL or the default browser will be opened.")
                        }
                    }
                }
                
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
            .animation(.default, value: viewModel.autoSearchOnSilence)
            .animation(.default, value: viewModel.openIn)
            .navigationTitle("Side Search")
            .scrollDismissesKeyboard(.interactively)
            .fullScreenCover(isPresented: $viewModel.isAssistantActivated) {
                AssistantView()
            }
            .sheet(isPresented: $viewModel.isShowingPresets) {
                SearchEnginePresetsView(SearchEngine: $viewModel.defaultSE)
            }
            .sheet(isPresented: $isShowingHelp) {
                HelpView()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { viewModel.isAssistantActivated = true }) {
                        Label("Start Assistant", systemImage: viewModel.startWithMicMuted ? "magnifyingglass" : "mic")
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
                isShowingHelp = false
                viewModel.isShowingPresets = false
                viewModel.isAssistantActivated = true
            }
        }
    }
}
