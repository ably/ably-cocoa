//
//  TestUtilities.swift
//  ably
//
//  Created by Yavor Georgiev on 2.08.15.
//  Copyright © 2015 г. Ably. All rights reserved.
//


import Foundation
import XCTest
import SwiftyJSON
import ably
import Quick

class Configuration : QuickConfiguration {
    override class func configure(configuration: Quick.Configuration!) {
        configuration.beforeEach {
            ARTClientOptions.getDefaultRestHost("sandbox-rest.ably.io", modify: true)
        }
    }
}

func pathForTestResource(resourcePath: String) -> String {
    let testBundle = NSBundle(forClass: AblyTests.self)
    return testBundle.pathForResource(resourcePath, ofType: "")!
}

let appSetupJson = JSON(data: NSData(contentsOfFile: pathForTestResource("ably-common/test-resources/test-app-setup.json"))!, options: .MutableContainers)

let restHost = "sandbox-rest.ably.io"

let testTimeout: NSTimeInterval = 30

class AblyTests {

    class var jsonRestOptions: ARTClientOptions {
        get {
            let options = ARTClientOptions()
            options.restHost = restHost
            options.binary = false
            return options
        }
    }

    class func setupOptions(options: ARTClientOptions) -> ARTClientOptions {
        var responseError: NSError?
        var responseData: NSData?

        var requestCompleted = false

        let request = NSMutableURLRequest(URL: NSURL(string: "https://\(options.restHost):\(options.restPort)/apps")!)
        request.HTTPMethod = "POST"
        request.HTTPBody = appSetupJson["post_apps"].rawData()

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
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Boolean(0))
        }

        if let error = responseError {
            XCTFail(error.localizedDescription)
        } else if let data = responseData {
            let response = JSON(data: data)
            let key = response["keys"][0]
            let appId = response["appId"]
            let id = key["id"]

            let appOptions = options.clone()
            appOptions.authOptions.keyName = "\(appId).\(id)"
            appOptions.authOptions.keySecret = key["value"].stringValue
            appOptions.authOptions.capability = key["capability"].stringValue
            return appOptions
        }
        
        return options
    }
}

func querySyslog(forLogsAfter startingTime: NSDate? = nil) -> GeneratorOf<String> {
    let query = asl_new(UInt32(ASL_TYPE_QUERY))
    asl_set_query(query, ASL_KEY_SENDER, NSProcessInfo.processInfo().processName, UInt32(ASL_QUERY_OP_EQUAL))
    if let date = startingTime {
        asl_set_query(query, ASL_KEY_TIME, "\(date.timeIntervalSince1970)", UInt32(ASL_QUERY_OP_GREATER_EQUAL))
    }

    let response = asl_search(nil, query)
    return GeneratorOf<String> {
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