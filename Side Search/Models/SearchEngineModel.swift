//
//  SearchEngineModel.swift
//  Side Search
//
//  Created by Cizzuk on 2025/12/24.
//

import Foundation

struct SearchEngineModel: Identifiable, Codable {
    var id = UUID()
    var name: LocalizedStringResource = ""
    var url = ""
    var disablePercentEncoding: Bool = false
    var maxQueryLength: Int? = nil
}

// Encode/Decode JSON
extension SearchEngineModel {
    func toJSON() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    
    static func fromJSON(_ data: Data) -> SearchEngineModel? {
        let decoder = JSONDecoder()
        return try? decoder.decode(SearchEngineModel.self, from: data)
    }
}
