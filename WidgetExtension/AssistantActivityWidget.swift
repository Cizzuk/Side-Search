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
            Image("Sidefish")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(.vertical, 2)
                .accessibilityLabel("Side Search")
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
                .frame(width: size, height: size)
                .padding(.vertical, 2)
                .padding(.trailing, 2)
                .accessibilityLabel("Assistant is Active")
                .foregroundStyle(.dropblue)
        }
    }
    
    struct DescriptionText: View {
        var showSubtitle: Bool = true
        var state: LocalizedStringResource? = nil
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Side Search")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.dropblue)
                if let state = state, showSubtitle {
                    Text(state)
                        .font(.subheadline)
                        .foregroundStyle(.dropblue.opacity(0.8))
                }
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
                    DescriptionText(showSubtitle: false)
                }
            case .medium:
                HStack(spacing: 15) {
                    IconImage(size: 45)
                        .padding(.leading, 10)
                    DescriptionText(state: context.state.state.description)
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
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IconImage(size: 55)
                        .padding(.vertical, 5)
                        .padding(.leading, 10)
                        .frame(maxHeight: .infinity)
                }
                DynamicIslandExpandedRegion(.center) {
                    DescriptionText(state: context.state.state.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EndAssistantButton()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } compactLeading: {
                IconImage()
            } compactTrailing: {
                StateImage(systemName: context.state.state.systemImage)
            } minimal: {
                IconImage()
            }
            .keylineTint(.dropblue)
        }
        .supplementalActivityFamilies([.small])
    }
}
