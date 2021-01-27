//
//  Constants.swift
//  VideoCallingTask
//
//  Created by Fahad jamal on 27/01/2021.
//

import Foundation

enum AppNetworkURL {
    static let SERVER_URL_CENTRIFUGO = "https://api.delta.duplex.network/api/v1/centrifugo-token/"
    static let PUBLISH_CENTRIFUGO = "https://api.delta.duplex.network/api/v1/publish"
}

enum MessageType {
    static let INVITE = "INVITE"
    static let ACCEPT = "ACCEPT"
    static let REJECT = "REJECT"
    static let BYE = "BYE"
}

enum CallerID {
    static let CALLER = "1234"
    static let CALLEE = "1235"
}
