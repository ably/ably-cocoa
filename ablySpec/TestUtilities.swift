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
import SwiftyJSON

import ably
import ably.Private

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

let appSetupJson = JSON(data: NSData(contentsOfFile: pathForTestResource("ably-common/test-resources/test-app-setup.json"))!, options: .MutableContainers)

let testTimeout: NSTimeInterval = 30

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
            options.binary = false
            return options
        }
    }

    class var authTokenCases: [String: (ARTAuthOptions) -> ()] {
        get { return [
            "useTokenAuth": { $0.useTokenAuth = true; $0.key = "fake:key" },
            "clientId": { $0.clientId = "client"; $0.key = "fake:key" },
            "authUrl": { $0.authUrl = NSURL(string: "http://test.com") },
            "authCallback": { $0.authCallback = { _, _ in return } },
            "tokenDetails": { $0.tokenDetails = ARTAuthTokenDetails(token: "token") },
            "token": { $0.token = "token" },
            "key": { $0.tokenDetails = ARTAuthTokenDetails(token: "token"); $0.key = "fake:key" }
            ]
        }
    }

    class func setupOptions(options: ARTClientOptions, debug: Bool = false) -> ARTClientOptions {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://\(options.restHost):\(options.restPort)/apps")!)
        request.HTTPMethod = "POST"
        request.HTTPBody = try? appSetupJson["post_apps"].rawData()

        request.allHTTPHeaderFields = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]

        let (responseData, responseError, _) = NSURLSessionSelfSignedCertificateSync().get(request)

        if let error = responseError {
            XCTFail(error.localizedDescription)
        } else if let data = responseData {
            let response = JSON(data: data)
            
            if debug {
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

    class func clientOptions(debug debug: Bool = false) -> ARTClientOptions {
        let options = ARTClientOptions()
        options.environment = "sandbox"
        if debug {
            options.logLevel = .Verbose
        }
        return options
    }
    
}

class NSURLSessionSelfSignedCertificateSync: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {

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
        if let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: serverTrust))
        }
        else {
            XCTFail("No self-signed certificate")
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

/// Publish message class
class PublishTestMessage {

    var completion: Optional<(NSError?)->()>
    var error: NSError? = NSError(domain: "", code: -1, userInfo: nil)

    convenience init(client: ARTRest, failOnError: Bool) {
        self.init(client: client, completion: nil)
    }

    init(client: ARTRest, completion: Optional<(NSError?)->()>) {
        client.channels.get("test").publish("message") { error in
            self.error = error
            if let callback = completion {
                callback(error)
            }
            else if let e = error {
                XCTFail("Got error '\(e)'")
            }
        }
    }

}

/// Publish message
func publishTestMessage(client: ARTRest, completion: Optional<(NSError?)->()>) -> PublishTestMessage {
    return PublishTestMessage(client: client, completion: completion)
}

func publishTestMessage(client: ARTRest, failOnError: Bool = true) -> PublishTestMessage {
    return PublishTestMessage(client: client, failOnError: failOnError)
}

/// Access Token
func getTestToken() -> String {
    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
    let client = ARTRest(options: options)
    
    var token: String?
    var error: NSError?
    
    client.auth.requestToken(nil, withOptions: nil) { tokenDetails, _error in
        token = tokenDetails?.token
        error = _error
    }
    
    while token == nil && error == nil {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Bool(0))
    }
    
    if let e = error {
        XCTFail(e.description)
    }
    return token ?? ""
}

public func delay(seconds: NSTimeInterval, closure: ()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(seconds * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

// TODO: after merge use robrix/Box
class Box<T> {
    let unbox: T
    init(_ value: T) {
        self.unbox = value
    }
}

// TODO: after merge use antitypical/Result
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

/*
 Records each request and response for test purpose.
 */
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

/*
 Records each message for test purpose.
*/
class MockTransport: ARTWebSocketTransport {

    var lastUrl: NSURL?

    override func setupWebSocket(params: [NSURLQueryItem], withOptions options: ARTClientOptions) -> NSURL {
        let url = super.setupWebSocket(params, withOptions: options)
        lastUrl = url
        return url
    }

}
