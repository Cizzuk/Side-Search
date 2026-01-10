//
//  HelpView.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Search URL Tip
                Section {
                    // 検索URLは、お好みのAIアシスタントや検索エンジンのURLを設定するために必要です。
                    // もし設定が難しい場合は、「おすすめのアシスタントと検索エンジン」からお好きなものを選んで簡単に設定することができます。
                    // カスタムの検索URLを設定したい場合は、検索クエリを「%s」で置き換えたURLを設定する必要があります。
                    Text("The Search URL is necessary to set your preferred AI assistant or search engine URL.")
                    Text("If setting it up is difficult, you can easily set it up by choosing from \"Recommended Assistants & Search Engines.\"")
                    Text("If you want to set a custom Search URL, you need to set a URL where the search query is replaced with \"%s\".")
                } header: { Text("Search URL Tip") }
                
                // Side Button Access Tip
                Section {
                    // もし、サイドボタンのカスタマイズが有効な地域にお住まいの場合、サイドボタンを長押しすることでSide Searchの音声アシスタントをすぐに起動できます。
                    // 設定 → アプリ → Side Searchで「サイドボタンを押してSide Searchを使用」をオンにすることで設定できます。
                    Text("If you are in a region where Side Button customization is enabled, you can quickly launch the Side Search voice assistant by pressing and holding the Side Button.")
                    Text("You can set it up by going to Settings → Apps → Side Search and turning on \"Press Side Button for Side Search\".")
                    Button() {
                        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                        if UIApplication.shared.canOpenURL(settingsURL) {
                            print(settingsURL.absoluteString)
                            UIApplication.shared.open(settingsURL)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                } header: { Text("Side Button Tip") }
                
                // Shortcut Tip
                Section {
                    // サイドボタン以外にも、ショートカットアプリを使ってSide Searchの音声アシスタントを起動することもできます。
                    // ショートカットアプリで「Side Search」から「アシスタントを有効にする」アクションから利用できます。
                    // ショートカットなら、アクションボタンからの起動も設定できます。
                    Text("Besides the Side Button, you can also launch the Side Search voice assistant using the Shortcuts app.")
                    Text("You can find it in the Shortcuts app under \"Side Search\" by selecting the \"Enable Assistant\" action.")
                    Text("With Shortcuts, you can also set up launching it from the Action Button.")
                } header: { Text("Shortcut Tip") }
                
                // MARK: - App Info Section
                
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
                    Text("App Info")
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
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", systemImage: "checkmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}
                        
                    
