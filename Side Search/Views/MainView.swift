//
//  MainView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import SafariServices
import Speech
import SwiftUI
import TemporaryScreenCurtain

struct MainView: View {
    @StateObject var viewModel = MainViewModel()
    
    @State private var showHelpView = false
    @State private var showChangeIconView = false
    @State private var showClearInAppBrowserDataAlert = false
    
    @Namespace private var ns_switchAssistantView
    private let id_switchAssistantViewButton = "switchAssistantViewButton"
    @Namespace private var ns_assistantView
    private let id_activateAssistantButton = "activateAssistantButton"
    
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
                    
                    Toggle("Disable Markdown Rendering", isOn: $viewModel.disableMarkdownRendering)
                }
                
                Section {
                    Button(action: { showClearInAppBrowserDataAlert = true }) {
                        Label("Clear In-App Browser Data", systemImage: "xmark.circle")
                    }
                }
                
                Section {
                    Button(action: { showChangeIconView = true }) {
                        Label("Change App Icon", systemImage: "app.dashed")
                    }
                }
            }
            .animation(.default, value: viewModel.currentAssistant)
            .navigationTitle("Side Search")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
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
                    Button(action: { viewModel.showSwitchAssistantView = true }) {
                        HStack {
                            Image(systemName: viewModel.currentAssistant.DescriptionProviderType.assistantSystemImage)
                            Text(viewModel.currentAssistant.DescriptionProviderType.assistantName)
                        }
                        .padding(.horizontal, 10)
                    }
                    .matchedTransitionSource(id: id_switchAssistantViewButton, in: ns_switchAssistantView)
                    
                    Button(action: { viewModel.activateAssistant() }) {
                        Label("Start Assistant", image: "Sidefish")
                            .foregroundStyle(.white)
                    }
                    .tint(.dropblue)
                    .buttonStyle(.glassProminent)
                    .matchedTransitionSource(id: id_activateAssistantButton, in: ns_assistantView)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { showHelpView = true }) {
                        Label("Help", systemImage: "questionmark")
                    }
                }
            }
            // MARK: - Events
            .onReceive(NotificationCenter.default.publisher(for: .activateIntentDidActivate)) { _ in
                showHelpView = false
                showChangeIconView = false
                showClearInAppBrowserDataAlert = false
                viewModel.activateAssistant()
            }
        }
        // MARK: - Sheets
        .sheet(isPresented: $showHelpView) { HelpView() }
        .sheet(isPresented: $showChangeIconView) { ChangeIconView() }
        .sheet(isPresented: $viewModel.showSwitchAssistantView) {
            SwitchAssistantView(currentAssistant: $viewModel.currentAssistant)
                .navigationTransition(.zoom(
                    sourceID: id_switchAssistantViewButton,
                    in: ns_switchAssistantView
                ))
        }
        .sheet(isPresented: $viewModel.showAssistant) {
            AssistantView()
                .navigationTransition(.zoom(
                    sourceID: id_activateAssistantButton,
                    in: ns_assistantView
                ))
        }
        .fullScreenCover(isPresented: $viewModel.showSafariView) {
            if let url = viewModel.safariViewURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        // MARK: - Dummy Curtain
        .temporaryScreenCurtain(isPresented: $viewModel.showDummyCurtain)
    }
}
