//
//  ChatHistoryViewModel.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/09.
//

import Combine
import UIKit
import SwiftUI

class ChatHistoryViewModel: ObservableObject {
    @Published var chats: [ChatHistorySupport.Chat] = []
    
    // Search Chat History
    @Published var searchResults: [ChatHistorySupport.Chat] = []
    @Published var searchQuery = "" {
        didSet { updateSearch() }
    }
    
    func loadChats() {
        chats = ChatHistorySupport.loadChats()
        updateSearch()
    }
    
    func delete(_ chat: UUID) {
        ChatHistorySupport.delete(chat)
        loadChats()
    }
    
    func clearAll() {
        ChatHistorySupport.clearAll()
        loadChats()
    }
    
    func updateSearch() {
        let query = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        if query.isEmpty {
            searchResults = []
            return
        }
        
        // Search in messages, assistant type
        let filtered = chats.filter { chat in
            let assistantName = String(localized: chat.assistantType.displayName).lowercased()
            
            let matchesAssistant = assistantName.contains(query)
            let matchesMessages = chat.messages.contains { $0.content.lowercased().contains(query) }
            
            return matchesAssistant || matchesMessages
        }
        
        searchResults = filtered.sorted { $0.date > $1.date }
    }
}
