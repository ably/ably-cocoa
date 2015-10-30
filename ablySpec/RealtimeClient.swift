//
//  RealtimeClient.swift
//  ably
//
//  Created by Ricardo Pereira on 26/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

import Quick
import Nimble

@testable import ably
@testable import ably.Private

class RealtimeClient: QuickSpec {

    func checkError(errorInfo: ARTErrorInfo?, withAlternative message: String) {
        if let error = errorInfo {
            XCTFail("\(error.code): \(error.message)")
        }
        else if !message.isEmpty {
            XCTFail(message)
        }
    }

    func checkError(errorInfo: ARTErrorInfo?) {
        checkError(errorInfo, withAlternative: "")
    }

    override func spec() {
        describe("RealtimeClient") {
            // RTC1
            context("options") {
                it("should support the same options as the Rest client") {
                    let options = AblyTests.commonAppSetup() //Same as Rest
                    options.clientId = "client_string"

                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: 20.0) { done in
                        client.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Connecting:
                                break
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            default:
                                expect(state).to(equal(ARTRealtimeConnectionState.Connected))
                                done()
                                break
                            }
                        }
                    }
                }
                
                //RTC1a
                it("should echoMessages option be true by default") {
                    let options = ARTClientOptions()
                    expect(options.echoMessages) == true
                }
                
                //RTC1b
                it("should autoConnect option be true by default") {
                    let options = ARTClientOptions()
                    expect(options.autoConnect) == true
                }

                //RTC1c
                it("should attempt to recover the connection state if recover string is assigned") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    options.environment = "eu-central-1-a-sandbox"

                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: 60) { done in
                        client.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                self.checkError(errorInfo)
                                expect(client.recoveryKey()).to(equal("\(client.connectionKey()):\(client.connectionSerial())"), description: "recoveryKey wrong formed")
                                options.recover = client.recoveryKey()
                                done()
                            default:
                                break
                            }
                        }
                    }

                    // New connection
                    let newClient = ARTRealtime(options: options)

                    waitUntil(timeout: 60) { done in
                        newClient.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                self.checkError(errorInfo)
                                done()
                            default:
                                break
                            }
                        }
                    }
                }

                //RTC1d
                it("should modify the realtime endpoint host if realtimeHost is assigned") {
                    // realtimeHost property is read-only
                }
                
                //RTC1e
                it("should modify both the REST and realtime endpoint if environment string is assigned") {
                    let options = AblyTests.commonAppSetup()
                    
                    let oldRestHost = options.restHost
                    let oldRealtimeHost = options.realtimeHost

                    // Change REST and realtime endpoint hosts
                    options.environment = "test"
                    
                    expect(options.restHost).to(equal("test-rest.ably.io"))
                    expect(options.realtimeHost).to(equal("test-realtime.ably.io"))
                    // Extra care
                    expect(oldRestHost).to(equal("sandbox-rest.ably.io"))
                    expect(oldRealtimeHost).to(equal("sandbox-realtime.ably.io"))
                }
            }

            // RTC2
            it("should have access to the underlying Connection object") {
                //ARTRealtime(options: AblyTests.commonAppSetup()).connection

                // TODO: There is no connection manager.
            }

            // RTC3
            it("should provide access to the underlying Channels object") {
                let client = ARTRealtime(options: AblyTests.commonAppSetup())

                client.channel("test").subscribe({ message, errorInfo in
                    // Attached
                })

                expect(client.channels()["test"]).toNot(beNil())
            }

            context("Auth object") {

                // RTC4
                it("should provide access to the Auth object") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)

                    expect(client.auth().options.key).to(equal(options.key))
                }

                // RTC4a
                it("clientId may be populated when the connection is established") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: 60) { done in
                        client.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                self.checkError(errorInfo)
                                expect(client.auth().clientId).to(equal(options.clientId))
                                done()
                            default:
                                break
                            }
                        }
                    }
                }
            }

            context("stats") {
                let query = ARTStatsQuery()
                query.unit = .Minute

                // RTC5a
                it("should present an async interface") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    // Async
                    waitUntil(timeout: 20.0) { done in
                        // Proxy from `client.rest.stats`
                        client.stats(query, callback: { paginated, error in
                            expect(paginated).toNot(beNil())
                            done()
                        })
                    }
                }

                // RTC5b
                it("should accept all the same params as RestClient") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    var paginatedResult: ARTPaginatedResult?

                    // Realtime
                    client.stats(query, callback: { paginated, error in
                        if let e = error {
                            XCTFail(e.description)
                        }
                        paginatedResult = paginated
                    })
                    expect(paginatedResult).toEventuallyNot(beNil(), timeout: 20.0)

                    // Rest
                    waitUntil(timeout: 20.0) { done in
                        client.rest.stats(query, callback: { paginated, error in
                            expect(paginated).to(beIdenticalTo(paginatedResult))
                            done()
                        })
                    }
                }
            }

            context("time") {
                // RTC6a
                it("should present an async interface") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    // Async
                    waitUntil(timeout: 20.0) { done in
                        // Proxy from `client.rest.time`
                        client.time({ date, error in
                            expect(date).toNot(beNil())
                            done()
                        })
                    }
                }
            }

            // RTC7
            it("should use the configured timeouts specified") {
                let options = AblyTests.commonAppSetup()
                options.suspendedRetryTimeout = 6.0

                let client = ARTRealtime(options: options)

                var start: NSDate?
                var endInterval: UInt?

                waitUntil(timeout: 120.0) { done in
                    client.eventEmitter.on { state, errorInfo in
                        switch state {
                        case .Failed:
                            self.checkError(errorInfo, withAlternative: "Failed state")
                            done()
                        case .Connecting:
                            if let start = start {
                                endInterval = UInt(start.timeIntervalSinceNow * -1)
                                done()
                            }
                        case .Connected:
                            self.checkError(errorInfo)

                            if start == nil {
                                // Force
                                client.transition(.Suspended)
                            }
                        case .Suspended:
                            start = NSDate()
                        default:
                            break
                        }
                    }
                }
                client.close()

                if let secs = endInterval {
                    expect(secs).to(beLessThanOrEqualTo(UInt(options.suspendedRetryTimeout)))
                }
            }
        }
    }
}
