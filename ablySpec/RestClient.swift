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

            // RSC7, RSC18
            it("should send requests over http and https") {
                let mockExecutor = MockHTTPExecutor()
                let options = AblyTests.commonAppSetup()

                let clientHttps = ARTRest(options: options)
                clientHttps.httpExecutor = mockExecutor

                options.clientId = "client_http"
                options.tls = false
                let clientHttp = ARTRest(options: options)
                clientHttp.httpExecutor = mockExecutor

                publishTestMessage(clientHttps)
                publishTestMessage(clientHttp)

                if let requestUrlA = mockExecutor.requests.first?.URL,
                   let requestUrlB = mockExecutor.requests.last?.URL {
                    expect(requestUrlA.scheme).to(equal("https"))
                    expect(requestUrlB.scheme).to(equal("http"))
                }
            }

            // RSC9
            it("should use Auth to manage authentication") {
                let options = AblyTests.commonAppSetup()
                let auth = ARTAuth(ARTRest(options: options), withOptions: options)

                expect(auth.method.rawValue).to(equal(ARTAuthMethod.Basic.rawValue))

                auth.requestToken(nil, withOptions: options, callback: { tokenDetailsA, errorA in
                    if let e = errorA {
                        XCTFail(e.description)
                    }
                    options.token = tokenDetailsA?.token ?? ""

                    auth.authorise(nil, options: options, force: false, callback: { tokenDetailsB, errorB in
                        if let e = errorB {
                            XCTFail(e.description)
                        }
                        // Use the same token because it is valid
                        expect(options.token).to(equal(tokenDetailsB?.token ?? ""))
                    })
                })
            }

        } //RestClient
    }
}