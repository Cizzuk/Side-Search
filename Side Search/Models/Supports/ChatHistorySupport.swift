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
        var messages: Data  // Store as Data (JSON)

        // Convert from Chat
        init(from chat: Chat) throws {
            self.id = chat.id
            self.date = chat.date
            self.assistantType = chat.assistantType
            self.messages = try JSONEncoder().encode(chat.messages)
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

    private static var context: ModelContext? {
        container?.mainContext
    }

    private static func fetchRecords(in context: ModelContext) -> [ChatEntity] {
        let descriptor = FetchDescriptor<ChatEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    private static func getRecord(_ id: UUID, in context: ModelContext) throws -> ChatEntity? {
        let chatID = id
        var descriptor = FetchDescriptor<ChatEntity>(
            predicate: #Predicate { $0.id == chatID }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Public Methods

    static func loadChats() -> [Chat] {
        guard let context else { return [] }

        let records = fetchRecords(in: context)

        return records.compactMap { $0.toChat() }
    }

    static func save(_ chat: Chat) throws {
        guard let context else { return }
        let newRecord = try ChatEntity(from: chat)

        if let oldRecord = try getRecord(newRecord.id, in: context) {
            context.delete(oldRecord)
        }

        context.insert(newRecord)
        try context.save()
    }

    static func delete(_ chat: UUID) throws {
        guard let context else { return }

        if let record = try getRecord(chat, in: context) {
            context.delete(record)
            try context.save()
        }
    }

    static func clearAll() throws {
        guard let context else { return }

        fetchRecords(in: context).forEach { context.delete($0) }
        try context.save()
    }
}
