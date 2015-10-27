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
    override func spec() {
        describe("RealtimeClient") {
            // RTC1
            context("options") {
                it("should support the same options as the Rest client") {
                    let options = AblyTests.commonAppSetup() //Same as Rest
                    options.clientId = "client_string"

                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: 20.0) { done in
                        client.eventEmitter.on { state in
                            switch state {
                            case .Connecting:
                                break
                            case .Failed:
                                let reason = client.connectionErrorReason()
                                XCTFail("\(reason.message): \(reason.description)")
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
                fit("should attempt to recover the connection state if recover string is assigned") {
                    let options = AblyTests.commonAppSetup(debug: true) //Same as Rest
                    options.clientId = "client_string"
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    client.connect()

                    waitUntil(timeout: 200) { done in
                        client.eventEmitter.on { state in
                            switch state {
                            case .Failed:
                                let reason = client.connectionErrorReason()
                                XCTFail("\(reason.message): \(reason.description)")
                                done()
                            case .Connected:
                                expect(client.recoveryKey()).toNot(beNil())

                                let channel = client.channel("demo", cipherParams: nil)

                                channel.subscribe { message in
                                    print(message)
                                }

                                channel.publish("something", withName: "Bob") { status in
                                    print(status)
                                }

                                // Force suspension
                                client.transition(.Suspended)
                            case .Suspended:
                                client.channel("demo").publish("something", withName: "Bob") { status in
                                    print(status)
                                    client.close()
                                }
                                break
                            case .Closed:
                                done()
                            default:
                                break
                            }
                        }
                    }
                }
                
                //RTC1d
                it("should modify the realtime endpoint host if realtimeHost is assigned") {
                    //let options = ARTClientOptions()
                    // realtimeHost string, when set, will modify the realtime endpoint host used by this client library

                    //Default: realtime.ably.io
                    //let realtimeHost = options.realtimeHost
                    
                    // TODO: try to swizzle
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
        }
    }
}
