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
    
    struct EndAssistantButton: View {
        var body: some View {
            Button(intent: EndAssistantButtonIntent()) {
                Label("End Assistant", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 30, weight: .bold))
                    .padding(5)
            }
            .tint(.dropblue)
            .padding(5)
        }
    }
    
    struct EndAssistantButtonIntent: AppIntent {
        static let title: LocalizedStringResource = "End Assistant"
        static var openAppWhenRun = false
        static var isDiscoverable = false
        
        @MainActor
        func perform() async throws -> some IntentResult {
//            GroupUserDefaults.set(true, forKey: CFNotificationFlags.shouldEndAssistant)
//            CFNotificationCenterPostNotification(
//                CFNotificationCenterGetDarwinNotifyCenter(),
//                .shouldEndAssistant,
//                nil,
//                nil,
//                true
//            )
            
            return .result()
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
                HStack(spacing: 15) {
                    IconImage(size: 45)
                        .padding(.leading, 10)
                    DescriptionText()
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
        ActivityConfiguration(for: AssistantActivityAttributes.self) { _ in
            MainActivityView()
                .activitySystemActionForegroundColor(.red)
            
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IconImage(size: 55)
                        .padding(.vertical, 5)
                        .padding(.leading, 10)
                }
                DynamicIslandExpandedRegion(.center) {
                    DescriptionText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EndAssistantButton()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
