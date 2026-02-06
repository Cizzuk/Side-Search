//
//  MessagesView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import SwiftUI
import Textual

struct MessagesView: View {
    var message: AssistantMessage
    var openSafariView: (URL) -> Void
    
    let disableMarkdownRendering: Bool = UserDefaults.standard.bool(forKey: "disableMarkdownRendering")
    
    func copyMessage() {
        UIPasteboard.general.string = message.content
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(message.from.displayName)
                    .font(.headline)
                Spacer()
                Button(action: { copyMessage() }) {
                    Label("Copy Message to Clipboard", systemImage: "document.on.document")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
            
            Spacer(minLength: 15)
            
            if disableMarkdownRendering {
                Text(message.content)
                    .textSelection(.enabled)
            } else {
                StructuredText(markdown: message.content, syntaxExtensions: [.math])
                    .textual.textSelection(.enabled)
                    .textual.structuredTextStyle(TextualSideStyle())
            }
            
            Spacer(minLength: 15)
            
            ForEach(message.sources, id: \.url) { source in
                Button(action: { openSafariView(source.url) }) {
                    Label(source.title, systemImage: "link")
                        .font(.caption)
                }
            }
        }
        .id(message.id)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAction(named: "Copy Message to Clipboard") {
            copyMessage()
        }
    }
}
