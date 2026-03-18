//
//  AssistantActivity.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/04.
//

import ActivityKit
import Foundation

nonisolated struct AssistantActivityAttributes: ActivityAttributes {
    enum AssistantState: String, Codable, Hashable {
        case listening          // Speech recognition is active
        case waitingForResponse // Waiting for assistant's response
        case pausingRecognition // Speech recognition is paused but microphone is still active
        case off                // Microphone is off and not listening
        
        var description: LocalizedStringResource {
            switch self {
            case .listening:
                return "Listening..."
            case .waitingForResponse:
                return "Waiting for assistant..."
            case .pausingRecognition:
                return "Recognition paused"
            case .off:
                return "Assistant is off"
            }
        }
        
        var systemImage: String {
            switch self {
            case .listening:
                return "microphone.fill"
            case .waitingForResponse:
                return "progress.indicator"
            case .pausingRecognition:
                return "microphone.slash"
            case .off:
                return "microphone.badge.xmark"
            }
        }
    }
    
    struct ContentState: Codable, Hashable {
        var state: AssistantState = .listening
    }
}

class AssistantActivityManager {
    static func isActive() -> Bool {
        return !Activity<AssistantActivityAttributes>.activities.isEmpty
    }
    
    static func start(
        endDate: Date? = nil,
        state: AssistantActivityAttributes.ContentState
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Activities are not enabled. Cannot start assistant activity.")
            return
        }
        endAll()
        
        let attributes = AssistantActivityAttributes()
        
        let content = ActivityContent(
            state: state,
            staleDate: endDate
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("Started assistant activity: \(activity) with state: \(state)")
        } catch {
            print("Failed to start assistant activity: \(error)")
        }
    }
    
    static func update(state: AssistantActivityAttributes.ContentState) {
        let activities = Activity<AssistantActivityAttributes>.activities
        
        let content = ActivityContent(
            state: state,
            staleDate: nil
        )
        
        Task {
            for activity in activities {
                guard activity.content.state != state else { continue }
                await activity.update(content)
                print("Updated assistant activity: \(activity) to state: \(state)")
            }
        }
    }
    
    static func endAll() {
        let contentState = AssistantActivityAttributes.ContentState()
        
        let content = ActivityContent(
            state: contentState,
            staleDate: nil
        )
        
        Task.detached {
            let activities = Activity<AssistantActivityAttributes>.activities
            
            for activity in activities {
                await activity.end(
                    content,
                    dismissalPolicy: .immediate
                )
                print("Ended assistant activity: \(activity)")
            }
        }
    }
}
