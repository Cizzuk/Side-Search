//
//  AssistantActivity.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/04.
//

import ActivityKit
import Foundation

nonisolated struct AssistantActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable { }
}

class AssistantActivityManager {
    static func isActive() -> Bool {
        return !Activity<AssistantActivityAttributes>.activities.isEmpty
    }
    
    static func start(endDate: Date? = nil) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Activities are not enabled. Cannot start assistant activity.")
            return
        }
        endAll()
        
        let attributes = AssistantActivityAttributes()
        
        let contentState = AssistantActivityAttributes.ContentState()
        
        let content = ActivityContent(
            state: contentState,
            staleDate: endDate
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("Started assistant activity: \(activity)")
        } catch {
            print("Failed to start assistant activity: \(error)")
        }
    }
    
    static func endAll() {
        let activities = Activity<AssistantActivityAttributes>.activities
        
        let contentState = AssistantActivityAttributes.ContentState()
        
        let content = ActivityContent(
            state: contentState,
            staleDate: nil
        )
        
        Task.detached {
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
