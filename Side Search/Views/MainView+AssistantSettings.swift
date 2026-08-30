//
//  MainView+AssistantSettings
//  Side Search
//
//  Created by Cizzuk on 2026/08/30.
//

import SafariServices
import Speech
import SwiftUI
import TemporaryScreenCurtain

extension MainView {
    @ViewBuilder
    func AssistantSettings() -> some View {
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
                    .tint(.accent)
                
                Toggle("Start with Mic Muted", isOn: $userSettings.startWithMicMuted)
                    .tint(.accent)
                
                Toggle("Use Bluetooth Microphones", isOn: $userSettings.allowBluetoothMic)
                    .tint(.accent)
            } header: { Text("Speech Settings") }
            
            // URL Settings
            Section {
                Picker("Open URLs in", selection: $userSettings.openURLsIn) {
                    ForEach(UserSettings.URLOpeningOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
            } header: {
                Text("URL Settings")
            } footer: {
                Text("If you select Default App, the app associated with the URL or your default browser will open.")
                    .padding(.bottom, 10)
            }
            
            // Background Settings
            if userSettings.currentAssistant.DescriptionProviderType.backgroundSupports {
                Section {
                    Toggle("Continue in Background", isOn: $userSettings.continueInBackground)
                        .tint(.accent)
                    
                    if userSettings.continueInBackground {
                        Toggle("Keep on Standby", isOn: $userSettings.standbyInBackground)
                            .tint(.accent)
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
                    ForEach(SoundEffectService.Mode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }
            
            Section {
                Toggle("Disable Markdown Rendering", isOn: $userSettings.disableMarkdownRendering)
                    .tint(.accent)
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
        }
        .animation(.default, value: userSettings.currentAssistant)
        .animation(.default, value: userSettings.continueInBackground)
        .navigationTitle(userSettings.currentAssistant.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { vm.activateAssistant() }) {
                    Label("Start Assistant", image: "Sidefish")
                        .foregroundStyle(.white)
                }
                .tint(.dropblue)
                .buttonStyle(.glassProminent)
                .matchedTransitionSource(id: id_activateAssistantButton, in: ns_assistantView)
            }
        }
    }
}
