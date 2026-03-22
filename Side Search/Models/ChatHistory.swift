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
    
    static func save(_ chat: Chat) {
        var chats = loadChats()
        
        // If id already exists, replace it, else append
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
        } else {
            chats.append(chat)
        }
        
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
    
    static func search(_ query: String) -> [Chat] {
        let chats = loadChats()
        let lowerQuery = query.lowercased() // Case-insensitive
        
        // Search in messages, assistant type
        let filtered = chats.filter { chat in
            let assistantName = String(localized: chat.assistantType.DescriptionProviderType.assistantName).lowercased()
            
            let matchesAssistant = assistantName.contains(lowerQuery)
            let matchesMessages = chat.messages.contains { $0.content.lowercased().contains(lowerQuery) }
            
            return matchesAssistant || matchesMessages
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
}
