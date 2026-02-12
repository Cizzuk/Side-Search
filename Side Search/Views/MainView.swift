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
    
    @State private var showClearInAppBrowserDataAlert = false
    
    @Namespace private var ns_chatHistoryView
    private let id_chatHistoryViewButton = "chatHistoryViewButton"
    @Namespace private var ns_helpView
    private let id_helpViewButton = "helpViewButton"
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
                    .confirmationDialog(
                        "Clear In-App Browser Data",
                        isPresented: $showClearInAppBrowserDataAlert
                    ) {
                        Button("Cancel", role: .cancel) {}
                        Button("Clear", role: .destructive) {
                            SFSafariViewController.DataStore.default.clearWebsiteData()
                        }
                    } message: {
                        Text("This will clear all in-app browser data, including cookies and cache.")
                    }
                }
                
                if UIApplication.shared.supportsAlternateIcons {
                    Section {
                        Button(action: { viewModel.showModal(.changeIcon) }) {
                            Label("Change App Icon", systemImage: "app.dashed")
                        }
                    }
                }
            }
            .animation(.default, value: viewModel.currentAssistant)
            .navigationTitle("Side Search")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .accessibilityAction(.magicTap, { viewModel.activateAssistant() })
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: { viewModel.showModal(.switchAssistant) }) {
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.showModal(.chatHistory) }) {
                        Label("Chat History", systemImage: "clock")
                    }
                    .matchedTransitionSource(id: id_chatHistoryViewButton, in: ns_chatHistoryView)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { viewModel.showModal(.help) }) {
                        Label("Help", systemImage: "questionmark")
                    }
                    .matchedTransitionSource(id: id_helpViewButton, in: ns_helpView)
                }
            }
            // MARK: - Events
            .onReceive(NotificationCenter.default.publisher(for: .activateIntentDidActivate)) { _ in
                showClearInAppBrowserDataAlert = false
                viewModel.activateAssistant()
            }
        }
        // MARK: - Sheets
        .sheet(isPresented: $viewModel.showHelpView) {
            HelpView()
                .navigationTransition(.zoom(
                    sourceID: id_helpViewButton,
                    in: ns_helpView
                ))
        }
        .fullScreenCover(isPresented: $viewModel.showChatHistoryView) {
            ChatHistoryView()
                .navigationTransition(.zoom(
                    sourceID: id_chatHistoryViewButton,
                    in: ns_chatHistoryView
                ))
        }
        .sheet(isPresented: $viewModel.showChangeIconView) { ChangeIconView() }
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
        // MARK: - Temporary Screen Curtain
        .temporaryScreenCurtain(isPresented: $viewModel.showTmpCurtain)
    }
}
