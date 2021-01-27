//
//  NetworkService.swift
//

import Foundation
import Alamofire

/// Generic Response Struct
struct BaseResponse<T : Decodable> : Decodable {
    let status: Bool?
    let message: String?
    let data: T?
    
    init(from decoder: Decoder) throws {
        self.status = try decoder.container(keyedBy: CodingKeys.self)
            .decode(Bool.self, forKey: CodingKeys.status)
        self.message = try decoder.container(keyedBy: CodingKeys.self)
            .decode(String.self, forKey: CodingKeys.message)
        do {
            self.data = try decoder.container(keyedBy: CodingKeys.self)
                .decode(T.self, forKey: CodingKeys.data)
        } catch {
            self.data = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case message = "message"
        case data = "data"
    }
    
}

struct BaseNotificationResponse<T : Decodable> : Decodable {
    let status: Bool?
    let message: String?
    let notifications: T?
    
    init(from decoder: Decoder) throws {
        self.status = try decoder.container(keyedBy: CodingKeys.self)
            .decode(Bool.self, forKey: CodingKeys.status)
        self.message = try decoder.container(keyedBy: CodingKeys.self)
            .decode(String.self, forKey: CodingKeys.message)
        do {
            self.notifications = try decoder.container(keyedBy: CodingKeys.self)
                .decode(T.self, forKey: CodingKeys.notifications)
        } catch {
            self.notifications = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case message = "message"
        case notifications = "notifications"
    }
}

/// Generic Response Struct
struct SimpleResponse<T : Decodable> : Decodable {
    let status: Bool?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case message = "message"
    }
}


struct AppError: Error {
    private let title: String
    private let message: String
    
    var localizedDescription: String {
        return message
    }
    
    init(title:String, message: String) {
        self.title = title
        self.message = message
    }
}


/// Alamofire Network Request Helper
class NetworkService {
    
    
    /// Maximum Life Of Request In Seconds
    private var REQUEST_TIMEOUT = TimeInterval(20)
    
    init() {}
    
    /// Create generic error
    /// - Returns: error
    func generateError() -> Error {
        return NSError(
            domain: "InvalidResponse",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Someting went wrong"]) as Error
    }
    
    /// Create generic error
    /// - Returns: error
    func generateError(message: String) -> Error {
        return NSError(
            domain: "InvalidResponse",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: message]) as Error
    }
    
    
    
    /// Network GET Request
    /// - Parameters:
    ///   - url: url
    ///   - successCompletion: completion callback when request fullfil
    ///   - errorCapturer: error capturer when error occurred
    func requestHttpGET(withUrl url: String,
                    successHandler successCompletion: @escaping ((Any?) -> ()),
                    errorHandler errorCapturer: @escaping ((Error) -> ())) {
        AF.request(url) {
            urlRequest in
            urlRequest.timeoutInterval = self.REQUEST_TIMEOUT
            if #available(iOS 13.0, *) {
                urlRequest.allowsConstrainedNetworkAccess = false
            }
        }
        .validate(contentType: ["application/json"])
        .validate()
        .response { response in
            switch response.result {
            case .success(let data):
                successCompletion(data)
                break
            case .failure(let error):
                if let statusCode = response.response?.statusCode, (statusCode != 200 || statusCode != 201) {
                    errorCapturer(self.generateError( message: "Internet Error"))
                } else {
                    errorCapturer(error)
                }
                break
            }
        }
    }
    
    func requestHttpPost(withUrl url: String, params : [String : Any],
                    successHandler successCompletion: @escaping ((Any?) -> ()),
                    errorHandler errorCapturer: @escaping ((Error) -> ())) {
        
            AF.request(url, method:.post, parameters: params,encoding: URLEncoding.queryString)
                .validate()
                .response { (result) in
                    if result.response?.statusCode != nil {
                        if let status =  (result.response?.statusCode)! as? Int {
                            if status == 200 {
                                print("status : \(status)")
                                successCompletion(result.value ?? Data())
                            }
                            else {
                                if let statusCode = result.response?.statusCode, (statusCode != 200 || statusCode != 201) {
                                    errorCapturer(self.generateError( message: "Internet Error"))
                                } else {
                                    errorCapturer("Internet Error" as! Error)
                                }
                            }
                        }
                    }
                }
    }
}
