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
    
    @StateObject var vm = MainViewModel()
    @StateObject var userSettings = UserSettings.shared
    
    @State var showClearInAppBrowserDataAlert = false
    
    @Namespace var ns_assistantView
    let id_activateAssistantButton = "activateAssistantButton"
    
    @ViewBuilder
    func AssistantListRow(type: AssistantType) -> some View {
        let isSelected = userSettings.currentAssistant == type
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(type.displayName)
                    .font(.title3)
                    .bold(isSelected)
                    .foregroundStyle(isSelected ? .accent : .primary)
                Spacer()
                type.DescriptionProviderType.assistantImage
                    .font(.title3)
                    .foregroundStyle(type.DescriptionProviderType.assistantShapeStyle)
            }
            Text(type.DescriptionProviderType.assistantDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(type.DescriptionProviderType.assistantDescription)
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            List(selection: $vm.path) {
                Section {
                    NavigationLink(value: MainViewModel.Route.chatHistory) {
                        Label("Chat History", systemImage: "clock")
                    }
                    NavigationLink(value: MainViewModel.Route.help) {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                }
                
                Section("Assistants") {
                    ForEach(AssistantType.allCases, id: \.self) { type in
                        if userSettings.currentAssistant == type && vm.path == .assistantSettings {
                            NavigationLink(value: MainViewModel.Route.assistantSettings) {
                                AssistantListRow(type: type)
                            }
                        } else {
                            Button {
                                userSettings.currentAssistant = type
                                vm.path = .assistantSettings
                            } label: {
                                AssistantListRow(type: type)
                            }
                            .disabled(!type.DescriptionProviderType.isAvailable())
                        }
                    }
                }
                .navigationLinkIndicatorVisibility(.hidden)
                
                Section {
                    NavigationLink(value: MainViewModel.Route.about) {
                        Label("About", systemImage: "info.circle")
                    }
                    if UIApplication.shared.supportsAlternateIcons {
                        NavigationLink(value: MainViewModel.Route.changeIcon) {
                            Label("Change App Icon", systemImage: "app.dashed")
                        }
                    }
                }
            }
            .navigationTitle("Side Search")
            .navigationBarTitleDisplayMode(.large)
        } detail: {
            switch vm.path {
            case .assistantSettings: AssistantSettings()
            case .help: HelpView()
            case .chatHistory: ChatHistoryView()
            case .about: AboutView()
            case .changeIcon: ChangeIconView()
            case .none: EmptyView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        // MARK: - Events
        .onReceive(NotificationCenter.default.publisher(for: .assistantDidActivate)) { _ in
            showClearInAppBrowserDataAlert = false
            vm.activateAssistant()
        }
        .onChange(of: scenePhase) { vm.onChange(scenePhase: scenePhase) }
        .accessibilityAction(.magicTap) {
            NotificationCenter.default.post(name: .assistantDidActivate, object: nil)
        }
        // MARK: - Sheets
        .fullScreenCover(isPresented: $vm.showAssistant) {
            NavigationStack { AssistantView() }
                .navigationTransition(.zoom(
                    sourceID: id_activateAssistantButton,
                    in: ns_assistantView
                ))
        }
        .fullScreenCover(isPresented: $vm.showSafariView) {
            if let url = vm.safariViewURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        // MARK: - Temporary Screen Curtain
        .temporaryScreenCurtain(isPresented: $vm.showTmpCurtain)
    }
}
