//
//  RealtimeClient.swift
//  ably
//
//  Created by Ricardo Pereira on 26/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

import Quick
import Nimble

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

                    waitUntil(timeout: testTimeout) { done in
                        client.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Connecting, .Closing, .Closed:
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
                    client.close()
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

                    // First connection
                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        client.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                self.checkError(errorInfo)
                                expect(client.recoveryKey()).to(equal("\(client.connectionKey() ?? ""):\(client.connectionSerial())"), description: "recoveryKey wrong formed")
                                options.recover = client.recoveryKey()
                                done()
                            default:
                                break
                            }
                        }
                    }

                    // New connection
                    let newClient = ARTRealtime(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        newClient.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
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
                    newClient.close()
                    client.close()
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
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false

                let client = ARTRealtime(options: options)

                client.channels.get("test").subscribe({ message, errorInfo in
                    // Attached
                })

                expect(client.channels.get("test")).toNot(beNil())
                client.close()
            }

            context("Auth object") {

                // RTC4
                it("should provide access to the Auth object") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)

                    expect(client.auth().options.key).to(equal(options.key))
                    client.close()
                }

                // RTC4a
                it("clientId may be populated when the connection is established") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        client.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
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
                    client.close()
                }
            }

            context("stats") {
                let query = ARTStatsQuery()
                query.unit = .Minute

                // RTC5a
                it("should present an async interface") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    // Async
                    waitUntil(timeout: testTimeout) { done in
                        // Proxy from `client.rest.stats`
                        try! client.stats(query, callback: { paginated, error in
                            expect(paginated).toNot(beNil())
                            done()
                        })
                    }
                    client.close()
                }

                // RTC5b
                it("should accept all the same params as RestClient") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    var paginatedResult: ARTPaginatedResult?

                    // Realtime
                    try! client.stats(query, callback: { paginated, error in
                        if let e = error {
                            XCTFail(e.description)
                        }
                        paginatedResult = paginated
                    })
                    expect(paginatedResult).toEventuallyNot(beNil(), timeout: testTimeout)
                    if paginatedResult == nil {
                        return
                    }

                    // Rest
                    waitUntil(timeout: testTimeout) { done in
                        try! client.rest.stats(query, callback: { paginated, error in
                            defer { done() }
                            if let e = error {
                                XCTFail(e.description)
                                return
                            }
                            guard let paginated = paginated else {
                                XCTFail("both paginated and error are nil")
                                return
                            } 
                            expect(paginated.items.count).to(equal(paginatedResult!.items.count))
                        })
                    }
                    client.close()
                }
            }

            context("time") {
                // RTC6a
                it("should present an async interface") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    // Async
                    waitUntil(timeout: testTimeout) { done in
                        // Proxy from `client.rest.time`
                        client.time({ date, error in
                            expect(date).toNot(beNil())
                            done()
                        })
                    }
                    client.close()
                }
            }

            // RTC7
            it("should use the configured timeouts specified") {
                let options = AblyTests.commonAppSetup()
                options.suspendedRetryTimeout = 6.0

                let client = ARTRealtime(options: options)

                var start: NSDate?
                var endInterval: UInt?

                waitUntil(timeout: testTimeout + options.suspendedRetryTimeout) { done in
                    client.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
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
                                client.onSuspended()
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
