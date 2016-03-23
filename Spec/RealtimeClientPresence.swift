//
//  RealtimeClientPresence.swift
//  Ably
//
//  Created by Ricardo Pereira on 07/03/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble

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
            pending("should complete the SYNC operation when the connection is disconnected unexpectedly") {
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
                        transport.beforeProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .Sync {
                                lastSyncSerial = protocolMessage.channelSerial
                                client.onDisconnected()
                                done()
                            }
                        }
                    }
                }

                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connecting), timeout: options.disconnectedRetryTimeout + 1.0)

                //Client library requests a SYNC resume by sending a SYNC ProtocolMessage with the last received sync serial number
                let transport = client.transport as! TestProxyTransport
                expect(transport.protocolMessagesSent.filter{ $0.action == .Sync }).toEventually(haveCount(1), timeout: testTimeout)
                expect(transport.protocolMessagesSent.filter{ $0.action == .Sync }.first!.channelSerial).to(equal(lastSyncSerial))

                expect(transport.protocolMessagesReceived.filter{ $0.action == .Sync }).to(haveCount(2))
            }

            // RTP4
            pending("should receive all 250 members") {
                let options = AblyTests.commonAppSetup()
                var clientSource: ARTRealtime!
                defer { clientSource.close() }

                let clientTarget = ARTRealtime(options: options)
                defer { clientTarget.close() }
                let channel = clientTarget.channels.get("test")

                channel.presence.subscribe { member in
                    expect(member.action).to(equal(ARTPresenceAction.Present))
                }

                waitUntil(timeout: testTimeout) { done in
                    clientSource = AblyTests.addMembersSequentiallyToChannel("test", members: 250, options: options) {
                        done()
                    }.first
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
                pending("with no arguments should subscribe a listener to all presence messages") {
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

                    channel2.presence.enterClient("john", data: "online")
                    channel2.presence.updateClient("john", data: "away")
                    channel2.presence.leaveClient("john", data: nil)

                    expect(receivedMembers).toEventually(haveCount(3), timeout: testTimeout)

                    expect(receivedMembers[0].action).to(equal(ARTPresenceAction.Enter))
                    expect(receivedMembers[0].data as? NSObject).to(equal("online"))
                    expect(receivedMembers[0].clientId).to(equal("john"))

                    expect(receivedMembers[1].action).to(equal(ARTPresenceAction.Update))
                    expect(receivedMembers[1].data as? NSObject).to(equal("away"))
                    expect(receivedMembers[1].clientId).to(equal("john"))

                    expect(receivedMembers[2].action).to(equal(ARTPresenceAction.Leave))
                    expect(receivedMembers[2].data).to(beNil())
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

                    let listener = channel.presence.subscribe { _ in }
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
                pending("all queued presence messages should fail immediately if the channel enters the DETACHED state") {
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
                pending("all queued presence messages will be sent immediately and a presence SYNC will be initiated implicitly if a channel enters the ATTACHED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    let channel = client.channels.get("test")
                    channel.attach()

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).to(beNil())
                            expect(channel.queuedMessages).to(haveCount(0))
                            done()
                        }
                        expect(channel.queuedMessages).to(haveCount(1))
                    }

                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))
                    expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
                    expect(channel.presenceMap.members).to(haveCount(1))
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
                    ARTRealtimePresenceQuery.testSuite_injectIntoClassMethod("init") { // Default initialiser
                        presenceQueryWasCreated = true
                    }

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
                pending("should result in an error if the channel is in the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    channel.onError(AblyTests.newErrorProtocolMessage())

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { members, error in
                            expect(error!.message).to(contain("invalid channel state"))
                            expect(members).to(beNil())
                            done()
                        }
                    }
                }

                // RTP11b
                pending("should result in an error if the channel moves to the FAILED state") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let error = AblyTests.newErrorProtocolMessage()
                        channel.presence.get() { members, error in
                            expect(error).to(equal(error))
                            expect(members).to(beNil())
                            done()
                        }
                        channel.onError(error)
                    }
                }

            }

        }
    }
}
