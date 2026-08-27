//
//  ChatHistorySupport.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/08.
//

import Foundation
import SwiftData

final class ChatHistorySupport {
    // MARK: - Chat Model
    // To migrate from UserDefaults to SwiftData and make it easier to use in views.
    struct Chat: Identifiable, Codable {
        var id = UUID()
        var date: Date = Date()
        var assistantType: AssistantType
        var messages: [AssistantMessage]
        var previewText: String {
            messages.first?.content ?? ""
        }
    }
    
    // MARK: - SwiftData Model
    @Model
    final class ChatEntity {
        @Attribute(.unique) var id: UUID
        var date: Date
        var assistantType: AssistantType
        var messages: Data // Store as Data (JSON)
        
        // Convert from Chat
        init(from chat: Chat) {
            self.id = chat.id
            self.date = chat.date
            self.assistantType = chat.assistantType
            self.messages = (try? JSONEncoder().encode(chat.messages)) ?? Data()
        }
        
        // Convert to Chat
        func toChat() -> Chat {
            return Chat(
                id: self.id,
                date: self.date,
                assistantType: self.assistantType,
                messages: (try? JSONDecoder().decode([AssistantMessage].self, from: self.messages)) ?? []
            )
        }
    }
    
    private static let container: ModelContainer? = try? ModelContainer(for: ChatEntity.self)
    
    private static func makeContext() -> ModelContext? {
        guard let container else { return nil }
        return ModelContext(container)
    }
    
    private static func fetchRecords(in context: ModelContext) -> [ChatEntity] {
        let descriptor = FetchDescriptor<ChatEntity>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    private static func getRecord(_ id: UUID, in context: ModelContext) -> ChatEntity? {
        return fetchRecords(in: context).first(where: { $0.id == id })
    }
    
    // MARK: - Public Methods
    
    static func loadChats() -> [Chat] {
        guard let context = makeContext() else { return [] }
        
        let records = fetchRecords(in: context)
        
        return records
            .compactMap { $0.toChat() }
            .sorted(by: { $0.date > $1.date })
    }
    
    static func save(_ chat: Chat) {
        guard let context = makeContext() else { return }
        let newRecord = ChatEntity(from: chat)
        
        // If id already exists, delete the old record
        if let oldRecord = getRecord(newRecord.id, in: context) {
            context.delete(oldRecord)
        }
        
        context.insert(newRecord)
        try? context.save()
    }
    
    static func delete(_ chat: UUID) {
        guard let context = makeContext() else { return }
        
        if let record = getRecord(chat, in: context) {
            context.delete(record)
            try? context.save()
        }
    }
    
    static func clearAll() {
        guard let context = makeContext() else { return }
        
        fetchRecords(in: context).forEach { context.delete($0) }
        try? context.save()
    }
}
