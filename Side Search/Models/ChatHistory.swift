//
//  ChatHistory.swift
//  Side Search
//
//  Created by Cizzuk on 2026/02/08.
//

import Foundation

struct ChatHistory: Identifiable, Decodable {
    var id = UUID()
    var date: Date
    var assistantType: AssistantType
    var assistantSettings: String
    var messages: [AssistantMessage]
}
