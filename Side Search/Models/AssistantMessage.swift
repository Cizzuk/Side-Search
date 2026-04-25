//
//  AssistantMessage.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/06.
//

import Foundation
import SideBridge

// MARK: - 'AssistantMessage' does NOT conform to 'MergeCodable'.
// Any changes to this struct should first make it conforms to 'MergeCodable'.
struct AssistantMessage: Identifiable, Codable {
    enum From: Codable, Equatable {
        case user
        case assistant
        case system
        case unknown
        
        var displayName: LocalizedStringResource {
            switch self {
            case .user:
                return "You"
            case .assistant:
                return "Assistant"
            case .system:
                return "System"
            case .unknown:
                return "Unknown"
            }
        }
    }
    
    struct Source: Codable {
        var title: String
        var url: URL
    }
    
    var id = UUID()
    var from: From
    var content: String
    var sources: [Source] = []
}

extension AssistantMessage.From {
    func toSBMessageFrom() -> SBMessage.From {
        switch self {
        case .user:
            return .user
        case .assistant:
            return .assistant
        case .system:
            return .system
        case .unknown:
            return .unknown
        }
    }
    
    static func fromSBMessageFrom(_ sbFrom: SBMessage.From) -> AssistantMessage.From {
        switch sbFrom {
        case .user:
            return .user
        case .assistant:
            return .assistant
        case .system:
            return .system
        case .unknown:
            return .unknown
        }
    }
}

extension AssistantMessage {
    func toSBMessage() -> SBMessage {
        SBMessage(
            id: id,
            from: from.toSBMessageFrom(),
            content: content,
            sources: sources.map { source in
                SBMessage.Source(title: source.title, url: source.url)
            }
        )
    }
    
    static func fromSBMessage(_ sbMessage: SBMessage) -> AssistantMessage {
        AssistantMessage(
            id: sbMessage.id,
            from: AssistantMessage.From.fromSBMessageFrom(sbMessage.from),
            content: sbMessage.content,
            sources: sbMessage.sources.map { source in
                Source(title: source.title, url: source.url)
            }
        )
    }
}
