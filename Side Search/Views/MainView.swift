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
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var viewModel = MainViewModel()
    @StateObject private var userSettings = UserSettings.shared
    
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
                AnyView(userSettings.currentAssistant.makeSettingsView())
                
                // MARK: - Shared Settings
                
                // Speech Recognition Settings
                Section {
                    Picker("Language", selection: Binding(
                        get: { userSettings.speechLocale },
                        set: { newValue in
                            userSettings.speechLocale = newValue
                        }
                    )) {
                        ForEach(SFSpeechRecognizer.supportedLocales().sorted(by: { $0.identifier < $1.identifier }), id: \.self) { locale in
                            Text("\(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)")
                                .tag(locale)
                        }
                    }
                    
                    Toggle("Manually Confirm", isOn: $userSettings.manuallyConfirmSpeech)

                    Toggle("Start with Mic Muted", isOn: $userSettings.startWithMicMuted)
                } header: { Text("Speech Settings") }
                
                // Background Settings
                if userSettings.currentAssistant.DescriptionProviderType.backgroundSupports {
                    Section {
                        Toggle("Continue in Background", isOn: $userSettings.continueInBackground)
                        
                        if userSettings.continueInBackground {
                            Toggle("Keep on Standby", isOn: $userSettings.standbyInBackground)
                        }
                    } header: {
                        Text("Background Settings")
                    } footer: {
                        if userSettings.continueInBackground {
                            Text("By keeping the microphone on, you can have the assistant standby in the background. While in standby, you can use the Side Button or Action Button to resume the assistant without opening the app.")
                        }
                    }
                }
                
                Section {
                    Picker("Sound Effects", selection: $userSettings.soundEffectsMode) {
                        ForEach(SoundEffect.Mode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    
                    Toggle("Disable Markdown Rendering", isOn: $userSettings.disableMarkdownRendering)
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
            .animation(.default, value: userSettings.currentAssistant)
            .animation(.default, value: userSettings.continueInBackground)
            .navigationTitle("Side Search")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: { viewModel.showModal(.switchAssistant) }) {
                        HStack {
                            Image(systemName: userSettings.currentAssistant.DescriptionProviderType.assistantSystemImage)
                            Text(userSettings.currentAssistant.DescriptionProviderType.assistantName)
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
            .onReceive(NotificationCenter.default.publisher(for: .assistantDidActivate)) { _ in
                showClearInAppBrowserDataAlert = false
                viewModel.activateAssistant(disableAnimations: true)
            }
            .onChange(of: scenePhase) { viewModel.onChange(scenePhase: scenePhase) }
        }
        .accessibilityAction(.magicTap) {
            NotificationCenter.default.post(name: .assistantDidActivate, object: nil)
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
            SwitchAssistantView(currentAssistant: $userSettings.currentAssistant)
                .navigationTransition(.zoom(
                    sourceID: id_switchAssistantViewButton,
                    in: ns_switchAssistantView
                ))
        }
        .fullScreenCover(isPresented: $viewModel.showAssistant) {
            NavigationStack { AssistantView() }
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
