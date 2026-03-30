//
//  MessagesView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import SwiftUI
import Translation
import Textual

struct MessagesView: View {
    var message: AssistantMessage
    var openSafariView: (URL) -> Void
    
    @Environment(\.accessibilityAssistiveAccessEnabled) private var isAssistiveAccessEnabled
    
    @ObservedObject private var userSettings = UserSettings.shared
    
    @State private var isCopied: Bool = false
    @State private var showTranslation: Bool = false
    
    func copyMessage() {
        UIPasteboard.general.string = message.content
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCopied = false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(message.from.displayName)
                    .font(.headline)
                Spacer()
                
                if !isAssistiveAccessEnabled {
                    HStack(spacing: 20) {
                        Button(action: { copyMessage() }) {
                            Label("Copy Message to Clipboard",
                                  systemImage: isCopied ? "checkmark" : "document.on.document")
                        }
                        .disabled(isCopied)
                        .animation(.default, value: isCopied)
                        
                        Button(action: { showTranslation = true }) {
                            Label("Translate Message", systemImage: "translate")
                        }
                    }
                    .labelStyle(.iconOnly)
                    .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
            
            Spacer(minLength: 15)
            
            if userSettings.disableMarkdownRendering {
                Text(message.content)
                    .textSelection(.enabled)
            } else {
                StructuredText(markdown: message.content, syntaxExtensions: [.math])
                    .textual.textSelection(.enabled)
                    .textual.structuredTextStyle(TextualSideStyle())
            }
            
            // MARK: - Sources
            
            if !message.sources.isEmpty && !isAssistiveAccessEnabled {
                Spacer(minLength: 15)
                
                ForEach(message.sources, id: \.url) { source in
                    Button(action: { openSafariView(source.url) }) {
                        Label(source.title, systemImage: "link")
                            .font(.subheadline)
                            .padding(.vertical, 1)
                            .padding(.trailing, 20)
                    }
                    .contextMenu {
                        // Copy URL
                        Button(action: { UIPasteboard.general.string = source.url.absoluteString }) {
                            Label("Copy URL", systemImage: "document.on.document")
                        }
                        
                        // In-App Browser
                        Button(action: { openSafariView(source.url) }) {
                            Label("Open in In-App Browser", systemImage: "safari")
                        }
                        
                        // Default Browser
                        Button(action: { UIApplication.shared.open(source.url) }) {
                            Label("Open in Default App", systemImage: "arrow.up.forward.app")
                        }
                    }
                }
            }
        }
        .id(message.id)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAction(named: "Copy Message to Clipboard") {
            copyMessage()
        }
        .translationPresentation(isPresented: $showTranslation, text: message.content)
    }
}
