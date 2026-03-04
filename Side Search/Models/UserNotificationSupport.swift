//
//  UserNotificationSupport.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/04.
//

import UserNotifications

class UserNotificationSupport {
    static func isAvailable() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        if settings.authorizationStatus == .notDetermined || settings.authorizationStatus == .authorized {
            return true
        }
        
        return false
    }
    
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        if settings.authorizationStatus == .notDetermined {
            do {
                try await center.requestAuthorization(options: [.alert])
                return await requestAuthorization()
            } catch {
                print("Failed to request notification authorization: \(error)")
                return false
            }
        }

        if settings.authorizationStatus == .authorized {
            return true
        }

        return false
    }
    
    static func sendAssistantMessage(message: AssistantMessage) async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: message.from.displayName)
        content.body = message.content
        content.sound = .none
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        let notificationCenter = UNUserNotificationCenter.current()
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to add notification request: \(error)")
        }
    }
}
