//
//  ConfiguroToken.swift
//  VideoCallingTask
//
//  Created by Fahad jamal on 27/01/2021.
//

import Foundation

// MARK: - Welcome
struct CentrifugoToken: Codable {
    let token, url, channel: String
}

struct CentrifugoTypeResponse: Codable {
    let callee, caller: String
    let room, type: String
}
