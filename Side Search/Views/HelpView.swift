//
//  HelpView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    private var canOpenSettingsURL: Bool {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return false }
        return UIApplication.shared.canOpenURL(settingsURL)
    }
    
    private func openSettingsURL() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
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
                
                if AssistantType.current == .urlBased {
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
                        guard let shortcutsURL = URL(string: "shortcuts://") else { return }
                        if UIApplication.shared.canOpenURL(shortcutsURL) {
                            UIApplication.shared.open(shortcutsURL)
                        }
                    } label: {
                        Label("Open Shortcuts App", systemImage: "square.2.layers.3d")
                    }
                } header: { Label("Shortcut Tip", systemImage: "square.2.layers.3d") }
                
                Section {
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                            .foregroundColor(.primary)
                    }
                    NavigationLink(destination: LicensesView()) {
                        Label("Licenses", systemImage: "book.closed")
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                    let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                    Label("Version", systemImage: "info.circle")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(currentVersion ?? "Unknown") (\(currentBuild ?? "Unknown"))")
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .accessibilityElement(children: .combine)
                HStack {
                    Label("Developer", systemImage: "hammer")
                        .foregroundColor(.primary)
                    Spacer()
                    Link(destination:URL(string: "https://cizzuk.net/")!, label: {
                        Text("Cizzuk")
                    })
                }
                Link(destination:URL(string: "https://github.com/Cizzuk/Side-Search")!, label: {
                    Label("Source", systemImage: "ladybug")
                })
                Link(destination:URL(string: "https://i.cizzuk.net/privacy/")!, label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                })
            } header: {
                Text("Side Search")
            }
            
            Section {} header: {
                Text("License")
            } footer: {
                Text("MIT License\n\nCopyright (c) 2025 Cizzuk\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.")
                    .environment(\.layoutDirection, .leftToRight)
                    .textSelection(.enabled)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
        
// MARK: - Licenses View
struct LicensesView: View {
    func sec(_ title: String, _ license: String) -> some View {
        Section{} header: {
            Text(verbatim: title)
                .textSelection(.enabled)
        } footer: {
            Text(verbatim: license)
                .environment(\.layoutDirection, .leftToRight)
                .textSelection(.enabled)
                .padding(.bottom, 40)
        }
    }
    
    var body: some View {
        List {
            sec("swift-concurrency-extras", "MIT License\n\nCopyright (c) 2023 Point-Free\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.")
            sec("swiftui-math", "MIT License\n\nCopyright (c) 2026 Guille Gonzalez\nCopyright (c) 2023 Computer Inspirations (SwiftMath)\nCopyright (c) 2013 MathChat (iosMath)\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.")
            sec("textual", "MIT License\n\nCopyright (c) 2024 Guille Gonzalez\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.")
        }
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}
