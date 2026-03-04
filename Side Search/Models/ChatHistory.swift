//
//  ChatHistory.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/08.
//

import Foundation

class ChatHistory {
    // MARK: - 'Chat' does NOT conform to 'MergeCodable'.
    // Any changes to this struct should first make it conforms to 'MergeCodable'.
    struct Chat: Identifiable, Codable {
        var id = UUID()
        var date: Date = Date()
        var assistantType: AssistantType
        var messages: [AssistantMessage]
        var previewText: String {
            messages.first?.content ?? ""
        }
    }
    
    static let userDefaultsKey = "ChatHistory"
    
    static func loadChats() -> [Chat] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let chats = try? JSONDecoder().decode([Chat].self, from: data) else {
            return []
        }
        return chats.sorted { $0.date > $1.date }
    }
    
    static func add(_ chat: Chat) {
        var chats = loadChats()
        chats.append(chat)
        if let data = try? JSONEncoder().encode(chats) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    static func delete(_ chat: UUID) {
        var chats = loadChats()
        chats.removeAll { $0.id == chat }
        if let data = try? JSONEncoder().encode(chats) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
