//
//  RealtimeClient.channel.swift
//  ably
//
//  Created by Ricardo Pereira on 18/01/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble
import Aspects

class RealtimeClientChannel: QuickSpec {
    override func spec() {
        describe("Channel") {

            // RTL1
            it("should process all incoming messages and presence messages as soon as a Channel becomes attached") {
                let options = AblyTests.commonAppSetup()
                let client1 = ARTRealtime(options: options)
                defer { client1.close() }

                let channel1 = client1.channels.get("room")
                channel1.attach()

                waitUntil(timeout: testTimeout) { done in
                    channel1.presence.enterClient("Client 1", data: nil) { errorInfo in
                        expect(errorInfo).to(beNil())
                        done()
                    }
                }

                options.clientId = "Client 2"
                let client2 = ARTRealtime(options: options)
                defer { client2.close() }

                let channel2 = client2.channels.get(channel1.name)
                channel2.attach()

                expect(channel2.presence.syncComplete).to(beFalse())

                expect(channel1.presenceMap.members).to(haveCount(1))
                expect(channel2.presenceMap.members).to(haveCount(0))

                expect(channel2.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                expect(channel2.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)

                expect(channel1.presenceMap.members).to(haveCount(1))
                expect(channel2.presenceMap.members).to(haveCount(1))

                // Check if receives incoming messages
                channel2.subscribe("Client 1") { message in
                    expect(message.data as? String).to(equal("message"))
                }

                waitUntil(timeout: testTimeout) { done in
                    channel1.publish("message", data: nil) { errorInfo in
                        expect(errorInfo).to(beNil())
                        done()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel2.presence.enter(nil) { errorInfo in
                        expect(errorInfo).to(beNil())
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

                        let channel = client.channels.get("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Attached]

                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))

                        waitUntil(timeout: testTimeout) { done in
                            channel.on { errorInfo in
                                if channel.state == .Failed {
                                    expect(errorInfo!.code).to(equal(90000))
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

                        let channel = client.channels.get("test")
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            channel.on { errorInfo in
                                if channel.state == .Failed {
                                    expect(errorInfo!.code).to(equal(90000))
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

                        let channel = client.channels.get("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Attached]

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                        client.onSuspended()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                    }

                    it("ATTACHED channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        defer { client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                        client.onSuspended()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                    }

                }

                // RTL3b
                pending("changes to CLOSED") {

                    it("ATTACHING channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Attached]

                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                        client.close()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closing))
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closed))
                    }

                    it("ATTACHED channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        defer { client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()

                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                        client.close()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closing))
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closed))
                    }

                }

            }

            // RTL4
            describe("attach") {

                // RTL4a
                pending("if already ATTACHED or ATTACHING nothing is done") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }

                    var errorInfo: ARTErrorInfo?
                    let channel = client.channels.get("test")

                    channel.attach { errorInfo in
                        expect(errorInfo).to(beNil())
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))

                    channel.attach { errorInfo in
                        expect(errorInfo).to(beNil())
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    }

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))
                            done()
                        }
                    }
                }

                // RTL4b
                context("results in an error if the connection state is") {

                    pending("CLOSING") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Closed]

                        let channel = client.channels.get("test")

                        client.close()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closing))

                        expect(channel.attach()).toNot(beNil())
                    }

                    it("CLOSED") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.close() }

                        let channel = client.channels.get("test")

                        client.close()
                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Closed), timeout: testTimeout)

                        expect(channel.attach()).toNot(beNil())
                    }

                    it("SUSPENDED") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.close() }

                        let channel = client.channels.get("test")
                        client.onSuspended()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Suspended))
                        expect(channel.attach()).toNot(beNil())
                    }

                    it("FAILED") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.close() }

                        let channel = client.channels.get("test")
                        client.onError(AblyTests.newErrorProtocolMessage())
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Failed))
                        expect(channel.attach()).toNot(beNil())
                    }

                }

                // RTL4c
                it("should send an ATTACH ProtocolMessage, change state to ATTACHING and change state to ATTACHED after confirmation") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()
                    defer { client.close() }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                    let transport = client.transport as! TestProxyTransport

                    let channel = client.channels.get("test")
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

                    let channel = client.channels.get("test")
                    channel.attach()

                    channel.on { errorInfo in
                        if channel.state == .Failed {
                            expect(errorInfo!.code).to(equal(40160))
                        }
                    }

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Failed), timeout: testTimeout)
                }

                // RTL4f
                pending("should transition the channel state to FAILED if ATTACHED ProtocolMessage is not received") {
                    ARTDefault.setRealtimeRequestTimeout(3.0)
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()
                    defer { client.close() }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                    let transport = client.transport as! TestProxyTransport
                    transport.actionsIgnored += [.Attached]

                    let channel = client.channels.get("test")
                    channel.attach()
                    let start = NSDate()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Failed), timeout: ARTDefault.realtimeRequestTimeout())
                    let end = NSDate()
                    expect(start.dateByAddingTimeInterval(3.0)).to(beCloseTo(end))
                }

            }

            // RTL6
            describe("publish") {

                // RTL6a
                it("should encode messages in the same way as the RestChannel") {
                    let data = ["value":1]

                    let rest = ARTRest(options: AblyTests.commonAppSetup())
                    let restChannel = rest.channels.get("test")

                    var restEncodedMessage: ARTMessage?
                    restChannel.testSuite_getReturnValueFrom(Selector("encodeMessageIfNeeded:")) { value in
                        restEncodedMessage = value as? ARTMessage
                    }

                    waitUntil(timeout: testTimeout) { done in
                        restChannel.publish(nil, data: data) { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }

                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { realtime.close() }
                    let realtimeChannel = realtime.channels.get("test")
                    realtimeChannel.attach()
                    expect(realtimeChannel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    var realtimeEncodedMessage: ARTMessage?
                    realtimeChannel.testSuite_getReturnValueFrom(Selector("encodeMessageIfNeeded:")) { value in
                        realtimeEncodedMessage = value as? ARTMessage
                    }

                    waitUntil(timeout: testTimeout) { done in
                        realtimeChannel.publish(nil, data: data) { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }

                    expect(restEncodedMessage!.data as? NSObject).to(equal(realtimeEncodedMessage!.data as? NSObject))
                    expect(restEncodedMessage!.data).toNot(beNil())
                    expect(realtimeEncodedMessage!.data).toNot(beNil())
                    expect(restEncodedMessage!.encoding).to(equal(realtimeEncodedMessage!.encoding))
                    expect(restEncodedMessage!.encoding).toNot(beNil())
                    expect(realtimeEncodedMessage!.encoding).toNot(beNil())
                }

                // RTL6b
                context("should invoke callback") {

                    it("when the message is successfully delivered") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .Connected {
                                    let channel = client.channels.get("test")
                                    channel.on { errorInfo in
                                        if channel.state == .Attached {
                                            channel.publish(nil, data: "message") { errorInfo in
                                                expect(errorInfo).to(beNil())
                                                done()
                                            }
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
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .Connected {
                                    let channel = client.channels.get("test")
                                    channel.on { errorInfo in
                                        if channel.state == .Attached {
                                            channel.publish(nil, data: "message") { errorInfo in
                                                expect(errorInfo).toNot(beNil())
                                                guard let errorInfo = errorInfo else {
                                                    XCTFail("ErrorInfo is nil"); done(); return
                                                }
                                                // Unable to perform channel operation
                                                expect(errorInfo.code).to(equal(40160))
                                                done()
                                            }
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

                        let channelToSucceed = client.channels.get("channelToSucceed")
                        channelToSucceed.on { errorInfo in
                            if channelToSucceed.state == .Attached {
                                for index in 1...TotalMessages.expected {
                                    channelToSucceed.publish(nil, data: "message\(index)") { errorInfo in
                                        if errorInfo == nil {
                                            expect(index).to(equal(++TotalMessages.succeeded), description: "Callback was invoked with an invalid sequence")
                                        }
                                    }
                                }
                            }
                        }
                        channelToSucceed.attach()

                        let channelToFail = client.channels.get("channelToFail")
                        channelToFail.on { errorInfo in
                            if channelToFail.state == .Attached {
                                for index in 1...TotalMessages.expected {
                                    channelToFail.publish(nil, data: "message\(index)") { errorInfo in
                                        if errorInfo != nil {
                                            expect(index).to(equal(++TotalMessages.failed), description: "Callback was invoked with an invalid sequence")
                                        }
                                    }
                                }
                            }
                        }
                        channelToFail.attach()

                        expect(TotalMessages.succeeded).toEventually(equal(TotalMessages.expected), timeout: testTimeout)
                        expect(TotalMessages.failed).toEventually(equal(TotalMessages.expected), timeout: testTimeout)
                    }

                }

                // RTL6e
                context("Unidentified clients using Basic Auth") {

                    // RTL6e1
                    pending("should have the provided clientId on received message when it was published with clientId") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.close() }

                        expect(client.auth.clientId).to(beNil())

                        let channel = client.channels.get("test")

                        var resultClientId: String?
                        channel.subscribe() { message in
                            resultClientId = message.clientId
                        }

                        let message = ARTMessage(data: "message", name: nil)
                        message.clientId = "client_string"

                        channel.publish([message]) { errorInfo in
                            expect(errorInfo).to(beNil())
                        }

                        expect(resultClientId).toEventually(equal(message.clientId), timeout: testTimeout)
                    }

                }

                // RTL6g
                context("Identified clients with clientId") {

                    // RTL6g1
                    context("When publishing a Message with clientId set to null") {

                        // RTL6g1a
                        it("should be unnecessary to set clientId of the Message before publishing") {
                            let options = AblyTests.commonAppSetup()
                            options.autoConnect = false
                            let client = ARTRealtime(options: options)
                            client.setTransportClass(TestProxyTransport.self)
                            client.connect()
                            defer { client.close() }

                            let channel = client.channels.get("test")

                            channel.publish(nil, data: "message") { errorInfo in
                                expect(errorInfo).to(beNil())
                            }

                            let transport = client.transport as! TestProxyTransport
                            expect(transport.protocolMessagesSent.filter { $0.action == .Message }).toEventually(haveCount(1), timeout: testTimeout)

                            let messageSent = transport.protocolMessagesSent.filter({ $0.action == .Message })[0]
                            expect(messageSent.messages![0].clientId).to(beNil())
                        }

                    }

                }

            }

            // RTL7
            context("subscribe") {

                // RTL7a
                it("with no arguments subscribes a listener to all messages") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }

                    let channel = client.channels.get("test")

                    class Test {
                        static var counter = 0
                        private init() {}
                    }

                    channel.subscribe { message in
                        expect(message.data as? String).to(equal("message"))
                        Test.counter += 1
                    }

                    channel.publish(nil, data: "message")
                    channel.publish("eventA", data: "message")
                    channel.publish("eventB", data: "message")

                    expect(Test.counter).toEventually(equal(3), timeout: testTimeout)
                }

                // RTL7b
                it("with a single name argument subscribes a listener to only messages whose name member matches the string name") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }

                    let channel = client.channels.get("test")

                    class Test {
                        static var counter = 0
                        private init() {}
                    }

                    channel.subscribe("eventA") { message in
                        expect(message.name).to(equal("eventA"))
                        expect(message.data as? String).to(equal("message"))
                        Test.counter += 1
                    }

                    channel.publish(nil, data: "message")
                    channel.publish("eventA", data: "message")
                    channel.publish("eventB", data: "message")
                    channel.publish("eventA", data: "message")

                    expect(Test.counter).toEventually(equal(2), timeout: testTimeout)
                }

            }

        }
    }
}
