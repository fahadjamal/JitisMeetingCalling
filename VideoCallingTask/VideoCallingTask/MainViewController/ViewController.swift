//
//  ViewController.swift
//  VideoCallingTask
//
//  Created by Fahad jamal on 25/01/2021.
//

import UIKit
import PromiseKit
import SwiftCentrifuge
import JitsiMeet

class ViewController: UIViewController {
    @IBOutlet weak var connectionStatus: UILabel!
    @IBOutlet weak var lastMessage: UILabel!
    @IBOutlet weak var newMessage: UITextField!
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var byeButton: UIButton!
    
    private var client: CentrifugeClient?
    private var sub: CentrifugeSubscription?
    private var isConnected: Bool = false
    private var subscriptionCreated: Bool = false
    
    var centrifugoToken : CentrifugoToken?
    var centrifugoTypeResponse : CentrifugoTypeResponse?
    
    fileprivate var jitsiMeetView: JitsiMeetView?
    
    lazy var networkService: NetworkService = NetworkService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Please provide the channel name here 
        self.loadCentrifugeTokenFromServer(channel: "1234")
    }
    
    func loadCentrifugeTokenFromServer(channel : String) {
        let userRegURL = "\(AppNetworkURL.SERVER_URL_CENTRIFUGO)\(channel)"
        networkService.requestHttpGET(withUrl: userRegURL, successHandler: { (serverResponse) in
            print("serverResponse\(String(describing: serverResponse))")
            if let data = serverResponse, let stringResponse = String(data: data as! Data, encoding: .utf8) {
                let responseString : String = stringResponse
                let fixedString = responseString.replacingOccurrences(of: "\\", with: "")
                let data = Data(fixedString.utf8)
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                    if let object = json as? NSDictionary {
                        // json is a dictionary
                        print(object)
                        let stringToken : String = String(format: "%@", object.value(forKey: "token") as! CVarArg)
                        let channelToken : String = String(format: "%@", object.value(forKey: "channel") as! CVarArg)
                        let stringurl : String = String(format: "%@?format=protobuf", object.value(forKey: "url") as! CVarArg)
                        self.centrifugoToken = CentrifugoToken(token: stringToken, url: stringurl, channel: channelToken)
                        self.fetchTokenForUser()
                        
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
    
    
    func fetchTokenForUser() {
        let config = CentrifugeClientConfig()
        let url = self.centrifugoToken?.url
        self.client = CentrifugeClient(url: url!, config: config, delegate: self)
        let token = self.centrifugoToken?.token
        self.client?.setToken(token!)
    }

    @IBAction func send(_ sender: Any) {
        self.getCentrifugeTokenFromServer(inputStatus: MessageType.INVITE)
        let data = ["input": MessageType.INVITE]
        self.newMessage.text = ""
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else {return}
        sub?.publish(data: jsonData, completion: { error in
            if let err = error {
                print("Unexpected publish error: \(err)")
            }
        })
    }
    
    @IBAction func acceptButton(_ sender: Any) {
        self.getCentrifugeTokenFromServer(inputStatus: MessageType.ACCEPT)
        let data = ["input": MessageType.ACCEPT]
        self.newMessage.text = ""
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else {return}
        sub?.publish(data: jsonData, completion: { error in
            if let err = error {
                print("Unexpected publish error: \(err)")
            }
        })
    }

    @IBAction func rejectButton(_ sender: Any) {
        self.getCentrifugeTokenFromServer(inputStatus: MessageType.REJECT)
        let data = ["input": MessageType.REJECT]
        self.newMessage.text = ""
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else {return}
        sub?.publish(data: jsonData, completion: { error in
            if let err = error {
                print("Unexpected publish error: \(err)")
            }
        })
    }
    
    @IBAction func byeButton(_ sender: Any) {
        self.getCentrifugeTokenFromServer(inputStatus: MessageType.BYE)
        let data = ["input": MessageType.BYE]
        self.newMessage.text = ""
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else {return}
        sub?.publish(data: jsonData, completion: { error in
            if let err = error {
                print("Unexpected publish error: \(err)")
            }
        })
    }
    
    @IBAction func connect(_ sender: Any) {
        if self.isConnected {
            self.client?.disconnect()
        } else {
            self.client?.connect()
            if !self.subscriptionCreated {
                // Only subscribe once, after this client will internally keep all subscriptions
                // so we don't need to subscribe again.
                self.createSubscription()
                self.subscriptionCreated = true
            }
        }
    }
    
    private func createSubscription() {
        do {
            let channel = self.centrifugoToken?.channel
            sub = try self.client?.newSubscription(channel: channel ?? "", delegate: self)
        } catch {
            print("Can not create subscription: \(error)")
            return
        }
        sub?.subscribe()
    }
    
    func setUpJitsiCall(jwtToken : String)  {
        let defaultOptions = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            // for JaaS replace url with https://8x8.vc
            builder.serverURL = URL(string: "https://jitsi.delta.duplex.network")
            // for JaaS use the obtained Jitsi JWT
            builder.token = jwtToken
            builder.setFeatureFlag("meeting-name.enabled", withValue: false)
            builder.welcomePageEnabled = false
        }

        JitsiMeet.sharedInstance().defaultConferenceOptions = defaultOptions
    }

    func openJitsiMeet(room : String) {
        let userInfo =  JitsiMeetUserInfo.init()
            userInfo.displayName = "Fahad"
        
        DispatchQueue.main.async {
            // UIView usage
            // create and configure jitsimeet view
            let jitsiMeetView = JitsiMeetView()
                jitsiMeetView.delegate = self
            self.jitsiMeetView = jitsiMeetView
            let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
                // for JaaS use <tenant>/<roomName> format
                builder.userInfo = userInfo
                builder.room = room
            }

            // setup view controller
            let vc = UIViewController()
            vc.modalPresentationStyle = .fullScreen
            vc.view = jitsiMeetView

            // join room and display jitsi-call
            jitsiMeetView.join(options)
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func makeACall() {
        self.setUpJitsiCall(jwtToken: CustomManager.sharedInstance.jwtToken)
        DispatchQueue.main.async {
            self.openJitsiMeet(room: self.centrifugoTypeResponse?.room ?? "")
        }
    }
    
    func updateUIItems(inputString : String) {
        self.lastMessage.text = inputString
        if self.centrifugoTypeResponse != nil {
            if self.centrifugoTypeResponse?.type == MessageType.ACCEPT {
                print("start call")
                self.setUpJitsiCall(jwtToken: CustomManager.sharedInstance.jwtToken)
                self.openJitsiMeet(room: self.centrifugoTypeResponse?.room ?? "")
            }
            else if self.centrifugoTypeResponse?.type == MessageType.BYE {
                print("end call")
                self.cleanUp()
            }
            else if self.centrifugoTypeResponse?.type == MessageType.INVITE {
                print("end call")
                self.getCentrifugeTokenFromServer(inputStatus: MessageType.INVITE)
            }
        }
    }
}

extension ViewController: CentrifugeClientDelegate {
    func onConnect(_ c: CentrifugeClient, _ e: CentrifugeConnectEvent) {
        self.isConnected = true
        print("connected with id", e.client)
        DispatchQueue.main.async { [weak self] in
            self?.connectionStatus.text = "Connected"
            self?.connectButton.setTitle("Disconnect", for: .normal)
        }
    }
    
    func onDisconnect(_ c: CentrifugeClient, _ e: CentrifugeDisconnectEvent) {
        self.isConnected = false
        print("disconnected", e.reason, "reconnect", e.reconnect)
        DispatchQueue.main.async { [weak self] in
            self?.connectionStatus.text = "Disconnected"
            self?.connectButton.setTitle("Connect", for: .normal)
        }
    }
}

extension ViewController: CentrifugeSubscriptionDelegate {
    func onPublish(_ s: CentrifugeSubscription, _ e: CentrifugePublishEvent) {
        let data = String(data: e.data, encoding: .utf8) ?? ""
        print("message from channel", s.channel, data)
        
        let localDictionary = self.gettingDictFromData(data: e.data)
        print("localDictionary", localDictionary)
        
        guard let inputType = localDictionary.value(forKey: "input") else {
            DispatchQueue.main.async { [weak self] in
                self?.updateUIItems(inputString: data)
            }
            return
        }
        
        if localDictionary.value(forKey: "input") as! String == MessageType.BYE {
            self.cleanUp()
            print("call closed")
        }
        else if localDictionary.value(forKey: "input") as! String == MessageType.ACCEPT {
            print("call Make")
            self.makeACall()
        }
    }
    
    
    func onSubscribeSuccess(_ s: CentrifugeSubscription, _ e: CentrifugeSubscribeSuccessEvent) {
        s.presence(completion: { result, error in
            if let err = error {
                print("Unexpected presence error: \(err)")
            } else if let presence = result {
                print(presence)
            }
        })
        print("successfully subscribed to channel \(s.channel)")
    }
    
    func onSubscribeError(_ s: CentrifugeSubscription, _ e: CentrifugeSubscribeErrorEvent) {
        print("failed to subscribe to channel", e.code, e.message)
    }
    
    func onUnsubscribe(_ s: CentrifugeSubscription, _ e: CentrifugeUnsubscribeEvent) {
        print("unsubscribed from channel", s.channel)
    }
    
    func onJoin(_ s: CentrifugeSubscription, _ e: CentrifugeJoinEvent) {
        print("client joined channel \(s.channel), user ID \(e.user)")
    }
    
    func onLeave(_ s: CentrifugeSubscription, _ e: CentrifugeLeaveEvent) {
        print("client left channel \(s.channel), user ID \(e.user)")
    }
    
    func gettingDictFromData(data : Data) -> NSDictionary {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            if let object = json as? NSDictionary {
                // json is a dictionary
                print(object)
                
                if object.count > 1 {
                    let stringCallee : String = String(format: "%d", object.value(forKey: "callee") as! CVarArg)
                    let stringCaller : String = String(format: "%d", object.value(forKey: "caller") as! CVarArg)
                    let stringRoom : String = String(format: "%@", object.value(forKey: "room") as! CVarArg)
                    let stringType : String = String(format: "%@", object.value(forKey: "type") as! CVarArg)
                    self.centrifugoTypeResponse = CentrifugoTypeResponse(callee: stringCallee, caller: stringCaller, room: stringRoom, type: stringType)
                }
                
                return object
                
            } else {
                print("JSON is invalid")
                return NSDictionary()
            }
            
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
            return NSDictionary()
        }
    }
    
}

extension ViewController: JitsiMeetViewDelegate {
    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        cleanUp()
    }

    fileprivate func cleanUp() {
        if(jitsiMeetView != nil) {
            dismiss(animated: true, completion: nil)
            jitsiMeetView = nil
        }
    }

}
