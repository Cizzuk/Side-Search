//
//  AssistantActivityWidget.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/04.
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct AssistantActivityWidget: Widget {
    static let kind = "net.cizzuk.sidesearch.WidgetExtension.AssistantActivityWidget"
    
    struct IconImage: View {
        var size: CGFloat? = nil

        var body: some View {
            Image("sidefish")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(.dropblue)
        }
    }
    
    struct StateImage: View {
        var size: CGFloat? = nil
        var systemName: String

        var body: some View {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(.dropblue)
        }
    }
    
    struct DescriptionText: View {
        var description: LocalizedStringResource
        var small: Bool = false
        
        var body: some View {
            VStack(alignment: .leading) {
                if !small {
                    Text("Side Search")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.dropblue)
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.dropblue.opacity(0.8))
            }
        }
    }
    
    struct EndAssistantButton: View {
        var body: some View {
            Button(intent: EndAssistantIntent()) {
                Label("End Assistant", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 30, weight: .bold))
                    .padding(5)
            }
            .tint(.dropblue)
            .padding(5)
        }
    }
    
    struct MainActivityView: View {
        @Environment(\.activityFamily) var activityFamily
        var context: ActivityViewContext<AssistantActivityAttributes>
        
        var body: some View {
            switch activityFamily {
            case .small:
                HStack(spacing: 10) {
                    IconImage(size: 30)
                        .accessibilityHidden(true)
                    DescriptionText(description: context.state.state.description, small: true)
                }
            case .medium:
                HStack(spacing: 15) {
                    IconImage(size: 45)
                        .padding(.leading, 10)
                        .accessibilityHidden(true)
                    DescriptionText(description: context.state.state.description)
                    Spacer()
                    EndAssistantButton()
                }
                .padding()
            @unknown default:
                EmptyView()
            }
        }
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AssistantActivityAttributes.self) { context in
            MainActivityView(context: context)
                .activitySystemActionForegroundColor(.dropblue)
            
        } dynamicIsland: { context in
            let activeOpacity = context.state.state.isActive ? 1.0 : 0.75
            let compactA11yLabel: LocalizedStringResource = "\(context.state.state.description), \("Side Search")"
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IconImage(size: 55)
                        .padding(.vertical, 5)
                        .padding(.leading, 10)
                        .frame(maxHeight: .infinity)
                        .accessibilityHidden(true)
                }
                DynamicIslandExpandedRegion(.center) {
                    DescriptionText(description: context.state.state.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EndAssistantButton()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } compactLeading: {
                IconImage(size: 20)
                    .padding(.horizontal, 1)
                    .opacity(activeOpacity)
                    .accessibilityLabel(compactA11yLabel)
            } compactTrailing: {
                StateImage(size: 20, systemName: context.state.state.systemImage)
                    .padding(.vertical, 2)
                    .opacity(activeOpacity)
                    .accessibilityHidden(true)
            } minimal: {
                StateImage(size: 20, systemName: context.state.state.systemImage)
                    .padding(.vertical, 2)
                    .opacity(activeOpacity)
                    .accessibilityLabel(compactA11yLabel)
            }
            .keylineTint(context.state.state.isActive ? .dropblue : nil)
        }
        .supplementalActivityFamilies([.small])
    }
}
