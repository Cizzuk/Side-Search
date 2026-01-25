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
    @State private var showingChangeIconView = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: Assistant Settings
                URLBasedAssistant.makeSettingsView()
                
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
                
                Section {
                    Button() {
                        SFSafariViewController.DataStore.default.clearWebsiteData()
                    } label: {
                        Label("Clear In-App Browser Data", systemImage: "trash")
                    }
                }
                
                Section {
                    Button(action: { showingChangeIconView = true }) {
                        Label("Change App Icon", systemImage: "app.dashed")
                    }
                }
            }
            .navigationTitle("Side Search")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .fullScreenCover(isPresented: $viewModel.showSafariView) {
                if let url = viewModel.safariViewURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $viewModel.showHelp) {
                HelpView()
            }
            .sheet(isPresented: $showingChangeIconView) {
                ChangeIconView()
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
                        Label("Start Assistant", image: "Sidefish")
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
