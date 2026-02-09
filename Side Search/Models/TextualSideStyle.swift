//
//  TextualSideStyle.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import SwiftUI
import Textual

struct TextualSideStyle: StructuredText.Style {
    private static let borderWidth: CGFloat = 1.5
    private static let borderColor: Color = .secondary.opacity(0.5)
    private static let borderRadius: CGFloat = 10
    
    let headingStyle: some StructuredText.HeadingStyle = SideHeading()
    let blockQuoteStyle: some StructuredText.BlockQuoteStyle = SideBlockQuote()
    let codeBlockStyle: some StructuredText.CodeBlockStyle = SideCodeBlock()
    let tableStyle: some StructuredText.TableStyle = SideTable()
    let thematicBreakStyle: some StructuredText.ThematicBreakStyle = SideLine()
    
    let inlineStyle: InlineStyle = .default
    let paragraphStyle: some StructuredText.ParagraphStyle = .default
    let listItemStyle: some StructuredText.ListItemStyle = .default
    let unorderedListMarker: StructuredText.SymbolListMarker = .disc
    let orderedListMarker: StructuredText.DecimalListMarker = .decimal
    let tableCellStyle: some StructuredText.TableCellStyle = .default
    
    private struct SideHeading: StructuredText.HeadingStyle {
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
    
    private struct SideBlockQuote: StructuredText.BlockQuoteStyle {
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
    
    private struct SideCodeBlock: StructuredText.CodeBlockStyle {
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
    
    private struct SideTable: StructuredText.TableStyle {
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
    
    private struct SideLine: StructuredText.ThematicBreakStyle {
        func makeBody(configuration: Configuration) -> some View {
            Rectangle()
                .frame(height: borderWidth)
                .foregroundStyle(borderColor)
                .textual.blockSpacing(.fontScaled(top: 1.6, bottom: 1.6))
        }
    }
}
