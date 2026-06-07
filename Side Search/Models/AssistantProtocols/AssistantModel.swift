//
//  AssistantProtocols.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/25.
//

import Foundation

protocol AssistantModel: Codable, Equatable {
    static func load() -> Self
    func save()
}
