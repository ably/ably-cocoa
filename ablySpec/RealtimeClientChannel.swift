//
//  RealtimeClient.channel.swift
//  ably
//
//  Created by Ricardo Pereira on 18/01/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble

class RealtimeClientChannel: QuickSpec {
    override func spec() {
        describe("Channel") {

            // RTL1
            it("should process all incoming messages and presence messages as soon as a Channel becomes attached") {
                let options = AblyTests.commonAppSetup()
                let client1 = ARTRealtime(options: options)
                defer { client1.close() }

                let channel1 = client1.channel("room")
                channel1.attach()

                waitUntil(timeout: testTimeout) { done in
                    channel1.presence().enterClient("Client 1", data: nil) { status in
                        expect(status.state).to(equal(ARTState.Ok))
                        done()
                    }
                }

                options.clientId = "Client 2"
                let client2 = ARTRealtime(options: options)
                defer { client2.close() }

                let channel2 = client2.channel(channel1.name)
                channel2.attach()

                expect(channel2.presence().isSyncComplete()).to(beFalse())

                expect(channel1.presenceMap.members).to(haveCount(1))
                expect(channel2.presenceMap.members).to(haveCount(0))

                expect(channel2.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                expect(channel2.presence().isSyncComplete()).toEventually(beTrue(), timeout: testTimeout)

                expect(channel1.presenceMap.members).to(haveCount(1))
                expect(channel2.presenceMap.members).to(haveCount(1))

                // Check if receives incoming messages
                channel2.subscribeToName("Client 1") { message, errorInfo in
                    expect(message.data as? String).to(equal("message"))
                }

                waitUntil(timeout: testTimeout) { done in
                    channel1.publish("message", cb: { status in
                        expect(status.state).to(equal(ARTState.Ok))
                        done()
                    })
                }

                waitUntil(timeout: testTimeout) { done in
                    channel2.presence().enter(nil) { status in
                        expect(status.state).to(equal(ARTState.Ok))
                        done()
                    }
                }

                expect(channel1.presenceMap.members).to(haveCount(2))
                expect(channel1.presenceMap.members).to(allKeysPass({ $0.hasPrefix("Client") }))
                expect(channel1.presenceMap.members).to(allValuesPass({ $0.action == .Enter }))

                expect(channel2.presenceMap.members).to(haveCount(2))
                expect(channel2.presenceMap.members).to(allKeysPass({ $0.hasPrefix("Client") }))
                expect(channel2.presenceMap.members["Client 1"]!.action).to(equal(ARTPresenceAction.Present))
                expect(channel2.presenceMap.members["Client 2"]!.action).to(equal(ARTPresenceAction.Enter))
            }

            // RTL3
            context("connection state") {

                // RTL3a
                pending("changes to FAILED") {

                    it("ATTACHING channel should transition to FAILED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        let channel = client.channel("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Attached]

                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))

                        waitUntil(timeout: testTimeout) { done in
                            channel.subscribeToStateChanges { state, status in
                                if state == .Failed {
                                    expect(status.state).to(equal(ARTState.Error))
                                    expect(status.errorInfo!.code).to(equal(90000))
                                    done()
                                }
                            }
                            client.onError(AblyTests.newErrorProtocolMessage())
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))
                    }

                    it("ATTACHED channel should transition to FAILED") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.close() }

                        let channel = client.channel("test")
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            channel.subscribeToStateChanges { state, status in
                                if state == .Failed {
                                    expect(status.state).to(equal(ARTState.Error))
                                    expect(status.errorInfo!.code).to(equal(90000))
                                    done()
                                }
                            }
                            client.onError(AblyTests.newErrorProtocolMessage())
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))
                    }
                    
                }

                // RTL3b
                context("changes to SUSPENDED") {

                    it("ATTACHING channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        let channel = client.channel("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Attached]

                        expect(client.connection().state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                        client.onSuspended()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                    }

                    it("ATTACHED channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        defer { client.close() }

                        let channel = client.channel("test")
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                        client.onSuspended()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                    }

                }

                // RTL3b
                context("changes to CLOSED") {

                    it("ATTACHING channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        let channel = client.channel("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Attached]

                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                        client.close()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                    }

                    it("ATTACHED channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        defer { client.close() }

                        let channel = client.channel("test")
                        channel.attach()

                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                        client.close()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                    }

                }

            }

            // RTL4
            describe("attach") {

                // RTL4c
                it("should send an ATTACH ProtocolMessage, change state to ATTACHING and change state to ATTACHED after confirmation") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()
                    defer { client.close() }

                    expect(client.connection().state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                    let transport = client.transport as! TestProxyTransport

                    let channel = client.channel("test")
                    channel.attach()

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    expect(transport.protocolMessagesSent.filter({ $0.action == .Attach })).to(haveCount(1))

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                    expect(transport.protocolMessagesReceived.filter({ $0.action == .Attached })).to(haveCount(1))
                }

                // RTL4e
                it("should transition the channel state to FAILED if the user does not have sufficient permissions") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken(capability: "{ \"main\":[\"subscribe\"] }")
                    let client = ARTRealtime(options: options)
                    defer { client.close() }

                    let channel = client.channel("test")
                    channel.attach()

                    channel.subscribeToStateChanges { state, status in
                        if state == .Failed {
                            expect(status.state).to(equal(ARTState.Error))
                            expect(status.errorInfo!.code).to(equal(40160))
                        }
                    }

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Failed), timeout: testTimeout)
                }

            }

            // RTL6
            describe("publish") {

                // RTL6b
                context("should invoke callback") {

                    it("when the message is successfully delivered") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.eventEmitter.on { state, error in
                                if state == .Connected {
                                    let channel = client.channel("test")
                                    channel.subscribeToStateChanges { state, status in
                                        if state == .Attached {
                                            channel.publish("message", cb: { status in
                                                expect(status.state).to(equal(ARTState.Ok))
                                                done()
                                            })
                                        }
                                    }
                                    channel.attach()
                                }
                            }
                        }
                    }

                    it("upon failure") {
                        let options = AblyTests.clientOptions()
                        options.token = getTestToken(capability: "{ \"test\":[\"subscribe\"] }")
                        let client = ARTRealtime(options: options)
                        defer { client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.eventEmitter.on { state, error in
                                if state == .Connected {
                                    let channel = client.channel("test")
                                    channel.subscribeToStateChanges { channelState, channelStatus in
                                        if channelState == .Attached {
                                            channel.publish("message", cb: { status in
                                                expect(status.state).to(equal(ARTState.Error))
                                                guard let errorInfo = status.errorInfo else {
                                                    XCTFail("ErrorInfo is nil"); done(); return
                                                }
                                                // Unable to perform channel operation
                                                expect(errorInfo.code).to(equal(40160))
                                                done()
                                            })
                                        }
                                    }
                                    channel.attach()
                                }
                            }
                        }
                    }

                    class TotalMessages {
                        static let expected = 50
                        static var succeeded = 0
                        static var failed = 0
                        private init() {}
                    }

                    it("for all messages published") {
                        let options = AblyTests.clientOptions()
                        options.token = getTestToken(capability: "{ \"channelToSucceed\":[\"subscribe\", \"publish\"], \"channelToFail\":[\"subscribe\"] }")
                        let client = ARTRealtime(options: options)
                        defer { client.close() }

                        TotalMessages.succeeded = 0
                        TotalMessages.failed = 0

                        let channelToSucceed = client.channel("channelToSucceed")
                        channelToSucceed.subscribeToStateChanges { state, status in
                            if state == .Attached {
                                for index in 1...TotalMessages.expected {
                                    channelToSucceed.publish("message\(index)", cb: { status in
                                        if status.state == .Ok {
                                            expect(index).to(equal(++TotalMessages.succeeded), description: "Callback was invoked with an invalid sequence")
                                        }
                                    })
                                }
                            }
                        }
                        channelToSucceed.attach()

                        let channelToFail = client.channel("channelToFail")
                        channelToFail.subscribeToStateChanges { channelState, channelStatus in
                            if channelState == .Attached {
                                for index in 1...TotalMessages.expected {
                                    channelToFail.publish("message\(index)", cb: { status in
                                        if status.state == .Error {
                                            expect(index).to(equal(++TotalMessages.failed), description: "Callback was invoked with an invalid sequence")
                                        }
                                    })
                                }
                            }
                        }
                        channelToFail.attach()

                        expect(TotalMessages.succeeded).toEventually(equal(TotalMessages.expected), timeout: testTimeout)
                        expect(TotalMessages.failed).toEventually(equal(TotalMessages.expected), timeout: testTimeout)
                    }

                }

            }

        }
    }
}
