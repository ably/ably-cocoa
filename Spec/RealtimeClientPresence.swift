import Ably
import Quick
import Nimble
import Foundation
import Aspects
                private let channelName = NSUUID().uuidString

                // RTP16c
                private func testResultsInErrorWithConnectionState(_ connectionState: ARTRealtimeConnectionState, performMethod: @escaping (ARTRealtime) -> ()) {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(client.internal.options.queueMessages).to(beTrue())
                    
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
                            expect(client.internal.queuedMessages).to(haveCount(0))
                            done()
                        }
                        expect(client.internal.queuedMessages).to(haveCount(0))
                    }
                }
                    private func getSuspendedChannel() -> (ARTRealtimeChannel, ARTRealtime) {
                        let options = AblyTests.commonAppSetup()
                        
                        let client = ARTRealtime(options: options)
                        let channel = client.channels.get("test")
                        
                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.suspended) { _ in
                                done()
                            }
                            client.internal.onSuspended()
                        }
                        
                        return (channel, client)
                    }
                    
                    private func testSuspendedStateResultsInError(_ getPresence: (ARTRealtimeChannel, @escaping ([ARTPresenceMessage]?, ARTErrorInfo?) -> Void) -> Void) {
                        let (channel, client) = getSuspendedChannel()
                        defer { client.dispose(); client.close() }
                        
                        getPresence(channel) { result, err in
                            expect(result).to(beNil())
                            expect(err).toNot(beNil())
                            guard let err = err else {
                                return
                            }
                            expect(err.code).to(equal(ARTErrorCode.presenceStateIsOutOfSync.intValue))
                        }
                    }
                        private let getParams: ARTRealtimePresenceQuery = {
                            let getParams = ARTRealtimePresenceQuery()
                            getParams.waitForSync = false
                            return getParams
                        }()

class RealtimeClientPresence: XCTestCase {

    override func setUp() {
        super.setUp()
        AsyncDefaults.timeout = testTimeout
    }

override class var defaultTestSuite : XCTestSuite {
    let _ = channelName
    let _ = getParams

    return super.defaultTestSuite
}

        

            // RTP1
            

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                func skipped__test__009__Presence__ProtocolMessage_bit_flag__when_no_members_are_present() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.internal.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get(channelName)
                    channel.attach()

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    let transport = client.internal.transport as! TestProxyTransport
                    let attached = transport.protocolMessagesReceived.filter({ $0.action == .attached })[0]

                    expect(attached.flags & 0x1).to(equal(0))
                    expect(attached.hasPresence).to(beFalse())
                    expect(channel.presence.syncComplete).to(beFalse())
                    expect(channel.internal.presenceMap.syncComplete).to(beFalse())
                }

                func skipped__test__010__Presence__ProtocolMessage_bit_flag__when_members_are_present() {
                    let options = AblyTests.commonAppSetup()

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.dispose()
                            clientItem.close()
                        }
                    }

                    disposable += [AblyTests.addMembersSequentiallyToChannel(channelName, members: 250, options: options)]

                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.internal.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get(channelName)
                    channel.attach()

                    expect(channel.presence.syncComplete).to(beFalse())
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    let transport = client.internal.transport as! TestProxyTransport
                    let attached = transport.protocolMessagesReceived.filter({ $0.action == .attached })[0]

                    // There are members present on the channel
                    expect(attached.flags & 0x1).to(equal(1))
                    expect(attached.hasPresence).to(beTrue())
                    
                    expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)

                    expect(transport.protocolMessagesReceived.filter({ $0.action == .sync })).to(haveCount(3))
                }

            // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
            // RTP3
            func skipped__test__001__Presence__should_complete_the_SYNC_operation_when_the_connection_is_disconnected_unexpectedly() {
                let membersCount = 110

                let options = AblyTests.commonAppSetup()
                var clientSecondary: ARTRealtime!
                defer { clientSecondary.dispose(); clientSecondary.close() }

                clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: membersCount, options: options)

                let client = AblyTests.newRealtime(options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")

                var lastSyncSerial: String?
                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(2, done: done)
                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }
                    transport.setBeforeIncomingMessageModifier({ protocolMessage in
                        if protocolMessage.action == .sync {
                            lastSyncSerial = protocolMessage.channelSerial
                            expect(lastSyncSerial).toNot(beNil())
                            client.internal.onDisconnected()
                            partialDone()
                            transport.setBeforeIncomingMessageModifier(nil)
                        }
                        return protocolMessage
                    })
                    channel.attach() { _ in
                        partialDone()
                    }
                }

                expect(channel.internal.presenceMap.members).toNot(haveCount(membersCount))
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connecting), timeout: DispatchTimeInterval.milliseconds(Int(1000.0 * (options.disconnectedRetryTimeout + 1.0))))
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                // Client library requests a SYNC resume by sending a SYNC ProtocolMessage with the last received sync serial number
                guard let transport = client.internal.transport as? TestProxyTransport else {
                    fail("TestProxyTransport is not set"); return
                }

                let syncSentProtocolMessages = transport.protocolMessagesSent.filter({ $0.action == .sync })
                guard let syncSentMessage = syncSentProtocolMessages.last, syncSentProtocolMessages.count == 1 else {
                    fail("Should send one SYNC protocol message"); return
                }
                expect(syncSentMessage.channelSerial).to(equal(lastSyncSerial))

                expect(transport.protocolMessagesReceived.filter{ $0.action == .sync }).toEventually(haveCount(2), timeout: testTimeout)

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.get { members, error in
                        expect(error).to(beNil())
                        guard let members = members else {
                            fail("No present members"); done(); return
                        }
                        expect(members).to(haveCount(membersCount))
                        done()
                    }
                }
            }

            // RTP18
            

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP18a, RTP18b
                func skipped__test__011__Presence__realtime_system_reserves_the_right_to_initiate_a_sync_of_the_presence_members_at_any_point_once_a_channel_is_attached__should_do_a_new_sync_whenever_a_SYNC_ProtocolMessage_is_received_with_a_channel_attribute_and_a_new_sync_sequence_identifier_in_the_channelSerial_attribute() {
                    let options = AblyTests.commonAppSetup()
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    expect(channel.internal.presenceMap.syncInProgress).to(beFalse())
                    expect(channel.internal.presenceMap.members).to(beEmpty())

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.present) { msg in
                            if msg.clientId != "a" {
                                return
                            }
                            expect(channel.presence.syncComplete).to(beFalse())
                            var aClientHasLeft = false;
                            channel.presence.subscribe(.leave) { _ in
                                if (aClientHasLeft) {
                                    return
                                }
                                aClientHasLeft = true;
                                done()
                            }
                        }

                        guard let lastConnectionSerial = transport.protocolMessagesReceived.last?.connectionSerial else {
                            fail("No protocol message has been received yet"); done(); return
                        }

                        // Inject a SYNC Presence message (first page)
                        let sync1Message = ARTProtocolMessage()
                        sync1Message.action = .sync
                        sync1Message.channel = channel.name
                        sync1Message.channelSerial = "sequenceid:cursor"
                        sync1Message.connectionSerial = lastConnectionSerial + 1
                        sync1Message.timestamp = Date()
                        sync1Message.presence = [
                            ARTPresenceMessage(clientId: "a", action: .present, connectionId: "another", id: "another:0:0"),
                            ARTPresenceMessage(clientId: "b", action: .present, connectionId: "another", id: "another:0:1"),
                        ]
                        transport.receive(sync1Message)

                        // Inject a SYNC Presence message (last page)
                        let sync2Message = ARTProtocolMessage()
                        sync2Message.action = .sync
                        sync2Message.channel = channel.name
                        sync2Message.channelSerial = "sequenceid:" //indicates SYNC is complete
                        sync2Message.connectionSerial = lastConnectionSerial + 2
                        sync2Message.timestamp = Date()
                        sync2Message.presence = [
                            ARTPresenceMessage(clientId: "a", action: .leave, connectionId: "another", id: "another:1:0"),
                        ]
                        delay(0.5) {
                            transport.receive(sync2Message)
                        }
                    }

                    expect(channel.presence.syncComplete).to(beTrue())
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members, members.count == 1 else {
                                fail("Should at least have 1 member"); done(); return
                            }
                            expect(members[0].clientId).to(equal("b"))
                            done()
                        }
                    }
                }

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP18c, RTP18b
                func skipped__test__012__Presence__realtime_system_reserves_the_right_to_initiate_a_sync_of_the_presence_members_at_any_point_once_a_channel_is_attached__when_a_SYNC_is_sent_with_no_channelSerial_attribute_then_the_sync_data_is_entirely_contained_within_that_ProtocolMessage() {
                    let options = AblyTests.commonAppSetup()
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)
                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    expect(channel.internal.presenceMap.syncInProgress).to(beFalse())
                    expect(channel.internal.presenceMap.members).to(beEmpty())

                    waitUntil(timeout: testTimeout) { done in
                        var aClientHasLeft = false;
                        channel.presence.subscribe(.leave) { error in
                            if (aClientHasLeft) {
                                return
                            }
                            aClientHasLeft = true;
                            done()
                        }

                        guard let lastConnectionSerial = transport.protocolMessagesReceived.last?.connectionSerial else {
                            fail("No protocol message has been received yet"); done(); return
                        }

                        // Inject a SYNC Presence message (entirely contained)
                        let syncMessage = ARTProtocolMessage()
                        syncMessage.action = .sync
                        syncMessage.channel = channel.name
                        syncMessage.connectionSerial = lastConnectionSerial + 1
                        syncMessage.timestamp = Date()
                        syncMessage.presence = [
                            ARTPresenceMessage(clientId: "a", action: .present, connectionId: "another", id: "another:0:0"),
                            ARTPresenceMessage(clientId: "b", action: .present, connectionId: "another", id: "another:0:1"),
                            ARTPresenceMessage(clientId: "a", action: .leave, connectionId: "another", id: "another:1:0"),
                        ]
                        transport.receive(syncMessage)
                    }

                    expect(channel.presence.syncComplete).to(beTrue())
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members, members.count == 1 else {
                                fail("Should at least have 1 member"); done(); return
                            }
                            expect(members[0].clientId).to(equal("b"))
                            done()
                        }
                    }
                }

            // RTP19
            

                func skipped__test__013__Presence__PresenceMap_has_existing_members_when_a_SYNC_is_started__should_ensure_that_members_no_longer_present_on_the_channel_are_removed_from_the_local_PresenceMap_once_the_sync_is_complete() {
                    let options = AblyTests.commonAppSetup()
                    let channelName = NSUUID().uuidString
                    var clientMembers: ARTRealtime?
                    defer { clientMembers?.dispose(); clientMembers?.close() }
                    clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 2, options: options)

                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get(channelName)
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            expect(members).to(haveCount(2)) //synced
                            done()
                        }
                    }

                    expect(channel.internal.presenceMap.members).to(haveCount(2))
                    // Inject a local member
                    let localMember = ARTPresenceMessage(clientId: NSUUID().uuidString, action: .enter, connectionId: "another", id: "another:0:0")
                    channel.internal.presenceMap.add(localMember)
                    expect(channel.internal.presenceMap.members).to(haveCount(3))
                    expect(channel.internal.presenceMap.members.filter{ memberKey, _ in memberKey.contains(localMember.clientId!) }).to(haveCount(1))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members, members.count == 3 else {
                                fail("Should at least have 3 members"); done(); return
                            }
                            expect(members.filter{ $0.clientId == localMember.clientId }).to(haveCount(1))
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.leave) { leave in
                            expect(leave.clientId).to(equal(localMember.clientId))
                            done()
                        }

                        // Request a sync   
                        let syncMessage = ARTProtocolMessage()
                        syncMessage.action = .sync
                        syncMessage.channel = channel.name
                        guard let transport = client.internal.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); done(); return
                        }
                        transport.send(syncMessage)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members, members.count == 2 else {
                                fail("Should at least have 2 members"); done(); return
                            }
                            expect(members.filter{ $0.clientId == localMember.clientId }).to(beEmpty())
                            done()
                        }
                    }
                }

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP19a
                func skipped__test__014__Presence__PresenceMap_has_existing_members_when_a_SYNC_is_started__should_emit_a_LEAVE_event_for_each_existing_member_if_the_PresenceMap_has_existing_members_when_an_ATTACHED_message_is_received_without_a_HAS_PRESENCE_flag() {
                    let options = AblyTests.commonAppSetup()
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)

                    // Inject local members
                    channel.internal.presenceMap.add(ARTPresenceMessage(clientId: "tester1", action: .enter, connectionId: "another", id: "another:0:0"))
                    channel.internal.presenceMap.add(ARTPresenceMessage(clientId: "tester2", action: .enter, connectionId: "another", id: "another:0:1"))

                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(4, done: done)
                        transport.setListenerAfterProcessingIncomingMessage({ protocolMessage in
                            if protocolMessage.action == .attached {
                                expect(protocolMessage.hasPresence).to(beFalse())
                                partialDone()
                            }
                        })
                        channel.presence.subscribe(.leave) { leave in
                            expect(leave.clientId?.hasPrefix("tester")).to(beTrue())
                            expect(leave.action).to(equal(ARTPresenceAction.leave))
                            expect(leave.timestamp).to(beCloseTo(Date(), within: 0.5))
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

            // RTP4
            func skipped__test__002__Presence__should_receive_all_250_members() {
                let options = AblyTests.commonAppSetup()
                var clientSource: ARTRealtime!
                defer { clientSource.dispose(); clientSource.close() }
                clientSource = AblyTests.addMembersSequentiallyToChannel("test", members: 250, options: options)

                let clientTarget = ARTRealtime(options: options)
                defer { clientTarget.close() }
                let channel = clientTarget.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    var pending = 250
                    channel.presence.subscribe { member in
                        expect(member.action).to(equal(ARTPresenceAction.present))
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
            

                // RTP6a
                func test__015__Presence__subscribe__with_no_arguments_should_subscribe_a_listener_to_all_presence_messages() {
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

                    expect(receivedMembers[0].action).to(equal(ARTPresenceAction.enter))
                    expect(receivedMembers[0].data as? NSObject).to(equal("online" as NSObject?))
                    expect(receivedMembers[0].clientId).to(equal("john"))

                    expect(receivedMembers[1].action).to(equal(ARTPresenceAction.update))
                    expect(receivedMembers[1].data as? NSObject).to(equal("away" as NSObject?))
                    expect(receivedMembers[1].clientId).to(equal("john"))

                    expect(receivedMembers[2].action).to(equal(ARTPresenceAction.leave))
                    expect(receivedMembers[2].data as? NSObject).to(equal("away" as NSObject?))
                    expect(receivedMembers[2].clientId).to(equal("john"))
                }

            // RTP7
            

                // RTP7a
                func test__016__Presence__unsubscribe__with_no_arguments_unsubscribes_the_listener_if_previously_subscribed_with_an_action_specific_subscription() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let listener = channel.presence.subscribe { _ in }!
                    expect(channel.internal.presenceEventEmitter.anyListeners).to(haveCount(1))
                    channel.presence.unsubscribe(listener)
                    expect(channel.internal.presenceEventEmitter.anyListeners).to(haveCount(0))
                }

            // RTP5
            

                // RTP5a
                

                    func test__018__Presence__Channel_state_change_side_effects__if_the_channel_enters_the_FAILED_state__all_queued_presence_messages_should_fail_immediately() {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            let protocolError = AblyTests.newErrorProtocolMessage()
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).to(beIdenticalTo(protocolError.error))
                                expect(channel.presence.internal.pendingPresence).to(haveCount(0))
                                done()
                            }
                            expect(channel.presence.internal.pendingPresence).to(haveCount(1))
                            client.internal.rest.queue.async {
                                channel.internal.onError(protocolError)
                            }
                        }
                    }

                    func skipped__test__019__Presence__Channel_state_change_side_effects__if_the_channel_enters_the_FAILED_state__should_clear_the_PresenceMap_including_local_members_and_does_not_emit_any_presence_events() {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                            channel.presence.subscribe { message in
                                expect(message.clientId).to(equal("user"))
                                channel.presence.unsubscribe()
                                partialDone()
                            }
                        }

                        expect(channel.internal.presenceMap.members).to(haveCount(1))
                        expect(channel.internal.presenceMap.localMembers).to(haveCount(1))

                        channel.subscribe() { _ in
                            fail("Shouldn't receive any presence event")
                        }
                        defer { channel.off() }

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.failed) { _ in
                                expect(channel.internal.presenceMap.members).to(beEmpty())
                                expect(channel.internal.presenceMap.localMembers).to(beEmpty())
                                done()
                            }
                            AblyTests.queue.async {
                                channel.internal.onError(AblyTests.newErrorProtocolMessage())
                            }
                        }
                    }

                // RTP5a
                

                    func test__020__Presence__Channel_state_change_side_effects__if_the_channel_enters_the_DETACHED_state__all_queued_presence_messages_should_fail_immediately() {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.attaching) { _ in
                                channel.detach()
                            }
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).toNot(beNil())
                                expect(client.internal.queuedMessages).to(haveCount(0))
                                done()
                            }
                        }
                    }

                    func test__021__Presence__Channel_state_change_side_effects__if_the_channel_enters_the_DETACHED_state__should_clear_the_PresenceMap_including_local_members_and_does_not_emit_any_presence_events() {
                        let client = ARTRealtime(options: AblyTests.commonAppSetup())
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.presence.enterClient("user", data: nil) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                            channel.presence.subscribe { message in
                                expect(message.clientId).to(equal("user"))
                                channel.presence.unsubscribe()
                                partialDone()
                            }
                        }

                        expect(channel.internal.presenceMap.members).to(haveCount(1))
                        expect(channel.internal.presenceMap.localMembers).to(haveCount(1))

                        channel.subscribe() { _ in
                            fail("Shouldn't receive any presence event")
                        }
                        defer { channel.off() }

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.detached) { _ in
                                expect(channel.internal.presenceMap.members).to(beEmpty())
                                expect(channel.internal.presenceMap.localMembers).to(beEmpty())
                                done()
                            }
                            channel.detach()
                        }
                    }

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP5b
                func skipped__test__017__Presence__Channel_state_change_side_effects__if_a_channel_enters_the_ATTACHED_state_then_all_queued_presence_messages_will_be_sent_immediately_and_a_presence_SYNC_may_be_initiated() {
                    let options = AblyTests.commonAppSetup()
                    let client1 = AblyTests.newRealtime(options)
                    defer { client1.dispose(); client1.close() }
                    let channel1 = client1.channels.get(NSUUID().uuidString)

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
                            expect(client2.internal.queuedMessages).to(haveCount(0))
                            expect(channel2.state).to(equal(ARTRealtimeChannelState.attached))
                            partialDone()
                        }
                        channel2.presence.subscribe(.enter) { _ in
                            if channel2.presence.syncComplete {
                                expect(channel2.internal.presenceMap.members).to(haveCount(2))
                            }
                            else {
                                expect(channel2.internal.presenceMap.members).to(haveCount(1))
                            }
                            channel2.presence.unsubscribe()
                            partialDone()
                        }

                        expect(client2.internal.queuedMessages).to(haveCount(1))
                        expect(channel2.presence.syncComplete).to(beFalse())
                        expect(channel2.internal.presenceMap.members).to(haveCount(0))
                    }

                    guard let transport = client2.internal.transport as? TestProxyTransport else {
                        fail("Transport should be a test proxy"); return
                    }

                    expect(transport.protocolMessagesReceived.filter{ $0.action == .sync }).to(haveCount(1))

                    expect(channel2.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
                    expect(channel2.internal.presenceMap.members).to(haveCount(2))
                }

                // RTP5f
                

                    func test__022__Presence__Channel_state_change_side_effects__channel_enters_the_SUSPENDED_state__all_queued_presence_messages_should_fail_immediately() {
                        let options = AblyTests.commonAppSetup()
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channelName = NSUUID().uuidString
                        let channel = client.channels.get(channelName)

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            channel.once(.attaching) { stateChange in
                                expect(stateChange.reason).to(beNil())
                                expect(channel.presence.internal.pendingPresence.count) == 1
                                channel.internalAsync { _internal in
                                    _internal.setSuspended(ARTStatus.state(.error, info: ARTErrorInfo.create(withCode: 1234, message: "unknown error")))
                                }
                                partialDone()
                            }
                            channel.once(.suspended) { stateChange in
                                // All queued presence messages will fail immediately
                                expect(channel.presence.internal.pendingPresence.count) == 0
                                partialDone()
                            }
                            channel.presence.enterClient("tester", data: nil) { error in
                                guard let error = error else {
                                    fail("Error is nil"); partialDone(); return
                                }
                                expect((error ).code) == 1234
                                expect(error.message).to(contain("unknown error"))
                                partialDone()
                            }
                        }
                    }

                    func test__023__Presence__Channel_state_change_side_effects__channel_enters_the_SUSPENDED_state__should_maintain_the_PresenceMap_and_any_members_present_before_and_after_the_sync_should_not_emit_presence_events() {
                        let options = AblyTests.commonAppSetup()
                        let channelName = NSUUID().uuidString

                        var clientMembers: ARTRealtime?
                        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 3, options: options)
                        defer { clientMembers?.dispose(); clientMembers?.close() }

                        options.clientId = "tester"
                        options.tokenDetails = getTestTokenDetails(key: options.key!, clientId: options.clientId, ttl: 5.0)
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get(channelName)
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            channel.presence.enter(nil) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                            channel.presence.get { members, error in
                                expect(error).to(beNil())
                                expect(members).to(haveCount(3))
                                partialDone()
                            }
                            channel.presence.subscribe(.enter) { message in
                                if message.clientId == "tester" {
                                    channel.presence.unsubscribe()
                                    partialDone()
                                }
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(4, done: done)
                            channel.presence.subscribe { presence in
                                expect(presence.action).to(equal(ARTPresenceAction.leave))
                                expect(presence.clientId).to(equal("tester"))
                                partialDone()
                            }
                            channel.once(.suspended) { stateChange in
                                channel.internalSync { _internal in
                                    expect(_internal.presenceMap.members).to(haveCount(4))
                                    expect(_internal.presenceMap.localMembers).to(haveCount(1))
                                }
                                partialDone()
                            }
                            channel.once(.attached) { stateChange in
                                expect(stateChange.reason).to(beNil())
                                channel.presence.leave(nil) { error in
                                    expect(error).to(beNil())
                                    partialDone()
                                }
                                partialDone()
                            }
                            channel.internalAsync { _internal in
                                _internal.setSuspended(ARTStatus.state(.ok))
                            }
                        }

                        channel.presence.unsubscribe()
                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get { members, error in
                                expect(error).to(beNil())
                                guard let members = members else {
                                    fail("Members is nil"); done(); return
                                }
                                expect(members).to(haveCount(3))
                                expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .absent }))
                                done()
                            }
                        }

                        channel.internalSync { _internal in
                            expect(_internal.presenceMap.members).to(haveCount(3))
                            expect(_internal.presenceMap.localMembers).to(beEmpty())
                        }
                    }

            // RTP8
            

                // RTP8a
                func skipped__test__024__Presence__enter__should_enter_the_current_client__optionally_with_the_data_provided() {
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
                            channel1.presence.subscribe(.enter) { member in
                                expect(member.clientId).to(equal(options.clientId))
                                expect(member.data as? NSObject).to(equal("online" as NSObject?))
                                done()
                            }
                            channel2.presence.enter("online")
                        }
                    }
                }

            // RTP7
            

                // RTP7b
                func test__025__Presence__unsubscribe__with_a_single_action_argument_unsubscribes_the_provided_listener_to_all_presence_messages_for_that_action() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let listener = channel.presence.subscribe(.present) { _ in }!
                    expect(channel.internal.presenceEventEmitter.listeners).to(haveCount(1))
                    channel.presence.unsubscribe(.present, listener: listener)
                    expect(channel.internal.presenceEventEmitter.listeners).to(haveCount(0))
                }

            // RTP6
            

                // RTP6c
                func test__026__Presence__subscribe__should_implicitly_attach_the_channel() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))
                    channel.presence.subscribe { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    channel.detach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)

                    channel.presence.subscribe(.present) { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                }

                // RTP6c
                func test__027__Presence__subscribe__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    channel.internal.onError(AblyTests.newErrorProtocolMessage())
                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(attachCallback: { errorInfo in
                            expect(errorInfo).toNot(beNil())

                            channel.presence.subscribe(.enter, onAttach: { errorInfo in
                                expect(errorInfo).toNot(beNil())
                                done()
                            }) { _ in }
                        }) { _ in }
                    }
                }

                // RTP6c
                func test__028__Presence__subscribe__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let error = AblyTests.newErrorProtocolMessage()
                        channel.presence.subscribe(attachCallback: { errorInfo in
                            expect(errorInfo).toNot(beNil())

                            channel.presence.subscribe(.enter, onAttach: { errorInfo in
                                expect(errorInfo).toNot(beNil())
                                done()
                            }) { _ in }
                        }) {_ in }
                        AblyTests.queue.async {
                            channel.internal.onError(error)
                        }
                    }
                }

            // RTP6
            

                // RTP6b
                func test__029__Presence__subscribe__with_a_single_action_argument() {
                    let options = AblyTests.commonAppSetup()

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    var count = 0
                    channel1.presence.subscribe(.update) { member in
                        expect(member.action).to(equal(ARTPresenceAction.update))
                        expect(member.clientId).to(equal("john"))
                        expect(member.data as? NSObject).to(equal("away" as NSObject?))
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

            // RTP8
            

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP8b
                func skipped__test__030__Presence__enter__optionally_a_callback_can_be_provided_that_is_called_for_success() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel1.presence.subscribe(.enter) { member in
                            expect(member.clientId).to(equal(options.clientId))
                            expect(member.data as? NSObject).to(equal("online" as NSObject?))
                            done()
                        }
                        channel2.presence.enter("online") { error in
                            expect(error).to(beNil())
                        }
                    }
                }

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP8b
                func skipped__test__031__Presence__enter__optionally_a_callback_can_be_provided_that_is_called_for_failure() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel1.presence.subscribe(.enter) { member in
                            fail("shouldn't be called")
                        }
                        let protocolError = AblyTests.newErrorProtocolMessage()
                        channel2.presence.enter("online") { error in
                            expect(error).to(beIdenticalTo(protocolError.error))
                            done()
                        }
                        delay(0.1) {
                            channel2.internal.onError(protocolError)
                        }
                    }
                }

                // RTP8c
                func test__032__Presence__enter__entering_without_an_explicit_PresenceMessage_clientId_should_implicitly_use_the_clientId_of_the_current_connection() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.enter("online") { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                        channel.presence.subscribe { message in
                            expect(message.clientId).to(equal("john"))
                            channel.presence.unsubscribe()
                            partialDone()
                        }
                    }

                    let transport = client.internal.transport as! TestProxyTransport
                    let sent = transport.protocolMessagesSent.filter({ $0.action == .presence })[0].presence![0]
                    expect(sent.action).to(equal(ARTPresenceAction.enter))
                    expect(sent.clientId).to(beNil())

                    let received = transport.protocolMessagesReceived.filter({ $0.action == .presence })[0].presence![0]
                    expect(received.action).to(equal(ARTPresenceAction.enter))
                    expect(received.clientId).to(equal("john"))
                }

            // RTP8
            

                // RTP8f
                func test__033__Presence__enter__should_result_in_an_error_immediately_if_the_client_is_anonymous() {
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

            // RTP8
            

                // RTP8g
                func test__034__Presence__enter__should_result_in_an_error_immediately_if_the_channel_is_DETACHED() {
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
                    
                    expect(channel.state).to(equal(ARTRealtimeChannelState.detached))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            done()
                        }
                    }
                }

                // RTP8g
                func test__035__Presence__enter__should_result_in_an_error_immediately_if_the_channel_is_FAILED() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        AblyTests.queue.async {
                            channel.internal.onError(AblyTests.newErrorProtocolMessage())
                            done()
                        }
                    }

                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                        

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter(nil) { error in
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            done()
                        }
                    }
                }

            // RTP8
            

                // RTP8i
                func test__036__Presence__enter__should_result_in_an_error_if_Ably_service_determines_that_the_client_is_unidentified() {
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

            // RTP9
            

                // RTP9a
                func test__037__Presence__update__should_update_the_data_for_the_present_member_with_a_value() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.enter) { member in
                            expect(member.data).to(beNil())
                            done()
                        }
                        channel.presence.enter(nil)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.update) { member in
                            expect(member.data as? NSObject).to(equal("online" as NSObject?))
                            done()
                        }
                        channel.presence.update("online")
                    }
                }

                // RTP9a
                func skipped__test__038__Presence__update__should_update_the_data_for_the_present_member_with_null() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.enter) { member in
                            expect(member.data as? NSObject).to(equal("online" as NSObject?))
                            done()
                        }
                        channel.presence.enter("online")
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.update) { member in
                            expect(member.data).to(beNil())
                            done()
                        }
                        channel.presence.update(nil)
                    }
                }

            // RTP9
            

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP9b
                func skipped__test__039__Presence__update__should_enter_current_client_into_the_channel_if_the_client_was_not_already_entered() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.internal.presenceMap.members).to(haveCount(0))
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.enter) { member in
                            expect(member.clientId).to(equal("john"))
                            expect(member.data as? NSObject).to(equal("online" as NSObject?))
                            done()
                        }
                        channel.presence.update("online")
                    }
                }

            // RTP9
            

                // RTP9c
                func test__040__Presence__update__optionally_a_callback_can_be_provided_that_is_called_for_success() {
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
                func test__041__Presence__update__optionally_a_callback_can_be_provided_that_is_called_for_failure() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let protocolError = AblyTests.newErrorProtocolMessage()
                        channel.once(.attaching) { _ in
                            AblyTests.queue.async {
                                channel.internal.onError(protocolError)
                            }
                        }
                        (client.internal.transport as! TestProxyTransport).actionsIgnored += [.attached]
                        channel.presence.update("online") { error in
                            expect(error).to(beIdenticalTo(protocolError.error))
                            done()
                        }
                    }
                }

                // RTP9d
                func test__042__Presence__update__update_without_an_explicit_PresenceMessage_clientId_should_implicitly_use_the_clientId_of_the_current_connection() {
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

                    let transport = client.internal.transport as! TestProxyTransport
                    let sent = transport.protocolMessagesSent.filter({ $0.action == .presence })[1].presence![0]
                    expect(sent.action).to(equal(ARTPresenceAction.update))
                    expect(sent.clientId).to(beNil())

                    let receivedPresenceProtocolMessages = transport.protocolMessagesReceived.filter({ $0.action == .presence })
                    let receivedPresenceMessages = receivedPresenceProtocolMessages.flatMap({ $0.presence! })
                    let received = receivedPresenceMessages.filter({ $0.action == .update })[0]
                    expect(received.action).to(equal(ARTPresenceAction.update))
                    expect(received.clientId).to(equal("john"))
                }

            // RTP10
            

                // RTP10a
                func skipped__test__043__Presence__leave__should_leave_the_current_client_from_the_channel_and_the_data_will_be_updated_with_the_value_provided() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.enter) { member in
                            expect(member.data as? NSObject).to(equal("online" as NSObject?))
                            done()
                        }
                        channel.presence.enter("online")
                    }

                    expect(channel.internal.presenceMap.members).toEventually(haveCount(1), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.leave) { member in
                            expect(member.data as? NSObject).to(equal("offline" as NSObject?))
                            done()
                        }
                        channel.presence.leave("offline")
                    }

                    expect(channel.internal.presenceMap.members).toEventually(haveCount(0), timeout: testTimeout)
                }

                // RTP10a
                func skipped__test__044__Presence__leave__should_leave_the_current_client_with_no_data() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.enter) { member in
                            expect(member.data as? NSObject).to(equal("online" as NSObject?))
                            done()
                        }
                        channel.presence.enter("online")
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.leave) { member in
                            expect(member.data as? NSObject).to(equal("online" as NSObject?))
                            done()
                        }
                        channel.presence.leave(nil)
                    }
                }

            // RTP2
            func skipped__test__003__Presence__should_be_used_a_PresenceMap_to_maintain_a_list_of_members() {
                let options = AblyTests.commonAppSetup()
                var clientSecondary: ARTRealtime!
                defer { clientSecondary.dispose(); clientSecondary.close() }
                clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 100, options: options)

                let client = AblyTests.newRealtime(options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    channel.attach() { error in
                        expect(error).to(beNil())
                        done()
                    }
                }

                channel.presence.unsubscribe()
                waitUntil(timeout: testTimeout) { done in
                    channel.presence.get { members, error in
                        expect(error).to(beNil())
                        guard let members = members else {
                            fail("Members is nil"); done(); return
                        }
                        expect(members.count) == 100
                        done()
                    }
                }
            }

            // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
            // RTP2
            

                // RTP2a
                func skipped__test__045__Presence__PresenceMap__all_incoming_presence_messages_must_be_compared_for_newness_with_the_matching_member_already_in_the_PresenceMap() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.subscribe { presence in
                            expect(presence.clientId).to(equal("tester"))
                            expect(presence.action).to(equal(.enter))
                            channel.presence.unsubscribe()
                            partialDone()
                        }
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    guard let intialPresenceMessage = channel.internal.presenceMap.members["\(channel.internal.connectionId):tester"] else {
                        fail("Missing Presence message"); return
                    }

                    expect(intialPresenceMessage.memberKey()).to(equal("\(client.connection.id!):tester"))

                    var compareForNewnessMethodCalls = 0
                    let hook = ARTPresenceMessage.testSuite_injectIntoClassMethod(#selector(ARTPresenceMessage.isNewerThan(_:))) {
                        compareForNewnessMethodCalls += 1
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let updatedPresenceMessage = channel.internal.presenceMap.members["\(channel.internal.connectionId):tester"] else {
                        fail("Missing Presence message"); return
                    }

                    expect(intialPresenceMessage.memberKey()).to(equal(updatedPresenceMessage.memberKey()))
                    expect(intialPresenceMessage.timestamp).to(beLessThan(updatedPresenceMessage.timestamp))

                    expect(compareForNewnessMethodCalls) == 1

                    hook?.remove()
                }

                // RTP2b
                

                    
                        // RTP2b1
                        func test__053__Presence__PresenceMap__compare_for_newness__presence_message_has_a_connectionId_which_is_not_an_initial_substring_of_its_id__compares_them_by_timestamp_numerically() {
                            let options = AblyTests.commonAppSetup()
                            let now = NSDate()
                            let channelName = NSUUID().uuidString
                            var clientMembers: ARTRealtime?
                            defer { clientMembers?.dispose(); clientMembers?.close() }
                            clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 101, options: options)

                            let clientSubscribed = AblyTests.newRealtime(options)
                            defer { clientSubscribed.dispose(); clientSubscribed.close() }
                            let channelSubscribed = clientSubscribed.channels.get(channelName)

                            let presenceData: [ARTPresenceMessage] = [
                                ARTPresenceMessage(clientId: "a", action: .enter, connectionId: "one", id: "one:0:0", timestamp: now as Date),
                                ARTPresenceMessage(clientId: "a", action: .leave, connectionId: "one", id: "fabricated:0:1", timestamp: (now as Date) + 1),
                                ARTPresenceMessage(clientId: "b", action: .enter, connectionId: "one", id: "one:0:2", timestamp: now as Date),
                                ARTPresenceMessage(clientId: "b", action: .leave, connectionId: "one", id: "fabricated:0:3", timestamp: (now as Date) - 1),
                                ARTPresenceMessage(clientId: "c", action: .enter, connectionId: "one", id: "fabricated:0:4", timestamp: now as Date),
                                ARTPresenceMessage(clientId: "c", action: .leave, connectionId: "one", id: "fabricated:0:5", timestamp: (now as Date) - 1),
                            ]

                            guard let transport = clientSubscribed.internal.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); return
                            }

                            waitUntil(timeout: testTimeout.multiplied(by: 2)) { done in
                                transport.setAfterIncomingMessageModifier({ protocolMessage in
                                    // Receive the first Sync message from Ably service
                                    if protocolMessage.action == .sync {
                                        // Inject a fabricated Presence message
                                        let presenceMessage = ARTProtocolMessage()
                                        presenceMessage.action = .presence
                                        presenceMessage.channel = protocolMessage.channel
                                        presenceMessage.connectionSerial = protocolMessage.connectionSerial + 1
                                        presenceMessage.timestamp = Date()
                                        presenceMessage.presence = presenceData

                                        transport.receive(presenceMessage)

                                        // Simulate an end to the sync
                                        let endSyncMessage = ARTProtocolMessage()
                                        endSyncMessage.action = .sync
                                        endSyncMessage.channel = protocolMessage.channel
                                        endSyncMessage.channelSerial = "validserialprefix:" //with no part after the `:` this indicates the end to the SYNC
                                        endSyncMessage.connectionSerial = protocolMessage.connectionSerial + 2
                                        endSyncMessage.timestamp = Date()

                                        transport.setAfterIncomingMessageModifier(nil)
                                        transport.receive(endSyncMessage)

                                        // Stop the next sync message from Ably service because we already injected the end of the sync
                                        transport.actionsIgnored = [.sync]

                                        done()
                                    }
                                    return protocolMessage
                                })
                                channelSubscribed.attach()
                            }

                            waitUntil(timeout: testTimeout) { done in
                                channelSubscribed.presence.get { members, error in
                                    expect(error).to(beNil())
                                    guard let members = members else {
                                        fail("Members is nil"); done(); return
                                    }
                                    expect(members).to(haveCount(102)) //100 initial members + "b" + "c", client "a" is discarded
                                    expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .absent }))
                                    expect(members.filter{ $0.clientId == "a" }).to(beEmpty())
                                    expect(members.filter{ $0.clientId == "b" }).to(haveCount(1))
                                    expect(members.filter{ $0.clientId! == "b" }.first?.timestamp).to(equal(now as Date))
                                    expect(members.filter{ $0.clientId == "c" }).to(haveCount(1))
                                    expect(members.filter{ $0.clientId! == "c" }.first?.timestamp).to(equal(now as Date))
                                    done()
                                }
                            }
                        }

                    // RTP2b2
                    func test__052__Presence__PresenceMap__compare_for_newness__split_the_id_of_both_presence_messages() {
                        let options = AblyTests.commonAppSetup()
                        let now = NSDate()
                        let channelName = NSUUID().uuidString
                        var clientMembers: ARTRealtime?
                        defer { clientMembers?.dispose(); clientMembers?.close() }
                        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 101, options: options)

                        let clientSubscribed = AblyTests.newRealtime(options)
                        defer { clientSubscribed.dispose(); clientSubscribed.close() }
                        let channelSubscribed = clientSubscribed.channels.get(channelName)

                        let presenceData: [ARTPresenceMessage] = [
                            ARTPresenceMessage(clientId: "a", action: .enter, connectionId: "one", id: "one:0:0", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "a", action: .leave, connectionId: "one", id: "one:1:0", timestamp: (now as Date) - 1),
                            ARTPresenceMessage(clientId: "b", action: .enter, connectionId: "one", id: "one:2:2", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "b", action: .leave, connectionId: "one", id: "one:2:1", timestamp: (now as Date) + 1),
                            ARTPresenceMessage(clientId: "c", action: .enter, connectionId: "one", id: "one:4:4", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "c", action: .leave, connectionId: "one", id: "one:3:5", timestamp: (now as Date) + 1),
                        ]

                        guard let transport = clientSubscribed.internal.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            transport.setAfterIncomingMessageModifier({ protocolMessage in
                                // Receive the first Sync message from Ably service
                                if protocolMessage.action == .sync {
                                    // Inject a fabricated Presence message
                                    let presenceMessage = ARTProtocolMessage()
                                    presenceMessage.action = .presence
                                    presenceMessage.channel = protocolMessage.channel
                                    presenceMessage.connectionSerial = protocolMessage.connectionSerial + 1
                                    presenceMessage.timestamp = Date()
                                    presenceMessage.presence = presenceData

                                    transport.receive(presenceMessage)

                                    // Simulate an end to the sync
                                    let endSyncMessage = ARTProtocolMessage()
                                    endSyncMessage.action = .sync
                                    endSyncMessage.channel = protocolMessage.channel
                                    endSyncMessage.channelSerial = "validserialprefix:" //with no part after the `:` this indicates the end to the SYNC
                                    endSyncMessage.connectionSerial = protocolMessage.connectionSerial + 2
                                    endSyncMessage.timestamp = Date()

                                    transport.setAfterIncomingMessageModifier(nil)
                                    transport.receive(endSyncMessage)

                                    // Stop the next sync message from Ably service because we already injected the end of the sync
                                    transport.actionsIgnored = [.sync]

                                    done()
                                }
                                return protocolMessage
                            })
                            channelSubscribed.attach()
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channelSubscribed.presence.get { members, error in
                                expect(error).to(beNil())
                                guard let members = members else {
                                    fail("Members is nil"); done(); return
                                }
                                expect(members).to(haveCount(102)) //100 initial members + "b" + "c", client "a" is discarded
                                expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .absent }))
                                expect(members.filter{ $0.clientId == "a" }).to(beEmpty())
                                expect(members.filter{ $0.clientId == "b" }).to(haveCount(1))
                                expect(members.filter{ $0.clientId! == "b" }.first?.timestamp).to(equal(now as Date))
                                expect(members.filter{ $0.clientId == "c" }).to(haveCount(1))
                                expect(members.filter{ $0.clientId! == "c" }.first?.timestamp).to(equal(now as Date))
                                done()
                            }
                        }
                    }

                // RTP2c
                

                    // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                    func skipped__test__054__Presence__PresenceMap__all_presence_messages_from_a_SYNC_must_also_be_compared_for_newness_in_the_same_way_as_they_would_from_a_PRESENCE__discard_members_where_messages_have_arrived_before_the_SYNC() {
                        let options = AblyTests.commonAppSetup()
                        let timeBeforeSync = NSDate()
                        let channelName = NSUUID().uuidString
                        var clientMembers: ARTRealtime?
                        defer { clientMembers?.dispose(); clientMembers?.close() }
                        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 120, options: options)

                        guard let membersConnectionId = clientMembers?.connection.id else {
                            fail("Members client isn't connected"); return
                        }

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get(channelName)

                        guard let transport = client.internal.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        channel.presence.subscribe(.leave) { leave in
                            expect(leave.clientId).to(equal("user110"))
                            fail("Should not fire Leave event for member `user110` because it's out of date")
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)
                            transport.setBeforeIncomingMessageModifier({ protocolMessage in
                                if protocolMessage.action == .sync {
                                    let injectLeave = ARTPresenceMessage()
                                    injectLeave.action = .leave
                                    injectLeave.connectionId = membersConnectionId
                                    injectLeave.clientId = "user110"
                                    injectLeave.timestamp = timeBeforeSync as Date
                                    protocolMessage.presence?.append(injectLeave)
                                    transport.setBeforeIncomingMessageModifier(nil)
                                    partialDone()
                                }
                                return protocolMessage
                            })
                            channel.internal.presenceMap.testSuite_injectIntoMethod(after: #selector(ARTPresenceMap.endSync)) {
                                expect(channel.internal.presenceMap.syncInProgress).to(beFalse())
                                expect(channel.internal.presenceMap.members).to(haveCount(120))
                                expect(channel.internal.presenceMap.members.filter{ _, presence in presence.clientId == "user110" && presence.action == .present }).to(haveCount(1))
                                partialDone()
                            }
                            channel.attach() { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }

                    // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                    func skipped__test__055__Presence__PresenceMap__all_presence_messages_from_a_SYNC_must_also_be_compared_for_newness_in_the_same_way_as_they_would_from_a_PRESENCE__accept_members_where_message_have_arrived_after_the_SYNC() {
                        let options = AblyTests.commonAppSetup()
                        let channelName = NSUUID().uuidString
                        var clientMembers: ARTRealtime?
                        defer { clientMembers?.dispose(); clientMembers?.close() }
                        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 120, options: options)

                        guard let membersConnectionId = clientMembers?.connection.id else {
                            fail("Members client isn't connected"); return
                        }

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get(channelName)

                        guard let transport = client.internal.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        waitUntil(timeout: testTimeout.multiplied(by: 2)) { done in
                            let partialDone = AblyTests.splitDone(4, done: done)
                            channel.presence.subscribe(.leave) { leave in
                                expect(leave.clientId).to(equal("user110"))
                                partialDone()
                            }
                            transport.setBeforeIncomingMessageModifier({ protocolMessage in
                                if protocolMessage.action == .sync {
                                    let injectLeave = ARTPresenceMessage()
                                    injectLeave.action = .leave
                                    injectLeave.connectionId = membersConnectionId
                                    injectLeave.clientId = "user110"
                                    injectLeave.timestamp = (Date()) + 1
                                    protocolMessage.presence?.append(injectLeave)
                                    transport.setBeforeIncomingMessageModifier(nil)
                                    partialDone()
                                }
                                return protocolMessage
                            })
                            channel.internal.presenceMap.testSuite_injectIntoMethod(after: #selector(ARTPresenceMap.endSync)) {
                                expect(channel.internal.presenceMap.syncInProgress).to(beFalse())
                                expect(channel.internal.presenceMap.members).to(haveCount(119))
                                expect(channel.internal.presenceMap.members.filter{ _, presence in presence.clientId == "user110" }).to(beEmpty())
                                partialDone()
                            }
                            channel.attach() { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }

                // RTP2d
                func skipped__test__046__Presence__PresenceMap__if_action_of_ENTER_arrives__it_should_be_added_to_the_presence_map_with_the_action_set_to_PRESENT() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.subscribe(.enter) { _ in
                            partialDone()
                        }
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    expect(channel.internal.presenceMap.members.filter{ _, presence in presence.action == .present }).to(haveCount(1))
                    expect(channel.internal.presenceMap.members.filter{ _, presence in presence.action == .enter }).to(beEmpty())
                }

                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP2d
                func skipped__test__047__Presence__PresenceMap__if_action_of_UPDATE_arrives__it_should_be_added_to_the_presence_map_with_the_action_set_to_PRESENT() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)
                        channel.presence.subscribe(.update) { _ in
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

                    expect(channel.internal.presenceMap.members).to(haveCount(1))
                    expect(channel.internal.presenceMap.members.filter{ _, presence in presence.action == .present }).to(haveCount(1))
                    expect(channel.internal.presenceMap.members.filter{ _, presence in presence.action == .update }).to(beEmpty())
                }

                // RTP2d
                func test__048__Presence__PresenceMap__if_action_of_PRESENT_arrives__it_should_be_added_to_the_presence_map_with_the_action_set_to_PRESENT() {
                    let options = AblyTests.commonAppSetup()
                    let channelName = NSUUID().uuidString
                    var clientMembers: ARTRealtime!
                    defer { clientMembers.dispose(); clientMembers.close() }
                    clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 1, options: options)

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get(channelName)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.internal.presenceMap.testSuite_injectIntoMethod(after: #selector(ARTPresenceMap.endSync)) {
                            expect(channel.internal.presenceMap.syncInProgress).to(beFalse())
                            partialDone()
                        }
                        channel.attach() { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    expect(channel.internal.presenceMap.members).to(haveCount(1))
                }

                // RTP2e
                func skipped__test__049__Presence__PresenceMap__if_a_SYNC_is_not_in_progress__then_when_a_presence_message_with_an_action_of_LEAVE_arrives__that_memberKey_should_be_deleted_from_the_presence_map__if_present() {
                    let options = AblyTests.commonAppSetup()

                    var clientMembers: ARTRealtime?
                    defer { clientMembers?.dispose(); clientMembers?.close() }
                    let channelName = NSUUID().uuidString
                    clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 20, options: options)

                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get(channelName)
                    channel.attach()

                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }
                    waitUntil(timeout: testTimeout) { done in
                        transport.setListenerAfterProcessingIncomingMessage({ protocolMessage in
                            if protocolMessage.action == .sync {
                                done()
                            }
                        })
                    }

                    expect(channel.internal.presenceMap.syncInProgress).toEventually(beFalse(), timeout: testTimeout)

                    guard let user11MemberKey = channel.internal.presenceMap.members["\(clientMembers?.connection.id ?? ""):user11"]?.memberKey() else {
                        fail("user11 memberKey is not present"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(.leave) { presence in
                            expect(presence.clientId).to(equal("user11"))
                            done()
                        }
                        clientMembers?.channels.get(channelName).presence.leaveClient("user11", data: nil)
                    }
                    channel.presence.unsubscribe()

                    channel.internalSync { _internal in
                        expect(_internal.presenceMap.members.filter{ _, presence in presence.memberKey() == user11MemberKey }).to(beEmpty())
                    }
                }

                // RTP2f
                func skipped__test__050__Presence__PresenceMap__if_a_SYNC_is_in_progress__then_when_a_presence_message_with_an_action_of_LEAVE_arrives__it_should_be_stored_in_the_presence_map_with_the_action_set_to_ABSENT() {
                    let options = AblyTests.commonAppSetup()
                    let channelName = NSUUID().uuidString

                    var clientMembers: ARTRealtime?
                    defer { clientMembers?.dispose(); clientMembers?.close() }
                    clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 20, options: options)

                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get(channelName)

                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    var hook: AspectToken?
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        
                        channel.presence.subscribe(.leave) { leave in
                            expect(leave.clientId).to(equal("user11"))
                            partialDone()
                        }

                        hook = channel.internal.presenceMap.testSuite_getArgument(
                            from: #selector(ARTPresenceMap.internalAdd(_:withSessionId:)),
                            at: 0
                        ) { arg in
                            let m = arg as? ARTPresenceMessage
                            if (m?.clientId == "user11" && m?.action == .absent) {
                                partialDone()
                            }
                        }

                        channel.attach { error in
                            expect(error).to(beNil())
                            expect(channel.internal.presenceMap.syncInProgress).to(beTrue())

                            // Inject a fabricated Presence message
                            let leaveMessage = ARTProtocolMessage()
                            leaveMessage.action = .presence
                            leaveMessage.channel = channel.name
                            leaveMessage.connectionSerial = client.connection.internal.serial_nosync() + 1
                            leaveMessage.timestamp = Date()
                            leaveMessage.presence = [
                                ARTPresenceMessage(clientId: "user11", action: .leave, connectionId: "another", id: "another:123:0", timestamp: Date())
                            ]
                            transport.receive(leaveMessage)
                        }
                    }
                    hook?.remove()
                    channel.presence.unsubscribe()
                    
                    expect(channel.internal.presenceMap.syncInProgress).toEventually(beFalse(), timeout: testTimeout)
                    expect(channel.internal.presenceMap.members.filter{ _, presence in presence.action == .leave }).to(beEmpty())
                    expect(channel.internal.presenceMap.members.filter{ _, presence in presence.action == .absent }).to(beEmpty())

                    // A single clientId may be present multiple times on the same channel via different client connections and that's way user11 is present because user11 presences messages were in distinct connections.
                    expect(channel.internal.presenceMap.members).to(haveCount(20))
                }

                // RTP2g
                func skipped__test__051__Presence__PresenceMap__any_incoming_presence_message_that_passes_the_newness_check_should_be_emitted_on_the_Presence_object__with_an_event_name_set_to_its_original_action() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.enterClient("tester", data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                        channel.presence.subscribe(.enter) { _ in
                            partialDone()
                        }
                    }

                    channel.internalSync { _internal in
                        expect(_internal.presenceMap.members.filter{ _, presence in presence.action == .present }).to(haveCount(1))
                        expect(_internal.presenceMap.members.filter{ _, presence in presence.action == .enter }).to(beEmpty())
                    }
                }

            // RTP8
            
                // RTP8h
                func test__056__Presence__enter__should_result_in_an_error_if_the_client_does_not_have_required_presence_permission() {
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


            // RTP9
            

                // RTP9e
                func test__057__Presence__update__should_result_in_an_error_immediately_if_the_client_is_anonymous() {
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
                func test__058__Presence__update__should_result_in_an_error_immediately_if_the_channel_is_DETACHED() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    channel.attach()
                    channel.detach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            done()
                        }
                    }
                }

                // RTP9e
                func test__059__Presence__update__should_result_in_an_error_immediately_if_the_channel_is_FAILED() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    AblyTests.queue.async {
                        channel.internal.onError(AblyTests.newErrorProtocolMessage())
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.update(nil) { error in
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            done()
                        }
                    }
                }

                // RTP9e
                func test__060__Presence__update__should_result_in_an_error_if_the_client_does_not_have_required_presence_permission() {
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
                func test__061__Presence__update__should_result_in_an_error_if_Ably_service_determines_that_the_client_is_unidentified() {
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

            // RTP10
            

                // RTP10b
                func test__062__Presence__leave__optionally_a_callback_can_be_provided_that_is_called_for_success() {
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
                func test__063__Presence__leave__optionally_a_callback_can_be_provided_that_is_called_for_failure() {
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
                        let sentError = ARTErrorInfo.create(withCode: 0, message: "test error")
                        let transport = client.internal.transport as! TestProxyTransport
                        transport.enableReplaceAcksWithNacks(with: sentError)
                        channel.presence.leave("offline") { error in
                            expect(error).to(beIdenticalTo(sentError))
                            transport.disableReplaceAcksWithNacks()
                            done()
                        }
                    }
                }

                func test__064__Presence__leave__should_raise_an_error_if_client_is_not_present() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leave("offline") { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.code) == Int(ARTState.noClientId.rawValue)
                            expect(error.message).to(contain("message without clientId"))
                            done()
                        }
                    }
                }

                // RTP10c
                func test__065__Presence__leave__entering_without_an_explicit_PresenceMessage_clientId_should_implicitly_use_the_clientId_of_the_current_connection() {
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

                    let transport = client.internal.transport as! TestProxyTransport

                    let sent = transport.protocolMessagesSent.filter({ $0.action == .presence })[1].presence![0]
                    expect(sent.action).to(equal(ARTPresenceAction.leave))
                    expect(sent.clientId).to(beNil())

                    let receivedPresenceProtocolMessages = transport.protocolMessagesReceived.filter({ $0.action == .presence })
                    let receivedPresenceMessages = receivedPresenceProtocolMessages.flatMap({ $0.presence! })
                    let received = receivedPresenceMessages.filter({ $0.action == .leave })[0]
                    expect(received.action).to(equal(ARTPresenceAction.leave))
                    expect(received.clientId).to(equal("john"))
                }

                // RTP10d
                func test__066__Presence__leave__if_the_client_is_not_currently_ENTERED__Ably_will_respond_with_an_ACK_and_the_request_will_succeed() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leave(nil) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error).to(beNil())
                            channel.presence.leave(nil) { error in
                                expect(error).to(beNil())
                                channel.presence.leave(nil) { error in
                                    expect(error).to(beNil())
                                    done()
                                }
                            }
                        }
                    }
                }

            // RTP8
            

                // RTP8d
                func test__067__Presence__enter__implicitly_attaches_the_Channel() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error).to(beNil())
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                }

                // RTP8d
                func test__068__Presence__enter__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    AblyTests.queue.async {
                        channel.internal.onError(AblyTests.newErrorProtocolMessage())
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            done()
                        }
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                }

                // RTP8d
                func test__069__Presence__enter__should_result_in_an_error_if_the_channel_is_in_the_DETACHED_state() {
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
                    expect(channel.state).to(equal(ARTRealtimeChannelState.detached))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enter("online") { error in
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            done()
                        }
                    }
                }

            // RTP10
            

                // RTP10e
                func test__070__Presence__leave__should_result_in_an_error_immediately_if_the_client_is_anonymous() {
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
                func test__071__Presence__leave__should_result_in_an_error_immediately_if_the_channel_is_DETACHED() {
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
                func test__072__Presence__leave__should_result_in_an_error_immediately_if_the_channel_is_FAILED() {
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

                    AblyTests.queue.async {
                        channel.internal.onError(AblyTests.newErrorProtocolMessage())
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.leave(nil) { error in
                            expect(error!.message).to(contain("invalid channel state"))
                            done()
                        }
                    }
                }

                // RTP10e
                func test__073__Presence__leave__should_result_in_an_error_if_the_client_does_not_have_required_presence_permission() {
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
                func test__074__Presence__leave__should_result_in_an_error_if_Ably_service_determines_that_the_client_is_unidentified() {
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

            // RTP6
            

                // RTP6c
                func test__075__Presence__subscribe_2__should_implicitly_attach_the_channel() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))
                    channel.presence.subscribe { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    channel.detach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)

                    channel.presence.subscribe(.present) { _ in }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                }

                // RTP6c
                func test__076__Presence__subscribe_2__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let protocolError = AblyTests.newErrorProtocolMessage()
                    AblyTests.queue.async {
                        channel.internal.onError(protocolError)
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.subscribe(attachCallback: { error in
                            expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                            expect(error).toNot(beNil())
                            done()
                        }, callback: { member in
                            fail("Should not be called")
                        })
                    }
                }

                // RTP6c
                func test__077__Presence__subscribe_2__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let error = AblyTests.newErrorProtocolMessage()
                        channel.presence.subscribe(attachCallback: { error in
                            expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                            expect(error).toNot(beNil())
                            done()
                        }, callback: { member in
                            fail("Should not be called")
                        })
                        AblyTests.queue.async {
                            channel.internal.onError(error)
                        }
                    }
                }

            // RTP8
            

                // RTP8e
                func test__078__Presence__enter__optional_data_can_be_included_when_entering_a_channel() {
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
                            channel1.presence.subscribe(.enter) { member in
                                expect(member.data as? NSObject).to(equal(expectedData as NSObject?))
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
                func test__079__Presence__enter__should_emit_the_data_attribute_in_the_LEAVE_event_when_data_is_provided_when_entering_but_no_data_is_provided_when_leaving() {
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
                            channel1.presence.subscribe(.leave) { member in
                                expect(member.data as? NSObject).to(equal(expectedData as NSObject?))
                                partlyDone()
                            }
                            channel2.presence.leave(nil) { error in
                                expect(error).to(beNil())
                                partlyDone()
                            }
                        }
                    }
                }

            // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
            // RTP17
            

                func skipped__test__080__Presence__private_and_internal_PresenceMap_containing_only_members_that_match_the_current_connectionId__any_ENTER__PRESENT__UPDATE_or_LEAVE_event_that_matches_the_current_connectionId_should_be_applied_to_this_object() {
                    let options = AblyTests.commonAppSetup()
                    let channelName = NSUUID().uuidString

                    options.clientId = "a"
                    let clientA = ARTRealtime(options: options)
                    defer { clientA.dispose(); clientA.close() }
                    let channelA = clientA.channels.get(channelName)

                    options.clientId = "b"
                    let clientB = ARTRealtime(options: options)
                    defer { clientB.dispose(); clientB.close() }
                    let channelB = clientB.channels.get(channelName)

                    // ENTER
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channelA.presence.subscribe { presence in
                            guard let currentConnectionId = clientA.connection.id else {
                                fail("ClientA should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.enter))
                            expect(presence.connectionId).to(equal(currentConnectionId))
                            expect(channelA.internal.presenceMap.members).to(haveCount(1))
                            expect(channelA.internal.presenceMap.localMembers).to(haveCount(1))
                            channelA.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.subscribe { presence in
                            guard let currentConnectionId = clientB.connection.id else {
                                fail("ClientB should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.enter) || equal(ARTPresenceAction.present))
                            expect(presence.connectionId).toNot(equal(currentConnectionId))
                            expect(channelB.internal.presenceMap.members).to(haveCount(1))
                            expect(channelB.internal.presenceMap.localMembers).to(haveCount(0))
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
                            expect(presence.action).to(equal(ARTPresenceAction.enter))
                            expect(presence.connectionId).toNot(equal(currentConnectionId))
                            expect(channelA.internal.presenceMap.members).to(haveCount(2))
                            expect(channelA.internal.presenceMap.localMembers).to(haveCount(1))
                            channelA.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.subscribe { presence in
                            guard let currentConnectionId = clientB.connection.id else {
                                fail("ClientB should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.enter))
                            expect(presence.connectionId).to(equal(currentConnectionId))
                            expect(channelB.internal.presenceMap.members).to(haveCount(2))
                            expect(channelB.internal.presenceMap.localMembers).to(haveCount(1))
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
                            expect(presence.action).to(equal(ARTPresenceAction.update))
                            expect(presence.data as? String).to(equal("hello"))
                            expect(presence.connectionId).toNot(equal(currentConnectionId))
                            expect(channelA.internal.presenceMap.members).to(haveCount(2))
                            expect(channelA.internal.presenceMap.localMembers).to(haveCount(1))
                            channelA.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.subscribe { presence in
                            guard let currentConnectionId = clientB.connection.id else {
                                fail("ClientB should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.update))
                            expect(presence.data as? String).to(equal("hello"))
                            expect(presence.connectionId).to(equal(currentConnectionId))
                            expect(channelB.internal.presenceMap.members).to(haveCount(2))
                            expect(channelB.internal.presenceMap.localMembers).to(haveCount(1))
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
                            expect(presence.action).to(equal(ARTPresenceAction.leave))
                            expect(presence.data as? String).to(equal("bye"))
                            expect(presence.connectionId).toNot(equal(currentConnectionId))
                            expect(channelA.internal.presenceMap.members).to(haveCount(1))
                            expect(channelA.internal.presenceMap.localMembers).to(haveCount(1))
                            channelA.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.subscribe { presence in
                            guard let currentConnectionId = clientB.connection.id else {
                                fail("ClientB should be connected"); partialDone(); return
                            }
                            expect(presence.action).to(equal(ARTPresenceAction.leave))
                            expect(presence.data as? String).to(equal("bye"))
                            expect(presence.connectionId).to(equal(currentConnectionId))
                            expect(channelB.internal.presenceMap.members).to(haveCount(1))
                            expect(channelB.internal.presenceMap.localMembers).to(haveCount(0))
                            channelB.presence.unsubscribe()
                            partialDone()
                        }
                        channelB.presence.leave("bye")
                    }
                }

                // RTP17a
                func skipped__test__081__Presence__private_and_internal_PresenceMap_containing_only_members_that_match_the_current_connectionId__all_members_belonging_to_the_current_connection_are_published_as_a_PresenceMessage_on_the_Channel_by_the_server_irrespective_of_whether_the_client_has_permission_to_subscribe_or_the_Channel_is_configured_to_publish_presence_events() {
                    let options = AblyTests.commonAppSetup()
                    let channelName = NSUUID().uuidString
                    let clientId = NSUUID().uuidString
                    options.tokenDetails = getTestTokenDetails(clientId: clientId, capability: "{\"\(channelName)\":[\"presence\",\"publish\"]}")
                    // Prevent channel name to be prefixed by test-*
                    options.channelNamePrefix = nil
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get(channelName)
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        channel.presence.enterClient(clientId, data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                        channel.presence.subscribe(.enter) { presence in
                            expect(presence.clientId).to(equal(clientId))
                            partialDone()
                        }
                    }
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            expect(members).to(haveCount(1))
                            expect(channel.internal.presenceMap.members).to(haveCount(1))
                            expect(channel.internal.presenceMap.localMembers).to(haveCount(1))
                            done()
                        }
                    }
                }

                // RTP17b
                

                    func skipped__test__082__Presence__private_and_internal_PresenceMap_containing_only_members_that_match_the_current_connectionId__events_applied_to_presence_map__should_be_applied_to_ENTER__PRESENT_or_UPDATE_events_with_a_connectionId_that_matches_the_current_client_s_connectionId() {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.presence.subscribe(.enter) { presence in
                                expect(presence.clientId).to(equal("one"))
                                channel.presence.unsubscribe()
                                partialDone()
                            }
                            channel.presence.enterClient("one", data: nil) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }

                        guard let connectionId = client.connection.id else {
                            fail("connectionId is empty"); return
                        }

                        channel.internalSync { _internal in
                            expect(_internal.presenceMap.localMembers).to(haveCount(1))
                        }

                        let additionalMember = ARTPresenceMessage(
                            clientId: "two",
                            action: .enter,
                            connectionId: connectionId,
                            id: connectionId + ":0:0"
                        )

                        // Inject an additional member into the myMember set, then force a suspended state
                        client.simulateSuspended(beforeSuspension: { done in
                            channel.internal.presenceMap.localMembers.add(additionalMember)
                            done()
                        })
                        expect(client.connection.state).toEventually(equal(.suspended), timeout: testTimeout)

                        expect(channel.internal.presenceMap.localMembers).to(haveCount(2))
                        
                        channel.internalSync { _internal in
                            expect(_internal.presenceMap.localMembers).to(haveCount(2))
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)

                            channel.once(.attached) { stateChange in
                                expect(stateChange.reason).to(beNil())
                                partialDone()
                            }

                            // Await Sync
                            channel.internal.presenceMap.onceSyncEnds { _ in
                                // Should remove the "two" member that was added manually because the connectionId
                                //doesn't match and it's not synthesized, it will be re-entered.
                                expect(channel.internal.presenceMap.localMembers).to(haveCount(1))

                                partialDone()
                            }

                            channel.presence.subscribe(.enter) { presence in
                                expect(presence.clientId).to(equal("two"))
                                channel.presence.unsubscribe()
                                partialDone()
                            }

                            // Reconnect
                            client.connect()
                        }

                        // Wait for server
                        waitUntil(timeout: testTimeout) { done in
                            delay(1, closure: done)
                        }

                        channel.internalAsync { _internal in
                            _internal.sync()
                        }

                        expect(channel.presence.syncComplete).to(beFalse())
                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get { presences, error in
                                expect(error).to(beNil())
                                guard let presences = presences else {
                                    fail("Presences is nil"); done(); return
                                }
                                expect(channel.presence.syncComplete).to(beTrue())
                                expect(presences).to(haveCount(2))
                                expect(presences.map({$0.clientId})).to(contain(["one", "two"]))
                                done()
                            }
                        }
                    }

                    func skipped__test__083__Presence__private_and_internal_PresenceMap_containing_only_members_that_match_the_current_connectionId__events_applied_to_presence_map__should_be_applied_to_any_LEAVE_event_with_a_connectionId_that_matches_the_current_client_s_connectionId_and_is_not_a_synthesized() {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        client.internal.shouldImmediatelyReconnect = false
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.presence.subscribe(.enter) { presence in
                                expect(presence.clientId).to(equal("one"))
                                channel.presence.unsubscribe()
                                partialDone()
                            }
                            channel.presence.enterClient("one", data: nil) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }

                        waitUntil(timeout: .seconds(20)) { done in
                            channel.internal.presenceMap.onceSyncEnds { _ in
                                // Synthesized leave
                                expect(channel.internal.presenceMap.localMembers).to(beEmpty())
                                done()
                            }
                            client.internal.onDisconnected()
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.subscribe(.enter) { presence in
                                // Re-entering...
                                expect(presence.clientId).to(equal("one"))
                                channel.presence.unsubscribe()
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get { presences, error in
                                expect(error).to(beNil())
                                guard let presences = presences else {
                                    fail("Presences is nil"); done(); return
                                }
                                expect(channel.internal.presenceMap.syncComplete).to(beTrue())
                                expect(presences).to(haveCount(1))
                                expect(presences.map({$0.clientId})).to(contain(["one"]))
                                done()
                            }
                        }
                    }

            // RTP15d
            func test__004__Presence__callback_can_be_provided_that_will_be_called_upon_success() {
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
            func test__005__Presence__callback_can_be_provided_that_will_be_called_upon_failure() {
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
                        expect(errorInfo.code).to(equal(ARTErrorCode.operationNotPermittedWithProvidedCapability.intValue))
                        done()
                    }
                }
            }

            // RTP15c
            func test__006__Presence__should_also_ensure_that_using_updateClient_has_no_side_effects_on_a_client_that_has_entered_normally_using_Presence_enter() {
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
enum TestCase_ReusableTestsTestPresencePerformMethod {
case should_implicitly_attach_the_Channel
case should_result_in_an_error_if_the_channel_is_in_the_FAILED_state
case should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state
}


            // RTP15e
            func reusableTestsTestPresencePerformMethod(testCase: TestCase_ReusableTestsTestPresencePerformMethod, context: (beforeEach: (() -> ())?, afterEach: (() -> ())?), _ performMethod: @escaping (ARTRealtimePresence, Optional<(ARTErrorInfo?)->Void>)->()) {
                func test__should_implicitly_attach_the_Channel() {
context.beforeEach?()

                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    
                    expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))
                    waitUntil(timeout: testTimeout) { done in
                        //Call: enterClient, updateClient and leaveClient
                        performMethod(channel.presence) { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
context.afterEach?()

                }
                
                func test__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() {
context.beforeEach?()

                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    
                    let expectedErrorMessage = "Something has failed"
                    AblyTests.queue.async {
                        channel.internal.onError(AblyTests.newErrorProtocolMessage(message: expectedErrorMessage))
                    }
                    
                    waitUntil(timeout: testTimeout) { done in
                        //Call: enterClient, updateClient and leaveClient
                        performMethod(channel.presence) { error in
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                            guard let reason = channel.errorReason else {
                                fail("Reason is empty"); done(); return
                            }
                            expect(reason.message).to(equal(expectedErrorMessage))
                            done()
                        }
                    }
context.afterEach?()

                }
                
                func test__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() {
context.beforeEach?()

                    let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    
                    waitUntil(timeout: testTimeout) { done in
                        let error = AblyTests.newErrorProtocolMessage()
                        channel.once(.attaching) { _ in
                            AblyTests.queue.async {
                                channel.internal.onError(error)
                            }
                        }
                        (client.internal.transport as! TestProxyTransport).actionsIgnored += [.attached]
                        //Call: enterClient, updateClient and leaveClient
                        performMethod(channel.presence) { errorInfo in
                            expect(errorInfo).to(equal(error.error))
                            done()
                        }
                    }
context.afterEach?()

                }

switch testCase  {
case .should_implicitly_attach_the_Channel:
    test__should_implicitly_attach_the_Channel()
case .should_result_in_an_error_if_the_channel_is_in_the_FAILED_state:
    test__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state()
case .should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state:
    test__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state()
}

            }
            
            
                func test__Presence__enterClient__reusableTestsTestPresencePerformMethod(testCase: TestCase_ReusableTestsTestPresencePerformMethod) {
                reusableTestsTestPresencePerformMethod (testCase: testCase, context: (beforeEach: nil, afterEach: nil)){ $0.enterClient("john", data: nil, callback: $1) }}
func test__084__Presence__enterClient__should_implicitly_attach_the_Channel() {
test__Presence__enterClient__reusableTestsTestPresencePerformMethod(testCase: .should_implicitly_attach_the_Channel)
}

func test__085__Presence__enterClient__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() {
test__Presence__enterClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_is_in_the_FAILED_state)
}

func test__086__Presence__enterClient__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() {
test__Presence__enterClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state)
}

            
            
                func test__Presence__updateClient__reusableTestsTestPresencePerformMethod(testCase: TestCase_ReusableTestsTestPresencePerformMethod) {
                reusableTestsTestPresencePerformMethod (testCase: testCase, context: (beforeEach: nil, afterEach: nil)){ $0.updateClient("john", data: nil, callback: $1) }}
func test__087__Presence__updateClient__should_implicitly_attach_the_Channel() {
test__Presence__updateClient__reusableTestsTestPresencePerformMethod(testCase: .should_implicitly_attach_the_Channel)
}

func test__088__Presence__updateClient__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() {
test__Presence__updateClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_is_in_the_FAILED_state)
}

func test__089__Presence__updateClient__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() {
test__Presence__updateClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state)
}

            
            
                func test__Presence__leaveClient__reusableTestsTestPresencePerformMethod(testCase: TestCase_ReusableTestsTestPresencePerformMethod) {
                reusableTestsTestPresencePerformMethod (testCase: testCase, context: (beforeEach: nil, afterEach: nil)){ $0.leaveClient("john", data: nil, callback: $1) }}
func test__090__Presence__leaveClient__should_implicitly_attach_the_Channel() {
test__Presence__leaveClient__reusableTestsTestPresencePerformMethod(testCase: .should_implicitly_attach_the_Channel)
}

func test__091__Presence__leaveClient__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() {
test__Presence__leaveClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_is_in_the_FAILED_state)
}

func test__092__Presence__leaveClient__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() {
test__Presence__leaveClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state)
}


            // RTP15f
            func test__007__Presence__should_indicate_an_error_if_the_client_is_identified_and_has_a_valid_clientId_and_the_clientId_argument_does_not_match_the_client_s_clientId() {
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
                        expect(members?.first?.data as? String).to(equal("browser"))
                        done()
                    }
                }
            }

            // RTP16
            

                // RTP16a
                func test__093__Presence__Connection_state_conditions__all_presence_messages_are_published_immediately_if_the_connection_is_CONNECTED() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).to(beNil())
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                            expect(client.internal.queuedMessages).to(haveCount(0))
                            done()
                        }
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connecting))
                        expect(client.internal.queuedMessages).to(haveCount(1))
                    }
                }

                // RTP16b
                func test__094__Presence__Connection_state_conditions__all_presence_messages_will_be_queued_and_delivered_as_soon_as_the_connection_state_returns_to_CONNECTED() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(client.internal.options.queueMessages).to(beTrue())

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { _ in
                            client.internal.onDisconnected()
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).to(beNil())
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                            expect(client.internal.queuedMessages).to(haveCount(0))
                            done()
                        }
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.disconnected))
                        expect(client.internal.queuedMessages).to(haveCount(1))
                    }
                }

                // RTP16b
                func test__095__Presence__Connection_state_conditions__all_presence_messages_will_be_lost_if_queueMessages_has_been_explicitly_set_to_false() {
                    let options = AblyTests.commonAppSetup()
                    options.queueMessages = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(client.internal.options.queueMessages).to(beFalse())

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { _ in
                            client.internal.onDisconnected()
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error).toNot(beNil())
                            done()
                        }
                        expect(client.internal.queuedMessages).to(haveCount(0))
                    }
                }

                // RTP16c
                func test__096__Presence__Connection_state_conditions__should_result_in_an_error_if_the_connection_state_is_INITIALIZED_and_queueMessages_has_been_explicitly_set_to_false() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.queueMessages = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.initialized))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.enterClient("user", data: nil) { error in
                            expect(error?.code).to(equal(ARTErrorCode.invalidTransportHandle.intValue))
                            expect(channel.presence.internal.pendingPresence).to(haveCount(0))
                            done()
                        }
                        expect(channel.presence.internal.pendingPresence).to(haveCount(0))
                    }
                }

                func test__097__Presence__Connection_state_conditions__should_result_in_an_error_if_the_connection_state_is__suspended() {
                    testResultsInErrorWithConnectionState(.suspended) { client in
                        AblyTests.queue.async {
                            client.internal.onSuspended()
                        }
                    }
                }
                
                func test__098__Presence__Connection_state_conditions__should_result_in_an_error_if_the_connection_state_is__closed() {
                    testResultsInErrorWithConnectionState(.closed) { client in
                        client.close()
                    }
                }
                
                func test__099__Presence__Connection_state_conditions__should_result_in_an_error_if_the_connection_state_is__failed() {
                    testResultsInErrorWithConnectionState(.failed) { client in
                        AblyTests.queue.async {
                            client.internal.onError(AblyTests.newErrorProtocolMessage())
                        }
                    }
                }

            // RTP11
            

                
                    func test__106__Presence__get__query__waitForSync_should_be_true_by_default() {
                        expect(ARTRealtimePresenceQuery().waitForSync).to(beTrue())
                    }
                
                // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
                // RTP11a
                func skipped__test__100__Presence__get__should_return_a_list_of_current_members_on_the_channel() {
                    let options = AblyTests.commonAppSetup()

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.dispose()
                            clientItem.close()
                        }
                    }

                    let expectedData = "online"

                    disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 150, data:expectedData as AnyObject?, options: options)]

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let hook = ARTRealtimePresenceQuery.testSuite_injectIntoClassMethod(#selector(ARTRealtimePresenceQuery.init as () -> ARTRealtimePresenceQuery)) { // Default initialiser: referring to the no-parameter variant of `init` as one of several overloaded methods requires an explicit `as <signature>` cast
                    }
                    defer { hook?.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            expect(members).to(haveCount(150))
                            expect(members!.first).to(beAnInstanceOf(ARTPresenceMessage.self))
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: "^user(\\d+)$")
                                    && (member!.data as? String) == expectedData
                            }))
                            done()
                        }
                    }

                }

                // RTP11b
                func test__101__Presence__get__should_implicitly_attach_the_channel() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    expect(channel.state).to(equal(ARTRealtimeChannelState.initialized))
                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { membersPage, error in
                            expect(error).to(beNil())
                            expect(membersPage).toNot(beNil())
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                    }
                    expect(channel.state).to(equal(ARTRealtimeChannelState.attached))
                }

                // RTP11b
                func test__102__Presence__get__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    let pm = AblyTests.newErrorProtocolMessage()
                    AblyTests.queue.async {
                        channel.internal.onError(pm)
                    }

                    guard let protocolError = pm.error else {
                        fail("Protocol error is empty"); return
                    }
                    guard let channelError = channel.errorReason else {
                        fail("Channel error is empty"); return
                    }
                    expect(channelError.message).to(equal(protocolError.message))
                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { members, error in
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            expect(channel.errorReason).to(equal(protocolError))
                            expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                            expect(members).to(beNil())
                            done()
                        }
                    }
                }

                // RTP11b
                func test__103__Presence__get__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() {
                    let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let pm = AblyTests.newErrorProtocolMessage()
                        guard let protocolError = pm.error else {
                            fail("Protocol error is empty"); done(); return
                        }
                        (client.internal.transport as! TestProxyTransport).actionsIgnored += [.attached]
                        channel.once(.attaching) { _ in
                            AblyTests.queue.async {
                                channel.internal.onError(pm)
                            }
                        }
                        channel.presence.get() { members, error in
                            guard let error = error else {
                                fail("Error is empty"); done(); return
                            }
                            expect(error.message).to(equal(protocolError.message))
                            expect(members).to(beNil())
                            done()
                        }
                    }

                    expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                }

                // RTP11b
                func test__104__Presence__get__should_result_in_an_error_if_the_channel_is_in_the_DETACHED_state() {
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
                            expect(error?.code).to(equal(ARTErrorCode.channelOperationFailedInvalidState.intValue))
                            expect(members).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.detached))
                            done()
                        }
                    }
                }

                // RTP11b
                func test__105__Presence__get__should_result_in_an_error_if_the_channel_moves_to_the_DETACHED_state() {
                    let options = AblyTests.commonAppSetup()

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    var clientMembers: ARTRealtime?
                    defer { clientMembers?.dispose(); clientMembers?.close() }
                    clientMembers = AblyTests.addMembersSequentiallyToChannel("test", members: 120, options: options)

                    let channel = client.channels.get("test")
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

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)
                }
                
                // RTP11d
                
                    
                    
                        func test__107__Presence__get__If_the_Channel_is_in_the_SUSPENDED_state_then__by_default__results_in_an_error() {
                            testSuspendedStateResultsInError { channel, callback in
                                channel.presence.get(callback)
                            }
                        }
                    
                    
                        func test__108__Presence__get__If_the_Channel_is_in_the_SUSPENDED_state_then__if_waitForSync_is_true__results_in_an_error() {
                            testSuspendedStateResultsInError { channel, callback in
                                let params = ARTRealtimePresenceQuery()
                                params.waitForSync = true
                                channel.presence.get(params, callback: callback)
                            }
                        }
                    
                    
                        
                        func test__109__Presence__get__If_the_Channel_is_in_the_SUSPENDED_state_then__if_waitForSync_is_false__returns_the_members_in_the_current_PresenceMap() {
                            let (channel, client) = getSuspendedChannel()
                            defer { client.dispose(); client.close() }
                            
                            var msgs = [String: ARTPresenceMessage]()
                            for i in 0..<3 {
                                let msg = ARTPresenceMessage(clientId: "client\(i)", action: .present, connectionId: "foo", id: "foo:0:0")
                                msgs[msg.clientId!] = msg
                                channel.internal.presenceMap.internalAdd(msg)
                            }
                            
                            channel.presence.get(getParams) { result, err in
                                expect(err).to(beNil())
                                expect(result).toNot(beNil())
                                guard let result = result else {
                                    return
                                }
                                var resultByClient = [String: ARTPresenceMessage]()
                                for msg in result {
                                    resultByClient[msg.clientId ?? "(no clientId)"] = msg
                                }
                                expect(resultByClient).to(equal(msgs))
                            }
                        }

                // RTP11c
                

                    // RTP11c1
                    func skipped__test__110__Presence__get__Query__set_of_params___waitForSync_is_true__should_wait_until_SYNC_is_complete_before_returning_a_list_of_members() {
                        let options = AblyTests.commonAppSetup()
                        var clientSecondary: ARTRealtime!
                        defer { clientSecondary.dispose(); clientSecondary.close() }
                        clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, options: options)

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        let query = ARTRealtimePresenceQuery()
                        expect(query.waitForSync).to(beTrue())

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                let transport = client.internal.transport as! TestProxyTransport
                                transport.setListenerBeforeProcessingIncomingMessage({ protocolMessage in
                                    if protocolMessage.action == .sync {
                                        expect(protocolMessage.presence!.count).to(equal(100))
                                        channel.presence.get(query) { members, error in
                                            expect(error).to(beNil())
                                            expect(members).to(haveCount(150))
                                            done()
                                        }
                                        transport.setListenerBeforeProcessingIncomingMessage(nil)
                                    }
                                })
                            }
                        }
                    }

                    // RTP11c1
                    func test__111__Presence__get__Query__set_of_params___waitForSync_is_false__should_return_immediately_the_known_set_of_presence_members() {
                        let options = AblyTests.commonAppSetup()
                        var clientSecondary: ARTRealtime!
                        defer { clientSecondary.dispose(); clientSecondary.close() }
                        clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, options: options)

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        let query = ARTRealtimePresenceQuery()
                        query.waitForSync = false

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                let transport = client.internal.transport as! TestProxyTransport
                                transport.setListenerBeforeProcessingIncomingMessage({ message in
                                    if message.action == .sync {
                                        // Ignore next SYNC so that the sync process never finishes.
                                        transport.actionsIgnored += [.sync]
                                        done()
                                    }
                                })
                            }
                        }
                        
                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get(query) { members, error in
                                expect(error).to(beNil())
                                expect(members).to(haveCount(100))
                                done()
                            }
                        }
                    }

                    // RTP11c2
                    func test__112__Presence__get__Query__set_of_params___should_return_members_filtered_by_clientId() {
                        let options = AblyTests.commonAppSetup()
                        let now = NSDate()

                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channelName = NSUUID().uuidString
                        let channel = client.channels.get(channelName)

                        let presenceData: [ARTPresenceMessage] = [
                            ARTPresenceMessage(clientId: "a", action: .enter, connectionId: "one", id: "one:0:0", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "a", action: .leave, connectionId: "one", id: "fabricated:0:1", timestamp: (now as Date) + 1),
                            ARTPresenceMessage(clientId: "b", action: .enter, connectionId: "one", id: "one:0:2", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "b", action: .leave, connectionId: "one", id: "fabricated:0:3", timestamp: (now as Date) - 1),
                            ARTPresenceMessage(clientId: "c", action: .enter, connectionId: "one", id: "fabricated:0:4", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "c", action: .leave, connectionId: "one", id: "fabricated:0:5", timestamp: (now as Date) - 1),
                        ]

                        guard let transport = client.internal.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())

                                // Inject a fabricated Presence message
                                let presenceMessage = ARTProtocolMessage()
                                presenceMessage.action = .presence
                                presenceMessage.channel = channel.name
                                presenceMessage.timestamp = Date()
                                presenceMessage.presence = presenceData

                                transport.receive(presenceMessage)

                                done()
                            }
                        }

                        let query = ARTRealtimePresenceQuery()
                        query.clientId = "b"

                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.get(query) { members, error in
                                expect(error).to(beNil())
                                guard let members = members else {
                                    fail("Members is nil"); done(); return
                                }
                                expect(members).to(haveCount(1))
                                expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .absent }))
                                expect(members.filter{ $0.clientId == "a" }).to(beEmpty())
                                expect(members.filter{ $0.clientId == "b" }).to(haveCount(1))
                                expect(members.filter{ $0.clientId == "c" }).to(beEmpty())
                                done()
                            }
                        }
                    }

                    // RTP11c3
                    func test__113__Presence__get__Query__set_of_params___should_return_members_filtered_by_connectionId() {
                        let options = AblyTests.commonAppSetup()
                        let now = NSDate()
                        let channelName = NSUUID().uuidString
                        var clientMembers: ARTRealtime?
                        defer { clientMembers?.dispose(); clientMembers?.close() }
                        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 101, options: options)

                        let clientSubscribed = AblyTests.newRealtime(options)
                        defer { clientSubscribed.dispose(); clientSubscribed.close() }
                        let channelSubscribed = clientSubscribed.channels.get(channelName)

                        let presenceData: [ARTPresenceMessage] = [
                            ARTPresenceMessage(clientId: "a", action: .enter, connectionId: "one", id: "one:0:0", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "a", action: .leave, connectionId: "one", id: "fabricated:0:1", timestamp: (now as Date) + 1),
                            ARTPresenceMessage(clientId: "b", action: .enter, connectionId: "one", id: "one:0:2", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "b", action: .leave, connectionId: "one", id: "fabricated:0:3", timestamp: (now as Date) - 1),
                            ARTPresenceMessage(clientId: "c", action: .enter, connectionId: "one", id: "fabricated:0:4", timestamp: now as Date),
                            ARTPresenceMessage(clientId: "c", action: .leave, connectionId: "one", id: "fabricated:0:5", timestamp: (now as Date) - 1),
                        ]

                        guard let transport = clientSubscribed.internal.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            transport.setAfterIncomingMessageModifier({ protocolMessage in
                                // Receive the first Sync message from Ably service
                                if protocolMessage.action == .sync {
                                    // Inject a fabricated Presence message
                                    let presenceMessage = ARTProtocolMessage()
                                    presenceMessage.action = .presence
                                    presenceMessage.channel = protocolMessage.channel
                                    presenceMessage.connectionSerial = protocolMessage.connectionSerial + 1
                                    presenceMessage.timestamp = Date()
                                    presenceMessage.presence = presenceData

                                    transport.receive(presenceMessage)

                                    // Simulate an end to the sync
                                    let endSyncMessage = ARTProtocolMessage()
                                    endSyncMessage.action = .sync
                                    endSyncMessage.channel = protocolMessage.channel
                                    endSyncMessage.channelSerial = "validserialprefix:" //with no part after the `:` this indicates the end to the SYNC
                                    endSyncMessage.connectionSerial = protocolMessage.connectionSerial + 2
                                    endSyncMessage.timestamp = Date()

                                    transport.setAfterIncomingMessageModifier(nil)
                                    transport.receive(endSyncMessage)

                                    // Stop the next sync message from Ably service because we already injected the end of the sync
                                    transport.actionsIgnored = [.sync]

                                    done()
                                }
                                return protocolMessage
                            })
                            channelSubscribed.attach()
                        }

                        let query = ARTRealtimePresenceQuery()
                        query.connectionId = "one"

                        waitUntil(timeout: testTimeout) { done in
                            channelSubscribed.presence.get(query) { members, error in
                                expect(error).to(beNil())
                                guard let members = members else {
                                    fail("Members is nil"); done(); return
                                }
                                expect(members).to(haveCount(2))
                                expect(members).to(allPass({ (member: ARTPresenceMessage?) in member!.action != .absent }))
                                expect(members.filter{ $0.clientId == "a" }).to(beEmpty())
                                expect(members.filter{ $0.clientId == "b" }).to(haveCount(1))
                                expect(members.filter{ $0.clientId == "c" }).to(haveCount(1))
                                done()
                            }
                        }
                    }

            // RTP12
            

                // RTP12a
                func test__114__Presence__history__should_support_all_the_same_params_as_Rest() {
                    let options = AblyTests.commonAppSetup()

                    let rest = ARTRest(options: options)

                    let realtime = ARTRealtime(options: options)
                    defer { realtime.dispose(); realtime.close() }

                    let channelRest = rest.channels.get("test")
                    let channelRealtime = realtime.channels.get("test")

                    var restPresenceHistoryMethodWasCalled = false

                    let hookRest = channelRest.presence.internal.testSuite_injectIntoMethod(after: #selector(ARTRestPresenceInternal.history(_:callback:))) {
                        restPresenceHistoryMethodWasCalled = true
                    }
                    defer { hookRest.remove() }

                    let hookRealtime = channelRealtime.presence.internal.testSuite_injectIntoMethod(after: #selector(ARTRestPresenceInternal.history(_:callback:))) {
                        restPresenceHistoryMethodWasCalled = true
                    }
                    defer { hookRealtime.remove() }

                    let queryRealtime = ARTRealtimeHistoryQuery()
                    queryRealtime.start = Date()
                    queryRealtime.end = Date()
                    queryRealtime.direction = .forwards
                    queryRealtime.limit = 50

                    let queryRest = queryRealtime as ARTDataQuery

                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try channelRest.presence.history(queryRest) { _, _ in
                                done()
                            }
                        }.toNot(throwError() { err in fail("\(err)"); done() })
                    }
                    expect(restPresenceHistoryMethodWasCalled).to(beTrue())
                    restPresenceHistoryMethodWasCalled = false

                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try channelRealtime.presence.history(queryRealtime) { _, _ in
                                done()
                            }
                        }.toNot(throwError() { err in fail("\(err)"); done() })
                    }
                    expect(restPresenceHistoryMethodWasCalled).to(beTrue())
                }

            // RTP12
            

                // RTP12c, RTP12d
                func test__115__Presence__history__should_return_a_PaginatedResult_page() {
                    let options = AblyTests.commonAppSetup()

                    var clientSecondary: ARTRealtime!
                    defer { clientSecondary.dispose(); clientSecondary.close() }

                    let expectedData = ["x", "y"]
                    let expectedPattern = "^user(\\d+)$"
                    clientSecondary = AblyTests.addMembersSequentiallyToChannel("test", members: 150, data: expectedData as AnyObject?, options: options)

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.history { membersPage, error in
                            expect(error).to(beNil())
                            guard let membersPage = membersPage else {
                                fail("membersPage is empty"); done(); return
                            }
                            expect(membersPage).to(beAnInstanceOf(ARTPaginatedResult<ARTPresenceMessage>.self))
                            expect(membersPage.items).to(haveCount(100))

                            let members = membersPage.items 
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                    && (member!.data as! [String]) == expectedData
                            }))

                            expect(membersPage.hasNext).to(beTrue())
                            expect(membersPage.isLast).to(beFalse())

                            membersPage.next { nextPage, error in
                                expect(error).to(beNil())
                                guard let nextPage = nextPage else {
                                    fail("nextPage is empty"); done(); return
                                }
                                expect(nextPage).to(beAnInstanceOf(ARTPaginatedResult<ARTPresenceMessage>.self))
                                expect(nextPage.items).to(haveCount(50))

                                let members = nextPage.items 
                                expect(members).to(allPass({ member in
                                    return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                        && (member!.data as! [String]) == expectedData
                                }))

                                expect(nextPage.hasNext).to(beFalse())
                                expect(nextPage.isLast).to(beTrue())
                                done()
                            }
                        }
                    }
                }

            // RTP13
            func skipped__test__008__Presence__Presence_syncComplete_returns_true_if_the_initial_SYNC_operation_has_completed() {
                let options = AblyTests.commonAppSetup()

                var disposable = [ARTRealtime]()
                defer {
                    for clientItem in disposable {
                        clientItem.dispose()
                        clientItem.close()
                    }
                }

                disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 250, options: options)]

                let client = AblyTests.newRealtime(options)
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")
                channel.attach()

                expect(channel.presence.syncComplete).to(beFalse())
                expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                let transport = client.internal.transport as! TestProxyTransport
                transport.setListenerBeforeProcessingIncomingMessage({ protocolMessage in
                    if protocolMessage.action == .sync {
                        expect(channel.presence.internal.syncComplete_nosync()).to(beFalse())
                    }
                })

                expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
                expect(transport.protocolMessagesReceived.filter({ $0.action == .sync })).to(haveCount(3))
            }

            // RTP14
            

                // RTP14a, RTP14b, RTP14c, RTP14d
                func skipped__test__116__Presence__enterClient__enters_into_presence_on_a_channel_on_behalf_of_another_clientId() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    expect(channel.internal.presenceMap.members).to(haveCount(0))

                    let expectedData = ["test":1]

                    var encodeNumberOfCalls = 0
                    let hookEncode = channel.internal.dataEncoder.testSuite_injectIntoMethod(after: #selector(ARTDataEncoder.encode(_:))) {
                        encodeNumberOfCalls += 1
                    }
                    defer { hookEncode.remove() }

                    var decodeNumberOfCalls = 0
                    let hookDecode = channel.internal.dataEncoder.testSuite_injectIntoMethod(after: #selector(ARTDataEncoder.decode(_:encoding:))) {
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
                    expect(channel.internal.presenceMap.members).toEventually(haveCount(3), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get() { members, error in
                            guard let members = members?.reduce([String:ARTPresenceMessage](), { (dictionary, item) in
                                return dictionary + [item.clientId ?? "":item]
                            }) else { fail("No members"); done(); return }

                            expect(members["test"]!.data as? NSDictionary).to(equal(expectedData as NSDictionary?))
                            expect(members["john"]).toNot(beNil())
                            expect(members["sara"]).toNot(beNil())
                            done()
                        }
                    }

                    expect(encodeNumberOfCalls).to(equal(1))
                    expect(decodeNumberOfCalls).to(equal(1))
                }

                // RTP14d
                func test__117__Presence__enterClient__should_be_present_all_the_registered_members_on_a_presence_channel() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let channelName = NSUUID().uuidString
                    let channel = client.channels.get(channelName)

                    let john = "john"
                    let max = "max"

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(4, done: done)
                        channel.presence.subscribe { message in
                            expect(message.clientId).to(satisfyAnyOf(equal(john), equal(max)))
                            partialDone()
                        }
                        channel.presence.enterClient(john, data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                        channel.presence.enterClient(max, data: nil) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { members, error in
                            expect(error).to(beNil())
                            guard let members = members else {
                                fail("Members is nil"); done(); return
                            }
                            expect(members).to(haveCount(2))
                            let clientIds = members.map({ $0.clientId })
                            // Cannot guarantee the order
                            expect(clientIds).to(equal([john, max]) || equal([max, john]))
                            done()
                        }
                    }
                }
            
            
                
                // TP3a
                func test__118__Presence__presence_message_attributes__if_the_presence_message_does_not_contain_an_id__it_should_be_set_to_protocolMsgId_index() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    let protocolMessage = ARTProtocolMessage()
                    protocolMessage.id = "protocolId"
                    let presenceMessage = ARTPresenceMessage()
                    presenceMessage.clientId = "clientId"
                    presenceMessage.action = .enter
                    protocolMessage.presence = [presenceMessage]
                    
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { _ in
                            let channel = client.channels.get(NSUUID().uuidString)
                            channel.presence.subscribe(.enter) { message in
                                expect(message.id).to(equal("protocolId:0"))
                                done()
                            }
                            AblyTests.queue.async {
                                channel.internal.onPresence(protocolMessage)
                            }
                        }
                        client.connect()
                    }
                }
}
