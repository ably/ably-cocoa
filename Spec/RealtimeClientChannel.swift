//
//  RealtimeClient.channel.swift
//  ably
//
//  Created by Ricardo Pereira on 18/01/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Ably
import Quick
import Nimble
import Aspects

class RealtimeClientChannel: QuickSpec {
    override func spec() {
        describe("Channel") {

            // RTL1
            it("should process all incoming messages and presence messages as soon as a Channel becomes attached") {
                let options = AblyTests.commonAppSetup()
                let client1 = AblyTests.newRealtime(options)
                defer { client1.dispose(); client1.close() }
                let channel1 = client1.channels.get("room")

                waitUntil(timeout: testTimeout) { done in
                    channel1.presence.enterClient("Client 1", data: nil) { errorInfo in
                        expect(errorInfo).to(beNil())
                        done()
                    }
                }

                options.clientId = "Client 2"
                let client2 = AblyTests.newRealtime(options)
                defer { client2.dispose(); client2.close() }
                let channel2 = client2.channels.get(channel1.name)

                channel2.subscribe("Client 1") { message in
                    expect(message.data as? String).to(equal("message"))
                }

                channel2.attach()

                expect(channel2.presence.getSyncComplete).to(beFalse())

                expect(channel1.presenceMap.members).to(haveCount(1))
                expect(channel2.presenceMap.members).to(haveCount(0))

                expect(channel2.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                expect(channel2.presence.getSyncComplete).toEventually(beTrue(), timeout: testTimeout)

                expect(channel1.presenceMap.members).to(haveCount(1))
                expect(channel2.presenceMap.members).toEventually(haveCount(1), timeout: testTimeout)

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
                
                expect(channel1.presenceMap.members).toEventually(haveCount(2), timeout: testTimeout)
                expect(channel1.presenceMap.members.keys).to(allPass({ $0!.hasPrefix("Client") }))
                expect(channel1.presenceMap.members.values).to(allPass({ $0!.action == .present }))

                expect(channel2.presenceMap.members).toEventually(haveCount(2), timeout: testTimeout)
                expect(channel2.presenceMap.members.keys).to(allPass({ $0!.hasPrefix("Client") }))
                expect(channel2.presenceMap.members["Client 1"]!.action).to(equal(ARTPresenceAction.present))
                expect(channel2.presenceMap.members["Client 2"]!.action).to(equal(ARTPresenceAction.present))
            }

            // RTL2
            context("EventEmitter, channel states and events") {

                // RTL2a
                it("should implement the EventEmitter and emit events for state changes") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    expect(channel.statesEventEmitter).to(beAKindOf(ARTEventEmitter<ARTEvent, ARTChannelStateChange>.self))

                    var channelOnMethodCalled = false
                    channel.testSuite_injectIntoMethod(after: #selector(ARTEventEmitter<ARTEvent, ARTChannelStateChange>.on(_:))) {
                        channelOnMethodCalled = true
                    }

                    // The `channel.on` should use `statesEventEmitter`
                    var statesEventEmitterOnMethodCalled = false
                    channel.statesEventEmitter.testSuite_injectIntoMethod(after: #selector(ARTEventEmitter<ARTEvent, ARTChannelStateChange>.on(_:))) {
                        statesEventEmitterOnMethodCalled = true
                    }

                    var emitCounter = 0
                    channel.statesEventEmitter.testSuite_injectIntoMethod(after: #selector(ARTEventEmitter<ARTEvent, ARTChannelStateChange>.emit(_:with:))) {
                        emitCounter += 1
                    }

                    var states = [channel.state]
                    waitUntil(timeout: testTimeout) { done in
                        channel.on { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); done(); return
                            }
                            expect(stateChange.previous).to(equal(states.last))
                            expect(channel.state).to(equal(stateChange.current))
                            states += [stateChange.current]

                            switch stateChange.current {
                            case .attached:
                                expect(stateChange.event).to(equal(ARTChannelEvent.attached))
                                expect(stateChange.reason).to(beNil())
                                channel.detach()
                            case .detached:
                                expect(stateChange.event).to(equal(ARTChannelEvent.detached))
                                guard let error = stateChange.reason else {
                                    fail("Detach state change reason is nil"); done(); return
                                }
                                expect(error.message).to(contain("channel has detached"))
                                done()
                            default:
                                break
                            }
                        }
                        channel.attach()
                    }

                    expect(channelOnMethodCalled).to(beTrue())
                    expect(statesEventEmitterOnMethodCalled).to(beTrue())
                    expect(emitCounter).to(equal(4))

                    if states.count != 5 {
                        fail("Expecting 5 states; got \(states)")
                        return
                    }

                    expect(states[0].rawValue).to(equal(ARTRealtimeChannelState.initialized.rawValue), description: "Should be INITIALIZED state")
                    expect(states[1].rawValue).to(equal(ARTRealtimeChannelState.attaching.rawValue), description: "Should be ATTACHING state")
                    expect(states[2].rawValue).to(equal(ARTRealtimeChannelState.attached.rawValue), description: "Should be ATTACHED state")
                    expect(states[3].rawValue).to(equal(ARTRealtimeChannelState.detaching.rawValue), description: "Should be DETACHING state")
                    expect(states[4].rawValue).to(equal(ARTRealtimeChannelState.detached.rawValue), description: "Should be DETACHED state")
                }

                // RTL2a
                it("should implement the EventEmitter and emit events for FAILED state changes") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken(capability: "{\"secret\":[\"subscribe\"]}")
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.on { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); done(); return
                            }
                            expect(channel.state).to(equal(stateChange.current))
                            switch stateChange.current {
                            case .attaching:
                                expect(stateChange.event).to(equal(ARTChannelEvent.attaching))
                                expect(stateChange.reason).to(beNil())
                                expect(stateChange.previous).to(equal(ARTRealtimeChannelState.initialized))
                            case .failed:
                                guard let reason = stateChange.reason else {
                                    fail("Reason is nil"); done(); return
                                }
                                expect(stateChange.event).to(equal(ARTChannelEvent.failed))
                                expect(reason.code) == 40160
                                expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attaching))
                                done()
                            default:
                                break
                            }
                        }
                        channel.attach()
                    }
                }

                // RTL2a
                it("should implement the EventEmitter and emit events for SUSPENDED state changes") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    client.simulateSuspended(beforeSuspension: { done in
                        channel.once(.suspended) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStageChange is nil"); done(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attached))
                            expect(stateChange.event).to(equal(ARTChannelEvent.suspended))
                            expect(channel.state).to(equal(stateChange.current))
                            done()
                        }
                    })
                }

                // RTL2g
                it("can emit an UPDATE event") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    channel.on(.attached) { _ in
                        fail("Should not emit Attached again")
                    }
                    defer {
                        channel.off()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.on(.update) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); done(); return
                            }
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                            expect(stateChange.previous).to(equal(channel.state))
                            expect(stateChange.current).to(equal(channel.state))
                            expect(stateChange.event).to(equal(ARTChannelEvent.update))
                            expect(stateChange.resumed).to(beFalse())
                            expect(stateChange.reason).to(beNil())
                            done()
                        }

                        let attachedMessage = ARTProtocolMessage()
                        attachedMessage.action = .attached
                        attachedMessage.channel = channel.name
                        client.transport?.receive(attachedMessage)
                    }
                }

                // RTL2b
                it("state attribute should be the current state of the channel") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))

                    channel.attach()
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                }

                // RTL2c
                it("should contain an ErrorInfo object with details when an error occurs") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let pmError = AblyTests.newErrorProtocolMessage()
                    waitUntil(timeout: testTimeout) { done in
                        channel.on(.failed) { stateChange in
                            guard let error = stateChange?.reason else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error).to(equal(pmError.error))
                            expect(channel.errorReason).to(equal(pmError.error))
                            done()
                        }
                        channel.onError(pmError)
                    }
                }

                // RTL2d
                it("a ChannelStateChange is emitted as the first argument for every channel state change") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    channel.on { stateChange in
                        guard let stateChange = stateChange else {
                            fail("ChannelStageChange is nil"); return
                        }
                        expect(stateChange.reason).to(beNil())
                        expect(stateChange.current.rawValue).to(equal(channel.state.rawValue))
                        expect(stateChange.previous.rawValue).toNot(equal(channel.state.rawValue))
                    }

                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                    channel.off()

                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.failed) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStageChange is nil"); done(); return
                            }
                            expect(stateChange.reason).toNot(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.failed))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attached))
                            done()
                        }
                        channel.onError(AblyTests.newErrorProtocolMessage())
                    }
                }

                // RTL2f
                pending("ChannelStateChange will contain a resumed boolean attribute with value @true@ if the bit flag RESUMED was included") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.0
                    options.tokenDetails = getTestTokenDetails(ttl: 5.0)
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.on { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStageChange is nil"); done(); return
                            }
                            switch stateChange.current {
                            case .attached:
                                expect(stateChange.resumed).to(beFalse())
                            default:
                                expect(stateChange.resumed).to(beFalse())
                            }
                        }
                        client.connection.once(.disconnected) { stateChange in
                            channel.off()
                            guard let error = stateChange?.reason else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.code) == 40142
                            done()
                        }
                        channel.attach()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.attached) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStageChange is nil"); done(); return
                            }
                            expect(stateChange.resumed).to(beTrue())
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.attached))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attached))
                            done()
                        }
                    }
                }

                // RTL2f, TR4i
                it("bit flag RESUMED was included") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.attached) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStageChange is nil"); done(); return
                            }
                            expect(stateChange.resumed).to(beFalse())
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        channel.attach()
                    }

                    let attachedMessage = ARTProtocolMessage()
                    attachedMessage.action = .attached
                    attachedMessage.channel = channel.name
                    attachedMessage.flags = 4 //Resumed

                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.update) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStageChange is nil"); done(); return
                            }
                            expect(stateChange.resumed).to(beTrue())
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.attached))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attached))
                            done()
                        }
                        client.transport?.receive(attachedMessage)
                    }
                }

            }

            // RTL3
            context("connection state") {

                // RTL3a
                context("changes to FAILED") {

                    it("ATTACHING channel should transition to FAILED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.attached]

                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))

                        waitUntil(timeout: testTimeout) { done in
                            let pmError = AblyTests.newErrorProtocolMessage()
                            channel.once(.failed) { stateChange in
                                guard let error = stateChange?.reason else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error).to(equal(pmError.error))
                                expect(channel.errorReason).to(beIdenticalTo(error))
                                done()
                            }
                            client.onError(pmError)
                        }

                        expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                    }

                    it("ATTACHED channel should transition to FAILED") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            let pmError = AblyTests.newErrorProtocolMessage()
                            channel.once(.failed) { stateChange in
                                guard let error = stateChange?.reason else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error).to(equal(pmError.error))
                                expect(channel.errorReason).to(equal(error))
                                done()
                            }
                            client.onError(pmError)
                        }

                        expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                    }

                }

                // RTL3b
                context("changes to CLOSED") {

                    it("ATTACHING channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }
                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                        let channel = client.channels.get("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.attached]

                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                        client.close()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closing))
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closed))
                    }

                    it("ATTACHED channel should transition to DETACHED") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()

                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                        client.close()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closing))
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closed))
                    }

                }

                // RTL3c
                context("changes to SUSPENDED") {

                    it("ATTACHING channel should transition to SUSPENDED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.attached]

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                        client.onSuspended()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.suspended))
                    }

                    it("ATTACHED channel should transition to SUSPENDED") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                        client.onSuspended()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.suspended))
                    }

                }

                // RTL3d
                it("if the connection state enters the CONNECTED state, then a SUSPENDED channel will initiate an attach operation") {
                    let options = AblyTests.commonAppSetup()
                    options.suspendedRetryTimeout = 1.0
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.suspended) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        delay(0) {
                            client.onSuspended()
                        }
                    }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                }

                // RTL3d
                it("if the attach operation for the channel times out and the channel returns to the SUSPENDED state") {
                    let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    client.simulateSuspended(beforeSuspension: { done in
                        channel.once(.suspended) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); done(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                    })
                }

                // RTL3e
                it("if the connection state enters the DISCONNECTED state, it will have no effect on the channel states") {
                    let options = AblyTests.commonAppSetup()
                    options.token = getTestToken(ttl: 5.0)
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    channel.once(.detached) { stateChange in
                        fail("Should not reach the DETACHED state")
                    }
                    defer {
                        channel.off()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.disconnected) { _ in
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                            done()
                        }
                    }
                }

            }

            // RTL4
            describe("attach") {

                // RTL4a
                it("if already ATTACHED or ATTACHING nothing is done") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    var errorInfo: ARTErrorInfo?
                    let channel = client.channels.get("test")

                    channel.attach { errorInfo in
                        expect(errorInfo).to(beNil())
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))

                    channel.attach { errorInfo in
                        expect(errorInfo).to(beNil())
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                    }

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                            done()
                        }
                    }
                }

                // RTL4e
                it("if the user does not have sufficient permissions to attach, then the channel will transition to FAILED and set the errorReason") {
                    let options = AblyTests.commonAppSetup()
                    options.token = getTestToken(key: options.key!, capability: "{\"restricted\":[\"*\"]}")
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.once(.failed) { stateChange in
                            expect(stateChange?.reason?.code) == 40160
                            partialDone()
                        }
                        channel.attach { error in
                            guard let error = error else {
                                fail("Error is nil"); partialDone(); return
                            }
                            expect((error ).code) == 40160
                            partialDone()
                        }
                    }

                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                    expect(channel.errorReason?.code) == 40160
                }

                // RTL4g
                it("if the channel is in the FAILED state, the attach request sets its errorReason to null, and proceeds with a channel attach") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    let errorMsg = AblyTests.newErrorProtocolMessage()
                    errorMsg.channel = channel.name
                    client.onError(errorMsg)
                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                    expect(channel.errorReason).toNot(beNil())

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                    expect(channel.errorReason).to(beNil())
                }

                // RTL4b
                context("results in an error if the connection state is") {

                    it("CLOSING") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.closed]

                        let channel = client.channels.get("test")

                        client.close()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closing))

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }

                    it("CLOSED") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")

                        client.close()
                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.closed), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }

                    it("SUSPENDED") {
                        let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        client.onSuspended()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.suspended))
                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }

                    it("FAILED") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        client.onError(AblyTests.newErrorProtocolMessage())
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.failed))
                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }

                }

                // RTL4i
                context("happens when connection is CONNECTED if it's currently") {
                    it("INITIALIZED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.initialized))
                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                                expect(error).to(beNil())
                                done()
                            }

                            client.connect()
                        }
                    }

                    it("CONNECTING") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            client.connect()
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connecting))

                            channel.attach { error in
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                                expect(error).to(beNil())
                                done()
                            }
                        }
                    }

                    it("DISCONNECTED") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 0.1
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            client.onDisconnected()
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.disconnected))

                            channel.attach { error in
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                                expect(error).to(beNil())
                                done()
                            }
                        }
                    }
                }

                // RTL4c
                it("should send an ATTACH ProtocolMessage, change state to ATTACHING and change state to ATTACHED after confirmation") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer { client.dispose(); client.close() }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                    let transport = client.transport as! TestProxyTransport

                    let channel = client.channels.get("test")
                    channel.attach()

                    expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    expect(transport.protocolMessagesSent.filter({ $0.action == .attach })).to(haveCount(1))

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                    expect(transport.protocolMessagesReceived.filter({ $0.action == .attached })).to(haveCount(1))
                }

                // RTL4e
                it("should transition the channel state to FAILED if the user does not have sufficient permissions") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken(capability: "{ \"main\":[\"subscribe\"] }")
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    channel.attach()

                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.failed) { stateChange in
                            guard let error = stateChange?.reason else {
                                fail("Reason error is nil"); done(); return
                            }
                            expect((error ).code).to(equal(40160))
                            done()
                        }
                    }

                    expect(channel.errorReason!.code).to(equal(40160))
                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                }

                // RTL4f
                it("should transition the channel state to SUSPENDED if ATTACHED ProtocolMessage is not received") {
                    let options = AblyTests.commonAppSetup()
                    options.channelRetryTimeout = 1.0
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                    defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                    ARTDefault.setRealtimeRequestTimeout(1.0)

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }
                    transport.actionsIgnored += [.attached]

                    let channel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { errorInfo in
                            expect(errorInfo).toNot(beNil())
                            expect(errorInfo).to(equal(channel.errorReason))
                            done()
                        }
                    }
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.suspended), timeout: testTimeout)
                    expect(channel.errorReason).toNot(beNil())

                    transport.actionsIgnored = []
                    // Automatically re-attached
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.once(.attaching) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            partialDone()
                        }
                        channel.once(.attached) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            partialDone()
                        }
                    }
                }

                it("if called with a callback should call it once attached") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                            done()
                        }
                    }
                }

                it("if called with a callback and already attaching should call the callback once attached") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                        channel.attach { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                            done()
                        }
                    }
                }

                it("if called with a callback and already attached should call the callback with nil error") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }
                }

                // RTL4h
                it("if the channel is in a pending state ATTACHING, do the attach operation after the completion of the pending request") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    var attachedCount = 0
                    channel.on(.attached) { stateChange in
                        guard let stateChange = stateChange else {
                            fail("ChannelStateChange is nil"); return
                        }
                        expect(stateChange.reason).to(beNil())
                        attachedCount += 1
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.once(.attaching) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.attaching))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.initialized))
                            channel.attach()
                            partialDone()
                        }
                        channel.once(.attached) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            partialDone()
                        }
                        channel.attach()
                    }

                    expect(attachedCount).toEventually(equal(1), timeout: testTimeout)
                }

                // RTL4h
                it("if the channel is in a pending state DETACHING, do the attach operation after the completion of the pending request") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(4, done: done)
                        channel.once(.detaching) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.detaching))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attached))
                            channel.attach()
                            partialDone()
                        }
                        channel.once(.detached) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason?.message).to(contain("channel has detached"))
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.detached))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.detaching))
                            partialDone()
                        }
                        channel.once(.attaching) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.attaching))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.detached))
                            partialDone()
                        }
                        channel.once(.attached) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.attached))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attaching))
                            partialDone()
                        }
                        channel.detach()
                    }
                }

                it("a channel in DETACHING can actually move back to ATTACHED if it fails to detach") {
                    let options = AblyTests.commonAppSetup()
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                    defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                    ARTDefault.setRealtimeRequestTimeout(1.0)

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    // Force timeout
                    transport.actionsIgnored = [.detached]

                    waitUntil(timeout: testTimeout) { done in
                        channel.detach() { error in
                            guard let error = error else {
                                fail("Reason error is nil"); return
                            }
                            expect(error.message).to(contain("timed out"))
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                            done()
                        }
                    }
                }

            }

            describe("detach") {
                // RTL5a
                it("if state is INITIALIZED or DETACHED nothing is done") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    var errorInfo: ARTErrorInfo?
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))
                    channel.detach { errorInfo in
                        expect(errorInfo).to(beNil())
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))

                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attaching), timeout: testTimeout)

                    channel.detach { errorInfo in
                        expect(errorInfo).to(beNil())
                        expect(channel.state).to(equal(ARTRealtimeChannelState.detached))
                    }

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.detach { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.detached))
                            done()
                        }
                    }
                }

                // RTL5i
                it("if the channel is in a pending state DETACHING, do the detach operation after the completion of the pending request") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    var detachedCount = 0
                    channel.on(.detached) { _ in
                        detachedCount += 1
                    }

                    var detachingCount = 0
                    channel.on(.detaching) { _ in
                        detachingCount += 1
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.once(.detaching) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); done(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.detaching))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attached))
                            channel.detach()
                            partialDone()
                        }
                        channel.once(.detached) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); done(); return
                            }
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.detached))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.detaching))
                            partialDone()
                        }
                        channel.detach()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        delay(1.0) {
                            expect(detachedCount) == 1
                            expect(detachingCount) == 1
                            done()
                        }
                    }

                    channel.off()
                }

                // RTL5i
                it("if the channel is in a pending state ATTACHING, do the detach operation after the completion of the pending request") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)
                        channel.once(.attaching) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.attaching))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.initialized))
                            channel.detach()
                            partialDone()
                        }
                        channel.once(.attached) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.attached))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attaching))
                            partialDone()
                        }
                        channel.once(.detaching) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.detaching))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.attached))
                            partialDone()
                        }
                        channel.attach()
                    }
                }

                // RTL5b
                it("results in an error if the connection state is FAILED") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    client.onError(AblyTests.newErrorProtocolMessage())
                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.failed))

                    waitUntil(timeout: testTimeout) { done in
                        channel.detach() { errorInfo in
                            expect(errorInfo!.code).to(equal(90000))
                            done()
                        }
                    }
                }

                // RTL5d
                it("should send a DETACH ProtocolMessage, change state to DETACHING and change state to DETACHED after confirmation") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer { client.dispose(); client.close() }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                    let transport = client.transport as! TestProxyTransport

                    let channel = client.channels.get("test")
                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                    channel.detach()

                    expect(channel.state).to(equal(ARTRealtimeChannelState.detaching))
                    expect(transport.protocolMessagesSent.filter({ $0.action == .detach })).to(haveCount(1))

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)
                    expect(transport.protocolMessagesReceived.filter({ $0.action == .detached })).to(haveCount(1))
                }

                // RTL5e
                it("if called with a callback should call it once detached") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.detach { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.detached))
                            done()
                        }
                    }
                }

                // RTL5e
                it("if called with a callback and already detaching should call the callback once detached") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.detach()
                        expect(channel.state).to(equal(ARTRealtimeChannelState.detaching))
                        channel.detach { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.detached))
                            done()
                        }
                    }
                }

                // RTL5e
                it("if called with a callback and already detached should should call the callback with nil error") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                    channel.detach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.detach { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }
                }

                // RTL5f
                it("if a DETACHED is not received within the default realtime request timeout, the detach request should be treated as though it has failed and the channel will return to its previous state") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer { client.dispose(); client.close() }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                    let transport = client.transport as! TestProxyTransport
                    transport.actionsIgnored += [.detached]

                    let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                    defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                    ARTDefault.setRealtimeRequestTimeout(1.0)

                    let channel = client.channels.get("test")
                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    var callbackCalled = false
                    channel.detach { error in
                        guard let error = error else {
                            fail("Error is nil"); return
                        }
                        expect(error.message).to(contain("timed out"))
                        expect(error).to(equal(channel.errorReason))
                        callbackCalled = true
                    }
                    let start = NSDate()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                    expect(channel.errorReason).toNot(beNil())
                    expect(callbackCalled).toEventually(beTrue(), timeout: testTimeout)
                    let end = NSDate()
                    expect(start.addingTimeInterval(1.0)).to(beCloseTo(end, within: 0.5))
                }

                // RTL5g
                context("results in an error if the connection state is") {

                    it("CLOSING") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.closed]

                        let channel = client.channels.get("test")
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                        client.close()
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closing))

                        waitUntil(timeout: testTimeout) { done in
                            channel.detach { error in
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }

                    it("FAILED") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                        client.onError(AblyTests.newErrorProtocolMessage())
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.failed))
                        waitUntil(timeout: testTimeout) { done in
                            channel.detach { error in
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }

                }

                // RTL5h
                context("happens when channel is ATTACHED if connection is currently") {
                    it("INITIALIZED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        waitUntil(timeout: testTimeout) { done in
                            channel.attach()
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.initialized))

                            channel.detach { error in
                                expect(error).to(beNil())
                                done()
                            }

                            client.connect()
                        }
                    }

                    it("CONNECTING") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            client.connect()
                            channel.attach()
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connecting))
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))

                            channel.detach { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }
                    }

                    it("DISCONNECTED") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 0.1
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            client.onDisconnected()
                            channel.attach()
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.disconnected))
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))

                            channel.detach { error in
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                                expect(error).to(beNil())
                                done()
                            }
                        }
                    }
                }

                // RTL5j
                it("if the channel state is SUSPENDED, the @detach@ request transitions the channel immediately to the DETACHED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    channel.setSuspended(ARTStatus.state(.ok))
                    expect(channel.state).to(equal(ARTRealtimeChannelState.suspended))

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.once(.detached) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(stateChange.current).to(equal(ARTRealtimeChannelState.detached))
                            expect(stateChange.previous).to(equal(ARTRealtimeChannelState.suspended))
                            partialDone()
                        }
                        channel.detach() { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    expect(channel.state).to(equal(ARTRealtimeChannelState.detached))
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
                    restChannel.testSuite_getReturnValue(from: NSSelectorFromString("encodeMessageIfNeeded:error:")) { value in
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
                    expect(realtimeChannel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    var realtimeEncodedMessage: ARTMessage?
                    realtimeChannel.testSuite_getReturnValue(from: NSSelectorFromString("encodeMessageIfNeeded:error:")) { value in
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
                        defer { client.dispose(); client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .connected {
                                    let channel = client.channels.get("test")
                                    channel.on { stateChange in
                                        guard let stateChange = stateChange else {
                                            fail("ChannelStageChange is nil"); done(); return
                                        }
                                        if stateChange.current == .attached {
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
                        let options = AblyTests.commonAppSetup()
                        options.token = getTestToken(key: options.key, capability: "{ \"\(ARTChannels_getChannelNamePrefix!())-test\":[\"subscribe\"] }")
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .connected {
                                    let channel = client.channels.get("test")
                                    channel.on { stateChange in
                                        guard let stateChange = stateChange else {
                                            fail("ChannelStageChange is nil"); done(); return
                                        }
                                        if stateChange.current == .attached {
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
                        fileprivate init() {}
                    }

                    it("for all messages published") {
                        let options = AblyTests.commonAppSetup()
                        options.token = getTestToken(key: options.key, capability: "{ \"\(ARTChannels_getChannelNamePrefix!())-channelToSucceed\":[\"subscribe\", \"publish\"], \"\(ARTChannels_getChannelNamePrefix!())-channelToFail\":[\"subscribe\"] }")
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        TotalMessages.succeeded = 0
                        TotalMessages.failed = 0

                        let channelToSucceed = client.channels.get("channelToSucceed")
                        channelToSucceed.on { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStageChange is nil"); return
                            }
                            if stateChange.current == .attached {
                                for index in 1...TotalMessages.expected {
                                    channelToSucceed.publish(nil, data: "message\(index)") { errorInfo in
                                        if errorInfo == nil {
                                            TotalMessages.succeeded += 1
                                            expect(index).to(equal(TotalMessages.succeeded), description: "Callback was invoked with an invalid sequence")
                                        }
                                    }
                                }
                            }
                        }
                        channelToSucceed.attach()

                        let channelToFail = client.channels.get("channelToFail")
                        channelToFail.on { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStageChange is nil"); return
                            }
                            if stateChange.current == .attached {
                                for index in 1...TotalMessages.expected {
                                    channelToFail.publish(nil, data: "message\(index)") { errorInfo in
                                        if errorInfo != nil {
                                            TotalMessages.failed += 1
                                            expect(index).to(equal(TotalMessages.failed), description: "Callback was invoked with an invalid sequence")
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

                // RTL6c
                context("Connection state conditions") {

                    // RTL6c1
                    it("if the connection is CONNECTED and the channel is ATTACHED then the messages should be published immediately") {
                        let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        channel.attach()

                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: "message") { error in
                                expect(error).to(beNil())
                                done()
                            }
                            expect((client.transport as! TestProxyTransport).protocolMessagesSent.filter({ $0.action == .message })).to(haveCount(1))
                        }
                    }

                    // RTL6c2
                    context("the message should be queued and delivered as soon as the connection state returns to CONNECTED if the connection is") {
                        let options = AblyTests.commonAppSetup()
                        options.useTokenAuth = true
                        options.disconnectedRetryTimeout = 0.3
                        options.autoConnect = false
                        var client: ARTRealtime!
                        var channel: ARTRealtimeChannel!

                        beforeEach {
                            client = ARTRealtime(options: options)
                            channel = client.channels.get("test")
                            expect(client.options.queueMessages).to(beTrue())
                        }
                        afterEach { client.close() }

                        func publish(_ done: @escaping () -> ()) {
                            channel.publish(nil, data: "message") { error in
                                expect(error).to(beNil())
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                                done()
                            }
                        }

                        it("INITIALIZED") {
                            waitUntil(timeout: testTimeout) { done in
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.initialized))
                                publish(done)
                                client.connect()
                                expect(channel.queuedMessages).to(haveCount(1))
                            }
                        }

                        it("CONNECTING") {
                            waitUntil(timeout: testTimeout) { done in
                                client.connect()
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connecting))
                                publish(done)
                                expect(channel.queuedMessages).to(haveCount(1))
                            }
                        }

                        it("DISCONNECTED") {
                            client.connect()
                            expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                            client.onDisconnected()

                            waitUntil(timeout: testTimeout) { done in
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.disconnected))
                                publish(done)
                                expect(channel.queuedMessages).to(haveCount(1))
                            }
                        }

                        it("ATTACHING") {
                            client.connect()
                            expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                            waitUntil(timeout: testTimeout) { done in
                                channel.attach()
                                expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                                publish(done)
                                expect(channel.queuedMessages).to(haveCount(1))
                            }
                        }

                        it("ATTACHED") {
                            waitUntil(timeout: testTimeout) { done in
                                channel.attach() { error in
                                    expect(error).to(beNil())
                                    done()
                                }
                                client.connect()
                            }

                            waitUntil(timeout: testTimeout) { done in
                                let tokenParams = ARTTokenParams()
                                tokenParams.ttl = 5.0
                                client.auth.authorize(tokenParams, options: nil) { tokenDetails, error in
                                    expect(error).to(beNil())
                                    expect(tokenDetails).toNot(beNil())
                                    done()
                                }
                            }

                            waitUntil(timeout: testTimeout) { done in
                                client.connection.once(.disconnected) { _ in
                                    done()
                                }
                            }

                            expect(channel.state).to(equal(ARTRealtimeChannelState.attached))

                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                                expect(channel.queuedMessages).to(haveCount(1))
                            }
                        }
                    }

                    // RTL6c3
                    it("implicitly attaches the channel; if the channel is in or moves to the FAILED state before the operation succeeds, it should result in an error") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        waitUntil(timeout: testTimeout) { done in
                            let protocolError = AblyTests.newErrorProtocolMessage()
                            expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))
                            channel.publish(nil, data: "message") { error in
                                expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                                expect(error).to(beIdenticalTo(protocolError.error))

                                channel.publish(nil, data: "message") { error in
                                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                                    expect(error).toNot(beNil())
                                    done()
                                }
                            }
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                            channel.onError(protocolError)
                        }
                    }

                    // RTL6c3
                    it("implicitly attaches the channel; if the channel is in or moves to the DETACHED state before the operation succeeds, it should result in an error") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))
                            channel.once(.attached) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                channel.detach()
                                partialDone()
                            }
                            channel.publish(nil, data: "message") { error in
                                guard let error = error else {
                                    fail("Error is nil"); done(); return
                                }
                                expect(error.message).to(contain("invalid channel state"))
                                expect(channel.state).to(equal(ARTRealtimeChannelState.detaching))
                                partialDone()
                            }
                        }
                    }

                    // RTL6c4
                    context("will result in an error if the") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 0.1
                        options.suspendedRetryTimeout = 0.3
                        options.autoConnect = false
                        var client: ARTRealtime!
                        var channel: ARTRealtimeChannel!

                        let previousConnectionStateTtl = ARTDefault.connectionStateTtl()

                        beforeEach {
                            ARTDefault.setConnectionStateTtl(0.3)
                            client = AblyTests.newRealtime(options)
                            channel = client.channels.get("test")
                        }
                        afterEach {
                            client.close()
                            ARTDefault.setConnectionStateTtl(previousConnectionStateTtl)
                        }

                        func publish(_ done: @escaping () -> ()) {
                            channel.publish(nil, data: "message") { error in
                                expect(error).toNot(beNil())
                                done()
                            }
                        }

                        it("connection is SUSPENDED") {
                            client.connect()
                            expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                            client.onSuspended()
                            expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.suspended), timeout: testTimeout)
                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                            }
                        }

                        it("connection is CLOSING") {
                            client.connect()
                            expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                            client.close()
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closing))
                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                            }
                        }

                        it("connection is CLOSED") {
                            client.connect()
                            expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                            client.close()
                            expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.closed), timeout: testTimeout)
                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                            }
                        }

                        it("connection is FAILED") {
                            client.connect()
                            expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                            client.onError(AblyTests.newErrorProtocolMessage())
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.failed))
                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                            }
                        }

                        it("channel is DETACHING") {
                            client.connect()
                            channel.attach()
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                            channel.detach()
                            expect(channel.state).to(equal(ARTRealtimeChannelState.detaching))
                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                            }
                        }

                        it("channel is DETACHED") {
                            client.connect()
                            channel.attach()
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                            channel.detach()
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)
                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                            }
                        }

                        it("channel is SUSPENDED") {
                            client.connect()
                            channel.attach()
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                            channel.setSuspended(ARTStatus.state(.ok))
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.suspended), timeout: testTimeout)
                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                            }
                        }

                        it("channel is FAILED") {
                            client.connect()
                            channel.attach()
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                            let protocolError = AblyTests.newErrorProtocolMessage()
                            channel.onError(protocolError)
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.failed), timeout: testTimeout)
                            waitUntil(timeout: testTimeout) { done in
                                publish(done)
                            }
                        }
                    }
                }

                // RTL6d
                it("Messages are delivered using a single ProtocolMessage where possible by bundling in all messages for that channel") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    // Test that the initially queued messages are sent together.

                    let messagesSent = 3
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(messagesSent, done: done)
                        for i in 1...messagesSent {
                            channel.publish("initial", data: "message\(i)") { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                        client.connect()
                    }

                    let transport = client.transport as! TestProxyTransport
                    let protocolMessages = transport.protocolMessagesSent.filter{ $0.action == .message }
                    expect(protocolMessages).to(haveCount(1))
                    if protocolMessages.count != 1 {
                        return
                    }
                    expect(protocolMessages[0].messages).to(haveCount(messagesSent))

                    // Test that publishing an array of messages sends them together. 

                    // TODO: limit the total number of messages bundled per ProtocolMessage
                    let maxMessages = 50

                    var messages = [ARTMessage]()
                    for i in 1...maxMessages {
                        messages.append(ARTMessage(name: "total number of messages", data: "message\(i)"))
                    }
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { error in
                            expect(error).to(beNil())
                            let transport = client.transport as! TestProxyTransport
                            let protocolMessages = transport.protocolMessagesSent.filter{ $0.action == .message }
                            expect(protocolMessages).to(haveCount(2))
                            if protocolMessages.count != 2 {
                                done(); return
                            }
                            expect(protocolMessages[1].messages).to(haveCount(maxMessages))
                            done()
                        }
                    }
                }

                // RTL6e
                context("Unidentified clients using Basic Auth") {

                    // RTL6e1
                    it("should have the provided clientId on received message when it was published with clientId") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }

                        expect(client.auth.clientId).to(beNil())

                        let channel = client.channels.get("test")

                        var resultClientId: String?

                        let message = ARTMessage(name: nil, data: "message")
                        message.clientId = "client_string"

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.subscribe() { message in
                                resultClientId = message.clientId
                                partialDone()
                            }
                            channel.publish([message]) { errorInfo in
                                expect(errorInfo).to(beNil())
                                partialDone()
                            }
                        }

                        expect(resultClientId).toEventually(equal(message.clientId), timeout: testTimeout)
                    }

                }

                // RTL6f
                it("Message#connectionId should match the current Connection#id for all published messages") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.subscribe() { message in
                            expect(message.connectionId).to(equal(client.connection.id))
                            done()
                        }
                        channel.publish(nil, data: "message")
                    }
                }

                // RTL6i
                context("expect either") {

                    it("an array of Message objects") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        typealias JSONObject = NSDictionary

                        var result = [JSONObject]()
                        channel.subscribe { message in
                            result.append(message.data as! JSONObject)
                        }

                        let messages = [ARTMessage(name: nil, data: ["key":1]), ARTMessage(name: nil, data: ["key":2])]
                        channel.publish(messages)

                        let transport = client.transport as! TestProxyTransport

                        expect(transport.protocolMessagesSent.filter{ $0.action == .message }).toEventually(haveCount(1), timeout: testTimeout)
                        expect(result).toEventually(equal(messages.map{ $0.data as! JSONObject }), timeout: testTimeout)
                    }

                    it("a name string and data payload") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        let expectedResult = "string_data"
                        var result: String?

                        channel.subscribe("event") { message in
                            result = message.data as? String
                        }

                        channel.publish("event", data: expectedResult, callback: nil)

                        expect(result).toEventually(equal(expectedResult), timeout: testTimeout)
                    }

                    it("allows name to be null") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        let expectedObject = ["data": "message", "connectionId": client.connection.id!]

                        var resultMessage: ARTMessage?
                        channel.subscribe { message in
                            resultMessage = message
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: expectedObject["data"]) { errorInfo in
                                expect(errorInfo).to(beNil())
                                done()
                            }
                        }

                        let transport = client.transport as! TestProxyTransport
                        
                        let rawProtoMsgsSent: [NSDictionary] = transport.rawDataSent.toMsgPackArray()
                        let rawMessagesSent = rawProtoMsgsSent.filter({ $0["action"] as! UInt == ARTProtocolMessageAction.message.rawValue })
                        let messagesList = rawMessagesSent[0]["messages"] as! NSArray
                        let resultObject = messagesList[0] as! [String: String]

                        expect(resultObject).to(equal(expectedObject))

                        expect(resultMessage).toNotEventually(beNil(), timeout: testTimeout)
                        expect(resultMessage!.name).to(beNil())
                        expect(resultMessage!.data as? String).to(equal(expectedObject["data"]))
                    }

                    it("allows data to be null") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        let expectedObject = ["name": "click", "connectionId": client.connection.id!]

                        var resultMessage: ARTMessage?
                        channel.subscribe(expectedObject["name"]!) { message in
                            resultMessage = message
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(expectedObject["name"], data: nil) { errorInfo in
                                expect(errorInfo).to(beNil())
                                done()
                            }
                        }

                        let transport = client.transport as! TestProxyTransport

                        let rawProtoMsgsSent: [NSDictionary] = transport.rawDataSent.toMsgPackArray()
                        let rawMessagesSent = rawProtoMsgsSent.filter({ $0["action"] as! UInt == ARTProtocolMessageAction.message.rawValue })
                        let messagesList = rawMessagesSent[0]["messages"] as! NSArray
                        let resultObject = messagesList[0] as! NSDictionary

                        expect(resultObject).to(equal(expectedObject as NSDictionary))

                        expect(resultMessage).toNotEventually(beNil(), timeout: testTimeout)
                        expect(resultMessage!.name).to(equal(expectedObject["name"]))
                        expect(resultMessage!.data).to(beNil())
                    }

                    it("allows name and data to be assigned") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        let expectedObject = ["name": "click", "data": "message", "connectionId": client.connection.id!]

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(expectedObject["name"], data: expectedObject["data"]) { errorInfo in
                                expect(errorInfo).to(beNil())
                                done()
                            }
                        }

                        let transport = client.transport as! TestProxyTransport

                        let rawProtoMsgsSent: [NSDictionary] = transport.rawDataSent.toMsgPackArray()
                        let rawMessagesSent = rawProtoMsgsSent.filter({ $0["action"] as! UInt == ARTProtocolMessageAction.message.rawValue })
                        let messagesList = rawMessagesSent[0]["messages"] as! NSArray
                        let resultObject = messagesList[0] as! NSDictionary

                        expect(resultObject).to(equal(expectedObject as NSDictionary))
                    }

                }

                // RTL6g
                context("Identified clients with clientId") {

                    // RTL6g1
                    context("When publishing a Message with clientId set to null") {

                        // RTL6g1a & RTL6g1b
                        it("should be unnecessary to set clientId of the Message before publishing and have clientId value set for the Message when received") {
                            let options = AblyTests.commonAppSetup()
                            options.clientId = "client_string"
                            options.autoConnect = false
                            let client = ARTRealtime(options: options)
                            client.setTransport(TestProxyTransport.self)
                            client.connect()
                            defer { client.dispose(); client.close() }
                            let channel = client.channels.get("test")

                            let message = ARTMessage(name: nil, data: "message")
                            expect(message.clientId).to(beNil())

                            waitUntil(timeout: testTimeout) { done in
                                channel.subscribe() { message in
                                    expect(message.clientId).to(equal(options.clientId))
                                    done()
                                }
                                channel.publish([message])
                            }

                            let transport = client.transport as! TestProxyTransport

                            let messageSent = transport.protocolMessagesSent.filter({ $0.action == .message })[0]
                            expect(messageSent.messages![0].clientId).to(beNil())

                            let messageReceived = transport.protocolMessagesReceived.filter({ $0.action == .message })[0]
                            expect(messageReceived.messages![0].clientId).to(equal(options.clientId))
                        }

                    }

                    // RTL6g2
                    it("when publishing a Message with the clientId attribute value set to the identified client’s clientId") {
                        let options = AblyTests.commonAppSetup()
                        options.clientId = "john"
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        let message = ARTMessage(name: nil, data: "message", clientId: options.clientId!)
                        var resultClientId: String?

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.subscribe() { message in
                                resultClientId = message.clientId
                                partialDone()
                            }
                            channel.publish([message]) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }

                        expect(resultClientId).toEventually(equal(message.clientId), timeout: testTimeout)
                    }

                    // RTL6g3
                    it("when publishing a Message with a different clientId attribute value from the identified client’s clientId, it should reject that publish operation immediately") {
                        let options = AblyTests.commonAppSetup()
                        options.clientId = "john"
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([ARTMessage(name: nil, data: "message", clientId: "tester")]) { error in
                                expect(error!.message).to(contain("mismatched clientId"))
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([ARTMessage(name: nil, data: "message")]) { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }
                    }

                    // RTL6g4
                    it("message should be published following authentication and received back with the clientId intact") {
                        let options = AblyTests.clientOptions()
                        options.authCallback = { tokenParams, completion in
                            getTestTokenDetails(clientId: "john", completion: completion)
                        }
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        let message = ARTMessage(name: nil, data: "message", clientId: "john")
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.subscribe() { received in
                                expect(received.clientId).to(equal(message.clientId))
                                partialDone()
                            }
                            channel.publish([message]) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }

                    // RTL6g4
                    it("message should be rejected by the Ably service and the message error should contain the server error") {
                        let options = AblyTests.clientOptions()
                        options.authCallback = { tokenParams, completion in
                            getTestTokenDetails(clientId: "john", completion: completion)
                        }
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        let message = ARTMessage(name: nil, data: "message", clientId: "tester")
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([message]) { error in
                                expect(error!.code).to(equal(40012))
                                expect(error!.message).to(contain("mismatched clientId"))
                                done()
                            }
                        }
                    }

                }

                // RTL6h
                it("should provide an optional argument that allows the clientId value to be specified") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.subscribe { message in
                            expect(message.name).to(equal("event"))
                            expect(message.data as? NSObject).to(equal("data" as NSObject?))
                            expect(message.clientId).to(equal("foo"))
                            partialDone()
                        }
                        channel.publish("event", data: "data", clientId: "foo") { errorInfo in
                            expect(errorInfo).to(beNil())
                            partialDone()
                        }
                    }
                }


            }

            // RTL7
            context("subscribe") {

                // RTL7a
                it("with no arguments subscribes a listener to all messages") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    class Test {
                        static var counter = 0
                        fileprivate init() {}
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
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    class Test {
                        static var counter = 0
                        fileprivate init() {}
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

                it("with a attach callback should subscribe and call the callback when attached") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    let publishedMessage = ARTMessage(name: "foo", data: "bar")

                    waitUntil(timeout: testTimeout) { done in
                        expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))

                        channel.subscribe(attachCallback: { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                            channel.publish([publishedMessage])
                        }) { message in
                            expect(message.name).to(equal(publishedMessage.name))
                            expect(message.data as? NSObject).to(equal(publishedMessage.data as? NSObject))
                            done()
                        }

                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    }
                }

                // RTL7c
                it("should implicitly attach the channel") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    channel.subscribe { _ in }

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                }

                // RTL7c
                it("should result in an error if channel is in the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    channel.onError(AblyTests.newErrorProtocolMessage())
                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))

                    waitUntil(timeout: testTimeout) { done in
                        channel.subscribe(attachCallback: { errorInfo in
                            expect(errorInfo).toNot(beNil())

                            channel.subscribe("foo", onAttach: { errorInfo in
                                expect(errorInfo).toNot(beNil())
                                done()
                            }) { _ in }
                        }) { _ in }
                    }
                }

                // RTL7d
                context("should deliver the message even if there is an error while decoding") {

                    for cryptoTest in [CryptoTest.aes128, CryptoTest.aes256] {
                        it("using \(cryptoTest) ") {
                            let options = AblyTests.commonAppSetup()
                            options.autoConnect = false
                            options.logHandler = ARTLog(capturingOutput: true)
                            let client = ARTRealtime(options: options)
                            client.setTransport(TestProxyTransport.self)
                            client.connect()
                            defer { client.dispose(); client.close() }

                            let (keyData, ivData, messages) = AblyTests.loadCryptoTestData(cryptoTest)
                            let testMessage = messages[0]

                            let cipherParams = ARTCipherParams(algorithm: "aes", key: keyData as ARTCipherKeyCompatible, iv: ivData)
                            let channelOptions = ARTChannelOptions(cipher: cipherParams)
                            let channel = client.channels.get("test", options: channelOptions)

                            let transport = client.transport as! TestProxyTransport

                            transport.beforeProcessingSentMessage = { protocolMessage in
                                if protocolMessage.action == .message {
                                    expect(protocolMessage.messages![0].data as? String).to(equal(testMessage.encrypted.data))
                                    expect(protocolMessage.messages![0].encoding).to(equal(testMessage.encrypted.encoding))
                                }
                            }

                            transport.beforeProcessingReceivedMessage = { protocolMessage in
                                if protocolMessage.action == .message {
                                    expect(protocolMessage.messages![0].data as? NSObject).to(equal(AblyTests.base64ToData(testMessage.encrypted.data) as NSObject?))
                                    expect(protocolMessage.messages![0].encoding).to(equal("utf-8/cipher+aes-\(cryptoTest == CryptoTest.aes128 ? "128" : "256")-cbc"))
                                    // Force an error decoding a message
                                    protocolMessage.messages![0].encoding = "bad_encoding_type"
                                }
                            }

                            waitUntil(timeout: testTimeout) { done in
                                let partlyDone = AblyTests.splitDone(2, done: done)

                                channel.subscribe(testMessage.encoded.name) { message in
                                    expect(message.data as? NSObject).to(equal(AblyTests.base64ToData(testMessage.encrypted.data) as NSObject?))

                                    let logs = options.logHandler.captured
                                    let line = logs.reduce("") { $0 + "; " + $1.toString() } //Reduce in one line

                                    expect(line).to(contain("Failed to decode data: unknown encoding: 'bad_encoding_type'"))

                                    partlyDone()
                                }

                                channel.on(.update) { stateChange in
                                    guard let error = stateChange?.reason else {
                                        return
                                    }
                                    expect(error.message).to(contain("Failed to decode data: unknown encoding: 'bad_encoding_type'"))
                                    expect(error).to(beIdenticalTo(channel.errorReason))
                                    partlyDone()
                                }

                                channel.publish(testMessage.encoded.name, data: testMessage.encoded.data)
                            }
                        }
                    }

                }

                context("message cannot be decoded or decrypted") {

                    // RTL7e
                    it("should deliver with encoding attribute set indicating the residual encoding and error should be emitted") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.logHandler = ARTLog(capturingOutput: true)
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        let channelOptions = ARTChannelOptions(cipher: ["key":ARTCrypto.generateRandomKey()] as ARTCipherParamsCompatible)
                        let channel = client.channels.get("test", options: channelOptions)

                        let expectedMessage = ["key":1]
                        let expectedData = try! JSONSerialization.data(withJSONObject: expectedMessage, options: JSONSerialization.WritingOptions(rawValue: 0))

                        let transport = client.transport as! TestProxyTransport

                        transport.beforeProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .message {
                                let messageReceived = protocolMessage.messages![0]
                                // Replacement: `json/utf-8/cipher+aes-256-cbc/base64` to `invalid/cipher+aes-256-cbc/base64`
                                let newEncoding = "invalid" + messageReceived.encoding!.substring(from: "json/utf-8".endIndex)
                                messageReceived.encoding = newEncoding
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.subscribe { message in
                                // Last decoding failed: NSData -> JSON object, so...
                                expect(message.data as? NSData).to(equal(expectedData as NSData?))
                                expect(message.encoding).to(equal("invalid"))

                                let logs = options.logHandler.captured
                                let line = logs.reduce("") { $0 + "; " + $1.toString() } //Reduce in one line
                                expect(line).to(contain("Failed to decode data: unknown encoding: 'invalid'"))

                                expect(channel.errorReason!.message).to(contain("Failed to decode data: unknown encoding: 'invalid'"))

                                done()
                            }
                            
                            channel.publish(nil, data: expectedMessage)
                        }
                    }
                    
                }

                // RTL7f
                it("should exist ensuring published messages are not echoed back to the subscriber when echoMessages is false") {
                    let options = AblyTests.commonAppSetup()
                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }

                    options.echoMessages = false
                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }

                    let channel1 = client1.channels.get("test")
                    let channel2 = client2.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel1.attach { err in
                            expect(err).to(beNil())
                            channel1.subscribe { message in
                                expect(message.data as? String).to(equal("message"))
                                delay(1.0) { done() }
                            }

                            channel2.subscribe { message in
                                fail("Shouldn't receive the message")
                            }

                            channel2.publish(nil, data: "message")
                        }
                    }
                }

            }

            // RTL8
            context("unsubscribe") {

                // RTL8a
                it("with no arguments unsubscribes the provided listener to all messages if subscribed") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let listener = channel.subscribe { message in
                            fail("Listener shouldn't exist")
                            done()
                        }

                        channel.unsubscribe(listener)

                        channel.publish(nil, data: "message") { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }
                }

                // RTL8b
                it("with a single name argument unsubscribes the provided listener if previously subscribed with a name-specific subscription") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let eventAListener = channel.subscribe("eventA") { message in
                            fail("Listener shouldn't exist")
                            done()
                        }

                        channel.unsubscribe("eventA", listener: eventAListener)

                        channel.publish("eventA", data: "message") { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }
                }

            }

            // RTL10
            context("history") {
                // RTL10a 
                it("should support all the same params as Rest") {
                    let options = AblyTests.commonAppSetup()

                    let rest = ARTRest(options: options)

                    let realtime = ARTRealtime(options: options)
                    defer { realtime.close() }

                    var restChannelHistoryMethodWasCalled = false
                    let hook = ARTRestChannel.testSuite_injectIntoClassMethod(#selector(ARTRestChannel.history(_:callback:))) {
                        restChannelHistoryMethodWasCalled = true
                    }
                    defer { hook?.remove() }

                    let channelRest = rest.channels.get("test")
                    let channelRealtime = realtime.channels.get("test")

                    let queryRealtime = ARTRealtimeHistoryQuery()
                    queryRealtime.start = NSDate() as Date
                    queryRealtime.end = NSDate() as Date
                    queryRealtime.direction = .forwards
                    queryRealtime.limit = 50

                    let queryRest = queryRealtime as ARTDataQuery

                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try channelRest.history(queryRest) { _, _ in
                                done()
                            }
                        }.toNot(throwError() { err in fail("\(err)"); done() })
                    }
                    expect(restChannelHistoryMethodWasCalled).to(beTrue())
                    restChannelHistoryMethodWasCalled = false

                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try channelRealtime.history(queryRealtime) { _, _ in
                                done()
                            }
                        }.toNot(throwError() { err in fail("\(err)"); done() })
                    }
                    expect(restChannelHistoryMethodWasCalled).to(beTrue())
                }

                // RTL10b
                context("supports the param untilAttach") {

                    it("should be false as default") {
                        let query = ARTRealtimeHistoryQuery()
                        expect(query.untilAttach).to(equal(false))
                    }

                    it("should invoke an error when the untilAttach is specified and the channel is not attached") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        let query = ARTRealtimeHistoryQuery()
                        query.untilAttach = true

                        do {
                            try channel.history(query, callback: { _, _ in })
                        }
                        catch let error as NSError {
                            if error.code != ARTRealtimeHistoryError.notAttached.rawValue {
                                fail("Shouldn't raise a global error, got \(error)")
                            }
                            return
                        }
                        fail("Should raise an error")
                    }

                    struct CaseTest {
                        let untilAttach: Bool
                    }

                    let cases = [CaseTest(untilAttach: true), CaseTest(untilAttach: false)]

                    for caseItem in cases {
                        it("where value is \(caseItem.untilAttach), should pass the querystring param fromSerial with the serial number assigned to the channel") {
                            let options = AblyTests.commonAppSetup()
                            let client = ARTRealtime(options: options)
                            defer { client.dispose(); client.close() }
                            let channel = client.channels.get("test")

                            let testHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
                            client.rest.httpExecutor = testHTTPExecutor

                            let query = ARTRealtimeHistoryQuery()
                            query.untilAttach = caseItem.untilAttach

                            channel.attach()
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                            waitUntil(timeout: testTimeout) { done in
                                expect {
                                    try channel.history(query) { _, errorInfo in
                                        expect(errorInfo).to(beNil())
                                        done()
                                    }
                                }.toNot(throwError() { err in fail("\(err)"); done() })
                            }

                            let queryString = testHTTPExecutor.requests.last!.url!.query

                            if query.untilAttach {
                                expect(queryString).to(contain("fromSerial=\(channel.attachSerial!)"))
                            }
                            else {
                                expect(queryString).toNot(contain("fromSerial"))
                            }
                        }
                    }

                    it("should retrieve messages prior to the moment that the channel was attached") {
                        let options = AblyTests.commonAppSetup()
                        let client1 = ARTRealtime(options: options)
                        defer { client1.close() }

                        options.autoConnect = false
                        let client2 = ARTRealtime(options: options)
                        defer { client2.close() }

                        let channel1 = client1.channels.get("test")
                        channel1.attach()
                        expect(channel1.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                        var messages = [ARTMessage]()
                        for i in 0..<20 {
                            messages.append(ARTMessage(name: nil, data: "message \(i)"))
                        }
                        waitUntil(timeout: testTimeout) { done in
                            channel1.publish(messages) { errorInfo in
                                expect(errorInfo).to(beNil())
                                done()
                            }
                        }

                        client2.connect()
                        let channel2 = client2.channels.get("test")
                        channel2.attach()
                        expect(channel2.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                        var counter = 20
                        channel2.subscribe { message in
                            expect(message.data as? String).to(equal("message \(counter)"))
                            counter += 1
                        }

                        messages = [ARTMessage]()
                        for i in 20..<40 {
                            messages.append(ARTMessage(name: nil, data: "message \(i)"))
                        }
                        waitUntil(timeout: testTimeout) { done in
                            channel1.publish(messages) { errorInfo in
                                expect(errorInfo).to(beNil())
                                done()
                            }
                        }

                        let query = ARTRealtimeHistoryQuery()
                        query.untilAttach = true

                        waitUntil(timeout: testTimeout) { done in
                            expect {
                                try channel2.history(query) { result, errorInfo in
                                    expect(result!.items).to(haveCount(20))
                                    expect(result!.hasNext).to(beFalse())
                                    expect(result!.items.first?.data as? String).to(equal("message 19"))
                                    expect(result!.items.last?.data as? String).to(equal("message 0"))
                                    done()
                                }
                            }.toNot(throwError() { err in fail("\(err)"); done() })
                        }
                    }

                }

                // RTL10c
                it("should return a PaginatedResult page") {
                    let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { realtime.close() }
                    let channel = realtime.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.history { result, _ in
                            expect(result).to(beAKindOf(ARTPaginatedResult<ARTMessage>.self))
                            expect(result!.items).to(haveCount(1))
                            expect(result!.hasNext).to(beFalse())
                            let messages = result!.items 
                            expect(messages[0].data as? String).to(equal("message"))
                            done()
                        }
                    }
                }

                // RTL10d
                it("should retrieve all available messages") {
                    let options = AblyTests.commonAppSetup()
                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }

                    let channel1 = client1.channels.get("test")
                    channel1.attach()
                    expect(channel1.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    var messages = [ARTMessage]()
                    for i in 0..<20 {
                        messages.append(ARTMessage(name: nil, data: "message \(i)"))
                    }
                    waitUntil(timeout: testTimeout) { done in
                        channel1.publish(messages) { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }

                    let channel2 = client2.channels.get("test")
                    channel2.attach()
                    expect(channel2.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    let query = ARTRealtimeHistoryQuery()
                    query.limit = 10

                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try channel2.history(query) { result, errorInfo in
                                expect(result!.items).to(haveCount(10))
                                expect(result!.hasNext).to(beTrue())
                                expect(result!.isLast).to(beFalse())
                                expect((result!.items.first! ).data as? String).to(equal("message 19"))
                                expect((result!.items.last! ).data as? String).to(equal("message 10"))

                                result!.next { result, errorInfo in
                                    expect(result!.items).to(haveCount(10))
                                    expect(result!.hasNext).to(beFalse())
                                    expect(result!.isLast).to(beTrue())
                                    expect((result!.items.first! ).data as? String).to(equal("message 9"))
                                    expect((result!.items.last! ).data as? String).to(equal("message 0"))
                                    done()
                                }
                            }
                        }.toNot(throwError() { err in fail("\(err)"); done() })
                    }
                }

                // RTL12
                it("attached channel may receive an additional ATTACHED ProtocolMessage") {
                    let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    channel.on(.attached) { _ in
                        fail("Should not be called")
                    }
                    defer {
                        channel.off()
                    }

                    var hook: AspectToken?
                    waitUntil(timeout: testTimeout) { done in
                        let attachedMessage = ARTProtocolMessage()
                        attachedMessage.action = .attached
                        attachedMessage.channel = channel.name

                        hook = channel.testSuite_injectIntoMethod(after: #selector(channel.onChannelMessage(_:))) {
                            done()
                        }

                        // Inject additional ATTACHED action without an error
                        client.transport?.receive(attachedMessage)
                    }
                    hook!.remove()
                    expect(channel.errorReason).to(beNil())
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attached))

                    waitUntil(timeout: testTimeout) { done in
                        let attachedMessageWithError = AblyTests.newErrorProtocolMessage()
                        attachedMessageWithError.action = .attached
                        attachedMessageWithError.channel = channel.name

                        channel.once(.update) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ChannelStateChange is nil"); done(); return
                            }
                            expect(stateChange.event).to(equal(ARTChannelEvent.update))
                            expect(stateChange.reason).to(beIdenticalTo(attachedMessageWithError.error))
                            expect(channel.errorReason).to(beIdenticalTo(stateChange.reason))
                            done()
                        }

                        // Inject additional ATTACHED action with an error
                        client.transport?.receive(attachedMessageWithError)
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                }

                // RTL13
                context("if the channel receives a server initiated DETACHED message when") {

                    // RTL13a
                    it("the channel is in the ATTACHED states, an attempt to reattach the channel should be made immediately by sending a new ATTACH message and the channel should transition to the ATTACHING state with the error emitted in the ChannelStateChange event") {
                        let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        expect(channel.state).to(equal(ARTRealtimeChannelState.attached))

                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let detachedMessageWithError = AblyTests.newErrorProtocolMessage()
                            detachedMessageWithError.action = .detached
                            detachedMessageWithError.channel = channel.name

                            channel.once(.attaching) { stateChange in
                                guard let error = stateChange?.reason  else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error).to(beIdenticalTo(detachedMessageWithError.error))
                                expect(channel.errorReason).to(beNil())
                                done()
                            }

                            transport.receive(detachedMessageWithError)
                        }

                        expect(transport.protocolMessagesSent.filter{ $0.action == .attach }).to(haveCount(2))
                    }

                    // RTL13a
                    it("the channel is in the SUSPENDED state, an attempt to reattach the channel should be made immediately by sending a new ATTACH message and the channel should transition to the ATTACHING state with the error emitted in the ChannelStateChange event") {
                        let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.connected) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                done()
                            }
                        }

                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                        defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                        ARTDefault.setRealtimeRequestTimeout(1.0)

                        // Timeout
                        transport.actionsIgnored += [.attached]

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.suspended) { stateChange in
                                expect(stateChange?.reason?.message).to(contain("timed out"))
                                done()
                            }
                            channel.attach()
                        }

                        transport.actionsIgnored = []

                        waitUntil(timeout: testTimeout) { done in
                            let detachedMessageWithError = AblyTests.newErrorProtocolMessage()
                            detachedMessageWithError.action = .detached
                            detachedMessageWithError.channel = channel.name

                            channel.once(.attaching) { stateChange in
                                guard let error = stateChange?.reason  else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error).to(beIdenticalTo(detachedMessageWithError.error))
                                expect(channel.errorReason).to(beNil())
                                done()
                            }

                            transport.receive(detachedMessageWithError)
                        }
                        
                        expect(transport.protocolMessagesSent.filter{ $0.action == .attach }).to(haveCount(2))
                    }

                    // RTL13b
                    it("if the attempt to re-attach fails the channel will transition to the SUSPENDED state and the error will be emitted in the ChannelStateChange event") {
                        let options = AblyTests.commonAppSetup()
                        options.channelRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                        defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                        ARTDefault.setRealtimeRequestTimeout(1.0)
                        transport.actionsIgnored = [.attached]

                        let detachedMessageWithError = AblyTests.newErrorProtocolMessage()
                        detachedMessageWithError.action = .detached
                        detachedMessageWithError.channel = channel.name

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.attaching) { stateChange in
                                guard let error = stateChange?.reason  else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error).to(beIdenticalTo(detachedMessageWithError.error))
                                expect(channel.errorReason).to(beNil())
                                done()
                            }

                            transport.receive(detachedMessageWithError)
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.suspended) { stateChange in
                                guard let error = stateChange?.reason  else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error.message).to(contain("timed out"))
                                expect(channel.errorReason).to(beIdenticalTo(error))
                                done()
                            }
                        }

                        let start = NSDate()
                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.attaching) { _ in
                                let end = NSDate()
                                expect(start.addingTimeInterval(options.channelRetryTimeout)).to(beCloseTo(end, within: 0.5))
                                done()
                            }
                        }
                    }

                    // RTL13b
                    it("if the channel was already in the ATTACHING state, the channel will transition to the SUSPENDED state and the error will be emitted in the ChannelStateChange event") {
                        let options = AblyTests.commonAppSetup()
                        options.channelRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")

                        let detachedMessageWithError = AblyTests.newErrorProtocolMessage()
                        detachedMessageWithError.action = .detached
                        detachedMessageWithError.channel = channel.name

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.once(.attaching) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                client.transport?.receive(detachedMessageWithError)
                                partialDone()
                            }
                            channel.once(.suspended) { stateChange in
                                guard let error = stateChange?.reason  else {
                                    fail("Reason error is nil"); partialDone(); return
                                }
                                expect(error).to(beIdenticalTo(detachedMessageWithError.error))
                                expect(channel.errorReason).to(beNil())

                                // Check retry
                                let start = NSDate()
                                channel.once(.attaching) { stateChange in
                                    let end = NSDate()
                                    expect(start).to(beCloseTo(end, within: 0.5))
                                    expect(stateChange?.reason).to(beNil())
                                    partialDone()
                                }
                            }
                            channel.attach()
                        }
                    }

                    // RTL13c
                    it("if the connection is no longer CONNECTED, then the automatic attempts to re-attach the channel must be cancelled") {
                        let options = AblyTests.commonAppSetup()
                        options.channelRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }
                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                        defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                        ARTDefault.setRealtimeRequestTimeout(1.0)

                        transport.actionsIgnored = [.attached]
                        let detachedMessageWithError = AblyTests.newErrorProtocolMessage()
                        detachedMessageWithError.action = .detached
                        detachedMessageWithError.channel = channel.name
                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.attaching) { stateChange in
                                guard let error = stateChange?.reason  else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error).to(beIdenticalTo(detachedMessageWithError.error))
                                expect(channel.errorReason).to(beNil())
                                done()
                            }
                            transport.receive(detachedMessageWithError)
                        }
                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.suspended) { stateChange in
                                guard let error = stateChange?.reason  else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error.message).to(contain("timed out"))
                                expect(channel.errorReason).to(beIdenticalTo(error))
                                done()
                            }
                        }

                        channel.once(.attaching) { _ in
                            fail("Should cancel the re-attach")
                        }

                        client.simulateSuspended(beforeSuspension: { done in
                            channel.once(.suspended) { _ in
                                done()
                            }
                        })
                    }

                }

                // RTL14
                it("If an ERROR ProtocolMessage is received for this channel then the channel should immediately transition to the FAILED state, the errorReason should be set and an error should be emitted on the channel") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let errorProtocolMessage = AblyTests.newErrorProtocolMessage()
                        errorProtocolMessage.action = .error
                        errorProtocolMessage.channel = channel.name

                        channel.once(.failed) { stateChange in
                            guard let error = stateChange?.reason else {
                                fail("Reason error is nil"); done(); return
                            }
                            expect(error).to(beIdenticalTo(errorProtocolMessage.error))
                            expect(channel.errorReason).to(beIdenticalTo(error))
                            done()
                        }

                        client.transport?.receive(errorProtocolMessage)
                    }

                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                }

            }

            context("crypto") {
                it("if configured for encryption, channels encrypt and decrypt messages' data") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false

                    let clientSender = ARTRealtime(options: options)
                    clientSender.setTransport(TestProxyTransport.self)
                    defer { clientSender.close() }
                    clientSender.connect()

                    let clientReceiver = ARTRealtime(options: options)
                    clientReceiver.setTransport(TestProxyTransport.self)
                    defer { clientReceiver.close() }
                    clientReceiver.connect()

                    let key = ARTCrypto.generateRandomKey()
                    let sender = clientSender.channels.get("test", options: ARTChannelOptions(cipherKey: key as ARTCipherKeyCompatible))
                    let receiver = clientReceiver.channels.get("test", options: ARTChannelOptions(cipherKey: key as ARTCipherKeyCompatible))

                    var received = [ARTMessage]()

                    waitUntil(timeout: testTimeout) { done in
                        receiver.attach { _ in
                            receiver.subscribe { message in
                                receiver.unsubscribe()
                                received.append(message)
                                done()
                            }

                            sender.publish("first", data: "first data")
                        }
                    }
                    if received.count != 1 {
                        fail("should have received one message")
                        return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        receiver.detach { _ in
                            sender.publish("second", data: "second data") { _ in done() }
                        }
                    }
                    if receiver.state != .detached {
                        fail("receiver should be detached")
                        return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        receiver.attach { _ in
                            receiver.subscribe { message in
                                received.append(message)
                                done()
                            }
                            sender.publish("third", data: "third data")
                        }
                    }
                    if received.count != 2 {
                        fail("should've received two messages")
                        return
                    }

                    expect(received[0].name).to(equal("first"))
                    expect(received[0].data as? NSString).to(equal("first data"))
                    expect(received[1].name).to(equal("third"))
                    expect(received[1].data as? NSString).to(equal("third data"))

                    let senderTransport = clientSender.transport as! TestProxyTransport
                    let senderMessages = senderTransport.protocolMessagesSent.filter({ $0.action == .message })
                    for protocolMessage in senderMessages {
                        for message in protocolMessage.messages! {
                            expect(message.data! as? String).toNot(equal("\(message.name!) data"))
                            expect(message.encoding).to(equal("utf-8/cipher+aes-256-cbc/base64"))
                        }
                    }

                    let receiverTransport = clientReceiver.transport as! TestProxyTransport
                    let receiverMessages = receiverTransport.protocolMessagesReceived.filter({ $0.action == .message })
                    for protocolMessage in receiverMessages {
                        for message in protocolMessage.messages! {
                            expect(message.data! as? NSObject).toNot(equal("\(message.name!) data" as NSObject?))
                            expect(message.encoding).to(equal("utf-8/cipher+aes-256-cbc"))
                        }
                    }
                }
            }

        }
    }
}
