//
//  MessagesView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import SwiftUI
import MarkdownUI

struct MessagesView: View {
    var message: AssistantMessage
    var openSafariView: (URL) -> Void
    var disableMarkdownRendering: Bool = UserDefaults.standard.bool(forKey: "disableMarkdownRendering")
    
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
            
            Spacer()
            
            if disableMarkdownRendering {
                Text(message.content)
                    .textSelection(.enabled)
            } else {
                Markdown(message.content)
                    .textSelection(.enabled)
            }
            
            Spacer()
            
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
