//
//  HelpView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/25.
//

import SwiftUI

struct HelpView: View {
    @ObservedObject private var userSettings = UserSettings.shared
    
    private var canOpenSettingsURL: Bool {
        guard URL(string: UIApplication.openSettingsURLString) != nil else { return false }
        return true
    }
    
    private func openSettingsURL() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
    
    @State var unAuthorizationStatus: UNAuthorizationStatus?
    
    private func updateUNAuthorizationStatus() async {
        unAuthorizationStatus = await UserNotificationSupport.authorizationStatus()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Side Button Access Tip
                Section {
                    // サイドボタンのカスタマイズが可能な地域では、サイドボタンを長押しすることでSide Searchのアシスタントをすぐに起動できます。
                    // 設定 → アプリ → Side Searchで「サイドボタンを押してSide Searchを使用」をオンにすることで設定できます。
                    // 現在確認されている対応地域は、日本のみです。
                    Text("If you are in a region where Side Button customization is enabled, you can quickly launch the Side Search assistant by pressing and holding the Side Button.")
                    Text("You can set it up by going to Settings → Apps → Side Search and turning on \"Press Side Button for Side Search\".")
                    Text("The confirmed supported region is Japan only.")
                    if canOpenSettingsURL {
                        Button(action: { openSettingsURL() }) {
                            Label("Open Settings", systemImage: "gear")
                        }
                    }
                } header: { Label("Side Button Tip", systemImage: "button.vertical.right.press") }
                
                if userSettings.currentAssistant == .urlBased {
                    // MARK: - Search URL Tip
                    Section {
                        // 検索URLは、お好みのAIアシスタントや検索エンジンのURLを設定するために必要です。
                        // クエリ部分を「%s」にすると、Side Searchの音声認識を利用できます。
                        // 検索URLにはアプリのURLスキームを使用することができます。アシスタントをデフォルトのアプリで開くように設定すれば、ユニバーサルリンクも使用できます。
                        Text("The Search URL is necessary to set your preferred AI assistant or search engine URL.")
                        Text("By setting the query part to \"%s\", you can use Side Search's speech recognition.")
                        Text("You can use the app's URL scheme for the Search URL. If you set the assistant to Open in Default App, you can also use Universal Links.")
                        Link(destination: URL(string: "https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios")!) {
                            Label("Run a shortcut using a URL scheme", systemImage: "book")
                        }
                    } header: { Label("Search URL Tip", systemImage: "magnifyingglass") }
                }
                
                Section {
                    // 対応するアシスタントでは、音声認識中にアプリを閉じてもバックグラウンドで会話を続けることができます。
                    // 通知を許可すれば、アシスタントの返事を通知で確認することができます。
                    Text("With a compatible assistant, you can continue conversations in the background even if you close Side Search during speech recognition.")
                    Text("If you allow notifications, you can receive the assistant's replies via notifications.")
                    if unAuthorizationStatus == .notDetermined {
                        Button(action: {
                            Task {
                                _ = await UserNotificationSupport.requestAuthorization()
                                unAuthorizationStatus = await UserNotificationSupport.authorizationStatus()
                            }
                        }) {
                            Label("Allow Notifications", systemImage: "app.badge")
                        }
                    } else if unAuthorizationStatus == .denied {
                        if canOpenSettingsURL {
                            Button(action: { openSettingsURL() }) {
                                Label("Allow in Settings", systemImage: "gear")
                            }
                        }
                    }
                } header: { Label("Background Tip", systemImage: "arrow.clockwise")
                } footer: {
                    if unAuthorizationStatus == .authorized {
                        Text("Notifications allowed.")
                    }
                }
                .task {
                    unAuthorizationStatus = await UserNotificationSupport.authorizationStatus()
                }
                
                // MARK: - Shortcut Tip
                Section {
                    // ショートカットを使ってSide Searchのアシスタントを起動することができます。
                    // オートメーションを設定すれば、Side Searchを起動した時に別のアクションを実行することもできます。「マイクミュートで開始」をオンにすることをおすすめします。
                    Text("You can launch the Side Search assistant using the Shortcuts.")
                    Text("By setting up automation, you can also perform other actions when Side Search is launched. I recommend turning on \"Start with Mic Muted\".")
                    Link(destination: URL(string: "https://support.apple.com/guide/shortcuts/create-a-new-personal-automation-apdfbdbd7123/ios")!) {
                        Label("Create a new personal automation in Shortcuts", systemImage: "book")
                    }
                    Button() {
                        if let shortcutsURL = URL(string: "shortcuts://") {
                            UIApplication.shared.open(shortcutsURL)
                        }
                    } label: {
                        Label("Open Shortcuts App", systemImage: "square.2.layers.3d")
                    }
                } header: { Label("Shortcut Tip", systemImage: "square.2.layers.3d") }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
