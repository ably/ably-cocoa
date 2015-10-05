//
//  RestClient.swift
//  ably
//
//  Created by Yavor Georgiev on 2.08.15.
//  Copyright © 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import ably
import ably.Private

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

func publishTestMessage(client: ARTRest, failOnError: Bool = true) -> PublishTestMessage {
    return PublishTestMessage(client: client, failOnError: failOnError)
}

func getTestToken() -> String {
    let options = AblyTests.commonAppSetup()
    options.useTokenAuth = true
    let client = ARTRest(options: options)

    var token: String?
    client.auth.requestToken(nil, withOptions: nil) { tokenDetails, error in
        token = tokenDetails?.token
        return
    }

    while token == nil {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Boolean(0))
    }

    return token!
}

class RestClient: QuickSpec {
    override func spec() {
        describe("RestClient") {
            // RSC1
            context("initializer") {
                it("should accept an API key") {
                    let options = AblyTests.commonAppSetup()
                    
                    let client = ARTRest(key: options.key!)
                    client.baseUrl = options.restUrl()

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.error).toEventually(beNil(), timeout: testTimeout)
                }

                it("should throw when provided an invalid key") {
                    expect{ ARTRest(key: "invalid_key") }.to(raiseException())
                }

                it("should result in error status when provided a bad key") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(key: "bad")

                    let publishTask = publishTestMessage(client, failOnError: false)

                    expect(publishTask.error?.domain).toEventually(equal(ARTAblyErrorDomain), timeout: testTimeout)
                    expect(publishTask.error?.code).toEventually(equal(40005))
                }

                it("should accept an options object") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.error).toEventually(beNil(), timeout: testTimeout)
                }

                it("should accept an options object with token authentication") {
                    let options = AblyTests.commonAppSetup()
                    options.token = getTestToken()
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.error).toEventually(beNil(), timeout: testTimeout)
                }

                it("should result in error status when provided a bad token") {
                    let options = AblyTests.commonAppSetup()
                    options.useTokenAuth = true
                    options.token = "invalid_token"
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client, failOnError: false)

                    expect(publishTask.error?.domain).toEventually(equal(ARTAblyErrorDomain), timeout: testTimeout)
                    expect(publishTask.error?.code).toEventually(equal(40005), timeout: testTimeout)
                }
            }

            context("logging") {
                // RSC2
                it("should output to the system log and the log level should be Warn") {
                    let logTime = NSDate()
                    let client = ARTRest(options: AblyTests.commonAppSetup())

                    client.logger.log("This is a warning", withLevel: .Warn)
                    let logs = querySyslog(forLogsAfter: logTime)

                    expect(client.logger.logLevel).to(equal(ARTLogLevel.Warn))
                    expect(logs).to(contain("WARN: This is a warning"))
                }

                // RSC3
                it("should have a mutable log level") {
                    let logTime = NSDate()
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    client.logger.logLevel = .Error

                    client.logger.log("This is a warning", withLevel: .Warn)
                    let logs = querySyslog(forLogsAfter: logTime)

                    expect(logs).toNot(contain("WARN: This is a warning"))
                }

                // RSC4
                it("should accept a custom logger") {
                    struct Log {
                        static var interceptedLog: (String, ARTLogLevel) = ("", .None)
                    }
                    class MyLogger : ARTLog {
                        override func log(message: String, withLevel level: ARTLogLevel) {
                            Log.interceptedLog = (message, level)
                        }
                    }

                    let options = AblyTests.commonAppSetup()
                    let customLogger = MyLogger()
                    customLogger.logLevel = .Verbose
                    let client = ARTRest(logger: customLogger, andOptions: options)

                    client.logger.log("This is a warning", withLevel: .Warn)
                    
                    expect(Log.interceptedLog.0).to(equal("This is a warning"))
                    expect(Log.interceptedLog.1).to(equal(ARTLogLevel.Warn))
                    
                    expect(client.logger.logLevel).to(equal(customLogger.logLevel))
                }
            }

            // RSC11
            context("endpoint") {
                var mockExecutor: MockHTTPExecutor!
                beforeEach {
                    mockExecutor = MockHTTPExecutor()
                }
                
                it("should accept an options object with a host set") {
                    let options = ARTClientOptions(key: "fake:key")
                    options.environment = "fake"
                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    publishTestMessage(client, failOnError: false)
                    
                    expect(mockExecutor.requests.first?.URL?.host).toEventually(equal("fake.ably.host"), timeout: testTimeout)
                }
                
                it("should accept an options object with an environment set") {
                    let options = ARTClientOptions(key: "fake:key")
                    options.environment = "myEnvironment"
                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    publishTestMessage(client, failOnError: false)
                    
                    expect(mockExecutor.requests.first?.URL?.host).toEventually(equal("myEnvironment-rest.ably.io"), timeout: testTimeout)
                }
                
                it("should default to https://rest.ably.io") {
                    let options = ARTClientOptions(key: "fake:key")
                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    publishTestMessage(client, failOnError: false)
                    
                    expect(mockExecutor.requests.first?.URL?.absoluteString).toEventually(beginWith("https://rest.ably.io"), timeout: testTimeout)
                }
                
                it("should connect over plain http:// when tls is off") {
                    let options = ARTClientOptions(key: "fake:key")
                    options.tls = false;
                    let client = ARTRest(options: options)
                    client.httpExecutor = mockExecutor
                    
                    publishTestMessage(client, failOnError: false)
                    
                    expect(mockExecutor.requests.first?.URL?.scheme).toEventually(equal("http"), timeout: testTimeout)
                }
            }

            // RSC5
            it("should provide access to the AuthOptions object passed in ClientOptions") {
                let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                let client = ARTRest(options: options)
                
                let authOptions = client.auth.options
                
                expect(authOptions).to(beIdenticalTo(options))
            }
            
            // RSC16
            context("time") {
                it("should return server time") {
                    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
                    let client = ARTRest(options: options)
                    
                    var time: NSDate?
                    
                    client.time({ date, error in
                        time = date
                    })
                    
                    expect(time?.timeIntervalSince1970).toEventually(beCloseTo(NSDate().timeIntervalSince1970, within: 60), timeout: testTimeout)
                }
            }
        }
    }
}