//
//  CustomManager.swift
//  HomeBusiness
//
//  Created by  on 11/1/17.
//  Copyright © 2017 Inari. All rights reserved.
//

import UIKit

class CustomManager: NSObject {
    var jwtToken : String = ""
    
    // MARK: - Shared Instance
    static let sharedInstance: CustomManager = {
        let instance = CustomManager()
        // setup code
        return instance
    }()
    
    enum MessageType {
        static let INVITE = "INVITE"
        static let ACCEPT = "ACCEPT"
        static let REJECT = "REJECT"
        static let BYE = "BYE"
    }

    func createParamDict(inputMessage : String) -> [String : Any] {
        var localInputChannel : String = "notification#"
        
        if inputMessage == MessageType.INVITE  {
            localInputChannel = "\(localInputChannel)\(CallerID.CALLEE)"
        }
        else if inputMessage == MessageType.ACCEPT || inputMessage == MessageType.REJECT || inputMessage == MessageType.BYE {
            localInputChannel = "\(localInputChannel)\(CallerID.CALLER)"
        }
        
        let dataParamDict : [String : String] = ["type": inputMessage, "caller":"1234", "callee":"1235", "room":"t063s8vdq"]
        let paramsDict : [String : Any] = ["channel": localInputChannel, "data": dataParamDict]
        let finalParamDict : [String : Any] = ["method":"publish", "params": paramsDict]
        return finalParamDict
    }
}
