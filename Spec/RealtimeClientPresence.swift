//
//  RealtimeClientPresence.swift
//  Ably
//
//  Created by Ricardo Pereira on 07/03/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Ably
import Quick
import Nimble
import Foundation

class RealtimeClientPresence: QuickSpec {

    override func setUp() {
        super.setUp()
        AsyncDefaults.Timeout = testTimeout
    }

    override func spec() {
        describe("Presence") {

            // RTP1
            context("ProtocolMessage bit flag") {

                it("when no members are present") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport)
                    client.connect()
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    channel.attach()

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    let transport = client.transport as! TestProxyTransport
                    let attached = transport.protocolMessagesReceived.filter({ $0.action == .Attached })[0]

                    expect(attached.flags & 0x1).to(equal(0))
                    expect(attached.hasPresence).to(beFalse())
                    expect(channel.presence.syncComplete).to(beFalse())
                    expect(channel.presenceMap.syncComplete).to(beFalse())
                }

                it("when members are present") {
                    let options = AblyTests.commonAppSetup()

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.dispose()
                            clientItem.close()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 250, options: options) {
                            done()
                        }]
                    }

                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport)
                    client.connect()
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    channel.attach()

                    expect(channel.presence.syncComplete).to(beFalse())
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    let transport = client.transport as! TestProxyTransport
                    let attached = transport.protocolMessagesReceived.filter({ $0.action == .Attached })[0]

                    // There are members present on the channel
                    expect(attached.flags & 0x1).to(equal(1))
                    expect(attached.hasPresence).to(beTrue())
                    
                    expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)

                    expect(transport.protocolMessagesReceived.filter({ $0.action == .Sync })).to(haveCount(3))
                }

            }

            // RTP3
            it("should complete the SYNC operation when the connection is disconnected unexpectedly") {
                let options = AblyTests.commonAppSetup()
                options.disconnectedRetryTimeout = 1.0
                var clientSecondary: ARTRealtime!
                defer { clientSecondary.dispose(); clientSecondary.close() }

                waitUntil(timeout: testTimeout) { done in
                    clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, options: options) {
                        done()
                    }
                }

                let client = AblyTests.newRealtime(options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")

                var lastSyncSerial: String?
                waitUntil(timeout: testTimeout) { done in
                    channel.attach() { _ in
                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }
                        transport.afterProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .Sync {
                                lastSyncSerial = protocolMessage.channelSerial
                                client.onDisconnected()
                                done()
                            }
                        }
                    }
                }

                expect(channel.presenceMap.members).toNot(haveCount(150))
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connecting), timeout: options.disconnectedRetryTimeout + 1.0)
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                // Client library requests a SYNC resume by sending a SYNC ProtocolMessage with the last received sync serial number
                guard let transport = client.transport as? TestProxyTransport else {
                    fail("TestProxyTransport is not set"); return
                }

                let syncSentProtocolMessages = transport.protocolMessagesSent.filter({ $0.action == .Sync })
                guard let syncSentMessage = syncSentProtocolMessages.last where syncSentProtocolMessages.count == 1 else {
                    fail("Should send one SYNC protocol message"); return
                }
                expect(syncSentMessage.channelSerial).to(equal(lastSyncSerial))

                expect(transport.protocolMessagesReceived.filter{ $0.action == .Sync }).toEventually(haveCount(2), timeout: testTimeout)

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.get { members, error in
                        expect(error).to(beNil())
                        guard let members = members else {
                            fail("No present members"); done(); return
                        }
                        expect(members).to(haveCount(150))
                        done()
                    }
                }
            }

            // RTP18
            context("realtime system reserves the right to initiate a sync of the presence members at any point once a channel is attached") {

                // RTP18a, RTP18b
                it("should do a new sync whenever a SYNC ProtocolMessage is received with a channel attribute and a new sync sequence identifier in the channelSerial attribute") {
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

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    expect(channel.presenceMap.syncInProgress).to(beFalse())
                    expect(channel.presenceMap.members).to(beEmpty())

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.subscribe(.Present) { error in
                            expect(channel.presence.syncComplete).to(beFalse())
                            partialDone()
                        }

                        guard let lastConnectionSerial = transport.protocolMessagesReceived.last?.connectionSerial else {
                            fail("No protocol message has been received yet"); done(); return
                        }

                        // Inject a SYNC Presence message (first page)
                        let sync1Message = ARTProtocolMessage()
                        sync1Message.action = .Sync
                        sync1Message.channel = channel.name
                        sync1Message.channelSerial = "sequenceid:cursor"
                        sync1Message.connectionSerial = lastConnectionSerial + 1
                        sync1Message.timestamp = NSDate()
                        sync1Message.presence = [
                            ARTPresenceMessage(clientId: "a", action: .Present, connectionId: "another", id: "another:0:0"),
                            ARTPresenceMessage(clientId: "b", action: .Present, connectionId: "another", id: "another:0:1"),
                        ]
                        transport.receive(sync1Message)

                        // Inject a SYNC Presence message (last page)
                        let sync2Message = ARTProtocolMessage()
                        sync2Message.action = .Sync
                        sync2Message.channel = channel.name
                        sync2Message.channelSerial = "sequenceid:" //indicates SYNC is complete
                        sync2Message.connectionSerial = lastConnectionSerial + 2
                        sync2Message.timestamp = NSDate()
                        sync2Message.presence = [
                            ARTPresenceMessage(clientId: "a", action: .Leave, connectionId: "another", id: "another:1:0"),
                        ]
                        transport.receive(sync2Message)
                    }

                    expect(channel.presence.syncComplete).to(beTrue())
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members where members.count == 1 else {
                                fail("Should at least have 1 member"); done(); return
                            }
                            expect(members[0].clientId).to(equal("b"))
                            done()
                        }
                    }
                }

                // RTP18c, RTP18b
                it("when a SYNC is sent with no channelSerial attribute then the sync data is entirely contained within that ProtocolMessage") {
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

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    expect(channel.presenceMap.syncInProgress).to(beFalse())
                    expect(channel.presenceMap.members).to(beEmpty())

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.subscribe(.Present) { error in
                            expect(channel.presence.syncComplete).to(beFalse())
                            partialDone()
                        }

                        guard let lastConnectionSerial = transport.protocolMessagesReceived.last?.connectionSerial else {
                            fail("No protocol message has been received yet"); done(); return
                        }

                        // Inject a SYNC Presence message (entirely contained)
                        let syncMessage = ARTProtocolMessage()
                        syncMessage.action = .Sync
                        syncMessage.channel = channel.name
                        syncMessage.connectionSerial = lastConnectionSerial + 1
                        syncMessage.timestamp = NSDate()
                        syncMessage.presence = [
                            ARTPresenceMessage(clientId: "a", action: .Present, connectionId: "another", id: "another:0:0"),
                            ARTPresenceMessage(clientId: "b", action: .Present, connectionId: "another", id: "another:0:1"),
                            ARTPresenceMessage(clientId: "a", action: .Leave, connectionId: "another", id: "another:1:0"),
                        ]
                        transport.receive(syncMessage)
                    }

                    expect(channel.presence.syncComplete).to(beTrue())
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members where members.count == 1 else {
                                fail("Should at least have 1 member"); done(); return
                            }
                            expect(members[0].clientId).to(equal("b"))
                            done()
                        }
                    }
                }

            }

            // RTP19
            context("PresenceMap has existing members when a SYNC is started") {

                it("should ensure that members no longer present on the channel are removed from the local PresenceMap once the sync is complete") {
                    let options = AblyTests.commonAppSetup()

                    var clientMembers: ARTRealtime?
                    defer { clientMembers?.dispose(); clientMembers?.close() }
                    waitUntil(timeout: testTimeout) { done in
                        clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 2, options: options) {
                            done()
                        }
                    }

                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            expect(members).to(haveCount(2)) //synced
                            done()
                        }
                    }

                    expect(channel.presenceMap.members).to(haveCount(2))
                    // Inject a local member
                    let localMember = ARTPresenceMessage(clientId: NSUUID().UUIDString, action: .Enter, connectionId: "another", id: "another:0:0")
                    channel.presenceMap.add(localMember)
                    expect(channel.presenceMap.members).to(haveCount(3))
                    expect(channel.presenceMap.members.filter{ clientId, _ in clientId == localMember.clientId }).to(haveCount(1))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members where members.count == 3 else {
                                fail("Should at least have 3 members"); done(); return
                            }
                            expect(members.filter{ $0.clientId == localMember.clientId }).to(haveCount(1))
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Leave) { leave in
                            expect(channel.presence.syncComplete).to(beFalse())
                            expect(leave.clientId).to(equal(localMember.clientId))
                            done()
                        }

                        // Request a sync
                        let syncMessage = ARTProtocolMessage()
                        syncMessage.action = .Sync
                        syncMessage.channel = channel.name
                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); done(); return
                        }
                        transport.send(syncMessage)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members where members.count == 2 else {
                                fail("Should at least have 2 members"); done(); return
                            }
                            expect(members.filter{ $0.clientId == localMember.clientId }).to(beEmpty())
                            done()
                        }
                    }
                }

                // RTP19a
                it("should emit a LEAVE event for each existing member if the PresenceMap has existing members when an ATTACHED message is received without a HAS_PRESENCE flag") {
                    let options = AblyTests.commonAppSetup()
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    // Inject local members
                    channel.presenceMap.add(ARTPresenceMessage(clientId: "tester1", action: .Enter, connectionId: "another", id: "another:0:0"))
                    channel.presenceMap.add(ARTPresenceMessage(clientId: "tester2", action: .Enter, connectionId: "another", id: "another:0:1"))

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(4, done: done)
                        transport.afterProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .Attached {
                                expect(protocolMessage.hasPresence).to(beFalse())
                                partialDone()
                            }
                        }
                        channel.presence.subscribe(.Leave) { leave in
                            expect(leave.clientId?.hasPrefix("tester")).to(beTrue())
                            expect(leave.action).to(equal(ARTPresenceAction.Leave))
                            expect(leave.timestamp).to(beCloseTo(NSDate(), within: 0.5))
                            expect(leave.id).to(beNil())
                            partialDone() //2 times
                        }
                        channel.attach { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            expect(members).to(beEmpty())
                            done()
                        }
                    }
                }

            }

            // RTP4
            it("should receive all 250 members") {
                let options = AblyTests.commonAppSetup()
                var clientSource: ARTRealtime!
                defer { clientSource.dispose(); clientSource.close() }

                waitUntil(timeout: testTimeout) { done in
                    clientSource = AblyTests.addMembersSequentiallyToChannel("test", members: 250, options: options) {
                        done()
                    }
                }

                let clientTarget = ARTRealtime(options: options)
                defer { clientTarget.close() }
                let channel = clientTarget.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    var pending = 250
                    channel.presence.subscribe { member in
                        expect(member.action).to(equal(ARTPresenceAction.Present))
                        pending -= 1
                        if pending == 0 {
                            done()
                        }
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.get() { members, error in
                        expect(error).to(beNil())
                        expect(members).to(haveCount(250))
                        done()
                    }
                }
            }

            // RTP6
            context("subscribe") {

                // RTP6a
                it("with no arguments should subscribe a listener to all presence messages") {
                    let options = AblyTests.commonAppSetup()

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    var receivedMembers = [ARTPresenceMessage]()
                    channel1.presence.subscribe { member in
                        receivedMembers.append(member)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel2.presence.enterClient("john", data: "online") { err in
                            channel2.presence.updateClient("john", data: "away") { err in
                                channel2.presence.leaveClient("john", data: nil) { err in
                                    done()
                                }
                            }
                        }
                    }

                    expect(receivedMembers).toEventually(haveCount(3), timeout: testTimeout)
                    if receivedMembers.count != 3 {
                        return
                    }

                    expect(receivedMembers[0].action).to(equal(ARTPresenceAction.Enter))
                    expect(receivedMembers[0].data as? NSObject).to(equal("online"))
                    expect(receivedMembers[0].clientId).to(equal("john"))

                    expect(receivedMembers[1].action).to(equal(ARTPresenceAction.Update))
                    expect(receivedMembers[1].data as? NSObject).to(equal("away"))
                    expect(receivedMembers[1].clientId).to(equal("john"))

                    expect(receivedMembers[2].action).to(equal(ARTPresenceAction.Leave))
                    expect(receivedMembers[2].data as? NSObject).to(equal("away"))
                    expect(receivedMembers[2].clientId).to(equal("john"))
                }

            }

            // RTP7
            context("unsubscribe") {

                // RTP7a
                it("with no arguments unsubscribes the listener if previously subscribed with an action-specific subscription") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let listener = channel.presence.subscribe { _ in }!
                    expect(channel.presenceEventEmitter.anyListeners).to(haveCount(1))
                    channel.presence.unsubscribe(listener)
                    expect(channel.presenceEventEmitter.anyListeners).to(haveCount(0))
                }

            }

            // RTP5
            context("Channel state change side effects") {

                // RTP5a
                context("if the channel enters the FAILED state") {

                    it("all queued presence messages should fail immediately") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            let protocolError = AblyTests.newErrorProtocolMessage()
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).to(beIdenticalTo(protocolError.error))
                                expect(channel.queuedMessages).to(haveCount(0))
                                done()
                            }
                            expect(channel.queuedMessages).to(haveCount(1))
                            channel.onError(protocolError)
                        }
                    }

                    it("should clear the PresenceMap including local members and does not emit any presence events") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        expect(channel.presenceMap.members).to(haveCount(1))
                        expect(channel.presenceMap.localMembers).to(haveCount(1))

                        channel.subscribe() { _ in
                            fail("Shouldn't receive any presence event")
                        }
                        defer { channel.off() }

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.Failed) { _ in
                                expect(channel.presenceMap.members).to(beEmpty())
                                expect(channel.presenceMap.localMembers).to(beEmpty())
                                done()
                            }
                            channel.onError(AblyTests.newErrorProtocolMessage())
                        }
                    }

                }

                // RTP5a
                context("if the channel enters the DETACHED state") {

                    it("all queued presence messages should fail immediately") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.Attaching) { _ in
                                channel.detach()
                            }
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).toNot(beNil())
                                expect(channel.queuedMessages).to(haveCount(0))
                                done()
                            }
                            expect(channel.queuedMessages).to(haveCount(1))
                        }
                    }

                    it("should clear the PresenceMap including local members and does not emit any presence events") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        expect(channel.presenceMap.members).to(haveCount(1))
                        expect(channel.presenceMap.localMembers).to(haveCount(1))

                        channel.subscribe() { _ in
                            fail("Shouldn't receive any presence event")
                        }
                        defer { channel.off() }

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.Detached) { _ in
                                expect(channel.presenceMap.members).to(beEmpty())
                                expect(channel.presenceMap.localMembers).to(beEmpty())
                                done()
                            }
                            channel.detach()
                        }
                    }

                }

                // RTP5b
                it("if a channel enters the ATTACHED state then all queued presence messages will be sent immediately and a presence SYNC may be initiated") {
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

                    let client2 = AblyTests.newRealtime(options)
                    defer { client2.dispose(); client2.close() }
                    let channel2 = client2.channels.get(channel1.name)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel2.presence.enterClient("Client 2", data: nil) { error in
                            expect(error).to(beNil())
                            expect(channel2.queuedMessages).to(haveCount(0))
                            expect(channel2.state).to(equal(ARTRealtimeChannelState.Attached))
                            partialDone()
                        }
                        channel2.presence.subscribe(.Enter) { _ in
                            if channel2.presence.syncComplete {
                                expect(channel2.presenceMap.members).to(haveCount(2))
                            }
                            else {
                                expect(channel2.presenceMap.members).to(haveCount(1))
                            }
                            channel2.presence.unsubscribe()
                            partialDone()
                        }

                        expect(channel2.queuedMessages).to(haveCount(1))
                        expect(channel2.presence.syncComplete).to(beFalse())
                        expect(channel2.presenceMap.members).to(haveCount(0))
                    }

                    guard let transport = client2.transport as? TestProxyTransport else {
                        fail("Transport should be a test proxy"); return
                    }

                    expect(transport.protocolMessagesReceived.filter{ $0.action == .Sync }).to(haveCount(1))

                    expect(channel2.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
                    expect(channel2.presenceMap.members).to(haveCount(2))
                }

                // RTP5c
                context("when a channel becomes ATTACHED") {

                    // RTP5c1
                    it("if the resumed flag is true and no SYNC is initiated as part of the attach then do nothing, PresenceMap is not affected and no members need to be re-entered") {
                        let options = AblyTests.commonAppSetup()

                        var clientMembers: ARTRealtime?
                        waitUntil(timeout: testTimeout) { done in
                            clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 3, options: options) {
                                done()
                            }
                        }
                        defer { clientMembers?.dispose(); clientMembers?.close() }

                        options.disconnectedRetryTimeout = 1.0
                        options.tokenDetails = getTestTokenDetails(key: options.key!, ttl: 5.0)
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")

                        var originalMembers: [ARTPresenceMessage]?
                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get { members, error in
                                expect(error).to(beNil())
                                expect(members).to(haveCount(3))
                                originalMembers = members
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            client.connection.once(.Disconnected) { stateChange in
                                // Token expired
                                partialDone()
                            }
                            client.connection.once(.Connected) { stateChange in
                                guard let transport = client.transport as? TestProxyTransport else {
                                    fail("TestProxyTransport is not set"); return
                                }
                                // TODO: use sandbox to reproduce this
                                let attached = ARTProtocolMessage()
                                attached.action = .Attached
                                attached.channel = channel.name
                                attached.flags = Int64(ARTProtocolMessageFlag.Resumed.rawValue)
                                client.transport?.receive(attached)
                                partialDone()
                            }
                            channel.once(.Update) { stateChange in
                                guard let stateChange = stateChange else {
                                    fail("ChannelStageChange is nil"); done(); return
                                }
                                // No loss of continuity
                                expect(stateChange.resumed).to(beTrue())
                                expect(stateChange.reason).to(beNil())
                                expect(stateChange.current).to(equal(ARTRealtimeChannelState.Attached))
                                expect(stateChange.previous).to(equal(ARTRealtimeChannelState.Attached))
                                partialDone()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get { members, error in
                                expect(error).to(beNil())
                                guard let members = members else {
                                    fail("Members is nil"); done(); return
                                }
                                expect(members).to(equal(originalMembers))
                                expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .Absent }))
                                done()
                            }
                        }
                    }

                    // RTP5c2
                    context("all members not present in the PresenceMap but present in the internal PresenceMap must be re-entered automatically") {

                        it("when SYNC is initiated as part of the attach and the SYNC is complete") {
                            let options = AblyTests.commonAppSetup()

                            var clientMembers: ARTRealtime?
                            waitUntil(timeout: testTimeout) { done in
                                clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 3, options: options) {
                                    done()
                                }
                            }
                            defer { clientMembers?.dispose(); clientMembers?.close() }

                            let client = AblyTests.newRealtime(options)
                            defer { client.dispose(); client.close() }
                            let channel = client.channels.get("foo")
                            waitUntil(timeout: testTimeout) { done in
                                client.connection.once(.Connected) { stateChange in
                                    expect(stateChange?.reason).to(beNil())
                                    done()
                                }
                            }

                            guard let connectionId = client.connection.id else {
                                fail("Should have a connection ID"); return
                            }
                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); return
                            }

                            waitUntil(timeout: testTimeout) { done in
                                let partialDone = AblyTests.splitDone(4, done: done)
                                let localMember = ARTPresenceMessage(clientId: "local1", action: .Enter, connectionId: connectionId, id: "\(connectionId):1:1", timestamp: NSDate())

                                channel.once(.Attaching) { stateChange in
                                    // Local member
                                    channel.presenceMap.add(localMember)
                                    partialDone()
                                }
                                channel.attach() { error in
                                    expect(error).to(beNil())
                                    partialDone()
                                }

                                transport.beforeProcessingReceivedMessage = { protocolMessage in
                                    if protocolMessage.action == .Attached {
                                        // Expect a Sync
                                        expect(protocolMessage.hasPresence).to(beTrue())
                                        expect(protocolMessage.resumed).to(beFalse())
                                    }
                                    else if protocolMessage.action == .Sync {
                                        transport.beforeProcessingReceivedMessage = nil
                                        partialDone()
                                    }
                                }

                                // Before the sync ends
                                channel.presenceMap.testSuite_injectIntoMethodBefore(#selector(ARTPresenceMap.endSync)) {
                                    expect(channel.presenceMap.members).to(haveCount(4))
                                    expect(channel.presenceMap.localMembers).to(haveCount(1))

                                    transport.beforeProcessingSentMessage = { protocolMessage in
                                        if protocolMessage.action == .Presence && protocolMessage.presence?.first?.action == .Enter {
                                            expect(channel.presenceMap.localMembers).to(beEmpty())
                                            transport.beforeProcessingSentMessage = nil
                                        }
                                    }
                                    // Re-entered automatically
                                    channel.presence.subscribe(.Enter) { enter in
                                        // The members re-entered automatically must be removed from the internal PresenceMap,
                                        //so it must be a different object
                                        expect(enter).toNot(beIdenticalTo(localMember))
                                        expect(enter.clientId) == localMember.clientId
                                        expect(enter.connectionId) == localMember.connectionId
                                        partialDone()
                                    }
                                }
                            }

                            waitUntil(timeout: testTimeout) { done in
                                channel.presence.get { members, error in
                                    expect(error).to(beNil())
                                    guard let members = members else {
                                        fail("Members is nil"); done(); return
                                    }
                                    expect(members).to(haveCount(4))
                                    expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .Absent }))
                                    done()
                                }
                            }
                        }

                        it("when resumed flag is false and a SYNC is not expected") {
                            let options = AblyTests.commonAppSetup()

                            var clientMembers: ARTRealtime?
                            waitUntil(timeout: testTimeout) { done in
                                clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 3, options: options) {
                                    done()
                                }
                            }
                            defer { clientMembers?.dispose(); clientMembers?.close() }

                            options.clientId = "local1"
                            let client = AblyTests.newRealtime(options)
                            defer { client.dispose(); client.close() }
                            let channel = client.channels.get("foo")

                            waitUntil(timeout: testTimeout) { done in
                                let partialDone = AblyTests.splitDone(2, done: done)
                                channel.presence.get { members, error in
                                    expect(error).to(beNil())
                                    expect(members).to(haveCount(3))
                                    partialDone()
                                }
                                channel.presence.enter(nil) { error in
                                    expect(error).to(beNil())
                                    partialDone()
                                }
                            }

                            expect(channel.presenceMap.members).to(haveCount(4))
                            expect(channel.presenceMap.localMembers).to(haveCount(1))

                            waitUntil(timeout: testTimeout) { done in
                                let partialDone = AblyTests.splitDone(3, done: done)

                                guard let transport = client.transport as? TestProxyTransport else {
                                    fail("TestProxyTransport is not set"); return
                                }
                                transport.beforeProcessingReceivedMessage = { protocolMessage in
                                    if protocolMessage.action == .Attached {
                                        expect(protocolMessage.hasPresence).to(beFalse())
                                        expect(protocolMessage.resumed).to(beFalse())
                                        transport.beforeProcessingReceivedMessage = nil
                                        partialDone()
                                    }
                                }
                                transport.beforeProcessingSentMessage = { protocolMessage in
                                    if protocolMessage.action == .Presence && protocolMessage.presence?.first?.action == .Enter {
                                        // Re-enter
                                        expect(protocolMessage.presence?.first?.clientId).to(equal("local1"))
                                        expect(channel.presenceMap.localMembers).to(beEmpty())
                                        transport.beforeProcessingSentMessage = nil
                                        partialDone()
                                    }
                                }

                                channel.presence.subscribe(.Leave) { leave in
                                    // Members will leave the PresenceMap due to the ATTACHED without Presence
                                    expect(leave.clientId).to(satisfyAnyOf(equal("local1"), equal("user1"), equal("user2"), equal("user3")))
                                }

                                // Re-entered automatically
                                channel.presence.subscribe(.Update) { update in
                                    expect(update.clientId) == "local1"
                                    partialDone()
                                }

                                channel.presence.subscribe(.Enter) { enter in
                                    fail("Members already being present so the client should receive UPDATE events"); done(); return
                                }

                                // Inject ATTACHED message
                                let attached = ARTProtocolMessage()
                                attached.action = .Attached
                                attached.channel = channel.name
                                attached.flags = 0 //no presence, no resume
                                transport.receive(attached)
                            }

                            channel.presence.unsubscribe()
                            waitUntil(timeout: testTimeout) { done in
                                channel.presence.get { members, error in
                                    expect(error).to(beNil())
                                    guard let members = members else {
                                        fail("Members is nil"); done(); return
                                    }
                                    expect(members).to(haveCount(1))
                                    expect(members.first?.clientId).to(equal("local1"))
                                    done()
                                }
                            }
                        }
                    }

                    // RTP5c3
                    it("if any of the automatic ENTER presence messages published fail then an UPDATE event should be emitted on the channel") {
                        let options = AblyTests.commonAppSetup()

                        var clientMembers: ARTRealtime?
                        waitUntil(timeout: testTimeout) { done in
                            clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 3, options: options) {
                                done()
                            }
                        }
                        defer { clientMembers?.dispose(); clientMembers?.close() }

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.Connected) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                done()
                            }
                        }

                        guard let connectionId = client.connection.id else {
                            fail("Should have a connection ID"); return
                        }
                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            let localMember = ARTPresenceMessage(clientId: "local1", action: .Enter, connectionId: connectionId, id: "\(connectionId):1:1", timestamp: NSDate())

                            channel.once(.Attaching) { stateChange in
                                // Local member
                                channel.presenceMap.add(localMember)
                                partialDone()
                            }
                            channel.attach()

                            // Before the sync ends
                            channel.presenceMap.testSuite_injectIntoMethodBefore(#selector(ARTPresenceMap.endSync)) {
                                expect(channel.presenceMap.members).to(haveCount(4))
                                expect(channel.presenceMap.localMembers).to(haveCount(1))

                                // Time out
                                let reEnterError = ARTErrorInfo.createWithCode(50003, message: "timed out")
                                transport.replaceAcksWithNacks(reEnterError) { _ in }

                                // Re-entered automatically should fail
                                channel.presence.subscribe(.Enter) { enter in
                                    fail("Should not Enter the local member")
                                }
                                partialDone()
                            }

                            channel.once(.Update) { stateChange in
                                guard let stateChange = stateChange else {
                                    fail("ChannelStateChange is nil"); partialDone(); return
                                }
                                guard let reason = stateChange.reason else {
                                    fail("Reason from ChannelStateChange is nil"); partialDone(); return
                                }
                                expect(reason.code) == 91004
                                expect(reason.message).to(contain(localMember.clientId!))
                                expect(reason.message).to(contain("timed out"))
                                expect(stateChange.resumed).to(beTrue())
                                partialDone()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get { members, error in
                                expect(error).to(beNil())
                                guard let members = members else {
                                    fail("Members is nil"); done(); return
                                }
                                expect(members).to(haveCount(3))
                                expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .Absent }))
                                done()
                            }
                        }
                    }

                }

                // RTP5f
                context("channel enters the SUSPENDED state") {

                    it("all queued presence messages should fail immediately") {
                        let options = AblyTests.commonAppSetup()
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            channel.once(.Attaching) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                expect(channel.queuedMessages.count) == 1
                                channel.setSuspended(ARTStatus.state(.Error, info: ARTErrorInfo.createWithCode(1234, message: "unknown error")))
                                partialDone()
                            }
                            channel.once(.Suspended) { stateChange in
                                // All queued presence messages will fail immediately
                                expect(channel.queuedMessages.count) == 0
                                partialDone()
                            }
                            channel.presence.enterClient("tester", data: nil) { error in
                                guard let error = error else {
                                    fail("Error is nil"); partialDone(); return
                                }
                                expect(error.code) == 1234
                                expect(error.message).to(contain("unknown error"))
                                partialDone()
                            }
                        }
                    }

                    it("should maintain the PresenceMap and any members present before and after the sync should not emit presence events") {
                        let options = AblyTests.commonAppSetup()

                        var clientMembers: ARTRealtime?
                        waitUntil(timeout: testTimeout) { done in
                            clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 3, options: options) {
                                done()
                            }
                        }
                        defer { clientMembers?.dispose(); clientMembers?.close() }

                        options.clientId = "tester"
                        options.tokenDetails = getTestTokenDetails(key: options.key!, ttl: 5.0, clientId: options.clientId)
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.presence.enter(nil) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                            channel.presence.get { members, error in
                                expect(error).to(beNil())
                                expect(members).to(haveCount(3))
                                partialDone()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(4, done: done)
                            channel.presence.subscribe { presence in
                                expect(presence.action).to(equal(ARTPresenceAction.Leave))
                                expect(presence.clientId).to(equal("tester"))
                                partialDone()
                            }
                            channel.once(.Suspended) { stateChange in
                                expect(channel.presenceMap.members).to(haveCount(4))
                                expect(channel.presenceMap.localMembers).to(haveCount(1))
                                partialDone()
                            }
                            channel.once(.Attaching) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                channel.presence.leave(nil) { error in
                                    expect(error).to(beNil())
                                    partialDone()
                                }
                                expect(channel.queuedMessages.count) == 1
                            }
                            channel.once(.Attached) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                partialDone()
                            }
                            channel.setSuspended(ARTStatus.state(.Ok))
                        }

                        channel.presence.unsubscribe()
                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get { members, error in
                                expect(error).to(beNil())
                                guard let members = members else {
                                    fail("Members is nil"); done(); return
                                }
                                expect(members).to(haveCount(3))
                                expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .Absent }))
                                expect(channel.presenceMap.members).to(haveCount(3))
                                expect(channel.presenceMap.localMembers).to(beEmpty())
                                done()
                            }
                        }
                    }

                }

            }

            // RTP8
            context("enter") {

                // RTP8a
                it("should enter the current client, optionally with the data provided") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel1.attach { err in 
                            expect(err).to(beNil())
                            channel1.presence.subscribe(.Enter) { member in
                                expect(member.clientId).to(equal(options.clientId))
                                expect(member.data as? NSObject).to(equal("online"))
                                done()
                            }
                            channel2.presence.enter("online")
                        }
                    }
                }

            }

            // RTP7
            context("unsubscribe") {

                // RTP7b
                it("with a single action argument unsubscribes the provided listener to all presence messages for that action") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let listener = channel.presence.subscribe(.Present) { _ in }!
                    expect(channel.presenceEventEmitter.listeners).to(haveCount(1))
                    channel.presence.unsubscribe(.Present, listener: listener)
                    expect(channel.presenceEventEmitter.listeners).to(haveCount(0))
                }

            }

            // RTP6
            context("subscribe") {

                // RTP6c
                it("should implicitly attach the channel") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Initialized))
                    channel.presence.subscribe { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    channel.detach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)

                    channel.presence.subscribe(.Present) { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                }

                // RTP6c
                it("should result in an error if the channel is in the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    channel.onError(AblyTests.newErrorProtocolMessage())
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribeWithAttachCallback({ errorInfo in
                            expect(errorInfo).toNot(beNil())

                            channel.presence.subscribe(.Enter, onAttach: { errorInfo in
                                expect(errorInfo).toNot(beNil())
                                done()
                            }) { _ in }
                        }) { _ in }
                    }
                }

                // RTP6c
                it("should result in an error if the channel moves to the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let error = AblyTests.newErrorProtocolMessage()
                        channel.presence.subscribeWithAttachCallback({ errorInfo in
                            expect(errorInfo).toNot(beNil())

                            channel.presence.subscribe(.Enter, onAttach: { errorInfo in
                                expect(errorInfo).toNot(beNil())
                                done()
                            }) { _ in }
                        }) {_ in }
                        channel.onError(error)
                    }
                }

            }

            // RTP6
            context("subscribe") {

                // RTP6b
                it("with a single action argument") {
                    let options = AblyTests.commonAppSetup()

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    var count = 0
                    channel1.presence.subscribe(.Update) { member in
                        expect(member.action).to(equal(ARTPresenceAction.Update))
                        expect(member.clientId).to(equal("john"))
                        expect(member.data as? NSObject).to(equal("away"))
                        count += 1
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel2.presence.enterClient("john", data: "online") { error in
                            expect(error).to(beNil())
                            channel2.presence.updateClient("john", data: "away") { error in
                                expect(error).to(beNil())
                                channel2.presence.leaveClient("john", data: nil) { error in
                                    expect(error).to(beNil())
                                    done()
                                }
                            }
                        }
                    }

                    expect(count).toEventually(equal(1), timeout: testTimeout)
                }

            }

            // RTP8
            context("enter") {

                // RTP8b
                it("optionally a callback can be provided that is called for success") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel1.presence.subscribe(.Enter) { member in
                            expect(member.clientId).to(equal(options.clientId))
                            expect(member.data as? NSObject).to(equal("online"))
                            done()
                        }
                        channel2.presence.enter("online") { error in
                            expect(error).to(beNil())
                        }
                    }
                }

                // RTP8b
                it("optionally a callback can be provided that is called for failure") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel1.presence.subscribe(.Enter) { member in
                            fail("shouldn't be called")
                        }
                        let protocolError = AblyTests.newErrorProtocolMessage()
                        channel2.presence.enter("online") { error in
                            expect(error).to(beIdenticalTo(protocolError.error))
                            done()
                        }
                        channel2.onError(protocolError)
                    }
                }

                // RTP8c
                it("entering without an explicit PresenceMessage#clientId should implicitly use the clientId of the current connection") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    let transport = client.transport as! TestProxyTransport
                    let sent = transport.protocolMessagesSent.filter({ $0.action == .Presence })[0].presence![0]
                    expect(sent.action).to(equal(ARTPresenceAction.Enter))
                    expect(sent.clientId).to(beNil())

                    let received = transport.protocolMessagesReceived.filter({ $0.action == .Presence })[0].presence![0]
                    expect(received.action).to(equal(ARTPresenceAction.Enter))
                    expect(received.clientId).to(equal("john"))
                }

            }

            // RTP8
            context("enter") {

                // RTP8f
                it("should result in an error immediately if the client is anonymous") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            expect(error!.message).to(contain("attempted to publish presence message without clientId"))
                            done()
                        }
                    }
                }

            }

            // RTP8
            context("enter") {

                // RTP8g
                it("should result in an error immediately if the channel is DETACHED") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { _ in
                            channel.detach() { _ in done() }
                        }
                    }
                    
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

                // RTP8g
                it("should result in an error immediately if the channel is FAILED") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    channel.onError(AblyTests.newErrorProtocolMessage())

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

            }

            // RTP8
            context("enter") {

                // RTP8i
                it("should result in an error if Ably service determines that the client is unidentified") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            expect(error!.message).to(contain("presence message without clientId"))
                            done()
                        }
                    }
                }

            }

            // RTP9
            context("update") {

                // RTP9a
                it("should update the data for the present member with a value") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Enter) { member in
                            expect(member.data).to(beNil())
                            done()
                        }
                        channel.presence.enter(nil)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Update) { member in
                            expect(member.data as? NSObject).to(equal("online"))
                            done()
                        }
                        channel.presence.update("online")
                    }
                }

                // RTP9a
                it("should update the data for the present member with null") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Enter) { member in
                            expect(member.data as? NSObject).to(equal("online"))
                            done()
                        }
                        channel.presence.enter("online")
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Update) { member in
                            expect(member.data).to(beNil())
                            done()
                        }
                        channel.presence.update(nil)
                    }
                }

            }

            // RTP9
            context("update") {

                // RTP9b
                it("should enter current client into the channel if the client was not already entered") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.presenceMap.members).to(haveCount(0))
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Enter) { member in
                            expect(member.clientId).to(equal("john"))
                            expect(member.data as? NSObject).to(equal("online"))
                            done()
                        }
                        channel.presence.update("online")
                    }
                }

            }

            // RTP9
            context("update") {

                // RTP9c
                it("optionally a callback can be provided that is called for success") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update("online") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                // RTP9c
                it("optionally a callback can be provided that is called for failure") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let protocolError = AblyTests.newErrorProtocolMessage()
                        channel.presence.update("online") { error in
                            expect(error).to(beIdenticalTo(protocolError.error))
                            done()
                        }
                        channel.onError(protocolError)
                    }
                }

                // RTP9d
                it("update without an explicit PresenceMessage#clientId should implicitly use the clientId of the current connection") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            channel.presence.update("offline") { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }
                    }

                    let transport = client.transport as! TestProxyTransport
                    let sent = transport.protocolMessagesSent.filter({ $0.action == .Presence })[1].presence![0]
                    expect(sent.action).to(equal(ARTPresenceAction.Update))
                    expect(sent.clientId).to(beNil())

                    let receivedPresenceProtocolMessages = transport.protocolMessagesReceived.filter({ $0.action == .Presence })
                    let receivedPresenceMessages = receivedPresenceProtocolMessages.flatMap({ $0.presence! })
                    let received = receivedPresenceMessages.filter({ $0.action == .Update })[0]
                    expect(received.action).to(equal(ARTPresenceAction.Update))
                    expect(received.clientId).to(equal("john"))
                }

            }

            // RTP10
            context("leave") {

                // RTP10a
                it("should leave the current client from the channel and the data will be updated with the value provided") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Enter) { member in
                            expect(member.data as? NSObject).to(equal("online"))
                            done()
                        }
                        channel.presence.enter("online")
                    }

                    expect(channel.presenceMap.members).toEventually(haveCount(1), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Leave) { member in
                            expect(member.data as? NSObject).to(equal("offline"))
                            done()
                        }
                        channel.presence.leave("offline")
                    }

                    expect(channel.presenceMap.members).toEventually(haveCount(0), timeout: testTimeout)
                }

                // RTP10a
                it("should leave the current client with no data") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Enter) { member in
                            expect(member.data as? NSObject).to(equal("online"))
                            done()
                        }
                        channel.presence.enter("online")
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Leave) { member in
                            expect(member.data as? NSObject).to(equal("online"))
                            done()
                        }
                        channel.presence.leave(nil)
                    }
                }

            }

            // RTP2
            it("should be used a PresenceMap to maintain a list of members") {
                let options = AblyTests.commonAppSetup()
                var clientSecondary: ARTRealtime!
                defer { clientSecondary.dispose(); clientSecondary.close() }

                waitUntil(timeout: testTimeout) { done in
                    clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 100, options: options) {
                        done()
                    }
                }

                let client = AblyTests.newRealtime(options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")

                var user50LeaveTimestamp: NSDate?
                channel.presence.subscribe(.Leave) { member in
                    expect(member.clientId).to(equal("user50"))
                    user50LeaveTimestamp = member.timestamp
                }

                var user50PresentTimestamp: NSDate?
                channel.presenceMap.testSuite_getArgumentFrom(#selector(ARTPresenceMap.add(_:)), atIndex: 0) { arg0 in
                    let member = arg0 as! ARTPresenceMessage
                    if member.clientId == "user50" && member.action == .Present {
                        user50PresentTimestamp = member.timestamp
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.attach() { error in
                        expect(error).to(beNil())
                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("Transport is nil"); done(); return
                        }
                        transport.beforeProcessingReceivedMessage = { protocolMessage in
                            // A leave event for a member can arrive before that member is later registered as present as part of the initial SYNC operation.
                            if protocolMessage.action == .Sync {
                                let msg = AblyTests.newPresenceProtocolMessage("test", action: .Leave, clientId: "user50")
                                // Ensure it happens "later" than the PRESENT message.
                                msg.timestamp = NSDate().dateByAddingTimeInterval(1.0)
                                client.onChannelMessage(msg)
                                done()
                            }
                            transport.beforeProcessingReceivedMessage = nil
                        }
                    }
                }

                channel.presence.unsubscribe()
                waitUntil(timeout: testTimeout) { done in
                    channel.presence.get { members, error in
                        expect(error).to(beNil())
                        guard let members = members else {
                            fail("Members is nil"); done(); return
                        }
                        expect(members.count) == 99
                        expect(members.filter{ $0.clientId == "user50" }).to(haveCount(0))
                        done()
                    }
                }

                expect(user50LeaveTimestamp).to(beGreaterThan(user50PresentTimestamp))
            }

            // RTP2
            context("PresenceMap") {

                // RTP2a
                it("all incoming presence messages must be compared for newness with the matching member already in the PresenceMap") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let intialPresenceMessage = channel.presenceMap.members["tester"] else {
                        fail("Missing Presence message"); return
                    }

                    expect(intialPresenceMessage.memberKey()).to(equal("\(client.connection.id!):tester"))

                    var compareForNewnessMethodCalls = 0
                    let hook = channel.presenceMap.testSuite_injectIntoMethodAfter(NSSelectorFromString("isNewestPresence:comparingWith:")) {
                        compareForNewnessMethodCalls += 1
                    }
                    defer { hook.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let updatedPresenceMessage = channel.presenceMap.members["tester"] else {
                        fail("Missing Presence message"); return
                    }

                    expect(intialPresenceMessage.memberKey()).to(equal(updatedPresenceMessage.memberKey()))
                    expect(intialPresenceMessage.timestamp).toNot(equal(updatedPresenceMessage.timestamp))

                    expect(compareForNewnessMethodCalls) == 1
                }

                // RTP2b
                context("compare for newness") {

                    context("presence message has a connectionId which is not an initial substring of its id") {
                        // RTP2b1
                        it("compares them by timestamp numerically") {
                            let options = AblyTests.commonAppSetup()
                            let now = NSDate()

                            var clientMembers: ARTRealtime?
                            defer { clientMembers?.dispose(); clientMembers?.close() }
                            waitUntil(timeout: testTimeout) { done in
                                clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 101, options: options) {
                                    done()
                                }
                            }

                            let clientSubscribed = AblyTests.newRealtime(options)
                            defer { clientSubscribed.dispose(); clientSubscribed.close() }
                            let channelSubscribed = clientSubscribed.channels.get("foo")

                            let presenceData: [ARTPresenceMessage] = [
                                ARTPresenceMessage(clientId: "a", action: .Enter, connectionId: "one", id: "one:0:0", timestamp: now),
                                ARTPresenceMessage(clientId: "a", action: .Leave, connectionId: "one", id: "fabricated:0:1", timestamp: now + 1),
                                ARTPresenceMessage(clientId: "b", action: .Enter, connectionId: "one", id: "one:0:2", timestamp: now),
                                ARTPresenceMessage(clientId: "b", action: .Leave, connectionId: "one", id: "fabricated:0:3", timestamp: now - 1),
                                ARTPresenceMessage(clientId: "c", action: .Enter, connectionId: "one", id: "fabricated:0:4", timestamp: now),
                                ARTPresenceMessage(clientId: "c", action: .Leave, connectionId: "one", id: "fabricated:0:5", timestamp: now - 1),
                            ]

                            guard let transport = clientSubscribed.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); return
                            }

                            waitUntil(timeout: testTimeout) { done in
                                transport.afterProcessingReceivedMessage = { protocolMessage in
                                    // Receive the first Sync message from Ably service
                                    if protocolMessage.action == .Sync {

                                        // Inject a fabricated Presence message
                                        let presenceMessage = ARTProtocolMessage()
                                        presenceMessage.action = .Presence
                                        presenceMessage.channel = protocolMessage.channel
                                        presenceMessage.connectionSerial = protocolMessage.connectionSerial + 1
                                        presenceMessage.timestamp = NSDate()
                                        presenceMessage.presence = presenceData

                                        transport.receive(presenceMessage)

                                        // Simulate an end to the sync
                                        let endSyncMessage = ARTProtocolMessage()
                                        endSyncMessage.action = .Sync
                                        endSyncMessage.channel = protocolMessage.channel
                                        endSyncMessage.channelSerial = "validserialprefix:" //with no part after the `:` this indicates the end to the SYNC
                                        endSyncMessage.connectionSerial = protocolMessage.connectionSerial + 2
                                        endSyncMessage.timestamp = NSDate()

                                        transport.afterProcessingReceivedMessage = nil
                                        transport.receive(endSyncMessage)

                                        // Stop the next sync message from Ably service because we already injected the end of the sync
                                        transport.actionsIgnored = [.Sync]

                                        done()
                                    }
                                }
                                channelSubscribed.attach()
                            }

                            waitUntil(timeout: testTimeout) { done in
                                channelSubscribed.presence.get { members, error in
                                    expect(error).to(beNil())
                                    guard let members = members else {
                                        fail("Members is nil"); done(); return
                                    }
                                    expect(members).to(haveCount(102)) //100 initial members + "b" + "c", client "a" is discarded
                                    expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .Absent }))
                                    expect(members.filter{ $0.clientId == "a" }).to(beEmpty())
                                    expect(members.filter{ $0.clientId == "b" }).to(haveCount(1))
                                    expect(members.filter{ $0.clientId == "b" }.first?.timestamp).to(equal(now))
                                    expect(members.filter{ $0.clientId == "c" }).to(haveCount(1))
                                    expect(members.filter{ $0.clientId == "c" }.first?.timestamp).to(equal(now))
                                    done()
                                }
                            }
                        }
                    }

                    // RTP2b2
                    it("split the id of both presence messages") {
                        let options = AblyTests.commonAppSetup()
                        let now = NSDate()

                        var clientMembers: ARTRealtime?
                        defer { clientMembers?.dispose(); clientMembers?.close() }
                        waitUntil(timeout: testTimeout) { done in
                            clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 101, options: options) {
                                done()
                            }
                        }

                        let clientSubscribed = AblyTests.newRealtime(options)
                        defer { clientSubscribed.dispose(); clientSubscribed.close() }
                        let channelSubscribed = clientSubscribed.channels.get("foo")

                        let presenceData: [ARTPresenceMessage] = [
                            ARTPresenceMessage(clientId: "a", action: .Enter, connectionId: "one", id: "one:0:0", timestamp: now),
                            ARTPresenceMessage(clientId: "a", action: .Leave, connectionId: "one", id: "one:1:0", timestamp: now - 1),
                            ARTPresenceMessage(clientId: "b", action: .Enter, connectionId: "one", id: "one:2:2", timestamp: now),
                            ARTPresenceMessage(clientId: "b", action: .Leave, connectionId: "one", id: "one:2:1", timestamp: now + 1),
                            ARTPresenceMessage(clientId: "c", action: .Enter, connectionId: "one", id: "one:4:4", timestamp: now),
                            ARTPresenceMessage(clientId: "c", action: .Leave, connectionId: "one", id: "one:3:5", timestamp: now + 1),
                        ]

                        guard let transport = clientSubscribed.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            transport.afterProcessingReceivedMessage = { protocolMessage in
                                // Receive the first Sync message from Ably service
                                if protocolMessage.action == .Sync {

                                    // Inject a fabricated Presence message
                                    let presenceMessage = ARTProtocolMessage()
                                    presenceMessage.action = .Presence
                                    presenceMessage.channel = protocolMessage.channel
                                    presenceMessage.connectionSerial = protocolMessage.connectionSerial + 1
                                    presenceMessage.timestamp = NSDate()
                                    presenceMessage.presence = presenceData

                                    transport.receive(presenceMessage)

                                    // Simulate an end to the sync
                                    let endSyncMessage = ARTProtocolMessage()
                                    endSyncMessage.action = .Sync
                                    endSyncMessage.channel = protocolMessage.channel
                                    endSyncMessage.channelSerial = "validserialprefix:" //with no part after the `:` this indicates the end to the SYNC
                                    endSyncMessage.connectionSerial = protocolMessage.connectionSerial + 2
                                    endSyncMessage.timestamp = NSDate()

                                    transport.afterProcessingReceivedMessage = nil
                                    transport.receive(endSyncMessage)

                                    // Stop the next sync message from Ably service because we already injected the end of the sync
                                    transport.actionsIgnored = [.Sync]

                                    done()
                                }
                            }
                            channelSubscribed.attach()
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channelSubscribed.presence.get { members, error in
                                expect(error).to(beNil())
                                guard let members = members else {
                                    fail("Members is nil"); done(); return
                                }
                                expect(members).to(haveCount(102)) //100 initial members + "b" + "c", client "a" is discarded
                                expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .Absent }))
                                expect(members.filter{ $0.clientId == "a" }).to(beEmpty())
                                expect(members.filter{ $0.clientId == "b" }).to(haveCount(1))
                                expect(members.filter{ $0.clientId == "b" }.first?.timestamp).to(equal(now))
                                expect(members.filter{ $0.clientId == "c" }).to(haveCount(1))
                                expect(members.filter{ $0.clientId == "c" }.first?.timestamp).to(equal(now))
                                done()
                            }
                        }
                    }

                }

                // RTP2c
                context("all presence messages from a SYNC must also be compared for newness in the same way as they would from a PRESENCE") {

                    it("discard members where messages have arrived before the SYNC") {
                        let options = AblyTests.commonAppSetup()
                        let timeBeforeSync = NSDate()

                        var clientMembers: ARTRealtime?
                        defer { clientMembers?.dispose(); clientMembers?.close() }
                        waitUntil(timeout: testTimeout) { done in
                            clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 120, options: options) {
                                done()
                            }
                        }
                        guard let membersConnectionId = clientMembers?.connection.id else {
                            fail("Members client isn't connected"); return
                        }

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")

                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        channel.presence.subscribe(.Leave) { leave in
                            expect(leave.clientId).to(equal("user110"))
                            fail("Should not fire Leave event for member `user110` because it's out of date")
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            transport.beforeProcessingReceivedMessage = { protocolMessage in
                                if protocolMessage.action == .Sync {
                                    let injectLeave = ARTPresenceMessage()
                                    injectLeave.action = .Leave
                                    injectLeave.connectionId = membersConnectionId
                                    injectLeave.clientId = "user110"
                                    injectLeave.timestamp = timeBeforeSync
                                    protocolMessage.presence?.append(injectLeave)
                                    transport.beforeProcessingReceivedMessage = nil
                                    partialDone()
                                }
                            }
                            channel.presenceMap.testSuite_injectIntoMethodAfter(#selector(ARTPresenceMap.endSync)) {
                                expect(channel.presenceMap.syncInProgress).to(beFalse())
                                expect(channel.presenceMap.members).to(haveCount(120))
                                expect(channel.presenceMap.members.filter{ _, presence in presence.clientId == "user110" && presence.action == .Present }).to(haveCount(1))
                                partialDone()
                            }
                            channel.attach() { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }

                    it("accept members where message have arrived after the SYNC") {
                        let options = AblyTests.commonAppSetup()

                        var clientMembers: ARTRealtime?
                        defer { clientMembers?.dispose(); clientMembers?.close() }
                        waitUntil(timeout: testTimeout) { done in
                            clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 120, options: options) {
                                done()
                            }
                        }
                        guard let membersConnectionId = clientMembers?.connection.id else {
                            fail("Members client isn't connected"); return
                        }

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("foo")

                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(4, done: done)
                            channel.presence.subscribe(.Leave) { leave in
                                expect(leave.clientId).to(equal("user110"))
                                partialDone()
                            }
                            transport.beforeProcessingReceivedMessage = { protocolMessage in
                                if protocolMessage.action == .Sync {
                                    let injectLeave = ARTPresenceMessage()
                                    injectLeave.action = .Leave
                                    injectLeave.connectionId = membersConnectionId
                                    injectLeave.clientId = "user110"
                                    injectLeave.timestamp = NSDate() + 1
                                    protocolMessage.presence?.append(injectLeave)
                                    transport.beforeProcessingReceivedMessage = nil
                                    partialDone()
                                }
                            }
                            channel.presenceMap.testSuite_injectIntoMethodAfter(#selector(ARTPresenceMap.endSync)) {
                                expect(channel.presenceMap.syncInProgress).to(beFalse())
                                expect(channel.presenceMap.members).to(haveCount(119))
                                expect(channel.presenceMap.members.filter{ _, presence in presence.clientId == "user110" }).to(beEmpty())
                                partialDone()
                            }
                            channel.attach() { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }

                }

                // RTP2d
                it("if action of ENTER arrives, it should be added to the presence map with the action set to PRESENT") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.subscribe(.Enter) { _ in
                            partialDone()
                        }
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Present }).to(haveCount(1))
                    expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Enter }).to(beEmpty())
                }

                // RTP2d
                it("if action of UPDATE arrives, it should be added to the presence map with the action set to PRESENT") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)
                        channel.presence.subscribe(.Update) { _ in
                            partialDone()
                        }
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                        channel.presence.updateClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    expect(channel.presenceMap.members).to(haveCount(1))
                    expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Present }).to(haveCount(1))
                    expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Update }).to(beEmpty())
                }

                // RTP2d
                it("if action of PRESENT arrives, it should be added to the presence map with the action set to PRESENT") {
                    let options = AblyTests.commonAppSetup()

                    var clientMembers: ARTRealtime!
                    defer { clientMembers.dispose(); clientMembers.close() }
                    waitUntil(timeout: testTimeout) { done in
                        clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 1, options: options) {
                            done()
                        }
                    }

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presenceMap.testSuite_injectIntoMethodAfter(#selector(ARTPresenceMap.endSync)) {
                            expect(channel.presenceMap.syncInProgress).to(beFalse())
                            partialDone()
                        }
                        channel.attach() { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    expect(channel.presenceMap.members).to(haveCount(1))
                }

                // RTP2e
                it("if a SYNC is not in progress, then when a presence message with an action of LEAVE arrives, that memberKey should be deleted from the presence map, if present") {
                    let options = AblyTests.commonAppSetup()

                    var clientMembers: ARTRealtime?
                    defer { clientMembers?.dispose(); clientMembers?.close() }
                    waitUntil(timeout: testTimeout) { done in
                        clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 20, options: options) {
                            done()
                        }
                    }

                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    channel.attach()

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }
                    waitUntil(timeout: testTimeout) { done in
                        transport.afterProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .Sync {
                                done()
                            }
                        }
                    }

                    expect(channel.presenceMap.syncInProgress).toEventually(beFalse(), timeout: testTimeout)

                    guard let user11MemberKey = channel.presenceMap.members["user11"]?.memberKey() else {
                        fail("user11 memberKey is not present"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.Leave) { presence in
                            expect(presence.clientId).to(equal("user11"))
                            done()
                        }
                        clientMembers?.channels.get("foo").presence.leaveClient("user11", data: nil)
                    }

                    expect(channel.presenceMap.members.filter{ _, presence in presence.memberKey() == user11MemberKey }).to(beEmpty())
                }

                // RTP2f
                it("if a SYNC is in progress, then when a presence message with an action of LEAVE arrives, it should be stored in the presence map with the action set to ABSENT") {
                    let options = AblyTests.commonAppSetup()

                    var clientMembers: ARTRealtime?
                    defer { clientMembers?.dispose(); clientMembers?.close() }
                    waitUntil(timeout: testTimeout) { done in
                        clientMembers = AblyTests.addMembersSequentiallyToChannel("foo", members: 20, options: options) {
                            done()
                        }
                    }

                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    channel.attach()

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)
                        channel.presenceMap.testSuite_injectIntoMethodAfter(#selector(ARTPresenceMap.startSync)) {
                            expect(channel.presenceMap.syncInProgress).to(beTrue())

                            channel.presence.subscribe(.Leave) { leave in
                                expect(leave.clientId).to(equal("user11"))
                                expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Leave }).to(beEmpty())
                                expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Absent }).to(haveCount(1))
                                partialDone()
                            }

                            // Inject a fabricated Presence message
                            let leaveMessage = ARTProtocolMessage()
                            leaveMessage.action = .Presence
                            leaveMessage.channel = channel.name
                            leaveMessage.connectionSerial = client.connection.serial + 1
                            leaveMessage.timestamp = NSDate()
                            leaveMessage.presence = [
                                ARTPresenceMessage(clientId: "user11", action: .Leave, connectionId: "another", id: "another:123:0", timestamp: NSDate())
                            ]
                            transport.receive(leaveMessage)
                        }
                        channel.presenceMap.testSuite_injectIntoMethodBefore(#selector(ARTPresenceMap.endSync)) {
                            expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Absent }).to(haveCount(1))
                            partialDone()
                        }
                        channel.presenceMap.testSuite_injectIntoMethodAfter(#selector(ARTPresenceMap.endSync)) {
                            expect(channel.presenceMap.syncInProgress).to(beFalse())
                            expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Leave }).to(beEmpty())
                            expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Absent }).to(beEmpty())
                            partialDone()
                        }
                    }

                    expect(channel.presenceMap.members).to(haveCount(19))
                }

                // RTP2g
                it("any incoming presence message that passes the newness check should be emitted on the Presence object, with an event name set to its original action") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                        channel.presence.subscribe(.Enter) { _ in
                            partialDone()
                        }
                    }

                    expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Present }).to(haveCount(1))
                    expect(channel.presenceMap.members.filter{ _, presence in presence.action == .Enter }).to(beEmpty())
                }

            }

            // RTP8
            context("enter") {
                // RTP8h
                it("should result in an error if the client does not have required presence permission") {
                    let options = AblyTests.commonAppSetup()
                    options.token = getTestToken(clientId: "john", capability: "{ \"cannotpresence:john\":[\"publish\"] }")
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("cannotpresence")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            guard let error = error else {
                                fail("error expected"); done(); return
                            }
                            expect(error.message).to(contain("Channel denied access based on given capability"))
                            done()
                        }
                    }
                }
            }


            // RTP9
            context("update") {

                // RTP9e
                it("should result in an error immediately if the client is anonymous") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            expect(error!.message).to(contain("attempted to publish presence message without clientId"))
                            done()
                        }
                    }
                }

                // RTP9e
                it("should result in an error immediately if the channel is DETACHED") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    channel.attach()
                    channel.detach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

                // RTP9e
                it("should result in an error immediately if the channel is FAILED") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    channel.onError(AblyTests.newErrorProtocolMessage())

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

                // RTP9e
                it("should result in an error if the client does not have required presence permission") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken(clientId: "john", capability: "{ \"cannotpresence:john\":[\"publish\"] }")
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("cannotpresence")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("Channel denied access based on given capability"))
                            done()
                        }
                    }
                }

                // RTP9e
                it("should result in an error if Ably service determines that the client is unidentified") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("presence message without clientId"))
                            done()
                        }
                    }
                }
            }

            // RTP10
            context("leave") {

                // RTP10b
                it("optionally a callback can be provided that is called for success") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leave("offline") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                // RTP10b
                it("optionally a callback can be provided that is called for failure") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                   waitUntil(timeout: testTimeout) { done in
                       channel.presence.enter("online") { error in
                           expect(error).to(beNil())
                           done()
                       }
                   }

                    waitUntil(timeout: testTimeout) { done in
                        let sentError = ARTErrorInfo.createWithCode(0, message: "test error")
                        let transport = client.transport as! TestProxyTransport
                        transport.replaceAcksWithNacks(sentError) { doneReplacing in
                            channel.presence.leave("offline") { error in
                                expect(error).to(beIdenticalTo(sentError))
                                doneReplacing()
                                done()
                            }
                        }
                    }
                }

                it("should raise an exception if client is not present") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(channel.presence.leave("offline")).to(raiseException())
                }

                // RTP10c
                it("entering without an explicit PresenceMessage#clientId should implicitly use the clientId of the current connection") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            channel.presence.leave(nil) { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }
                    }

                    let transport = client.transport as! TestProxyTransport

                    let sent = transport.protocolMessagesSent.filter({ $0.action == .Presence })[1].presence![0]
                    expect(sent.action).to(equal(ARTPresenceAction.Leave))
                    expect(sent.clientId).to(beNil())

                    let receivedPresenceProtocolMessages = transport.protocolMessagesReceived.filter({ $0.action == .Presence })
                    let receivedPresenceMessages = receivedPresenceProtocolMessages.flatMap({ $0.presence! })
                    let received = receivedPresenceMessages.filter({ $0.action == .Leave })[0]
                    expect(received.action).to(equal(ARTPresenceAction.Leave))
                    expect(received.clientId).to(equal("john"))
                }

            }

            // RTP8
            context("enter") {

                // RTP8d
                it("implicitly attaches the Channel") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Initialized))
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error).to(beNil())
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))
                }

                // RTP8d
                it("should result in an error if the channel is in the FAILED state") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    channel.onError(AblyTests.newErrorProtocolMessage())

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))
                }

                // RTP8d
                it("should result in an error if the channel is in the DETACHED state") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.attach { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                        channel.detach { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

            }

            // RTP10
            context("leave") {

                // RTP10e
                it("should result in an error immediately if the client is anonymous") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leave(nil) { error in
                            expect(error!.message).to(contain("attempted to publish presence message without clientId"))
                            done()
                        }
                    }
                }

                // RTP10e
                it("should result in an error immediately if the channel is DETACHED") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    channel.detach()

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leave(nil) { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

                // RTP10e
                it("should result in an error immediately if the channel is FAILED") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    channel.onError(AblyTests.newErrorProtocolMessage())

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leave(nil) { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

                // RTP10e
                it("should result in an error if the client does not have required presence permission") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken(clientId: "john", capability: "{ \"cannotpresence:other\":[\"publish\"] }")
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("cannotpresence")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leaveClient("other", data: nil) { error in
                            expect(error!.message).to(contain("Channel denied access based on given capability"))
                            done()
                        }
                    }
                }

                // RTP10e
                it("should result in an error if Ably service determines that the client is unidentified") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leave(nil) { error in
                            expect(error!.message).to(contain("presence message without clientId"))
                            done()
                        }
                    }
                }

            }

            // RTP6
            context("subscribe") {

                // RTP6c
                it("should implicitly attach the channel") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Initialized))
                    channel.presence.subscribe { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    channel.detach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)

                    channel.presence.subscribe(.Present) { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                }

                // RTP6c
                it("should result in an error if the channel is in the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let protocolError = AblyTests.newErrorProtocolMessage()
                    channel.onError(protocolError)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribeWithAttachCallback({ error in
                            expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))
                            expect(error).toNot(beNil())
                            done()
                        }, callback: { member in
                            fail("Should not be called")
                        })
                    }
                }

                // RTP6c
                it("should result in an error if the channel moves to the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let error = AblyTests.newErrorProtocolMessage()
                        channel.presence.subscribeWithAttachCallback({ error in
                            expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))
                            expect(error).toNot(beNil())
                            done()
                        }, callback: { member in
                            fail("Should not be called")
                        })
                        channel.onError(error)
                    }
                }

            }

            // RTP8
            context("enter") {

                // RTP8e
                it("optional data can be included when entering a channel") {
                    let options = AblyTests.commonAppSetup()

                    options.clientId = "john"
                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    options.clientId = "mary"
                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    let expectedData = ["data":123]

                    waitUntil(timeout: testTimeout) { done in
                        channel1.attach { error in
                            expect(error).to(beNil())
                            let partlyDone = AblyTests.splitDone(2, done: done)
                            channel1.presence.subscribe(.Enter) { member in
                                expect(member.data as? NSObject).to(equal(expectedData))
                                partlyDone()
                            }
                            channel2.presence.enter(expectedData) { error in
                                expect(error).to(beNil())
                                partlyDone()
                            }
                        }
                    }
                }

                // RTP8e
                it("should emit the data attribute in the LEAVE event when data is provided when entering but no data is provided when leaving") {
                    let options = AblyTests.commonAppSetup()

                    options.clientId = "john"
                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    options.clientId = "mary"
                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    let expectedData = "data"

                    waitUntil(timeout: testTimeout) { done in
                        channel2.presence.enter(expectedData) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel1.attach { err in
                            expect(err).to(beNil())
                            let partlyDone = AblyTests.splitDone(2, done: done)
                            channel1.presence.subscribe(.Leave) { member in
                                expect(member.data as? NSObject).to(equal(expectedData))
                                partlyDone()
                            }
                            channel2.presence.leave(nil) { error in
                                expect(error).to(beNil())
                                partlyDone()
                            }
                        }
                    }
                }

            }

            // RTP17
            pending("private and internal PresenceMap containing only members that match the current connectionId") {

                it("any ENTER, PRESENT, UPDATE or LEAVE event that matches the current connectionId should be applied to this object") {
                    let options = AblyTests.commonAppSetup()

                    options.clientId = "a"
                    let clientA = ARTRealtime(options: options)
                    defer { clientA.dispose(); clientA.close() }
                    let channelA = clientA.channels.get("foo")

                    options.clientId = "b"
                    let clientB = ARTRealtime(options: options)
                    defer { clientB.dispose(); clientB.close() }
                    let channelB = clientB.channels.get("foo")

                    // ENTER
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channelA.presence.subscribe { presence in
                            guard let currentConnectionId = clientA.connection.id else {
                                fail("ClientA should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.Enter))
                            expect(presence.connectionId).to(equal(currentConnectionId))
                            expect(channelA.presenceMap.members).to(haveCount(1))
                            expect(channelA.presenceMap.localMembers).to(haveCount(1))
                            channelA.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.subscribe { presence in
                            guard let currentConnectionId = clientB.connection.id else {
                                fail("ClientB should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.Enter))
                            expect(presence.connectionId).toNot(equal(currentConnectionId))
                            expect(channelB.presenceMap.members).to(haveCount(1))
                            expect(channelB.presenceMap.localMembers).to(haveCount(0))
                            channelB.presence.unsubscribe()
                            partialDone()
                        }
                        channelA.presence.enter(nil)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channelA.presence.subscribe { presence in
                            guard let currentConnectionId = clientA.connection.id else {
                                fail("ClientA should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.Enter))
                            expect(presence.connectionId).toNot(equal(currentConnectionId))
                            expect(channelA.presenceMap.members).to(haveCount(2))
                            expect(channelA.presenceMap.localMembers).to(haveCount(1))
                            channelA.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.subscribe { presence in
                            guard let currentConnectionId = clientB.connection.id else {
                                fail("ClientB should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.Enter))
                            expect(presence.connectionId).to(equal(currentConnectionId))
                            expect(channelB.presenceMap.members).to(haveCount(2))
                            expect(channelB.presenceMap.localMembers).to(haveCount(1))
                            channelB.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.enter(nil)
                    }

                    // UPDATE
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channelA.presence.subscribe { presence in
                            guard let currentConnectionId = clientA.connection.id else {
                                fail("ClientA should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.Update))
                            expect(presence.data as? String).to(equal("hello"))
                            expect(presence.connectionId).toNot(equal(currentConnectionId))
                            expect(channelA.presenceMap.members).to(haveCount(2))
                            expect(channelA.presenceMap.localMembers).to(haveCount(1))
                            channelA.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.subscribe { presence in
                            guard let currentConnectionId = clientB.connection.id else {
                                fail("ClientB should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.Update))
                            expect(presence.data as? String).to(equal("hello"))
                            expect(presence.connectionId).to(equal(currentConnectionId))
                            expect(channelB.presenceMap.members).to(haveCount(2))
                            expect(channelB.presenceMap.localMembers).to(haveCount(1))
                            channelB.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.update("hello")
                    }

                    // LEAVE
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channelA.presence.subscribe { presence in
                            guard let currentConnectionId = clientA.connection.id else {
                                fail("ClientA should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.Leave))
                            expect(presence.data as? String).to(equal("bye"))
                            expect(presence.connectionId).toNot(equal(currentConnectionId))
                            expect(channelA.presenceMap.members).to(haveCount(1))
                            expect(channelA.presenceMap.localMembers).to(haveCount(1))
                            channelA.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.subscribe { presence in
                            guard let currentConnectionId = clientB.connection.id else {
                                fail("ClientB should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.Leave))
                            expect(presence.data as? String).to(equal("bye"))
                            expect(presence.connectionId).to(equal(currentConnectionId))
                            expect(channelB.presenceMap.members).to(haveCount(1))
                            expect(channelB.presenceMap.localMembers).to(haveCount(0))
                            channelB.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.leave("bye")
                    }
                }

                // RTP17a
                it("all members belonging to the current connection are published as a PresenceMessage on the Channel by the server irrespective of whether the client has permission to subscribe or the Channel is configured to publish presence events") {
                    let options = AblyTests.commonAppSetup()
                    options.tokenDetails = getTestTokenDetails(capability: "{\"foo\":[\"presence\",\"publish\"]}")
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            expect(members).to(haveCount(1))
                            expect(channel.presenceMap.members).to(haveCount(1))
                            expect(channel.presenceMap.localMembers).to(haveCount(1))
                            done()
                        }
                    }
                }

            }

            // RTP15d
            it("callback can be provided that will be called upon success") {
                let options = AblyTests.commonAppSetup()
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("room")

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.enterClient("Client 1", data: nil) { errorInfo in
                        expect(errorInfo).to(beNil())
                        done()
                    }
                }
            }

            // RTP15d
            it("callback can be provided that will be called upon failure") {
                let options = AblyTests.clientOptions()
                options.token = getTestToken(capability: "{ \"room\":[\"subscribe\"] }")
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("private-room")

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.enterClient("Client 1", data: nil) { errorInfo in
                        guard let errorInfo = errorInfo else {
                            fail("ErrorInfo is empty"); done()
                            return
                        }
                        expect(errorInfo.code).to(equal(40160))
                        done()
                    }
                }
            }

            // RTP15c
            it("should also ensure that using updateClient has no side effects on a client that has entered normally using Presence#enter") {
                let options = AblyTests.commonAppSetup()
                options.clientId = "john"
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.enter(nil) { error in
                        expect(error).to(beNil())
                        channel.presence.updateClient("john", data:"mobile") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.get() { members, error in
                        expect(members!.first!.data as? String).to(equal("mobile"))
                        done()
                    }
                }
            }

            // RTP15e
            let cases: [String:(ARTRealtimePresence, Optional<(ARTErrorInfo?)->Void>)->()] = [
                "enterClient": { $0.enterClient("john", data: nil, callback: $1) },
                "updateClient": { $0.updateClient("john", data: nil, callback: $1) },
                "leaveClient": { $0.leaveClient("john", data: nil, callback: $1) }
            ]
            for (testCase, performMethod) in cases {
                context(testCase) {
                    it("should implicitly attach the Channel") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        expect(channel.state).to(equal(ARTRealtimeChannelState.Initialized))
                        waitUntil(timeout: testTimeout) { done in
                            //Call: enterClient, updateClient and leaveClient
                            performMethod(channel.presence) { errorInfo in
                                expect(errorInfo).to(beNil())
                                done()
                            }
                            expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))
                    }

                    it("should result in an error if the channel is in the FAILED state") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        channel.onError(AblyTests.newErrorProtocolMessage())

                        waitUntil(timeout: testTimeout) { done in
                            //Call: enterClient, updateClient and leaveClient
                            performMethod(channel.presence) { errorInfo in
                                expect(errorInfo!.message).to(contain("invalid channel state"))
                                done()
                            }
                        }
                    }

                    it("should result in an error if the channel moves to the FAILED state") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            let error = AblyTests.newErrorProtocolMessage()
                            //Call: enterClient, updateClient and leaveClient
                            performMethod(channel.presence) { errorInfo in
                                expect(errorInfo).to(equal(error.error))
                                done()
                            }
                            channel.onError(error)
                        }
                    }
                }
            }

            // RTP15f
            it("should indicate an error if the client is identified and has a valid clientId and the clientId argument does not match the client’s clientId") {
                let options = AblyTests.commonAppSetup()
                options.clientId = "john"
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.enter("browser") { error in
                        expect(error).to(beNil())
                        channel.presence.updateClient("tester", data:"mobile") { error in
                            expect(error!.message).to(contain("mismatched clientId"))
                            done()
                        }
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.get() { members, error in
                        expect(members!.first!.data as? String).to(equal("browser"))
                        done()
                    }
                }
            }

            // RTP16
            context("Connection state conditions") {

                // RTP16a
                it("all presence messages are published immediately if the connection is CONNECTED") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).to(beNil())
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(channel.queuedMessages).to(haveCount(0))
                            done()
                        }
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connecting))
                        expect(channel.queuedMessages).to(haveCount(1))
                    }
                }

                // RTP16b
                it("all presence messages will be queued and delivered as soon as the connection state returns to CONNECTED") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.0
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(client.options.queueMessages).to(beTrue())

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { _ in
                            client.onDisconnected()
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).to(beNil())
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(channel.queuedMessages).to(haveCount(0))
                            done()
                        }
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Disconnected))
                        expect(channel.queuedMessages).to(haveCount(1))
                    }
                }

                // RTP16b
                it("all presence messages will be lost if queueMessages has been explicitly set to false") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.0
                    options.queueMessages = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(client.options.queueMessages).to(beFalse())

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { _ in
                            client.onDisconnected()
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).toNot(beNil())
                            done()
                        }
                        expect(channel.queuedMessages).to(haveCount(0))
                    }
                }

                // RTP16c
                it("should result in an error if the connection state is INITIALIZED") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(client.options.queueMessages).to(beTrue())

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Initialized))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).toNot(beNil())
                            expect(channel.queuedMessages).to(haveCount(0))
                            done()
                        }
                        expect(channel.queuedMessages).to(haveCount(0))
                    }
                }

                // RTP16c
                let cases: [ARTRealtimeConnectionState:(ARTRealtime)->()] = [
                    .Suspended: { client in client.onSuspended() },
                    .Closed: { client in client.close() },
                    .Failed: { client in client.onError(AblyTests.newErrorProtocolMessage()) }
                ]
                for (connectionState, performMethod) in cases {
                    it("should result in an error if the connection state is \(connectionState)") {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        expect(client.options.queueMessages).to(beTrue())

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { _ in
                                performMethod(client)
                                done()
                            }
                        }

                        expect(client.connection.state).toEventually(equal(connectionState), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).toNot(beNil())
                                expect(channel.queuedMessages).to(haveCount(0))
                                done()
                            }
                            expect(channel.queuedMessages).to(haveCount(0))
                        }
                    }
                }

            }

            // RTP11
            context("get") {

                context("query") {
                    it("waitForSync should be true by default") {
                        expect(ARTRealtimePresenceQuery().waitForSync).to(beTrue())
                    }
                }

                // RTP11a
                it("should return a list of current members on the channel") {
                    let options = AblyTests.commonAppSetup()

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.dispose()
                            clientItem.close()
                        }
                    }

                    let expectedData = "online"
                    waitUntil(timeout: testTimeout) { done in
                        disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 150, data:expectedData, options: options) {
                            done()
                        }]
                    }

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    var presenceQueryWasCreated = false
                    let hook = ARTRealtimePresenceQuery.testSuite_injectIntoClassMethod(#selector(ARTRealtimePresenceQuery.init as () -> ARTRealtimePresenceQuery)) { // Default initialiser: referring to the no-parameter variant of `init` as one of several overloaded methods requires an explicit `as <signature>` cast
                        presenceQueryWasCreated = true
                    }
                    defer { hook?.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            expect(members).to(haveCount(150))
                            expect(members!.first).to(beAnInstanceOf(ARTPresenceMessage))
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: "^user(\\d+)$")
                                    && (member!.data as? NSObject) == expectedData
                            }))
                            done()
                        }
                    }

                    expect(presenceQueryWasCreated).to(beTrue())
                }

                // RTP11b
                it("should implicitly attach the channel") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Initialized))
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { membersPage, error in
                            expect(error).to(beNil())
                            expect(membersPage).toNot(beNil())
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))
                }

                // RTP11b
                it("should result in an error if the channel is in the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let pm = AblyTests.newErrorProtocolMessage()
                    channel.onError(pm)

                    guard let protocolError = pm.error else {
                        fail("Protocol error is empty"); return
                    }
                    guard let channelError = channel.errorReason else {
                        fail("Channel error is empty"); return
                    }
                    expect(channelError.message).to(equal(protocolError.message))
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { members, error in
                            guard let error = error else {
                                fail("Error is empty"); done(); return
                            }
                            expect(error.message).to(equal("invalid channel state"))
                            expect(channel.errorReason).to(equal(protocolError))
                            expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))
                            expect(members).to(beNil())
                            done()
                        }
                    }
                }

                // RTP11b
                it("should result in an error if the channel moves to the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let pm = AblyTests.newErrorProtocolMessage()
                        guard let protocolError = pm.error else {
                            fail("Protocol error is empty"); done(); return
                        }
                        channel.presence.get() { members, error in
                            guard let error = error else {
                                fail("Error is empty"); done(); return
                            }
                            expect(error.message).to(equal(protocolError.message))
                            expect(members).to(beNil())
                            done()
                        }
                        channel.onError(pm)
                    }

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))
                }

                // RTP11b
                it("should result in an error if the channel is in the DETACHED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach()
                        channel.detach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { members, error in
                            guard let error = error else {
                                fail("Error is empty"); done(); return
                            }
                            expect(error.message).to(equal("invalid channel state"))
                            expect(members).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                            done()
                        }
                    }
                }

                // RTP11b
                it("should result in an error if the channel moves to the DETACHED state") {
                    let options = AblyTests.commonAppSetup()

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    var clientMembers: ARTRealtime?
                    defer { clientMembers?.dispose(); clientMembers?.close() }
                    waitUntil(timeout: testTimeout) { done in
                        clientMembers = AblyTests.addMembersSequentiallyToChannel("test", members: 120, options: options) {
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.get() { members, error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(equal("channel is being DETACHED"))
                            expect(members).to(beNil())
                            partialDone()
                        }
                        channel.detach() { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)
                }

                // RTP11c
                context("Query (set of params)") {

                    // RTP11c1
                    it("waitForSync is true, should wait until SYNC is complete before returning a list of members") {
                        let options = AblyTests.commonAppSetup()
                        var clientSecondary: ARTRealtime!
                        defer { clientSecondary.dispose(); clientSecondary.close() }

                        waitUntil(timeout: testTimeout) { done in
                            clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, options: options) {
                                done()
                            }
                        }

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        let query = ARTRealtimePresenceQuery()
                        expect(query.waitForSync).to(beTrue())

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                let transport = client.transport as! TestProxyTransport
                                transport.beforeProcessingReceivedMessage = { protocolMessage in
                                    if protocolMessage.action == .Sync {
                                        expect(protocolMessage.presence!.count).to(equal(100))
                                        channel.presence.get(query) { members, error in
                                            expect(error).to(beNil())
                                            expect(members).to(haveCount(150))
                                            done()
                                        }
                                        transport.beforeProcessingReceivedMessage = nil
                                    }
                                }
                            }
                        }
                    }

                    // RTP11c1
                    it("waitForSync is false, should return immediately the known set of presence members") {
                        let options = AblyTests.commonAppSetup()
                        var clientSecondary: ARTRealtime!
                        defer { clientSecondary.dispose(); clientSecondary.close() }

                        waitUntil(timeout: testTimeout) { done in
                            clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, options: options) {
                                done()
                            }
                        }

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        let query = ARTRealtimePresenceQuery()
                        query.waitForSync = false

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                let transport = client.transport as! TestProxyTransport
                                transport.beforeProcessingReceivedMessage = { message in
                                    if message.action == .Sync && channel.isLastChannelSerial(message.channelSerial!)  {
                                        channel.presence.get(query) { members, error in
                                            expect(error).to(beNil())
                                            expect(members).to(haveCount(100))
                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }

                }

            }

            // RTP12
            context("history") {

                // RTP12a
                it("should support all the same params as Rest") {
                    let options = AblyTests.commonAppSetup()

                    let rest = ARTRest(options: options)

                    let realtime = ARTRealtime(options: options)
                    defer { realtime.close() }

                    var restPresenceHistoryMethodWasCalled = false
                    var hook = ARTRestPresence.testSuite_injectIntoClassMethod(#selector(ARTRestPresence.history(_:callback:))) {
                        restPresenceHistoryMethodWasCalled = true
                    }
                    defer { hook?.remove() }

                    let channelRest = rest.channels.get("test")
                    let channelRealtime = realtime.channels.get("test")

                    let queryRealtime = ARTRealtimeHistoryQuery()
                    queryRealtime.start = NSDate()
                    queryRealtime.end = NSDate()
                    queryRealtime.direction = .Forwards
                    queryRealtime.limit = 50

                    let queryRest = queryRealtime as ARTDataQuery

                    waitUntil(timeout: testTimeout) { done in
                        try! channelRest.presence.history(queryRest) { _, _ in
                            done()
                        }
                    }
                    expect(restPresenceHistoryMethodWasCalled).to(beTrue())
                    restPresenceHistoryMethodWasCalled = false

                    waitUntil(timeout: testTimeout) { done in
                        try! channelRealtime.presence.history(queryRealtime) { _, _ in
                            done()
                        }
                    }
                    expect(restPresenceHistoryMethodWasCalled).to(beTrue())
                }

            }

            // RTP12
            context("history") {

                // RTP12c, RTP12d
                it("should return a PaginatedResult page") {
                    let options = AblyTests.commonAppSetup()

                    var clientSecondary: ARTRealtime!
                    defer { clientSecondary.dispose(); clientSecondary.close() }

                    let expectedData = ["x", "y"]
                    let expectedPattern = "^user(\\d+)$"
                    waitUntil(timeout: testTimeout) { done in
                        clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, data: expectedData, options: options) {
                            done()
                        }
                    }

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.history { membersPage, error in
                            expect(error).to(beNil())

                            let membersPage = membersPage!
                            expect(membersPage).to(beAnInstanceOf(ARTPaginatedResult))
                            expect(membersPage.items).to(haveCount(100))

                            let members = membersPage.items as! [ARTPresenceMessage]
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                    && (member!.data as? NSObject) == expectedData
                            }))

                            expect(membersPage.hasNext).to(beTrue())
                            expect(membersPage.isLast).to(beFalse())

                            membersPage.next { nextPage, error in
                                expect(error).to(beNil())
                                let nextPage = nextPage!
                                expect(nextPage).to(beAnInstanceOf(ARTPaginatedResult))
                                expect(nextPage.items).to(haveCount(50))

                                let members = nextPage.items as! [ARTPresenceMessage]
                                expect(members).to(allPass({ member in
                                    return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                        && (member!.data as? NSObject) == expectedData
                                }))

                                expect(nextPage.hasNext).to(beFalse())
                                expect(nextPage.isLast).to(beTrue())
                                done()
                            }
                        }
                    }
                }

            }

            // RTP12
            context("history") {

                // RTP12b
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
                            try channel.presence.history(query, callback: { _, _ in })
                        }
                        catch let error as NSError {
                            if error.code == ARTRealtimeHistoryError.NotAttached.rawValue {
                                return
                            }
                            fail("Shouldn't raise a global error, got \(error)")
                        }
                        fail("Should raise an error")
                    }

                    struct CaseTest {
                        let untilAttach: Bool
                    }

                    let cases = [CaseTest(untilAttach: true), CaseTest(untilAttach: false)]

                    for caseItem in cases {
                        it("where value is \(caseItem.untilAttach), should pass the querystring param fromSerial with the serial number assigned to the channel") {
                            let client = ARTRealtime(options: AblyTests.commonAppSetup())
                            defer { client.dispose(); client.close() }
                            let channel = client.channels.get("test")

                            let testHTTPExecutor = TestProxyHTTPExecutor()
                            client.rest.httpExecutor = testHTTPExecutor

                            let query = ARTRealtimeHistoryQuery()
                            query.untilAttach = caseItem.untilAttach

                            channel.attach()
                            expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                            waitUntil(timeout: testTimeout) { done in
                                try! channel.presence.history(query) { _, errorInfo in
                                    expect(errorInfo).to(beNil())
                                    done()
                                }
                            }

                            let queryString = testHTTPExecutor.requests.last!.URL!.query

                            if query.untilAttach {
                                expect(queryString).to(contain("fromSerial=\(channel.attachSerial!)"))
                            }
                            else {
                                expect(queryString).toNot(contain("fromSerial"))
                            }
                        }
                    }

                    it("should retrieve members prior to the moment that the channel was attached") {
                        let options = AblyTests.commonAppSetup()

                        var disposable = [ARTRealtime]()
                        defer {
                            for clientItem in disposable {
                                clientItem.dispose()
                                clientItem.close()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 25, options: options) {
                                done()
                            }]
                        }

                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { _ in
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            disposable += [AblyTests.addMembersSequentiallyToChannel("test", startFrom: 26, members: 35, options: options) {
                                done()
                            }]
                        }

                        let query = ARTRealtimeHistoryQuery()
                        query.untilAttach = true

                        waitUntil(timeout: testTimeout) { done in
                            try! channel.presence.history(query) { result, errorInfo in
                                expect(result!.items).to(haveCount(25))
                                expect(result!.hasNext).to(beFalse())
                                expect((result!.items.first as? ARTPresenceMessage)?.clientId).to(equal("user25"))
                                expect((result!.items.last as? ARTPresenceMessage)?.clientId).to(equal("user1"))
                                done()
                            }
                        }
                    }

                }

            }

            // RTP13
            it("Presence#syncComplete returns true if the initial SYNC operation has completed") {
                let options = AblyTests.commonAppSetup()

                var disposable = [ARTRealtime]()
                defer {
                    for clientItem in disposable {
                        clientItem.dispose()
                        clientItem.close()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 250, options: options) {
                        done()
                    }]
                }

                let client = AblyTests.newRealtime(options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")
                channel.attach()

                expect(channel.presence.syncComplete).to(beFalse())
                expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                let transport = client.transport as! TestProxyTransport
                transport.beforeProcessingReceivedMessage = { protocolMessage in
                    if protocolMessage.action == .Sync {
                        expect(channel.presence.syncComplete).to(beFalse())
                    }
                }

                expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
                expect(transport.protocolMessagesReceived.filter({ $0.action == .Sync })).to(haveCount(3))
            }

            // RTP14
            context("enterClient") {

                // RTP14a, RTP14b, RTP14c, RTP14d
                it("enters into presence on a channel on behalf of another clientId") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(channel.presenceMap.members).to(haveCount(0))

                    let expectedData = ["test":1]

                    var encodeNumberOfCalls = 0
                    let hookEncode = channel.dataEncoder.testSuite_injectIntoMethodAfter(#selector(ARTDataEncoder.encode(_:))) {
                        encodeNumberOfCalls += 1
                    }
                    defer { hookEncode.remove() }

                    var decodeNumberOfCalls = 0
                    let hookDecode = channel.dataEncoder.testSuite_injectIntoMethodAfter(#selector(ARTDataEncoder.decode(_:encoding:))) {
                        decodeNumberOfCalls += 1
                    }
                    defer { hookDecode.remove() }


                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("test", data: expectedData)  { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    channel.presence.enterClient("john", data: nil)
                    channel.presence.enterClient("sara", data: nil)
                    expect(channel.presenceMap.members).toEventually(haveCount(3), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { members, error in
                            guard let members = members?.reduce([String:ARTPresenceMessage](), combine: { (dictionary, item) in
                                return dictionary + [item.clientId ?? "":item]
                            }) else { fail("No members"); done(); return }

                            expect(members["test"]!.data as? NSDictionary).to(equal(expectedData))
                            expect(members["john"]).toNot(beNil())
                            expect(members["sara"]).toNot(beNil())
                            done()
                        }
                    }

                    expect(encodeNumberOfCalls).to(equal(1))
                    expect(decodeNumberOfCalls).to(equal(1))
                }

            }

        }
    }
}
