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
                fit("should support the same options as the Rest client") {
                    let options = AblyTests.commonAppSetup() //Same as Rest
                    let client = ARTRealtime(options: options)
                    
                    client.eventEmitter.on { state in
                        if state != .Connecting {
                            println(state)
                            expect(state).to(equal(ARTRealtimeConnectionState.Connected))
                        }
                    }
                }
                
                //RTC1a
                fit("should echoMessages option be true by default") {
                    let options = ARTClientOptions()
                    expect(options.echoMessages) == true
                }
                
                //RTC1b
                fit("should autoConnect option be true by default") {
                    let options = ARTClientOptions()
                    expect(options.autoConnect) == true
                }
                
                //RTC1c
                fit("should attempt to recover the connection state if recover string is assigned") {
                    let options = ARTClientOptions()
                    // recover string, when set, will attempt to recover the connection state of a previous connection
                    
                    // TODO: need more background
                }
                
                //RTC1d
                fit("should modify the realtime endpoint host if realtimeHost is assigned") {
                    let options = ARTClientOptions()
                    // realtimeHost string, when set, will modify the realtime endpoint host used by this client library

                    //Default: realtime.ably.io
                    let realtimeHost = options.realtimeHost()
                    
                    // TODO: try to swizzle
                }
                
                //RTC1e
                fit("should modify both the REST and realtime endpoint if environment string is assigned") {
                    let options = AblyTests.commonAppSetup()
                    
                    // Change REST and realtime endpoint hosts
                    options.environment = "sandbox"
                    
                    //sandbox-rest.ably.io
                    //sandbox-realtime.ably.io
                    
                    let client = ARTRealtime(options: options)
                    
                    // FIXME: environment is not working
                    
                    client.eventEmitter.on { state in
                        if state != .Connecting {
                            expect(state).to(equal(ARTRealtimeConnectionState.Connected))
                        }
                    }
                }
            }
        }
    }
}