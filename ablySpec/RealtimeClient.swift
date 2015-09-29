//
//  RealtimeClient.swift
//  ably
//
//  Created by Ricardo Pereira on 26/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

import Nimble
import Quick
import ably
import ably.Private

class RealtimeClient: QuickSpec {
    override func spec() {
        describe("RealtimeClient") {
            // RTC1
            context("options") {
                it("should support the same options as the Rest client") {
                    let options = AblyTests.commonAppSetup() //Same as Rest
                    let client = ARTRealtime(options: options)
                    
                    client.eventEmitter.on { state in
                        if state != .Connecting {
                            expect(state).to(equal(ARTRealtimeConnectionState.Connected))
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
                    let options = ARTClientOptions()
                    // recover string, when set, will attempt to recover the connection state of a previous connection
                    
                    // TODO: need more background
                }
                
                //RTC1d
                it("should modify the realtime endpoint host if realtimeHost is assigned") {
                    let options = ARTClientOptions()
                    // realtimeHost string, when set, will modify the realtime endpoint host used by this client library

                    //Default: realtime.ably.io
                    let realtimeHost = options.realtimeHost()
                    
                    // TODO: try to swizzle
                }
                
                //RTC1e
                fit("should modify both the REST and realtime endpoint if environment string is assigned") {
                    let options = AblyTests.commonAppSetup()
                    
                    let logger = ARTLog()
                    logger.logLevel = .Verbose
                    
                    let expectation = self.expectationWithDescription("async")
                    
                    // Change REST and realtime endpoint hosts
                    options.environment = "test"
                    //options.realtimePort = 1111
                    
                    //sandbox-rest.ably.io
                    //sandbox-realtime.ably.io
                    
                    let client = ARTRealtime(logger: logger, andOptions: options)
                    
                    // FIXME: environment is not working
                    // Result: test-test-sandbox-realtime
                    
                    var testState: ARTRealtimeConnectionState = .Connecting
                    
                    client.eventEmitter.on { state in
                        if state != .Connecting {
                            expect(state).to(equal(ARTRealtimeConnectionState.Connected))
                            expectation.fulfill()
                        }
                    }
                    
                    self.waitForExpectationsWithTimeout(10.0, handler: nil)
                }
            }
        }
    }
}