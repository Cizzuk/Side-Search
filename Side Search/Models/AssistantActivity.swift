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
                return "Waiting for Assistant..."
            case .pausingRecognition:
                return "Recognition Paused"
            case .off:
                return "Assistant is Off"
            }
        }
        
        var isActive: Bool {
            switch self {
            case .listening, .waitingForResponse:
                return true
            case .pausingRecognition, .off:
                return false
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
        
        var imageHPadding: CGFloat {
            switch self {
            case .listening:
                return 3
            case .waitingForResponse:
                return 0
            case .pausingRecognition:
                return 1
            case .off:
                return 0
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
            let _ = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
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
            }
        }
    }
    
    static func endAll() {
        let activities = Activity<AssistantActivityAttributes>.activities
        
        let contentState = AssistantActivityAttributes.ContentState()
        
        let content = ActivityContent(
            state: contentState,
            staleDate: nil
        )
        
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached(priority: .userInitiated) {
            for activity in activities {
                await activity.end(content, dismissalPolicy: .immediate)
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}
