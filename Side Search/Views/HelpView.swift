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
                // MARK: - Side Button Access Tip
                Section {
                    // サイドボタンのカスタマイズが可能な地域では、サイドボタンを長押しすることでSide Searchのアシスタントをすぐに起動できます。
                    // 設定 → アプリ → Side Searchで「サイドボタンを押してSide Searchを使用」をオンにすることで設定できます。
                    Text("If you are in a region where Side Button customization is enabled, you can quickly launch the Side Search assistant by pressing and holding the Side Button.")
                    Text("You can set it up by going to Settings → Apps → Side Search and turning on \"Press Side Button for Side Search\".")
                    Button() {
                        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                        if UIApplication.shared.canOpenURL(settingsURL) {
                            UIApplication.shared.open(settingsURL)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                } header: { Label("Side Button Tip", systemImage: "button.vertical.right.press") }
                
                if AssistantType.current == .urlBased {
                    // MARK: - Search URL Tip
                    Section {
                        // 検索URLは、お好みのAIアシスタントや検索エンジンのURLを設定するために必要です。
                        // もし設定が難しい場合は、「検索URLのプリセット」からお好きなものを選んで簡単に設定することができます。
                        // クエリ部分を「%s」にすると、Side Searchの音声認識を利用できます。
                        // 検索URLにはアプリのURLスキームを使用することができます。アシスタントをデフォルトのアプリで開くように設定すれば、ユニバーサルリンクも使用できます。
                        Text("The Search URL is necessary to set your preferred AI assistant or search engine URL.")
                        Text("If setting it up is difficult, you can easily set it up by choosing from \"Search URL Presets\".")
                        Text("By setting the query part to \"%s\", you can use Side Search's speech recognition.")
                        Text("You can use the app's URL scheme for the Search URL. If you set the assistant to Open in Default App, you can also use Universal Links.")
                        Link(destination: URL(string: "https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios")!) {
                            Label("Run a shortcut using a URL scheme", systemImage: "book")
                        }
                        
                    } header: { Label("Search URL Tip", systemImage: "magnifyingglass") }
                }
                
                // MARK: - Shortcut Tip
                Section {
                    // ショートカットを使ってSide Searchのアシスタントを起動することができます。
                    // ショートカットで「Side Search」から「アシスタントを開始」アクションから利用できます。
                    // ショートカットのオートメーションを設定すれば、Side Searchを起動した時に別のアクションを実行することもできます。
                    Text("You can launch the Side Search assistant using the Shortcuts.")
                    Text("You can find it in the Shortcuts under \"Side Search\" by selecting the \"Start Assistant\" action.")
                    Text("By setting up automation in the Shortcuts, you can perform other actions when Side Search is launched.")
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
                        Text("About")
                    }
                    NavigationLink(destination: LicensesView()) {
                        Text("Licenses")
                    }
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
