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
    @Environment(\.scenePhase) private var scenePhase
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
                
                Button(action: { viewModel.showPresets = true }) {
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
            .fullScreenCover(isPresented: $viewModel.showAssistant) {
                AssistantView()
            }
            .fullScreenCover(isPresented: $viewModel.showSafariView) {
                if let url = URL(string: viewModel.defaultSE.url) {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $viewModel.showPresets) {
                SearchEnginePresetsView(SearchEngine: $viewModel.defaultSE)
            }
            .sheet(isPresented: $viewModel.showHelp) {
                HelpView()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { viewModel.activateAssistant() }) {
                        Label("Start Assistant", systemImage: viewModel.startWithMicMuted ? "magnifyingglass" : "mic")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { viewModel.showHelp = true }) {
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
            // MARK: - Events
            .onChange(of: scenePhase) { viewModel.onChange(scenePhase: scenePhase) }
            .onReceive(NotificationCenter.default.publisher(for: .activateIntentDidActivate)) { _ in
                viewModel.activateAssistant()
            }
        }
        // MARK: - Dummy Curtain
        .opacity(viewModel.showDummyCurtain ? 0.0 : 1.0)
        .fullScreenCover(isPresented: $viewModel.showDummyCurtain) { DummyCurtainView() }
    }
}
