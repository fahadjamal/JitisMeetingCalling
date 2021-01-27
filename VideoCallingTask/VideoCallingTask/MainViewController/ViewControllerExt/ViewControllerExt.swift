//
//  ViewControllerExt.swift
//  VideoCallingTask
//
//  Created by Fahad jamal on 27/01/2021.
//

import Foundation
import JitsiMeet

extension ViewController {
    
    func getCentrifugeTokenFromServer(inputStatus : String) {
        let userRegURL = "\(AppNetworkURL.PUBLISH_CENTRIFUGO)"
        let paramDict : [String : Any] = CustomManager.sharedInstance.createParamDict(inputMessage: inputStatus) as [String : Any]
        networkService.requestHttpPost(withUrl: userRegURL, params: paramDict , successHandler: { (serverResponse) in
            print("serverResponse\(String(describing: serverResponse))")
            if let data = serverResponse, let stringResponse = String(data: data as! Data, encoding: .utf8) {
                let responseString : String = stringResponse
                let fixedString = responseString.replacingOccurrences(of: "\\", with: "")
                let data = Data(fixedString.utf8)
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                    if let object = json as? NSDictionary {
                        // json is a dictionary
                        let stringToken : String = String(format: "%@", object.value(forKey: "jwt") as! CVarArg)
                        print("stringToken\(stringToken)")
                        CustomManager.sharedInstance.jwtToken = stringToken
                    } else {
                        print("JSON is invalid")
                    }
                } catch let error as NSError {
                    print("Failed to load: \(error.localizedDescription)")
                }
            }
            else {
                print("errorResponse")
            }
        }) {(errorResponse) in
            print("\(errorResponse)")
        }
    }

}

