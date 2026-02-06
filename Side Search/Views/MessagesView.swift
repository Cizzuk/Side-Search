//
//  MessagesView.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import SwiftUI
import Textual

struct MessagesView: View {
    static let borderWidth: CGFloat = 1.5
    static let borderColor: Color = .secondary.opacity(0.5)
    static let borderRadius: CGFloat = 10
    let disableMarkdownRendering: Bool = UserDefaults.standard.bool(forKey: "disableMarkdownRendering")
    
    var message: AssistantMessage
    var openSafariView: (URL) -> Void
    
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
                    .textual.headingStyle(SimpleHeading())
                    .textual.thematicBreakStyle(SimpleLine())
                    .textual.tableStyle(SimpleTable())
                    .textual.codeBlockStyle(SimpleCodeBlock())
                    .textual.blockQuoteStyle(SimpleBlockQuote())
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
    
    struct SimpleHeading: StructuredText.HeadingStyle {
        private static let fontScales: [CGFloat] = [1.5, 1.3, 1.15, 1, 0.875, 0.85]
        
        func makeBody(configuration: Configuration) -> some View {
            let headingLevel = min(configuration.headingLevel, 6)
            let fontScale = Self.fontScales[headingLevel - 1]
            
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .textual.fontScale(fontScale)
                    .fontWeight(.semibold)
            }
            .textual.blockSpacing(.fontScaled(top: 1.5, bottom: 0.5))
        }
    }
    
    struct SimpleTable: StructuredText.TableStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .textual.tableCellSpacing(horizontal: borderWidth, vertical: borderWidth)
                .textual.blockSpacing(.fontScaled(top: 1.6, bottom: 1.6))
                .textual.tableOverlay { layout in
                    Canvas { context, _ in
                        for divider in layout.dividers() {
                            context.fill(
                                Path(divider),
                                with: .color(borderColor)
                            )
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: borderRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
    }
    
    struct SimpleLine: StructuredText.ThematicBreakStyle {
        func makeBody(configuration: Configuration) -> some View {
            Rectangle()
                .frame(height: borderWidth)
                .foregroundStyle(borderColor)
                .textual.blockSpacing(.fontScaled(top: 1.6, bottom: 1.6))
        }
    }
    
    struct SimpleCodeBlock: StructuredText.CodeBlockStyle {
        func makeBody(configuration: Configuration) -> some View {
            Overflow {
                configuration.label
                    .textual.lineSpacing(.fontScaled(0.39))
                    .textual.fontScale(0.882)
                    .fixedSize(horizontal: false, vertical: true)
                    .monospaced()
                    .padding(.vertical, 10)
                    .padding(.leading, 14)
            }
            .overlay(
                RoundedRectangle(cornerRadius: borderRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .textual.blockSpacing(.fontScaled(top: 0.88, bottom: 0))
        }
    }
    
    struct SimpleBlockQuote: StructuredText.BlockQuoteStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                RoundedRectangle(cornerRadius: borderRadius, style: .continuous)
                    .fill(borderColor)
                    .frame(width: 5, alignment: .leading)
                
                configuration.label
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textual.lineSpacing(.fontScaled(0.471))
                    .textual.padding(.fontScaled(0.941))
            }
        }
    }
}
