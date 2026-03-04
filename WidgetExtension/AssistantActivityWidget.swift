//
//  AssistantActivityWidget.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/04.
//

import ActivityKit
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
    
    struct RecordImage: View {
        var size: CGFloat? = nil

        var body: some View {
            Image(systemName: "microphone.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(.vertical, 2)
                .padding(.trailing, 3)
                .accessibilityLabel("Assistant is Active")
                .foregroundStyle(.dropblue)
        }
    }
    
    struct DescriptionText: View {
        var showSubtitle: Bool = true
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Assistant is Active")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.dropblue)
                if showSubtitle {
                    Text("Side Search")
                        .font(.subheadline)
                        .foregroundStyle(.dropblue.opacity(0.8))
                }
            }
        }
    }
    
    struct MainActivityView: View {
        @Environment(\.activityFamily) var activityFamily
        
        var body: some View {
            switch activityFamily {
            case .small:
                HStack(spacing: 10) {
                    IconImage(size: 30)
                    DescriptionText(showSubtitle: false)
                }
            case .medium:
                HStack(spacing: 10) {
                    IconImage(size: 40)
                    DescriptionText()
                }
                .padding()
            @unknown default:
                EmptyView()
            }
        }
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AssistantActivityAttributes.self) { _ in
            MainActivityView()
                .activitySystemActionForegroundColor(.red)
            
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IconImage(size: 50)
                        .padding(5)
                }
                DynamicIslandExpandedRegion(.center) {
                    DescriptionText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                IconImage()
            } compactTrailing: {
                RecordImage()
            } minimal: {
                IconImage()
            }
            .keylineTint(.dropblue)
        }
        .supplementalActivityFamilies([.small])
    }
}
