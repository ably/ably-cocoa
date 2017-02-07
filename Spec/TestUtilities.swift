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
    override class func configure(_ configuration: Quick.Configuration!) {
        configuration.beforeSuite {
            AsyncDefaults.Timeout = testTimeout
        }
    }
}

func pathForTestResource(_ resourcePath: String) -> String {
    let testBundle = Bundle(for: AblyTests.self)
    return testBundle.path(forResource: resourcePath, ofType: "")!
}

let appSetupJson = JSON(parseJSON: try! String(contentsOfFile: pathForTestResource(testResourcesPath + "test-app-setup.json")))

let testTimeout: TimeInterval = 10.0
let testResourcesPath = "ably-common/test-resources/"

/// Common test utilities.
class AblyTests {

    class func base64ToData(_ base64: String) -> Data {
        return Data(base64Encoded: base64, options: NSData.Base64DecodingOptions(rawValue: 0))!
    }

    class func msgpackToJSON(_ data: NSData) -> JSON {
        let decoded = try! ARTMsgPackEncoder().decode(data as Data)
        let encoded = try! ARTJsonEncoder().encode(decoded)
        return JSON(data: encoded)
    }

    class func checkError(_ errorInfo: ARTErrorInfo?, withAlternative message: String) {
        if let error = errorInfo {
            XCTFail("\((error ).code): \(error.message)")
        }
        else if !message.isEmpty {
            XCTFail(message)
        }
    }

    class func checkError(_ errorInfo: ARTErrorInfo?) {
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
            "authUrl": { $0.authUrl = URL(string: "http://test.com") },
            "authCallback": { $0.authCallback = { _, _ in return } },
            "tokenDetails": { $0.tokenDetails = ARTTokenDetails(token: "token") },
            "token": { $0.token = "token" },
            "key": { $0.tokenDetails = ARTTokenDetails(token: "token"); $0.key = "fake:key" }
            ]
        }
    }

    static var testApplication: JSON?
    static fileprivate var setupOptionsCounter = 0

    static var queue = DispatchQueue(label: "io.ably.tests", qos: .userInitiated)
    static var userQueue = DispatchQueue(label: "io.ably.tests.callbacks", qos: .userInitiated)
    static var extraQueue = DispatchQueue(label: "io.ably.tests.extra", qos: .userInitiated)

    class func setupOptions(_ options: ARTClientOptions, forceNewApp: Bool = false, debug: Bool = false) -> ARTClientOptions {
        ARTChannels_getChannelNamePrefix = { "test-\(setupOptionsCounter)" }
        setupOptionsCounter += 1

        if forceNewApp {
            testApplication = nil
        }

        guard let app = testApplication else {
            let request = NSMutableURLRequest(url: URL(string: "https://\(options.restHost):\(options.tlsPort)/apps")!)
            request.httpMethod = "POST"
            request.httpBody = try? appSetupJson["post_apps"].rawData()

            request.allHTTPHeaderFields = [
                "Accept" : "application/json",
                "Content-Type" : "application/json"
            ]

            let (responseData, responseError, _) = NSURLSessionServerTrustSync().get(request)

            if let error = responseError {
                fatalError(error.localizedDescription)
            }

            testApplication = JSON(data: responseData!)
            
            if debug {
                options.logLevel = .verbose
                print(testApplication!)
            }

            return setupOptions(options, debug: debug)
        }
        
        let key = app["keys"][0]
        options.key = key["keyStr"].stringValue
        options.dispatchQueue = userQueue
        options.internalDispatchQueue = queue
        return options
    }
    
    class func commonAppSetup(_ debug: Bool = false) -> ARTClientOptions {
        return AblyTests.setupOptions(AblyTests.jsonRestOptions, debug: debug)
    }

    class func clientOptions(_ debug: Bool = false, key: String? = nil, requestToken: Bool = false) -> ARTClientOptions {
        let options = ARTClientOptions()
        options.environment = "sandbox"
        options.logExceptionReportingUrl = nil
        if debug {
            options.logLevel = .debug
        }
        if let key = key {
            options.key = key
        }
        if requestToken {
            options.token = getTestToken()
        }
        options.dispatchQueue = userQueue
        options.internalDispatchQueue = queue
        return options
    }

    class func newErrorProtocolMessage() -> ARTProtocolMessage {
        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .error
        protocolMessage.error = ARTErrorInfo.create(withCode: 0, message: "Fail test")
        return protocolMessage
    }

    class func newPresenceProtocolMessage(_ channel: String, action: ARTPresenceAction, clientId: String) -> ARTProtocolMessage {
        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .presence
        protocolMessage.channel = channel
        protocolMessage.timestamp = Date()
        let presenceMessage = ARTPresenceMessage()
        presenceMessage.action = action
        presenceMessage.clientId = clientId
        presenceMessage.timestamp = Date()
        protocolMessage.presence = [presenceMessage]
        return protocolMessage
    }

    class func newRealtime(_ options: ARTClientOptions) -> ARTRealtime {
        let autoConnect = options.autoConnect
        options.autoConnect = false
        let realtime = ARTRealtime(options: options)
        realtime.setTransport(TestProxyTransport.self)
        realtime.setReachabilityClass(TestReachability.self)
        if autoConnect {
            options.autoConnect = true
            realtime.connect()
        }
        return realtime
    }

    class func newRandomString() -> String {
        return ProcessInfo.processInfo.globallyUniqueString
    }

    class func addMembersSequentiallyToChannel(_ channelName: String, members: Int = 1, startFrom: Int = 1, data: AnyObject? = nil, options: ARTClientOptions, done: @escaping ()->()) -> ARTRealtime {
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

        return client
    }

    class func splitDone(_ howMany: Int, file: StaticString = #file, line: UInt = #line, done: @escaping () -> Void) -> (() -> Void) {
        var left = howMany
        return {
            left -= 1
            if left == 0 {
                done()
            } else if left < 0 {
                XCTFail("splitDone called more than the expected \(howMany) times", file: file, line: line)
            }
        }
    }

    class func waitFor<T>(timeout: TimeInterval, file: FileString = #file, line: UInt = #line, f: @escaping (@escaping (T?) -> Void) -> Void) -> T? {
        var value: T?
        waitUntil(timeout: timeout, file: file, line: line) { done in
            f() { v in
                value = v
                done()
            }
        }
        return value
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

    class func loadCryptoTestData(_ file: String) -> (key: Data, iv: Data, items: [CryptoTestItem]) {
        let json = JSON(parseJSON: try! String(contentsOfFile: pathForTestResource(file)))

        let keyData = Data(base64Encoded: json["key"].stringValue, options: Data.Base64DecodingOptions(rawValue: 0))!
        let ivData = Data(base64Encoded: json["iv"].stringValue, options: Data.Base64DecodingOptions(rawValue: 0))!
        let items = json["items"].map{ $0.1 }.map(CryptoTestItem.init)
        
        return (keyData, ivData, items)
    }

    class func loadCryptoTestData(_ crypto: CryptoTest) -> (key: Data, iv: Data, items: [CryptoTestItem]) {
        return loadCryptoTestData(testResourcesPath + crypto.rawValue + ".json")
    }

}

class NSURLSessionServerTrustSync: NSObject, URLSessionDelegate, URLSessionTaskDelegate {

    func get(_ request: NSMutableURLRequest) -> (Data?, NSError?, HTTPURLResponse?) {
        var responseError: NSError?
        var responseData: Data?
        var httpResponse: HTTPURLResponse?;
        var requestCompleted = false

        let configuration = URLSessionConfiguration.default
        let session = Foundation.URLSession(configuration:configuration, delegate:self, delegateQueue:OperationQueue.main)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            if let response = response as? HTTPURLResponse {
                responseData = data
                responseError = error as NSError?
                httpResponse = response
            }
            else if let error = error {
                responseError = error as NSError?
            }
            requestCompleted = true
        }) 
        task.resume()

        while !requestCompleted {
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, CFTimeInterval(0.1), Bool(0))
        }

        return (responseData, responseError, httpResponse)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Try to extract the server certificate for trust validation
        if let serverTrust = challenge.protectionSpace.serverTrust {
            // Server trust authentication
            // Reference: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/AuthenticationChallenges.html
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: serverTrust))
        }
        else {
            challenge.sender?.performDefaultHandling?(for: challenge)
            XCTFail("Current authentication: \(challenge.protectionSpace.authenticationMethod)")
        }
    }

}

extension Date {
    func isBefore(_ other: Date) -> Bool {
        return self.compare(other) == ComparisonResult.orderedAscending
    }
}

// MARK: ARTAuthOptions Equatable

func ==(lhs: ARTAuthOptions, rhs: ARTAuthOptions) -> Bool {
    return lhs.token == rhs.token &&
        lhs.authMethod == rhs.authMethod &&
        lhs.authUrl == rhs.authUrl &&
        lhs.key == rhs.key
}

func ==(lhs: ARTJsonCompatible?, rhs: ARTJsonCompatible?) -> Bool {
    guard let lhs = lhs else {
        return rhs == nil
    }
    guard let rhs = rhs else {
        return false
    }
    do {
        return NSDictionary(dictionary: try lhs.toJSON()).isEqual(to: try rhs.toJSON())
    } catch {
        return false
    }
}

// MARK: Publish message class

class PublishTestMessage {

    var completion: Optional<(ARTErrorInfo?)->()>
    var error: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))

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
            if state == .connected {
                let channel = client.channels.get("test")
                channel.on { stateChange in
                    switch stateChange!.current {
                    case .attached:
                        channel.publish(nil, data: "message") { errorInfo in
                            complete(errorInfo)
                        }
                    case .failed:
                        complete(stateChange!.reason)
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
@discardableResult func publishTestMessage(_ rest: ARTRest, completion: Optional<(ARTErrorInfo?)->()>) -> PublishTestMessage {
    return PublishTestMessage(client: rest, failOnError: false, completion: completion)
}

@discardableResult func publishTestMessage(_ rest: ARTRest, failOnError: Bool = true) -> PublishTestMessage {
    return PublishTestMessage(client: rest, failOnError: failOnError)
}

/// Realtime - Publish message with callback
/// (publishes if connection state changes to CONNECTED and channel state changes to ATTACHED)
@discardableResult func publishFirstTestMessage(_ realtime: ARTRealtime, completion: Optional<(ARTErrorInfo?)->()>) -> PublishTestMessage {
    return PublishTestMessage(client: realtime, failOnError: false, completion: completion)
}

/// Realtime - Publish message
/// (publishes if connection state changes to CONNECTED and channel state changes to ATTACHED)
@discardableResult func publishFirstTestMessage(_ realtime: ARTRealtime, failOnError: Bool = true) -> PublishTestMessage {
    return PublishTestMessage(client: realtime, failOnError: failOnError)
}

/// Access Token
func getTestToken(key: String? = nil, clientId: String? = nil, capability: String? = nil, ttl: TimeInterval? = nil, file: FileString = #file, line: UInt = #line) -> String {
    return getTestTokenDetails(key: key, clientId: clientId, capability: capability, ttl: ttl, file: file, line: line)?.token ?? ""
}

func getTestToken(key: String? = nil, clientId: String? = nil, capability: String? = nil, ttl: TimeInterval? = nil, file: FileString = #file, line: UInt = #line, completion: @escaping (String) -> Void) {
    getTestTokenDetails(key: key, clientId: clientId, capability: capability, ttl: ttl) { tokenDetails, error in
        if let e = error {
            fail(e.localizedDescription, file: file, line: line)
        }
        completion(tokenDetails?.token ?? "")
    }
}

/// Access TokenDetails
func getTestTokenDetails(key: String? = nil, clientId: String? = nil, capability: String? = nil, ttl: TimeInterval? = nil, completion: @escaping (ARTTokenDetails?, Error?) -> Void) {
    let options: ARTClientOptions
    if let key = key {
        options = AblyTests.clientOptions()
        options.key = key
    }
    else {
        options = AblyTests.commonAppSetup()
    }

    let client = ARTRest(options: options)

    var tokenParams: ARTTokenParams? = nil
    if let capability = capability {
        tokenParams = ARTTokenParams()
        tokenParams!.capability = capability
    }
    if let ttl = ttl {
        if tokenParams == nil { tokenParams = ARTTokenParams() }
        tokenParams!.ttl = NSNumber(value: ttl)
    }
    if let clientId = clientId {
        if tokenParams == nil { tokenParams = ARTTokenParams() }
        tokenParams!.clientId = clientId
    }

    client.auth.requestToken(tokenParams, with: nil) { details, error in
        _ = client // Hold reference to client, since requestToken is async and will lose it.
        completion(details, error)
    }
}

func getTestTokenDetails(key: String? = nil, clientId: String? = nil, capability: String? = nil, ttl: TimeInterval? = nil, file: FileString = #file, line: UInt = #line) -> ARTTokenDetails? {
    guard let (tokenDetails, error) = (AblyTests.waitFor(timeout: testTimeout, file: file, line: line) { value in
        getTestTokenDetails(key: key, clientId: clientId, capability: capability, ttl: ttl) { tokenDetails, error in
            value((tokenDetails, error))
        }
    }) else {
        return nil
    }

    if let e = error {
        fail(e.localizedDescription, file: file, line: line)
    }
    return tokenDetails
}

public func delay(_ seconds: TimeInterval, closure: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

class Box<T> {
    let unbox: T
    init(_ value: T) {
        self.unbox = value
    }
}

enum Result<T> {
    case success(Box<T>)
    case failure(String)
    /// Constructs a success wrapping a `value`.
    init(value: Box<T>) {
        self = .success(value)
    }
    /// Constructs a failure wrapping an `error`.
    init(error: String) {
        self = .failure(error)
    }
}

func extractURL(_ request: URLRequest?) -> Result<URL> {
    guard let request = request
        else { return Result(error: "No request found") }
    
    guard let url = request.url
        else { return Result(error: "Request has no URL defined") }
    
    return Result.success(Box(url))
}

func extractBodyAsJSON(_ request: URLRequest?) -> Result<NSDictionary> {
    guard let request = request
        else { return Result(error: "No request found") }
    
    guard let bodyData = request.httpBody
        else { return Result(error: "No HTTPBody") }
    
    guard let json = try? JSONSerialization.jsonObject(with: bodyData, options: .mutableLeaves)
        else { return Result(error: "Invalid json") }
    
    guard let httpBody = json as? NSDictionary
        else { return Result(error: "HTTPBody has invalid format") }

    return Result.success(Box(httpBody))
}

func extractBodyAsMsgPack(_ request: URLRequest?) -> Result<NSDictionary> {
    guard let request = request
        else { return Result(error: "No request found") }

    guard let bodyData = request.httpBody
        else { return Result(error: "No HTTPBody") }

    let json = try! ARTMsgPackEncoder().decode(bodyData)

    guard let httpBody = json as? NSDictionary
        else { return Result(error: "expected dictionary, got \(type(of: (json) as AnyObject)): \(json)") }

    return Result.success(Box(httpBody))
}

func extractBodyAsMessages(_ request: URLRequest?) -> Result<[NSDictionary]> {
    guard let request = request
        else { return Result(error: "No request found") }

    guard let bodyData = request.httpBody
        else { return Result(error: "No HTTPBody") }

    let json = try! ARTMsgPackEncoder().decode(bodyData)

    guard let httpBody = json as? NSArray
        else { return Result(error: "expected array, got \(type(of: (json) as AnyObject)): \(json)") }

    return Result.success(Box(httpBody.map{$0 as! NSDictionary}))
}

enum NetworkAnswer {
    case noInternet
    case hostUnreachable
    case requestTimeout(timeout: TimeInterval)
    case hostInternalError(code: Int)
    case host400BadRequest
}

class MockHTTP: ARTHttp {

    let network: NetworkAnswer

    init(network: NetworkAnswer, logger: ARTLog) {
        self.network = network
        super.init(AblyTests.queue, logger: logger)
    }

    override public func execute(_ request: URLRequest, completion callback: ((HTTPURLResponse?, Data?, Error?) -> Void)? = nil) {
        delay(0.0) { // Delay to simulate asynchronicity.
            switch self.network {
            case .noInternet:
                callback?(nil, nil, NSError(domain: NSURLErrorDomain, code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline.."]))
            case .hostUnreachable:
                callback?(nil, nil, NSError(domain: NSURLErrorDomain, code: -1003, userInfo: [NSLocalizedDescriptionKey: "A server with the specified hostname could not be found."]))
            case .requestTimeout(let timeout):
                delay(timeout) {
                    callback?(nil, nil, NSError(domain: NSURLErrorDomain, code: -1001, userInfo: [NSLocalizedDescriptionKey: "The request timed out."]))
                }
            case .hostInternalError(let code):
                callback?(HTTPURLResponse(url: URL(string: "http://ios.test.suite")!, statusCode: code, httpVersion: nil, headerFields: nil), nil, nil)
            case .host400BadRequest:
                callback?(HTTPURLResponse(url: URL(string: "http://ios.test.suite")!, statusCode: 400, httpVersion: nil, headerFields: nil), nil, nil)
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
        var statusCode: Int = 401

        mutating func stubResponse(_ url: URL) -> HTTPURLResponse? {
            return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [
                "Content-Length": String(stubData?.count ?? 0),
                "Content-Type": "application/json",
                "X-Ably-Errorcode": String(value),
                "X-Ably-Errormessage": description,
                "X-Ably-Serverid": serverId,
                ]
            )
        }

        lazy var stubData: Data? = {
            let jsonObject = ["error": [
                    "statusCode": modf(Float(self.value)/100).0, //whole number part
                    "code": self.value,
                    "message": self.description,
                    "serverId": self.serverId,
                ]
            ]
            return try? JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.init(rawValue: 0))
        }()
    }
    fileprivate var errorSimulator: ErrorSimulator?

    var http: ARTHttp!
    var _logger: ARTLog!
    
    init(_ logger: ARTLog) {
        self._logger = logger
        self.http = ARTHttp(AblyTests.queue, logger: _logger)
    }
    
    func logger() -> ARTLog {
        return self._logger
    }

    var requests: [URLRequest] = []
    var responses: [HTTPURLResponse] = []

    var beforeRequest: Optional<(URLRequest, ((HTTPURLResponse?, Data?, NSError?) -> Void)?)->()> = nil
    var afterRequest: Optional<(URLRequest, ((HTTPURLResponse?, Data?, NSError?) -> Void)?)->()> = nil
    var beforeProcessingDataResponse: Optional<(Data?)->(Data)> = nil

    public func execute(_ request: URLRequest, completion callback: ((HTTPURLResponse?, Data?, Error?) -> Void)? = nil) {
        guard let http = self.http else {
            return
        }
        self.requests.append(request)

        if var simulatedError = errorSimulator, var requestURL = request.url {
            defer { errorSimulator = nil }
            callback?(simulatedError.stubResponse(requestURL), simulatedError.stubData, nil)
            return
        }

        if let performEvent = beforeRequest {
            performEvent(request, callback)
        }
        http.execute(request, completion: { response, data, error in
            if let httpResponse = response {
                self.responses.append(httpResponse)
            }
            if let performEvent = self.beforeProcessingDataResponse {
                callback?(response, performEvent(data), error as NSError?)
            }
            else {
                callback?(response, data, error as NSError?)
            }
        })
        if let performEvent = afterRequest {
            performEvent(request, callback)
        }
    }

    func simulateIncomingServerErrorOnNextRequest(_ errorValue: Int, description: String) {
        errorSimulator = ErrorSimulator(value: errorValue, description: description, statusCode: 401, stubData: nil)
    }

    func simulateIncomingPayloadOnNextRequest(_ data: Data) {
        errorSimulator = ErrorSimulator(value: 0, description: "", statusCode: 200, stubData: data)
    }

}

/// Records each message for test purpose.
class TestProxyTransport: ARTWebSocketTransport {

    var lastUrl: URL?

    fileprivate(set) var protocolMessagesSent = [ARTProtocolMessage]()
    fileprivate(set) var protocolMessagesReceived = [ARTProtocolMessage]()
    fileprivate(set) var protocolMessagesSentIgnored = [ARTProtocolMessage]()

    fileprivate(set) var rawDataSent = [Data]()
    fileprivate(set) var rawDataReceived = [Data]()
    fileprivate var replacingAcksWithNacks: ARTErrorInfo?
    fileprivate var ignoreWebSocket = false
    
    var beforeProcessingSentMessage: Optional<(ARTProtocolMessage)->()> = nil
    var beforeProcessingReceivedMessage: Optional<(ARTProtocolMessage)->()> = nil
    var afterProcessingReceivedMessage: Optional<(ARTProtocolMessage)->()> = nil

    var actionsIgnored = [ARTProtocolMessageAction]()
    var ignoreSends = false

    static var network: NetworkAnswer? = nil
    static var networkConnectEvent: Optional<(ARTRealtimeTransport, URL)->()> = nil

    override func connect(withKey key: String) {
        if let network = TestProxyTransport.network {
            var hook: AspectToken?
            hook = SRWebSocket.testSuite_replaceClassMethod(#selector(SRWebSocket.open)) {
                if TestProxyTransport.network == nil {
                    return
                }
                func performConnectError(_ secondsForDelay: TimeInterval, error: ARTRealtimeTransportError) {
                    delay(secondsForDelay) {
                        self.delegate?.realtimeTransportFailed(self, withError: error)
                        hook?.remove()
                    }
                }
                let error = NSError.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "TestProxyTransport error"])
                switch network {
                case .noInternet, .hostUnreachable:
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, type: .hostUnreachable, url: self.lastUrl!))
                case .requestTimeout(let timeout):
                    performConnectError(0.1 + timeout, error: ARTRealtimeTransportError.init(error: error, type: .timeout, url: self.lastUrl!))
                case .hostInternalError(let code):
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, badResponseCode: code, url: self.lastUrl!))
                case .host400BadRequest:
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, badResponseCode: 400, url: self.lastUrl!))
                }
            }
        }
        super.connect(withKey: key)

        if let performNetworkConnect = TestProxyTransport.networkConnectEvent {
            func perform() {
                if let lastUrl = self.lastUrl {
                    performNetworkConnect(self, lastUrl)
                } else {
                    delay(0.1) { perform() }
                }
            }
            perform()
        }
    }

    override func connect(withToken token: String) {
        if let network = TestProxyTransport.network {
            var hook: AspectToken?
            hook = SRWebSocket.testSuite_replaceClassMethod(#selector(SRWebSocket.open)) {
                if TestProxyTransport.network == nil {
                    return
                }
                func performConnectError(_ secondsForDelay: TimeInterval, error: ARTRealtimeTransportError) {
                    delay(secondsForDelay) {
                        self.delegate?.realtimeTransportFailed(self, withError: error)
                        hook?.remove()
                    }
                }
                let error = NSError.init(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "TestProxyTransport error"])
                switch network {
                case .noInternet, .hostUnreachable:
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, type: .hostUnreachable, url: self.lastUrl!))
                case .requestTimeout(let timeout):
                    performConnectError(0.1 + timeout, error: ARTRealtimeTransportError.init(error: error, type: .timeout, url: self.lastUrl!))
                case .hostInternalError(let code):
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, badResponseCode: code, url: self.lastUrl!))
                case .host400BadRequest:
                    performConnectError(0.1, error: ARTRealtimeTransportError.init(error: error, badResponseCode: 400, url: self.lastUrl!))
                }
            }
        }
        super.connect(withToken: token)

        if let performNetworkConnect = TestProxyTransport.networkConnectEvent {
            func perform() {
                if let lastUrl = self.lastUrl {
                    performNetworkConnect(self, lastUrl)
                } else {
                    delay(0.1) { perform() }
                }
            }
            perform()
        }
    }

    override func setupWebSocket(_ params: [URLQueryItem], with options: ARTClientOptions, resumeKey: String?, connectionSerial: NSNumber?) -> URL {
        let url = super.setupWebSocket(params, with: options, resumeKey: resumeKey, connectionSerial: connectionSerial)
        lastUrl = url
        return url
    }

    func send(_ message: ARTProtocolMessage) {
        let data = try! encoder.encode(message)
        send(data, withSource: message)
    }

    override func send(_ data: Data, withSource decodedObject: Any?) {
        if let msg = decodedObject as? ARTProtocolMessage {
            if ignoreSends {
                protocolMessagesSentIgnored.append(msg)
                return
            }
            protocolMessagesSent.append(msg)
            if let performEvent = beforeProcessingSentMessage {
                performEvent(msg)
            }
        }
        rawDataSent.append(data)
        super.send(data, withSource: decodedObject)
    }

    override func receive(_ msg: ARTProtocolMessage) {
        if msg.action == .ack || msg.action == .presence {
            if let error = replacingAcksWithNacks {
                msg.action = .nack
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

    override func receive(with data: Data) -> ARTProtocolMessage? {
        rawDataReceived.append(data)
        return super.receive(with: data)
    }

    func replaceAcksWithNacks(_ error: ARTErrorInfo, block: (_ doneReplacing: @escaping () -> Void) -> Void) {
        replacingAcksWithNacks = error
        block({ self.replacingAcksWithNacks = nil })
    }

    func simulateTransportSuccess() {
        self.ignoreWebSocket = true
        let msg = ARTProtocolMessage()
        msg.action = .connected
        msg.connectionId = "x-xxxxxxxx"
        msg.connectionKey = "xxxxxxx-xxxxxxxxxxxxxx-xxxxxxxx"
        msg.connectionSerial = -1
        msg.connectionDetails = ARTConnectionDetails(clientId: nil, connectionKey: "a8c10!t-3D0O4ejwTdvLkl-b33a8c10", maxMessageSize: 16384, maxFrameSize: 262144, maxInboundRate: 250, connectionStateTtl: 60, serverId: "testServerId")
        super.receive(msg)
    }

    override func webSocketDidOpen(_ webSocket: SRWebSocket) {
        if !ignoreWebSocket {
            super.webSocketDidOpen(webSocket)
        }
    }

    override func webSocket(_ webSocket: SRWebSocket, didFailWithError error: Error) {
        if !ignoreWebSocket {
            super.webSocket(webSocket, didFailWithError: error)
        }
    }

    override func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any?) {
        if !ignoreWebSocket {
            super.webSocket(webSocket, didReceiveMessage: message)
        }
    }

    override func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String, wasClean: Bool) {
        if !ignoreWebSocket {
            super.webSocket(webSocket, didCloseWithCode: code, reason: reason, wasClean: wasClean)
        }
    }
}


// MARK: - Extensions

extension Sequence where Iterator.Element == Data {

    func toMsgPackArray<T>() -> [T] {
        let msgPackEncoder = ARTMsgPackEncoder()
        return map({ try! msgPackEncoder.decode($0) as! T })
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

func += <K,V> (left: inout Dictionary<K,V>, right: Dictionary<K,V>?) {
    guard let right = right else { return }
    right.forEach { key, value in
        left.updateValue(value, forKey: key)
    }
}

extension ARTMessage {

    open override func isEqual(_ object: Any?) -> Bool {
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
        return (try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions(rawValue: 0)).base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))) ?? ""
    }

}

extension Data {

    var toBase64: String {
        return self.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    var toUTF8String: String {
        return NSString(data: self, encoding: String.Encoding.utf8.rawValue)! as String
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

extension NSRegularExpression {

    class func match(_ value: String?, pattern: String) -> Bool {
        guard let value = value else {
            return false
        }
        let options = NSRegularExpression.Options()
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        let range = NSMakeRange(0, value.lengthOfBytes(using: String.Encoding.utf8))
        return regex.rangeOfFirstMatch(in: value, options: [], range: range).location != NSNotFound
    }

    class func extract(_ value: String?, pattern: String) -> String? {
        guard let value = value else {
            return nil
        }
        let options = NSRegularExpression.Options()
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        let range = NSMakeRange(0, value.lengthOfBytes(using: String.Encoding.utf8))
        let result = regex.firstMatch(in: value, options: [], range: range)
        guard let textRange = result?.rangeAt(0) else { return nil }
        let convertedRange =  value.characters.index(value.startIndex, offsetBy: textRange.location)..<value.characters.index(value.startIndex, offsetBy: textRange.location+textRange.length)
        return value.substring(with: convertedRange)
    }

}

extension String {

    func replace(_ value: String, withString string: String) -> String {
        return self.replacingOccurrences(of: value, with: string, options: NSString.CompareOptions.literal, range: nil)
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

    func simulateSuspended(beforeSuspension beforeSuspensionCallback: @escaping (_ done: @escaping () -> ()) -> Void) {
        waitUntil(timeout: testTimeout) { done in
            self.connection.once(.disconnected) { _ in
                beforeSuspensionCallback(done)
                self.onSuspended()
            }
            self.onDisconnected()
        }
    }

    func dispose() {
        let names = self.channels.map({ ($0 as! ARTRealtimeChannel).name })
        for name in names {
            self.channels.release(name)
        }
        self.connection.off()
    }

}

extension ARTWebSocketTransport {

    func simulateIncomingNormalClose() {
        let CLOSE_NORMAL = 1000
        self.setState(ARTRealtimeTransportState.closing)
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

    func testSuite_forceTokenToExpire(_ file: StaticString = #file, line: UInt = #line) {
        guard let tokenDetails = self.tokenDetails else {
            XCTFail("TokenDetails is nil", file: file, line: line)
            return
        }
        self.setTokenDetails(ARTTokenDetails(
            token: tokenDetails.token,
            expires: Date().addingTimeInterval(-1.0),
            issued: Date().addingTimeInterval(-1.0),
            capability: tokenDetails.capability,
            clientId: tokenDetails.clientId
            )
        )
    }

}

extension ARTPresenceMessage {

    convenience init(clientId: String, action: ARTPresenceAction, connectionId: String, id: String, timestamp: Date = Date()) {
        self.init()
        self.action = action
        self.clientId = clientId
        self.connectionId = connectionId
        self.id = id
        self.timestamp = timestamp
    }

}

extension ARTRealtimeConnectionState : CustomStringConvertible {
    public var description : String {
        return ARTRealtimeConnectionStateToStr(self)
    }
}

extension ARTRealtimeConnectionEvent : CustomStringConvertible {
    public var description : String {
        return ARTRealtimeConnectionEventToStr(self)
    }
}

extension ARTProtocolMessageAction : CustomStringConvertible {
    public var description : String {
        return ARTProtocolMessageActionToStr(self)
    }
}

extension ARTRealtimeChannelState : CustomStringConvertible {
    public var description : String {
        return ARTRealtimeChannelStateToStr(self)
    }
}

extension ARTChannelEvent : CustomStringConvertible {
    public var description : String {
        return ARTChannelEventToStr(self)
    }
}

extension ARTPresenceAction : CustomStringConvertible {
    public var description : String {
        return ARTPresenceActionToStr(self)
    }
}

// MARK: - Custom Nimble Matchers

/// A Nimble matcher that succeeds when two dates are quite the same.
public func beCloseTo(_ expectedValue: Date) -> Predicate<Date> {
    return Predicate.fromDeprecatedClosure { actualExpression, failureMessage in
        failureMessage.postfixMessage = "equal <\(expectedValue)>"
        guard let actualValue = try actualExpression.evaluate() else { return false }
        return abs(actualValue.timeIntervalSince1970 - expectedValue.timeIntervalSince1970) < 0.5
    }
}

/// A Nimble matcher that succeeds when a param exists.
public func haveParam(_ key: String, withValue expectedValue: String) -> Predicate<String> {
    return Predicate.fromDeprecatedClosure { actualExpression, failureMessage in
        failureMessage.postfixMessage = "param <\(key)=\(expectedValue)> exists"
        guard let actualValue = try actualExpression.evaluate() else { return false }
        let queryItems = actualValue.components(separatedBy: "&")
        for item in queryItems {
            let param = item.components(separatedBy: "=")
            if let currentKey = param.first, let currentValue = param.last, currentKey == key && currentValue == expectedValue {
                return true
            }
        }
        return false
    }
}

/// A Nimble matcher that succeeds when all Keys from a Dictionary are valid.
public func allKeysPass<U: Collection> (_ passFunc: @escaping (U.Key) -> Bool) -> Predicate<U> where U: ExpressibleByDictionaryLiteral, U.Iterator.Element == (U.Key, U.Value) {

    let elementEvaluator: (Expression<U.Generator.Element>, FailureMessage) throws -> Bool = {
        expression, failureMessage in
        failureMessage.postfixMessage = "pass a condition"
        let value = try expression.evaluate()!
        return passFunc(value.0)
    }

    return Predicate.fromDeprecatedClosure { actualExpression, failureMessage in
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
public func allValuesPass<U: Collection> (_ passFunc: @escaping (U.Value) -> Bool) -> Predicate<U> where U: ExpressibleByDictionaryLiteral, U.Iterator.Element == (U.Key, U.Value) {

    let elementEvaluator: (Expression<U.Generator.Element>, FailureMessage) throws -> Bool = {
        expression, failureMessage in
        failureMessage.postfixMessage = "pass a condition"
        let value = try expression.evaluate()!
        return passFunc(value.1)
    }

    return Predicate.fromDeprecatedClosure { actualExpression, failureMessage in
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

    func dataFromHexadecimalString() -> Data? {
        let data = NSMutableData(capacity: characters.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)
            data?.append(&num, length: 1)
        }

        return data as Data?
    }
}

@objc class TestReachability : NSObject, ARTReachability {
    var host: String?
    var callback: ((Bool) -> Void)?
    var queue: DispatchQueue

    required init(logger: ARTLog, queue: DispatchQueue) {
        self.queue = queue
    }

    func listen(forHost host: String, callback: @escaping (Bool) -> Void) {
        self.host = host
        self.callback = callback
    }

    func off() {
        self.host = nil
        self.callback = nil
    }

    func simulate(_ reachable: Bool) {
        self.queue.async {
            self.callback!(reachable)
        }
    }
}
