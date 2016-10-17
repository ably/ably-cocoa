//
//  TestUtilities.swift
//  ably
//
//  Created by Yavor Georgiev on 2.08.15.
//  Copyright © 2015 г. Ably. All rights reserved.
//

import Ably
import Foundation
import XCTest
import Quick
import Nimble
import SwiftyJSON
import SocketRocket
import Aspects

import Ably.Private

enum CryptoTest: String {
    case aes128 = "crypto-data-128"
    case aes256 = "crypto-data-256"

    static var all: [CryptoTest] {
        return [.aes128, .aes256]
    }
}

class Configuration : QuickConfiguration {
    override class func configure(configuration: Quick.Configuration!) {
        configuration.beforeEach {

        }
    }
}

func pathForTestResource(resourcePath: String) -> String {
    let testBundle = NSBundle(forClass: AblyTests.self)
    return testBundle.pathForResource(resourcePath, ofType: "")!
}

let appSetupJson = JSON(data: NSData(contentsOfFile: pathForTestResource(testResourcesPath + "test-app-setup.json"))!, options: .MutableContainers)

let testTimeout: NSTimeInterval = 10.0
let testResourcesPath = "ably-common/test-resources/"

/// Common test utilities.
class AblyTests {

    class func base64ToData(base64: String) -> NSData {
        return NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions(rawValue: 0))!
    }

    class func msgpackToJSON(data: NSData) -> JSON {
        return JSON(data: ARTJsonEncoder().encode(ARTMsgPackEncoder().decode(data)))
    }

    class func checkError(errorInfo: ARTErrorInfo?, withAlternative message: String) {
        if let error = errorInfo {
            XCTFail("\(error.code): \(error.message)")
        }
        else if !message.isEmpty {
            XCTFail(message)
        }
    }

    class func checkError(errorInfo: ARTErrorInfo?) {
        checkError(errorInfo, withAlternative: "")
    }

    class var jsonRestOptions: ARTClientOptions {
        get {
            let options = AblyTests.clientOptions()
            return options
        }
    }

    class var authTokenCases: [String: (ARTAuthOptions) -> ()] {
        get { return [
            "useTokenAuth": { $0.useTokenAuth = true; $0.key = "fake:key" },
            "authUrl": { $0.authUrl = NSURL(string: "http://test.com") },
            "authCallback": { $0.authCallback = { _, _ in return } },
            "tokenDetails": { $0.tokenDetails = ARTTokenDetails(token: "token") },
            "token": { $0.token = "token" },
            "key": { $0.tokenDetails = ARTTokenDetails(token: "token"); $0.key = "fake:key" }
            ]
        }
    }

    static var testApplication: JSON?
    static private var setupOptionsCounter = 0

    class func setupOptions(options: ARTClientOptions, forceNewApp: Bool = false, debug: Bool = false) -> ARTClientOptions {
        ARTChannels_getChannelNamePrefix = { "test-\(setupOptionsCounter)" }
        setupOptionsCounter += 1

        if forceNewApp {
            testApplication = nil
        }

        guard let app = testApplication else {
            let request = NSMutableURLRequest(URL: NSURL(string: "https://\(options.restHost):\(options.tlsPort)/apps")!)
            request.HTTPMethod = "POST"
            request.HTTPBody = try? appSetupJson["post_apps"].rawData()

            request.allHTTPHeaderFields = [
                "Accept" : "application/json",
                "Content-Type" : "application/json"
            ]

            let (responseData, responseError, _) = NSURLSessionServerTrustSync().get(request)

            if let error = responseError {
                XCTFail(error.localizedDescription)
                return options
            }

            testApplication = JSON(data: responseData!)
            
            if debug {
                options.logLevel = .Verbose
                print(testApplication!)
            }

            return setupOptions(options, debug: debug)
        }
        
        let key = app["keys"][0]
        options.key = key["keyStr"].stringValue
        return options
    }
    
    class func commonAppSetup(debug debug: Bool = false) -> ARTClientOptions {
        return AblyTests.setupOptions(AblyTests.jsonRestOptions, debug: debug)
    }

    class func clientOptions(debug debug: Bool = false, requestToken: Bool = false) -> ARTClientOptions {
        let options = ARTClientOptions()
        options.environment = "sandbox"
        if debug {
            options.logLevel = .Debug
        }
        else {
            options.logLevel = .Info
        }
        if requestToken {
            options.token = getTestToken()
        }
        return options
    }

    class func newErrorProtocolMessage() -> ARTProtocolMessage {
        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .Error
        protocolMessage.error = ARTErrorInfo.createWithCode(0, message: "Fail test")
        return protocolMessage
    }

    class func newPresenceProtocolMessage(channel: String, action: ARTPresenceAction, clientId: String) -> ARTProtocolMessage {
        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .Presence
        protocolMessage.channel = channel
        protocolMessage.timestamp = NSDate()
        let presenceMessage = ARTPresenceMessage()
        presenceMessage.action = action
        presenceMessage.clientId = clientId
        presenceMessage.timestamp = NSDate()
        protocolMessage.presence = [presenceMessage]
        return protocolMessage
    }

    class func newRealtime(options: ARTClientOptions) -> ARTRealtime {
        let autoConnect = options.autoConnect
        options.autoConnect = false
        let realtime = ARTRealtime(options: options)
        realtime.setTransportClass(TestProxyTransport.self)
        realtime.setReachabilityClass(TestReachability.self)
        if autoConnect {
            options.autoConnect = true
            realtime.connect()
        }
        return realtime
    }

    class func newRandomString() -> String {
        return NSProcessInfo.processInfo().globallyUniqueString
    }

    class func addMembersSequentiallyToChannel(channelName: String, members: Int = 1, startFrom: Int = 1, data: AnyObject? = nil, options: ARTClientOptions, done: ()->()) -> [ARTRealtime] {
        let client = ARTRealtime(options: options)
        let channel = client.channels.get(channelName)

        class Total {
            static var count: Int = 0
        }

        Total.count = 0
        channel.attach() { _ in
            for i in startFrom..<startFrom+members {
                channel.presence.enterClient("user\(i)", data: data) { _ in
                    Total.count += 1
                    if Total.count == members {
                        done()
                    }
                }
            }
        }
        return [client]
    }

    class func splitDone(howMany: Int, done: () -> ()) -> (() -> ()) {
        var left = howMany
        return {
            left -= 1
            if left == 0 {
                done()
            } else if left < 0 {
                fail("splitDone called more than the expected \(howMany) times")
            }
        }
    }

    // MARK: Crypto

    struct CryptoTestItem {

        struct TestMessage {
            let name: String
            let data: String
            let encoding: String
        }

        let encoded: TestMessage
        let encrypted: TestMessage

        init(object: JSON) {
            let encodedJson = object["encoded"]
            encoded = TestMessage(name: encodedJson["name"].stringValue, data: encodedJson["data"].stringValue, encoding: encodedJson["encoding"].string ?? "")
            let encryptedJson = object["encrypted"]
            encrypted = TestMessage(name: encryptedJson["name"].stringValue, data: encryptedJson["data"].stringValue, encoding: encryptedJson["encoding"].stringValue)
        }

    }

    class func loadCryptoTestData(file: String) -> (key: NSData, iv: NSData, items: [CryptoTestItem]) {
        let json = JSON(data: NSData(contentsOfFile: pathForTestResource(file))!)

        let keyData = NSData(base64EncodedString: json["key"].stringValue, options: NSDataBase64DecodingOptions(rawValue: 0))!
        let ivData = NSData(base64EncodedString: json["iv"].stringValue, options: NSDataBase64DecodingOptions(rawValue: 0))!
        let items = json["items"].map{ $0.1 }.map(CryptoTestItem.init)
        
        return (keyData, ivData, items)
    }

    class func loadCryptoTestData(crypto: CryptoTest) -> (key: NSData, iv: NSData, items: [CryptoTestItem]) {
        return loadCryptoTestData(testResourcesPath + crypto.rawValue + ".json")
    }

}

class NSURLSessionServerTrustSync: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {

    func get(request: NSMutableURLRequest) -> (NSData?, NSError?, NSHTTPURLResponse?) {
        var responseError: NSError?
        var responseData: NSData?
        var httpResponse: NSHTTPURLResponse?;
        var requestCompleted = false

        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration:configuration, delegate:self, delegateQueue:NSOperationQueue.mainQueue())

        let task = session.dataTaskWithRequest(request) { data, response, error in
            if let response = response as? NSHTTPURLResponse {
                responseData = data
                responseError = error
                httpResponse = response
            }
            requestCompleted = true
        }
        task.resume()

        while !requestCompleted {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Bool(0))
        }

        return (responseData, responseError, httpResponse)
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        // Try to extract the server certificate for trust validation
        if let serverTrust = challenge.protectionSpace.serverTrust {
            // Server trust authentication
            // Reference: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/AuthenticationChallenges.html
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: serverTrust))
        }
        else {
            challenge.sender?.performDefaultHandlingForAuthenticationChallenge?(challenge)
            XCTFail("Current authentication: \(challenge.protectionSpace.authenticationMethod)")
        }
    }

}

extension NSDate {
    func isBefore(other: NSDate) -> Bool {
        return self.compare(other) == NSComparisonResult.OrderedAscending
    }
}

// MARK: ARTAuthOptions Equatable

func ==(lhs: ARTAuthOptions, rhs: ARTAuthOptions) -> Bool {
    return lhs.token == rhs.token &&
        lhs.authMethod == rhs.authMethod &&
        lhs.authUrl == rhs.authUrl &&
        lhs.key == rhs.key
}

// MARK: Publish message class

class PublishTestMessage {

    var completion: Optional<(ARTErrorInfo?)->()>
    var error: ARTErrorInfo? = ARTErrorInfo.createWithNSError(NSError(domain: "", code: -1, userInfo: nil))

    init(client: ARTRest, failOnError: Bool = true, completion: Optional<(ARTErrorInfo?)->()> = nil) {
        client.channels.get("test").publish(nil, data: "message") { error in
            self.error = error
            if let callback = completion {
                callback(error)
            }
            else if failOnError, let e = error {
                XCTFail("Got error '\(e)'")
            }
        }
    }

    init(client: ARTRealtime, failOnError: Bool = true, completion: Optional<(ARTErrorInfo?)->()> = nil) {
        let complete: (ARTErrorInfo?)->() = { errorInfo in
            // ARTErrorInfo to NSError
            self.error = errorInfo

            if let callback = completion {
                callback(self.error)
            }
            else if failOnError, let e = self.error {
                XCTFail("Got error '\(e)'")
            }
        }

        client.connection.on { stateChange in
            let stateChange = stateChange!
            let state = stateChange.current
            if state == .Connected {
                let channel = client.channels.get("test")
                channel.on { errorInfo in
                    switch channel.state {
                    case .Attached:
                        channel.publish(nil, data: "message") { errorInfo in
                            complete(errorInfo)
                        }
                    case .Failed:
                        complete(errorInfo)
                    default:
                        break
                    }
                }
                channel.attach()
            }
        }
    }

}

/// Rest - Publish message
func publishTestMessage(rest: ARTRest, completion: Optional<(ARTErrorInfo?)->()>) -> PublishTestMessage {
    return PublishTestMessage(client: rest, failOnError: false, completion: completion)
}

func publishTestMessage(rest: ARTRest, failOnError: Bool = true) -> PublishTestMessage {
    return PublishTestMessage(client: rest, failOnError: failOnError)
}

/// Realtime - Publish message with callback
/// (publishes if connection state changes to CONNECTED and channel state changes to ATTACHED)
func publishFirstTestMessage(realtime: ARTRealtime, completion: Optional<(ARTErrorInfo?)->()>) -> PublishTestMessage {
    return PublishTestMessage(client: realtime, failOnError: false, completion: completion)
}

/// Realtime - Publish message
/// (publishes if connection state changes to CONNECTED and channel state changes to ATTACHED)
func publishFirstTestMessage(realtime: ARTRealtime, failOnError: Bool = true) -> PublishTestMessage {
    return PublishTestMessage(client: realtime, failOnError: failOnError)
}

/// Access Token
func getTestToken(key key: String? = nil, clientId: String? = nil, capability: String? = nil, ttl: NSTimeInterval? = nil) -> String {
    if let tokenDetails = getTestTokenDetails(key: key, clientId: clientId, capability: capability, ttl: ttl) {
        return tokenDetails.token
    }
    else {
        XCTFail("TokenDetails is empty")
        return ""
    }
}

/// Access TokenDetails
func getTestTokenDetails(key key: String? = nil, clientId: String? = nil, capability: String? = nil, ttl: NSTimeInterval? = nil) -> ARTTokenDetails? {
    let options: ARTClientOptions
    if let key = key {
        options = AblyTests.clientOptions()
        options.key = key
    }
    else {
        options = AblyTests.commonAppSetup()
    }

    let client = ARTRest(options: options)

    var tokenDetails: ARTTokenDetails?
    var error: NSError?

    var tokenParams: ARTTokenParams? = nil
    if let capability = capability {
        tokenParams = ARTTokenParams()
        tokenParams!.capability = capability
    }
    if let ttl = ttl {
        if tokenParams == nil { tokenParams = ARTTokenParams() }
        tokenParams!.ttl = ttl
    }
    if let clientId = clientId {
        if tokenParams == nil { tokenParams = ARTTokenParams() }
        tokenParams!.clientId = clientId
    }

    client.auth.requestToken(tokenParams, withOptions: nil) { _tokenDetails, _error in
        tokenDetails = _tokenDetails
        error = _error
    }

    while tokenDetails == nil && error == nil {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Bool(0))
    }

    if let e = error {
        XCTFail(e.description)
    }
    return tokenDetails
}

public func delay(seconds: NSTimeInterval, closure: ()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(seconds * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

class Box<T> {
    let unbox: T
    init(_ value: T) {
        self.unbox = value
    }
}

enum Result<T> {
    case Success(Box<T>)
    case Failure(String)
    /// Constructs a success wrapping a `value`.
    init(value: Box<T>) {
        self = .Success(value)
    }
    /// Constructs a failure wrapping an `error`.
    init(error: String) {
        self = .Failure(error)
    }
}

func extractURL(request: NSMutableURLRequest?) -> Result<NSURL> {
    guard let request = request
        else { return Result(error: "No request found") }
    
    guard let url = request.URL
        else { return Result(error: "Request has no URL defined") }
    
    return Result.Success(Box(url))
}

func extractBodyAsJSON(request: NSMutableURLRequest?) -> Result<NSDictionary> {
    guard let request = request
        else { return Result(error: "No request found") }
    
    guard let bodyData = request.HTTPBody
        else { return Result(error: "No HTTPBody") }
    
    guard let json = try? NSJSONSerialization.JSONObjectWithData(bodyData, options: .MutableLeaves)
        else { return Result(error: "Invalid json") }
    
    guard let httpBody = json as? NSDictionary
        else { return Result(error: "HTTPBody has invalid format") }

    return Result.Success(Box(httpBody))
}

func extractBodyAsMsgPack(request: NSMutableURLRequest?) -> Result<NSDictionary> {
    guard let request = request
        else { return Result(error: "No request found") }

    guard let bodyData = request.HTTPBody
        else { return Result(error: "No HTTPBody") }

    let json = ARTMsgPackEncoder().decode(bodyData)

    guard let httpBody = json as? NSDictionary
        else { return Result(error: "expected dictionary, got \(json.dynamicType): \(json)") }

    return Result.Success(Box(httpBody))
}

func extractBodyAsMessages(request: NSMutableURLRequest?) -> Result<[NSDictionary]> {
    guard let request = request
        else { return Result(error: "No request found") }

    guard let bodyData = request.HTTPBody
        else { return Result(error: "No HTTPBody") }

    let json = ARTMsgPackEncoder().decode(bodyData)

    guard let httpBody = json as? NSArray
        else { return Result(error: "expected array, got \(json.dynamicType): \(json)") }

    return Result.Success(Box(httpBody.map{$0 as! NSDictionary}))
}

enum NetworkAnswer {
    case NoInternet
    case HostUnreachable
    case RequestTimeout(timeout: NSTimeInterval)
    case HostInternalError(code: Int)
    case Host400BadRequest
}

class MockHTTP: ARTHttp {

    let network: NetworkAnswer

    init(network: NetworkAnswer) {
        self.network = network
    }

    override func executeRequest(request: NSMutableURLRequest, completion callback: ((NSHTTPURLResponse?, NSData?, NSError?) -> Void)?) {
        delay(0.0) { // Delay to simulate asynchronicity.
            switch self.network {
            case .NoInternet:
                callback?(nil, nil, NSError(domain: NSURLErrorDomain, code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline.."]))
            case .HostUnreachable:
                callback?(nil, nil, NSError(domain: NSURLErrorDomain, code: -1003, userInfo: [NSLocalizedDescriptionKey: "A server with the specified hostname could not be found."]))
            case .RequestTimeout(let timeout):
                delay(timeout) {
                    callback?(nil, nil, NSError(domain: NSURLErrorDomain, code: -1001, userInfo: [NSLocalizedDescriptionKey: "The request timed out."]))
                }
            case .HostInternalError(let code):
                callback?(NSHTTPURLResponse(URL: NSURL(string: "http://ios.test.suite")!, statusCode: code, HTTPVersion: nil, headerFields: nil), nil, nil)
            case .Host400BadRequest:
                callback?(NSHTTPURLResponse(URL: NSURL(string: "http://ios.test.suite")!, statusCode: 400, HTTPVersion: nil, headerFields: nil), nil, nil)
            }
        }
    }

}

/// Records each request and response for test purpose.
class TestProxyHTTPExecutor: NSObject, ARTHTTPExecutor {

    struct ErrorSimulator {
        let value: Int
        let description: String
        let serverId = "server-test-suite"

        mutating func stubResponse(url: NSURL) -> NSHTTPURLResponse? {
            return NSHTTPURLResponse(URL: url, statusCode: 401, HTTPVersion: "HTTP/1.1", headerFields: [
                "Content-Length": String(stubData?.length ?? 0),
                "Content-Type": "application/json",
                "X-Ably-Errorcode": String(value),
                "X-Ably-Errormessage": description,
                "X-Ably-Serverid": serverId,
                ]
            )
        }

        lazy var stubData: NSData? = {
            let jsonObject = ["error": [
                    "statusCode": modf(Float(self.value)/100).0, //whole number part
                    "code": self.value,
                    "message": self.description,
                    "serverId": self.serverId,
                ]
            ]
            return try? NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions.init(rawValue: 0))
        }()
    }
    private var errorSimulator: ErrorSimulator?

    var http: ARTHttp? = ARTHttp()
    var logger: ARTLog?

    var requests: [NSMutableURLRequest] = []
    var responses: [NSHTTPURLResponse] = []

    var beforeRequest: Optional<(NSMutableURLRequest, ((NSHTTPURLResponse?, NSData?, NSError?) -> Void)?)->()> = nil
    var afterRequest: Optional<(NSMutableURLRequest, ((NSHTTPURLResponse?, NSData?, NSError?) -> Void)?)->()> = nil
    var beforeProcessingDataResponse: Optional<(NSData?)->(NSData)> = nil

    func executeRequest(request: NSMutableURLRequest, completion callback: ((NSHTTPURLResponse?, NSData?, NSError?) -> Void)?) {
        guard let http = self.http else {
            return
        }
        self.requests.append(request)

        if var simulatedError = errorSimulator, requestURL = request.URL {
            defer { errorSimulator = nil }
            callback?(simulatedError.stubResponse(requestURL), simulatedError.stubData, nil)
            return
        }

        if let performEvent = beforeRequest {
            performEvent(request, callback)
        }
        http.executeRequest(request, completion: { response, data, error in
            if let httpResponse = response {
                self.responses.append(httpResponse)
            }
            if let performEvent = self.beforeProcessingDataResponse {
                callback?(response, performEvent(data), error)
            }
            else {
                callback?(response, data, error)
            }
        })
        if let performEvent = afterRequest {
            performEvent(request, callback)
        }
    }

    func simulateIncomingServerErrorOnNextRequest(errorValue: Int, description: String) {
        errorSimulator = ErrorSimulator(value: errorValue, description: description, stubData: nil)
    }

}

/// Records each message for test purpose.
class TestProxyTransport: ARTWebSocketTransport {

    var lastUrl: NSURL?

    private(set) var protocolMessagesSent = [ARTProtocolMessage]()
    private(set) var protocolMessagesReceived = [ARTProtocolMessage]()
    private(set) var protocolMessagesSentIgnored = [ARTProtocolMessage]()

    private(set) var rawDataSent = [NSData]()
    private(set) var rawDataReceived = [NSData]()
    private var replacingAcksWithNacks: ARTErrorInfo?
    private var ignoreWebSocket = false
    
    var beforeProcessingSentMessage: Optional<(ARTProtocolMessage)->()> = nil
    var beforeProcessingReceivedMessage: Optional<(ARTProtocolMessage)->()> = nil
    var afterProcessingReceivedMessage: Optional<(ARTProtocolMessage)->()> = nil

    var actionsIgnored = [ARTProtocolMessageAction]()
    var ignoreSends = false

    static var network: NetworkAnswer? = nil
    static var networkConnectEvent: Optional<(NSURL)->()> = nil

    override func connect() {
        if let network = TestProxyTransport.network {
            var hook: AspectToken?
            hook = SRWebSocket.testSuite_replaceClassMethod(#selector(SRWebSocket.open)) {
                if TestProxyTransport.network == nil {
                    return
                }
                func performConnectError(secondsForDelay: NSTimeInterval, error: ARTRealtimeTransportError) {
                    delay(secondsForDelay) {
                        self.delegate?.realtimeTransportFailed(self, withError: error)
                        hook?.remove()
                    }
                }
                let error = NSError.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "TestProxyTransport error"])
                switch network {
                case .NoInternet, .HostUnreachable:
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, type: .HostUnreachable, url: self.lastUrl!))
                case .RequestTimeout(let timeout):
                    performConnectError(0.1 + timeout, error: ARTRealtimeTransportError.init(error: error, type: .Timeout, url: self.lastUrl!))
                case .HostInternalError(let code):
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, badResponseCode: code, url: self.lastUrl!))
                case .Host400BadRequest:
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, badResponseCode: 400, url: self.lastUrl!))
                }
            }
        }
        super.connect()

        if let performNetworkConnect = TestProxyTransport.networkConnectEvent {
            func perform() {
                if let lastUrl = self.lastUrl {
                    performNetworkConnect(lastUrl)
                } else {
                    delay(0.1) { perform() }
                }
            }
            perform()
        }
    }

    override func setupWebSocket(params: [NSURLQueryItem], withOptions options: ARTClientOptions, resumeKey: String?, connectionSerial: NSNumber?) -> NSURL {
        let url = super.setupWebSocket(params, withOptions: options, resumeKey: resumeKey, connectionSerial: connectionSerial)
        lastUrl = url
        return url
    }

    override func send(msg: ARTProtocolMessage) {
        if ignoreSends {
            protocolMessagesSentIgnored.append(msg)
            return
        }
        protocolMessagesSent.append(msg)
        if let performEvent = beforeProcessingSentMessage {
            performEvent(msg)
        }
        super.send(msg)
    }

    override func sendWithData(data: NSData) {
        rawDataSent.append(data)
        super.sendWithData(data)
    }

    override func receive(msg: ARTProtocolMessage) {
        if msg.action == .Ack {
            if let error = replacingAcksWithNacks {
                msg.action = .Nack
                msg.error = error
            }
        }
        protocolMessagesReceived.append(msg)
        if actionsIgnored.contains(msg.action) {
            return
        }
        if let performEvent = beforeProcessingReceivedMessage {
            performEvent(msg)
        }
        super.receive(msg)
        if let performEvent = afterProcessingReceivedMessage {
            performEvent(msg)
        }
    }

    override func receiveWithData(data: NSData) {
        rawDataReceived.append(data)
        super.receiveWithData(data)
    }

    func replaceAcksWithNacks(error: ARTErrorInfo, block: (() -> ()) -> ()) {
        replacingAcksWithNacks = error
        block({ self.replacingAcksWithNacks = nil })
    }

    func simulateTransportSuccess() {
        self.ignoreWebSocket = true
        let msg = ARTProtocolMessage()
        msg.action = .Connected
        msg.connectionId = "x-xxxxxxxx"
        msg.connectionKey = "xxxxxxx-xxxxxxxxxxxxxx-xxxxxxxx"
        msg.connectionSerial = -1
        msg.connectionDetails = ARTConnectionDetails(clientId: nil, connectionKey: "a8c10!t-3D0O4ejwTdvLkl-b33a8c10", maxMessageSize: 16384, maxFrameSize: 262144, maxInboundRate: 250, connectionStateTtl: 60, serverId: "testServerId")
        super.receive(msg)
    }

    override func webSocketDidOpen(webSocket: SRWebSocket) {
        if !ignoreWebSocket {
            super.webSocketDidOpen(webSocket)
        }
    }

    override func webSocket(webSocket: SRWebSocket, didFailWithError error: NSError) {
        if !ignoreWebSocket {
            super.webSocket(webSocket, didFailWithError: error)
        }
    }

    override func webSocket(webSocket: SRWebSocket, didReceiveMessage message: AnyObject?) {
        if !ignoreWebSocket {
            super.webSocket(webSocket, didReceiveMessage: message)
        }
    }

    override func webSocket(webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String, wasClean: Bool) {
        if !ignoreWebSocket {
            super.webSocket(webSocket, didCloseWithCode: code, reason: reason, wasClean: wasClean)
        }
    }
}


// MARK: - Extensions

extension SequenceType where Generator.Element: NSData {

    var toMsgPackArray: [AnyObject] {
        return map({ ARTMsgPackEncoder().decode($0) })
    }
    
}

func + <K,V> (left: Dictionary<K,V>, right: Dictionary<K,V>?) -> Dictionary<K,V> {
    guard let right = right else { return left }
    return left.reduce(right) {
        var new = $0 as [K:V]
        new.updateValue($1.1, forKey: $1.0)
        return new
    }
}

func += <K,V> (inout left: Dictionary<K,V>, right: Dictionary<K,V>?) {
    guard let right = right else { return }
    right.forEach { key, value in
        left.updateValue(value, forKey: key)
    }
}

extension ARTMessage {

    public override func isEqual(object: AnyObject?) -> Bool {
        if let other = object as? ARTMessage {
            return self.name == other.name &&
                self.encoding == other.encoding &&
                self.data as! NSObject == other.data as! NSObject
        }

        return super.isEqual(object)
    }

}

extension NSObject {

    var toBase64: String {
        return (try? NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions(rawValue: 0)).base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))) ?? ""
    }

}

extension NSData {

    override var toBase64: String {
        return self.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }

    var toUTF8String: String {
        return NSString(data: self, encoding: NSUTF8StringEncoding) as! String
    }
    
}

extension JSON {

    var asArray: NSArray? {
        return object as? NSArray
    }

    var asDictionary: NSDictionary? {
        return object as? NSDictionary
    }

}


extension NSDate: Comparable { }

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return (lhs.compare(rhs) == .OrderedSame)
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return (lhs.compare(rhs) == .OrderedAscending)
}

public func >(lhs: NSDate, rhs: NSDate) -> Bool {
    return (lhs.compare(rhs) == .OrderedDescending)
}

public func <=(lhs: NSDate, rhs: NSDate) -> Bool {
    return (lhs < rhs || lhs == rhs)
}

public func >=(lhs: NSDate, rhs: NSDate) -> Bool {
    return (lhs > rhs || lhs == rhs)
}

extension NSRegularExpression {

    class func match(value: String?, pattern: String) -> Bool {
        guard let value = value else {
            return false
        }
        let options = NSRegularExpressionOptions()
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        let range = NSMakeRange(0, value.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        return regex.rangeOfFirstMatchInString(value, options: [], range: range).location != NSNotFound
    }

    class func extract(value: String?, pattern: String) -> String? {
        guard let value = value else {
            return nil
        }
        let options = NSRegularExpressionOptions()
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        let range = NSMakeRange(0, value.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let result = regex.firstMatchInString(value, options: [], range: range)
        guard let textRange = result?.rangeAtIndex(0) else { return nil }
        let convertedRange =  value.startIndex.advancedBy(textRange.location)..<value.startIndex.advancedBy(textRange.location+textRange.length)
        return value.substringWithRange(convertedRange)
    }

}

extension String {

    func replace(value: String, withString string: String) -> String {
        return self.stringByReplacingOccurrencesOfString(value, withString: string, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }

}

extension ARTRealtime {

    func simulateLostConnectionAndState() {
        //1. Abruptly disconnect
        //2. Change the `Connection#id` and `Connection#key` before the client
        //   library attempts to reconnect and resume the connection
        self.connection.setId("lost")
        self.connection.setKey("xxxxx!xxxxxxx-xxxxxxxx-xxxxxxxx")
        self.onDisconnected()
    }

    func simulateSuspended() {
        waitUntil(timeout: testTimeout) { done in
            self.connection.on(.Closed) { _ in
                self.onSuspended()
                done()
            }
            self.close()
        }
    }

    func dispose() {
        let names = self.channels.map({ $0.name })
        for name in names {
            self.channels.release(name)
        }
        self.connection.off()
    }

}

extension ARTWebSocketTransport {

    func simulateIncomingNormalClose() {
        let CLOSE_NORMAL = 1000
        self.closing = true
        let webSocketDelegate = self as SRWebSocketDelegate
        webSocketDelegate.webSocket!(nil, didCloseWithCode: CLOSE_NORMAL, reason: "", wasClean: true)
    }

    func simulateIncomingAbruptlyClose() {
        let CLOSE_ABNORMAL = 1006
        let webSocketDelegate = self as SRWebSocketDelegate
        webSocketDelegate.webSocket!(nil, didCloseWithCode: CLOSE_ABNORMAL, reason: "connection was closed abnormally", wasClean: false)
    }

    func simulateIncomingError() {
        let error = NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:"Fail test"])
        let webSocketDelegate = self as SRWebSocketDelegate
        webSocketDelegate.webSocket!(nil, didFailWithError: error)
    }
}

extension ARTAuth {

    func testSuite_forceTokenToExpire(file: StaticString = #file, line: UInt = #line) {
        guard let tokenDetails = self.tokenDetails else {
            XCTFail("TokenDetails is nil", file: file, line: line)
            return
        }
        self.setTokenDetails(ARTTokenDetails(
            token: tokenDetails.token,
            expires: NSDate().dateByAddingTimeInterval(-1.0),
            issued: NSDate().dateByAddingTimeInterval(-1.0),
            capability: tokenDetails.capability,
            clientId: tokenDetails.clientId
            )
        )
    }

}

extension ARTRealtimeConnectionState : CustomStringConvertible {
    public var description : String {
        return ARTRealtimeStateToStr(self)
    }
}

extension ARTProtocolMessageAction : CustomStringConvertible {
    public var description : String {
        return ARTRealtime.protocolStr(self)
    }
}

extension ARTRealtimeChannelState : CustomStringConvertible {
    public var description : String {
        switch self {
        case .Initialized:
            return "Initialized"
        case .Attaching:
            return "Attaching"
        case .Attached:
            return "Attached"
        case .Detaching:
            return "Detaching"
        case .Detached:
            return "Detached"
        case .Failed:
            return "Failed"
        }
    }
}

// MARK: - Custom Nimble Matchers

/// A Nimble matcher that succeeds when two dates are quite the same.
public func beCloseTo<T: NSDate>(expectedValue: NSDate?) -> MatcherFunc<T?> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "equal <\(expectedValue)>"
        guard let actualValue = try actualExpression.evaluate() as? NSDate else { return false }
        guard let expectedValue = expectedValue else { return false }
        return abs(actualValue.timeIntervalSince1970 - expectedValue.timeIntervalSince1970) < 0.5
    }
}

/// A Nimble matcher that succeeds when a param exists.
public func haveParam(key: String, withValue expectedValue: String) -> NonNilMatcherFunc<String> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "param <\(key)=\(expectedValue)> exists"
        guard let actualValue = try actualExpression.evaluate() else { return false }
        let queryItems = actualValue.componentsSeparatedByString("&")
        for item in queryItems {
            let param = item.componentsSeparatedByString("=")
            if let currentKey = param.first, let currentValue = param.last where currentKey == key && currentValue == expectedValue {
                return true
            }
        }
        return false
    }
}

/// A Nimble matcher that succeeds when all Keys from a Dictionary are valid.
public func allKeysPass<U: CollectionType where U: DictionaryLiteralConvertible, U.Generator.Element == (U.Key, U.Value)> (passFunc: (U.Key) -> Bool) -> NonNilMatcherFunc<U> {

    let elementEvaluator: (Expression<U.Generator.Element>, FailureMessage) throws -> Bool = {
        expression, failureMessage in
        failureMessage.postfixMessage = "pass a condition"
        let value = try expression.evaluate()!
        return passFunc(value.0)
    }

    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.actualValue = nil
        if let actualValue = try actualExpression.evaluate() {
            for item in actualValue {
                let exp = Expression(expression: { item }, location: actualExpression.location)
                if try !elementEvaluator(exp, failureMessage) {
                    failureMessage.postfixMessage =
                        "all \(failureMessage.postfixMessage),"
                        + " but failed first at element <\(item.0)>"
                        + " in <\(actualValue.map({ $0.0 }))>"
                    return false
                }
            }
            failureMessage.postfixMessage = "all \(failureMessage.postfixMessage)"
        } else {
            failureMessage.postfixMessage = "all pass (use beNil() to match nils)"
            return false
        }

        return true
    }
}

/// A Nimble matcher that succeeds when all Values from a Dictionary are valid.
public func allValuesPass<U: CollectionType where U: DictionaryLiteralConvertible, U.Generator.Element == (U.Key, U.Value)> (passFunc: (U.Value) -> Bool) -> NonNilMatcherFunc<U> {

    let elementEvaluator: (Expression<U.Generator.Element>, FailureMessage) throws -> Bool = {
        expression, failureMessage in
        failureMessage.postfixMessage = "pass a condition"
        let value = try expression.evaluate()!
        return passFunc(value.1)
    }

    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.actualValue = nil
        if let actualValue = try actualExpression.evaluate() {
            for item in actualValue {
                let exp = Expression(expression: { item }, location: actualExpression.location)
                if try !elementEvaluator(exp, failureMessage) {
                    failureMessage.postfixMessage =
                        "all \(failureMessage.postfixMessage),"
                        + " but failed first at element <\(item.1)>"
                        + " in <\(actualValue.map({ $0.1 }))>"
                    return false
                }
            }
            failureMessage.postfixMessage = "all \(failureMessage.postfixMessage)"
        } else {
            failureMessage.postfixMessage = "all pass (use beNil() to match nils)"
            return false
        }

        return true
    }
}

// http://stackoverflow.com/a/26502285/818420
extension String {

    /// Create `NSData` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `NSData` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.

    func dataFromHexadecimalString() -> NSData? {
        let data = NSMutableData(capacity: characters.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .CaseInsensitive)
        regex.enumerateMatchesInString(self, options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substringWithRange(match!.range)
            var num = UInt8(byteString, radix: 16)
            data?.appendBytes(&num, length: 1)
        }

        return data
    }
}

@objc class TestReachability : NSObject, ARTReachability {
    var host: String?
    var callback: ((Bool) -> Void)?

    required init(logger: ARTLog) {}

    func listenForHost(host: String, callback: (Bool) -> Void) {
        self.host = host
        self.callback = callback
    }

    func off() {
        self.host = nil
        self.callback = nil
    }

    func simulate(reachable reachable: Bool) {
        self.callback!(reachable)
    }
}
