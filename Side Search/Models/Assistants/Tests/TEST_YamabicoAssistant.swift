//
//  TEST_YamabicoAssistant.swift
//  Side Search
//
//  Created by Cizzuk on 2026/01/26.
//

import SwiftUI

struct TEST_YamabicoAssistant: AssistantDescriptionProvider {
    static var assistantName = LocalizedStringResource("TEST Yamabico Assistant")
    static var assistantDescription = LocalizedStringResource("TEST Assistant. Echo user input.")
    static var assistantSystemImage = "ladybug"
    static var assistantGradient = Gradient(colors: [
        Color(red: 51/255, green: 102/255,  blue: 255/255),
    ])
    
    static var makeSettingsView: any View { EmptyView() }
    static var userDefaultsKey = "TEST_YamabicoAssistantSettings"
    
    static func makeAssistantViewModel() -> AssistantViewModel { TEST_YamabicoAssistantViewModel() }
    
    static func isAvailable() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static func isBlocked() -> Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}

struct TEST_YamabicoAssistantModel: AssistantModel {
    static func fromJSON(_ data: Data) -> TEST_YamabicoAssistantModel? {
        let decoder = JSONDecoder()
        let model = try? decoder.decode(TEST_YamabicoAssistantModel.self, from: data)
        return model
    }
    
    func toJSON() -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    
    func isValidSettings() -> Bool {
        return true
    }
}
