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

    class var jsonRestOptions: ARTClientOptions {
        get {
            let options = ARTClientOptions()
            options.environment = "sandbox"
            options.binary = false
            return options
        }
    }

    class func setupOptions(options: ARTClientOptions, debug: Bool = false) -> ARTClientOptions {
        var responseError: NSError?
        var responseData: NSData?

        var requestCompleted = false

        let request = NSMutableURLRequest(URL: NSURL(string: "https://\(options.restHost):\(options.restPort)/apps")!)
        request.HTTPMethod = "POST"
        request.HTTPBody = try? appSetupJson["post_apps"].rawData()

        request.allHTTPHeaderFields = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]

        NSURLSession.sharedSession()
            .dataTaskWithRequest(request) { data, response, error in
                responseError = error
                responseData = data
                requestCompleted = true
            }.resume()

        while !requestCompleted {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Bool(0))
        }

        if let error = responseError {
            XCTFail(error.localizedDescription)
        } else if let data = responseData {
            let response = JSON(data: data)
            
            if debug {
                print(response)
                options.logLevel = .Verbose
            }
            
            let key = response["keys"][0]

            options.key = key["keyStr"].stringValue
            
            return options
        }
        
        return options
    }
    
    class func commonAppSetup() -> ARTClientOptions {
        return AblyTests.setupOptions(AblyTests.jsonRestOptions)
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
    var error: NSError?
    
    init(client: ARTRest, failOnError: Bool) {
        self.error = NSError(domain: "", code: -1, userInfo: nil)
        
        client.channels.get("test").publish("message") { error in
            self.error = error
            if failOnError {
                XCTFail("Got error '\(error)'")
            }
        }
    }
}

/// Publish message
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
 Records each request for test purpose.
 */
@objc
class MockHTTPExecutor: NSObject, ARTHTTPExecutor {
    // Who executes the request
    private let executor = ARTHttp()
    
    var logger: ARTLog?
    
    var requests: [NSMutableURLRequest] = []
    
    func executeRequest(request: NSMutableURLRequest!, callback: ((NSHTTPURLResponse!, NSData!, NSError!) -> Void)!) {
        self.requests.append(request)
        self.executor.executeRequest(request, callback: callback)
    }    
}
