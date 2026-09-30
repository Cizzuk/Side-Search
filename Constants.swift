//
//  Constants.swift
//  Side Search
//
//  Created by Cizzuk on 2026/03/08.
//

import Foundation

let GroupUserDefaults = UserDefaults(suiteName: "group.net.cizzuk.sidesearch")!

extension Notification.Name {
    static let assistantDidActivate = Notification.Name("assistantDidActivate")
    static let shouldEndAssistant = Notification.Name("shouldEndAssistant")
}
