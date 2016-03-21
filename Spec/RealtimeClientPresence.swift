//
//  RealtimeClientPresence.swift
//  Ably
//
//  Created by Ricardo Pereira on 07/03/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble
import Foundation

class RealtimeClientPresence: QuickSpec {
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
                    defer { client.close() }
                    let channel = client.channels.get("test")
                    channel.attach()

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    let transport = client.transport as! TestProxyTransport
                    let attached = transport.protocolMessagesReceived.filter({ $0.action == .Attached })[0]

                    expect(attached.flags & 0x1).to(equal(0))
                    expect(attached.isSyncEnabled()).to(beFalse())
                    expect(channel.presence.syncComplete).to(beFalse())
                    expect(channel.presenceMap.syncComplete).to(beFalse())
                }

                it("when members are present") {
                    let options = AblyTests.commonAppSetup()

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.close()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        disposable += AblyTests.addMembersSequentiallyToChannel("test", members: 250, options: options) {
                            done()
                        }
                    }

                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport)
                    client.connect()
                    defer { client.close() }
                    let channel = client.channels.get("test")
                    channel.attach()

                    expect(channel.presence.syncComplete).to(beFalse())
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    let transport = client.transport as! TestProxyTransport
                    let attached = transport.protocolMessagesReceived.filter({ $0.action == .Attached })[0]

                    // There are members present on the channel
                    expect(attached.flags & 0x1).to(equal(1))
                    expect(attached.isSyncEnabled()).to(beTrue())
                    
                    expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)

                    expect(transport.protocolMessagesReceived.filter({ $0.action == .Sync })).to(haveCount(3))
                }

            }

            // RTP3
            it("should complete the SYNC operation when the connection is disconnected unexpectedly") {
                let options = AblyTests.commonAppSetup()
                options.disconnectedRetryTimeout = 1.0
                var clientSecondary: ARTRealtime!
                defer { clientSecondary.close() }

                waitUntil(timeout: testTimeout) { done in
                    clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, options: options) {
                        done()
                    }.first
                }

                let client = AblyTests.newRealtime(options)
                defer { client.close() }
                let channel = client.channels.get("test")

                var lastSyncSerial: String?
                waitUntil(timeout: testTimeout) { done in
                    channel.attach() { _ in
                        let transport = client.transport as! TestProxyTransport
                        transport.afterProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .Sync {
                                lastSyncSerial = protocolMessage.channelSerial
                                client.onDisconnected()
                                done()
                            }
                        }
                    }
                }

                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connecting), timeout: options.disconnectedRetryTimeout + 1.0)
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                //Client library requests a SYNC resume by sending a SYNC ProtocolMessage with the last received sync serial number
                let transport = client.transport as! TestProxyTransport
                expect(transport.protocolMessagesSent.filter{ $0.action == .Sync }).toEventually(haveCount(1), timeout: testTimeout)
                expect(transport.protocolMessagesSent.filter{ $0.action == .Sync }.first!.channelSerial).to(equal(lastSyncSerial))

                expect(transport.protocolMessagesReceived.filter{ $0.action == .Sync }).toEventually(haveCount(2), timeout: testTimeout)
            }

            // RTP4
            it("should receive all 250 members") {
                let options = AblyTests.commonAppSetup()
                var clientSource: ARTRealtime!
                defer { clientSource.close() }

                waitUntil(timeout: testTimeout) { done in
                    clientSource = AblyTests.addMembersSequentiallyToChannel("test", members: 250, options: options) {
                        done()
                    }.first
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
                    defer { client.close() }
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
                it("all queued presence messages should fail immediately if the channel enters the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let protocolError = AblyTests.newErrorProtocolMessage()
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).to(beIdenticalTo(protocolError.error))
                            done()
                        }
                        channel.onError(protocolError)
                    }
                }


                // RTP5a
                it("all queued presence messages should fail immediately if the channel enters the DETACHED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).toNot(beNil())
                            done()
                        }
                        channel.detach()
                    }
                }

            }


            // RTP5
            context("Channel state change side effects") {

                // RTP5b
                it("all queued presence messages will be sent immediately and a presence SYNC will be initiated implicitly if a channel enters the ATTACHED state") {
                    let options = AblyTests.commonAppSetup()
                    let client1 = AblyTests.newRealtime(options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("room")

                    waitUntil(timeout: testTimeout) { done in
                        channel1.presence.enterClient("Client 1", data: nil) { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }

                    let client2 = AblyTests.newRealtime(options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get(channel1.name)

                    channel2.presence.enterClient("Client 2", data: nil) { error in
                        expect(error).to(beNil())
                        expect(channel2.queuedMessages).to(haveCount(0))
                        expect(channel2.state).to(equal(ARTRealtimeChannelState.Attached))
                    }
                    expect(channel2.queuedMessages).to(haveCount(1))

                    expect(channel2.presence.syncComplete).to(beFalse())

                    expect(channel1.presenceMap.members).to(haveCount(1))
                    expect(channel2.presenceMap.members).to(haveCount(0))

                    expect(channel2.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                    
                    expect(channel2.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
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
                    defer { client.close() }
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
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Initialized))
                    channel.presence.subscribe { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    channel.detach()

                    channel.presence.subscribe(.Present) { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                }

                // RTP6c
                it("should result in an error if the channel is in the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }

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
                    defer { client.close() }
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

                    waitUntil(timeout: testTimeout) { done in
                        channel1.presence.subscribe(.Update) { member in
                            expect(member.action).to(equal(ARTPresenceAction.Update))
                            expect(member.clientId).to(equal("john"))
                            expect(member.data as? NSObject).to(equal("away"))
                            done()
                        }
                        channel2.presence.enterClient("john", data: "online")
                        channel2.presence.updateClient("john", data: "away")
                        channel2.presence.leaveClient("john", data: nil)
                    }
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

            }

            // RTP8
            context("enter") {

                // RTP8f
                it("should result in an error immediately if the client is anonymous") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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

            }

            // RTP10
            context("leave") {

                // RTP10a
                it("should leave the current client from the channel and the data will be updated with the value provided") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.close() }
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
                    defer { client.close() }
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
            pending("should be used a PresenceMap to maintain a list of members") {
                let options = AblyTests.commonAppSetup()
                var clientSecondary: ARTRealtime!
                defer { clientSecondary.close() }

                waitUntil(timeout: testTimeout) { done in
                    clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 100, options: options) {
                        done()
                    }.first
                }

                let client = AblyTests.newRealtime(options)
                defer { client.close() }
                let channel = client.channels.get("test")

                var user50LeaveTimestamp: NSDate?
                channel.presence.subscribe(.Leave) { member in
                    expect(member.clientId).to(equal("user50"))
                    user50LeaveTimestamp = member.timestamp
                }

                var user50PresentTimestamp: NSDate?
                channel.presenceMap.testSuite_getArgumentFrom("put:", atIndex: 0) { arg0 in
                    let member = arg0 as! ARTPresenceMessage
                    if member.clientId == "user50" && member.action == .Present {
                        user50PresentTimestamp = member.timestamp
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.attach() { _ in
                        let transport = client.transport as! TestProxyTransport
                        transport.beforeProcessingReceivedMessage = { protocolMessage in
                            // A leave event for a member can arrive before that member is later registered as present as part of the initial SYNC operation.
                            if protocolMessage.action == .Sync {
                                let msg = AblyTests.newPresenceProtocolMessage("test", action: .Leave, clientId: "user50")
                                // Ensure it happens "later" than the PRESENT message.
                                msg.timestamp = NSDate().dateByAddingTimeInterval(1.0)
                                client.onChannelMessage(msg)
                                done()
                            }
                        }
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.get { members, error in
                        expect(error).to(beNil())
                        expect(members).to(haveCount(99))
                        expect(members!.filter{ $0.clientId == "user50" }).to(haveCount(0))
                        done()
                    }
                }

                expect(user50LeaveTimestamp).to(beGreaterThan(user50PresentTimestamp))
            }

            // RTP8
            context("enter") {
                // RTP8h
                it("should result in an error if the client does not have required presence permission") {
                    let options = AblyTests.commonAppSetup()
                    options.token = getTestToken(capability: "{ \"cannotpresence:john\":[\"publish\"] }")
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
                    let channel = client.channels.get("test")

                                        channel.attach()
                    channel.detach()

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

                // RTP9e
                it("should result in an error immediately if the channel is FAILED") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    channel.onError(AblyTests.newErrorProtocolMessage())

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

                // RTP9e
                it("should result in an error if the client does not have required presence permission") {
                    let options = AblyTests.clientOptions()
                    options.token = getTestToken(capability: "{ \"cannotpresence:john\":[\"publish\"] }")
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.close() }
                    let channel = client.channels.get("cannotpresence")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            expect(error!.message).to(contain("Channel denied access based on given capability"))
                            done()
                        }
                    }
                }

                // RTP9e
                it("should result in an error if Ably service determines that the client is unidentified") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            expect(error!.message).to(contain("presence message without clientId"))
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
                    defer { client.close() }
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
                    let client = ARTRealtime(options: options)
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let protocolError = AblyTests.newErrorProtocolMessage()
                        channel.presence.leave("offline") { error in
                            expect(error).to(beIdenticalTo(protocolError.error))
                            done()
                        }
                        channel.onError(protocolError)
                    }
                }

                it("should raise an exception if client is not present") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.close() }
                    let channel = client.channels.get("test")
                    expect(channel.presence.leave("offline")).to(raiseException())
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
                        defer { client.close() }
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
                        defer { client.close() }
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
                        defer { client.close() }
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

            // RTP16
            context("Connection state conditions") {

                // RTP16a
                it("all presence messages are published immediately if the connection is CONNECTED") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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
                    defer { client.close() }
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
                        defer { client.close() }
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
                            clientItem.close()
                        }
                    }

                    let expectedData = "online"
                    waitUntil(timeout: testTimeout) { done in
                        disposable += AblyTests.addMembersSequentiallyToChannel("test", members: 150, data:expectedData, options: options) {
                            done()
                        }
                    }

                    let client = ARTRealtime(options: options)
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    var presenceQueryWasCreated = false
                    let hook = ARTRealtimePresenceQuery.testSuite_injectIntoClassMethod("init") { // Default initialiser
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
                    defer { client.close() }
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
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    channel.onError(AblyTests.newErrorProtocolMessage())

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { members, error in
                            expect(error!.message).to(contain("can't attach when in a failed state"))
                            expect(members).to(beNil())
                            done()
                        }
                    }
                }

                // RTP11b
                it("should result in an error if the channel moves to the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let protoError = AblyTests.newErrorProtocolMessage()
                        channel.presence.get() { members, error in
                            expect(error).to(equal(protoError.error))
                            expect(members).to(beNil())
                            done()
                        }
                        channel.onError(protoError)
                    }
                }

                // RTP11c
                context("Query (set of params)") {

                    // RTP11c1
                    it("waitForSync is true, should wait until SYNC is complete before returning a list of members") {
                        let options = AblyTests.commonAppSetup()
                        var clientSecondary: ARTRealtime!
                        defer { clientSecondary.close() }

                        waitUntil(timeout: testTimeout) { done in
                            clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, options: options) {
                                done()
                            }.first
                        }

                        let client = AblyTests.newRealtime(options)
                        defer { client.close() }
                        let channel = client.channels.get("test")

                        let query = ARTRealtimePresenceQuery()
                        expect(query.waitForSync).to(beTrue())

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                let transport = client.transport as! TestProxyTransport
                                transport.beforeProcessingReceivedMessage = { protocolMessage in
                                    if protocolMessage.action == .Sync {
                                        channel.presence.get(query) { members, error in
                                            expect(error).to(beNil())
                                            expect(members).to(haveCount(150))
                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // RTP11c1
                    it("waitForSync is false, should return immediately the known set of presence members") {
                        let options = AblyTests.commonAppSetup()
                        var clientSecondary: ARTRealtime!
                        defer { clientSecondary.close() }

                        waitUntil(timeout: testTimeout) { done in
                            clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, options: options) {
                                done()
                            }.first
                        }

                        let client = AblyTests.newRealtime(options)
                        defer { client.close() }
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
                    var hook = ARTRestPresence.testSuite_injectIntoClassMethod("history:callback:error:") {
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
                    defer { clientSecondary.close() }

                    let expectedData = ["x", "y"]
                    let expectedPattern = "^user(\\d+)$"
                    waitUntil(timeout: testTimeout) { done in
                        clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, data: expectedData, options: options) {
                            done()
                        }.first
                    }

                    let client = ARTRealtime(options: options)
                    defer { client.close() }
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

        }
    }
}
