//
//  MainView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SafariServices
import Speech
import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var viewModel = MainViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: Assistant Settings
                
                // URL
                Section {
                    TextField("URL", text: $viewModel.SearchEngine.url, prompt: Text(verbatim: "https://example.com/search?q=%s"))
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .environment(\.layoutDirection, .leftToRight)
                        .submitLabel(.done)
                } header: { Text("Search URL")
                } footer: { Text("By setting the query part to \"%s\", you can use Side Search's speech recognition.") }
                
                Button(action: { viewModel.showPresets = true }) {
                    Label("Search URL Presets", systemImage: "sparkle.magnifyingglass")
                }
                
                Section {
                    Picker("Open in", selection: $viewModel.SearchEngine.openIn) {
                        ForEach(URLBasedAssistantModel.OpenInOption.allCases, id: \.self) { option in
                            Text(option.localizedName).tag(option)
                        }
                    }
                    .disabled(viewModel.shouldLockOpenInToDefaultApp)
                    
                    if viewModel.SearchEngine.openIn == .inAppBrowser {
                        Button() {
                            SFSafariViewController.DataStore.default.clearWebsiteData()
                        } label: {
                            Text("Clear In-App Browser Data")
                        }
                    }
                } footer: {
                    if viewModel.SearchEngine.openIn == .defaultApp {
                        if viewModel.shouldLockOpenInToDefaultApp {
                            Text("This option is locked to Default App because the In-App Browser does not support the Search URL.")
                        } else {
                            Text("If you select Open in Default App, the app corresponding to the Search URL or the default browser will be opened.")
                        }
                    }
                }
                
                // MARK: - Shared Settings
                
                // Speech Recognition Settings
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
                    
                    Toggle("Manually Confirm Speech", isOn: $viewModel.manuallyConfirmSpeech)

                    Toggle("Start with Mic Muted", isOn: $viewModel.startWithMicMuted)
                } header: { Text("Speech Settings") }
            }
            .animation(.default, value: viewModel.SearchEngine.openIn)
            .navigationTitle("Side Search")
            .scrollDismissesKeyboard(.interactively)
            .fullScreenCover(isPresented: $viewModel.showSafariView) {
                if let url = URL(string: viewModel.SearchEngine.url) {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $viewModel.showPresets) {
                SearchEnginePresetsView(SearchEngine: $viewModel.SearchEngine)
            }
            .sheet(isPresented: $viewModel.showHelp) {
                HelpView()
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    // TODO: Replace with Switch Assistant Button
//                    Picker("Open in", selection: $viewModel.SearchEngine.openIn) {
//                        ForEach(URLBasedAssistantModel.OpenInOption.allCases, id: \.self) { option in
//                            Text(option.localizedName).tag(option)
//                        }
//                    }
//                    .disabled(viewModel.shouldLockOpenInToDefaultApp)
                    Spacer()
                    Button(action: { viewModel.activateAssistant() }) {
                        Label("Start Assistant", systemImage: "arrowshape.left.fill")
                    }
                    .tint(.dropblue)
                    .buttonStyle(.glassProminent)
                    .popover(isPresented: $viewModel.showAssistant) {
                        AssistantView()
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
