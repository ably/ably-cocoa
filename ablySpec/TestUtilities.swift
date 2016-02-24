//
//  TestUtilities.swift
//  ably
//
//  Created by Yavor Georgiev on 2.08.15.
//  Copyright © 2015 г. Ably. All rights reserved.
//

import Foundation
import XCTest
import Quick
import Nimble
import SwiftyJSON
import SwiftWebSocket

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
            options.useBinaryProtocol = false
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

    class func setupOptions(options: ARTClientOptions, debug: Bool = false) -> ARTClientOptions {
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
        } else if let data = responseData {
            let response = JSON(data: data)
            
            if debug {
                options.logLevel = .Verbose
                print(response)
            }
            
            let key = response["keys"][0]

            options.key = key["keyStr"].stringValue
            
            return options
        }
        
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

func querySyslog(forLogsAfter startingTime: NSDate? = nil) -> AnyGenerator<String> {
    let query = asl_new(UInt32(ASL_TYPE_QUERY))
    asl_set_query(query, ASL_KEY_SENDER, NSProcessInfo.processInfo().processName, UInt32(ASL_QUERY_OP_EQUAL))
    if let date = startingTime {
        asl_set_query(query, ASL_KEY_TIME, "\(date.timeIntervalSince1970)", UInt32(ASL_QUERY_OP_GREATER_EQUAL))
    }

    let response = asl_search(nil, query)
    return anyGenerator {
        let entry = asl_next(response)
        if entry != nil {
            return String.fromCString(asl_get(entry, ASL_KEY_MSG))
        } else {
            asl_free(response)
            asl_free(query)
            return nil
        }
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
func getTestToken(key key: String? = nil, capability: String? = nil, ttl: NSTimeInterval? = nil) -> String {
    if let tokenDetails = getTestTokenDetails(key: key, capability: capability, ttl: ttl) {
        return tokenDetails.token
    }
    else {
        XCTFail("TokenDetails is empty")
        return ""
    }
}

/// Access TokenDetails
func getTestTokenDetails(key key: String? = nil, capability: String? = nil, ttl: NSTimeInterval? = nil) -> ARTTokenDetails? {
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

/// Records each request and response for test purpose.
@objc
class MockHTTPExecutor: NSObject, ARTHTTPExecutor {
    // Who executes the request
    private let executor = ARTHttp()
    
    var logger: ARTLog?
    
    var requests: [NSMutableURLRequest] = []
    var responses: [NSHTTPURLResponse] = []

    func executeRequest(request: NSMutableURLRequest, completion callback: ARTHttpRequestCallback?) {
        self.requests.append(request)
        self.executor.executeRequest(request, completion: { response, data, error in
            if let httpResponse = response {
                self.responses.append(httpResponse)
            }
            callback?(response, data, error)
        })
    }
}

/// Records each message for test purpose.
class TestProxyTransport: ARTWebSocketTransport {

    var lastUrl: NSURL?

    private(set) var protocolMessagesSent = [ARTProtocolMessage]()
    private(set) var protocolMessagesReceived = [ARTProtocolMessage]()

    private(set) var rawDataSent = [NSData]()
    private(set) var rawDataReceived = [NSData]()
    
    var beforeProcessingSentMessage: Optional<(ARTProtocolMessage)->()> = nil
    var beforeProcessingReceivedMessage: Optional<(ARTProtocolMessage)->()> = nil

    var actionsIgnored = [ARTProtocolMessageAction]()

    override func setupWebSocket(params: [NSURLQueryItem], withOptions options: ARTClientOptions, resumeKey: String?, connectionSerial: NSNumber?) -> NSURL {
        let url = super.setupWebSocket(params, withOptions: options, resumeKey: resumeKey, connectionSerial: connectionSerial)
        lastUrl = url
        return url
    }

    override func send(msg: ARTProtocolMessage) {
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
        protocolMessagesReceived.append(msg)
        if actionsIgnored.contains(msg.action) {
            return
        }
        if let performEvent = beforeProcessingReceivedMessage {
            performEvent(msg)
        }
        super.receive(msg)
    }

    override func receiveWithData(data: NSData) {
        rawDataReceived.append(data)
        super.receiveWithData(data)
    }

}


// MARK: - Extensions

extension SequenceType where Generator.Element: NSData {

    var toJSONArray: [AnyObject] {
        return map({ try! NSJSONSerialization.JSONObjectWithData($0, options: NSJSONReadingOptions(rawValue: 0)) })
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

extension ARTRealtime {

    func simulateLostConnection() {
        //1. Abruptly disconnect
        //2. Change the `Connection#id` and `Connection#key` before the client
        //   library attempts to reconnect and resume the connection
        self.connection.setId("lost")
        self.connection.setKey("xxxxx!xxxxxxx-xxxxxxxx-xxxxxxxx")
        self.onDisconnected()
    }

    func dispose() {
        let names = self.channels.map({ $0.name })
        for name in names {
            self.channels.release(name)
        }
        self.resetEventEmitter()
    }

}

extension ARTWebSocketTransport {

    func simulateIncomingNormalClose() {
        let CLOSE_NORMAL = 1000
        self.closing = true
        let webSocketDelegate = self as! WebSocketDelegate
        webSocketDelegate.webSocketClose(CLOSE_NORMAL, reason: "", wasClean: true)
    }

    func simulateIncomingAbruptlyClose() {
        let CLOSE_ABNORMAL = 1006
        let webSocketDelegate = self as! WebSocketDelegate
        webSocketDelegate.webSocketClose(CLOSE_ABNORMAL, reason: "connection was closed abnormally", wasClean: false)
    }

    func simulateIncomingError() {
        let error = NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:"Fail test"])
        let webSocketDelegate = self as! WebSocketDelegate
        webSocketDelegate.webSocketError(error)
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
