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
    var status: ARTStatus?

    init(client: ARTRest, failOnError: Bool) {
        client.channel("test").publish("message") { status in
            self.status = status
            if failOnError && status.status != .StatusOk {
                XCTFail("Got status \(status.status.rawValue) with error '\(status.errorInfo?.message)'")
            }
        }
    }
}

func publishTestMessage(client: ARTRest, failOnError: Bool = true) -> PublishTestMessage {
    return PublishTestMessage(client: client, failOnError: failOnError)
}

func getTestToken() -> String {
    let options = AblyTests.commonAppSetup()
    options.authOptions.useTokenAuth = true
    options.authOptions.clientId = "testToken"
    let client = ARTRest(options: options)

    var token: String?
    client.auth().requestToken() { tokenDetails in
        token = tokenDetails.token
        return nil
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
                    let client = ARTRest(key: "\(options.authOptions.keyName):\(options.authOptions.keySecret)")

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusOk), timeout: testTimeout)
                }

                it("should throw when provided an invalid key") {
                    expect{ ARTRest(key: "invalid_key") }.to(raiseException())
                }

                it("should result in error status when provided a bad key") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(key: "badName:\(options.authOptions.keySecret)")

                    let publishTask = publishTestMessage(client, failOnError: false)

                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusError), timeout: testTimeout)
                    expect(publishTask.status?.errorInfo.code).toEventually(equal(40005))
                }

                it("should accept an options object") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusOk), timeout: testTimeout)
                }

                it("should accept an options object with token authentication") {
                    let options = AblyTests.commonAppSetup()
                    options.authOptions.useTokenAuth = true
                    options.authOptions.token = getTestToken()
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client)

                    expect(client.auth().getAuthMethod()).to(equal(ARTAuthMethod.Token))
                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusOk), timeout: testTimeout)
                }

                it("should result in error status when provided a bad token") {
                    let options = AblyTests.commonAppSetup()
                    options.authOptions.useTokenAuth = true
                    options.authOptions.token = "invalid_token"
                    let client = ARTRest(options: options)

                    let publishTask = publishTestMessage(client, failOnError: false)

                    expect(client.auth().getAuthMethod()).to(equal(ARTAuthMethod.Token))
                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusError), timeout: testTimeout)
                    expect(publishTask.status?.errorInfo.code).toEventually(equal(40005))
                }
            }

            context("logging") {
                // RSC2
                it("should output to the system log and the log level should be Warn") {
                    let logTime = NSDate()
                    let client = ARTRest(options: AblyTests.commonAppSetup())

                    client.logger.warn("This is a warning")
                    let logs = querySyslog(forLogsAfter: logTime)

                    expect(client.logger.logLevel).to(equal(ARTLogLevel.Warn))
                    expect(logs).to(contain("WARN: This is a warning"))
                }

                // RSC3
                it("should have a mutable log level") {
                    let logTime = NSDate()
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    client.logger.logLevel = .Error

                    client.logger.warn("This is a warning")
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

                    client.logger.warn("This is a warning")

                    expect(Log.interceptedLog.0).to(equal("This is a warning"))
                    expect(Log.interceptedLog.1).to(equal(ARTLogLevel.Warn))
                }
            }

            // RSC11
            context("endpoint") {
                it("should accept an options object with an environment set") {
                    let options = AblyTests.commonAppSetup()
                    let newOptions = ARTClientOptions()
                    newOptions.authOptions.keyName = options.authOptions.keyName
                    newOptions.authOptions.keySecret = options.authOptions.keySecret
                    newOptions.environment = "sandbox"
                    let client = ARTRest(options: newOptions)

                    let publishTask = publishTestMessage(client)

                    expect(publishTask.status?.status).toEventually(equal(ARTState.StatusOk), timeout: testTimeout)
                }
            }

            // RSC5
            it("should provide access to the AuthOptions object passed in ClientOptions") {
                let options = AblyTests.commonAppSetup()
                let client = ARTRest(options: options)
                
                let authOptions = client.auth().getAuthOptions()

                expect(authOptions).to(beIdenticalTo(options.authOptions))
            }

            // RSC16
            context("time") {
                it("should return server time") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)

                    var time: NSDate?
                    client.time({ (status, date) in
                        time = date
                    })

                    expect(time?.timeIntervalSince1970).toEventually(beCloseTo(NSDate().timeIntervalSince1970, within: 60), timeout: testTimeout)
                }
            }
        }
    }
}