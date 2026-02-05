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
    @State private var showingSwitchAssistantView = false
    @State private var showClearInAppBrowserDataAlert = false
    @State private var isPhone = UIDevice.current.userInterfaceIdiom == .phone
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: Assistant Settings
                AnyView(viewModel.currentAssistant.makeSettingsView())
                
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
                    Picker("Assistant Screen Size", selection: $viewModel.assistantViewDetent) {
                        ForEach(AssistantViewModel.DetentOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
                
                Section {
                    Button(action: { showClearInAppBrowserDataAlert = true }) {
                        Label("Clear In-App Browser Data", systemImage: "xmark.circle")
                    }
                }
                
                Section {
                    Button(action: { showingChangeIconView = true }) {
                        Label("Change App Icon", systemImage: "app.dashed")
                    }
                }
            }
            .animation(.default, value: viewModel.currentAssistant)
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
            // Delete In-App Browser Data Alert
            .alert(isPresented: $showClearInAppBrowserDataAlert) {
                Alert(
                    title: Text("Clear In-App Browser Data"),
                    message: Text("Are you sure you want to clear all in-app browser data?"),
                    primaryButton: .destructive(Text("Clear")) { SFSafariViewController.DataStore.default.clearWebsiteData()
                    },
                    secondaryButton: .cancel()
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: { showingSwitchAssistantView = true }) {
                        HStack {
                            Image(systemName: viewModel.currentAssistant.DescriptionProviderType.assistantSystemImage)
                            Text(viewModel.currentAssistant.DescriptionProviderType.assistantName)
                        }
                        .padding(.horizontal, 10)
                    }
                    .popover(isPresented: isPhone ? $showingSwitchAssistantView : .constant(false)) {
                        SwitchAssistantView(currentAssistant: $viewModel.currentAssistant)
                            .presentationCompactAdaptation(.sheet)
                    }
                    .sheet(isPresented: !isPhone ? $showingSwitchAssistantView : .constant(false)) {
                        SwitchAssistantView(currentAssistant: $viewModel.currentAssistant)
                    }
                    
                    Button(action: { viewModel.activateAssistant() }) {
                        Label("Start Assistant", image: "Sidefish")
                    }
                    .tint(.dropblue)
                    .buttonStyle(.glassProminent)
                    .popover(isPresented: isPhone ? $viewModel.showAssistant : .constant(false)) {
                        AssistantView()
                            .presentationCompactAdaptation(.sheet)
                    }
                    .sheet(isPresented: !isPhone ? $viewModel.showAssistant : .constant(false)) {
                        AssistantView()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { viewModel.showHelp = true }) {
                        Label("Help", systemImage: "questionmark")
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
