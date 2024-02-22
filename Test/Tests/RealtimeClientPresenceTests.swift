import Ably
import Foundation
import Nimble
import XCTest

// RTP16c
private func testResultsInErrorWithConnectionState(_ connectionState: ARTRealtimeConnectionState, for test: Test, channelName: String, performMethod: @escaping (ARTRealtime) -> Void) throws {
    let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
    defer { client.dispose(); client.close() }
    let channel = client.channels.get(channelName)
    XCTAssertTrue(client.internal.options.queueMessages)

    waitUntil(timeout: testTimeout) { done in
        channel.attach { _ in
            performMethod(client)
            done()
        }
    }

    expect(client.connection.state).toEventually(equal(connectionState), timeout: testTimeout)

    waitUntil(timeout: testTimeout) { done in
        channel.presence.enterClient("user", data: nil) { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(client.internal.queuedMessages.count, 0)
            done()
        }
        XCTAssertEqual(client.internal.queuedMessages.count, 0)
    }
}

private func getSuspendedChannel(named: String, for test: Test) throws -> (ARTRealtimeChannel, ARTRealtime) {
    let options = try AblyTests.commonAppSetup(for: test)

    let client = ARTRealtime(options: options)
    let channel = client.channels.get(named)

    waitUntil(timeout: testTimeout) { done in
        channel.once(.suspended) { _ in
            done()
        }
        client.internal.onSuspended()
    }

    return (channel, client)
}

private func testSuspendedStateResultsInError(for test: Test, channelName: String, _ getPresence: (ARTRealtimeChannel, @escaping ([ARTPresenceMessage]?, ARTErrorInfo?) -> Void) -> Void) throws {
    let (channel, client) = try getSuspendedChannel(named: channelName, for: test)
    defer { client.dispose(); client.close() }

    getPresence(channel) { result, err in
        XCTAssertNil(result)
        XCTAssertNotNil(err)
        guard let err = err else {
            return
        }
        XCTAssertEqual(err.code, ARTErrorCode.presenceStateIsOutOfSync.intValue)
    }
}

private let getParams: ARTRealtimePresenceQuery = {
    let getParams = ARTRealtimePresenceQuery()
    getParams.waitForSync = false
    return getParams
}()

// Attaches to the given channel. If, upon attach, Realtime indicates that it
// will initiate a presence SYNC (as indicated by the presence flag on the
// received ATTACH protocol message), this method will then wait until the
// presence sync has completed.
//
// The client must have been set up to use TestProxyTransport (e.g. using
// AblyTests.newRealtime(:)).
private func attachAndWaitForInitialPresenceSyncToComplete(client: ARTRealtime, channel: ARTRealtimeChannel) {
    waitUntil(timeout: testTimeout) { done in
        channel.attach { error in
            XCTAssertNil(error)
            done()
        }
    }
    
    let transport = client.internal.transport as! TestProxyTransport
    
    let attachedProtocolMessage = transport.protocolMessagesReceived.first { $0.action == .attached }
    XCTAssertNotNil(attachedProtocolMessage)
    
    if ARTProtocolMessageFlag(rawValue: UInt(attachedProtocolMessage!.flags)).contains(.presence) {
        expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
    }
}

class RealtimeClientPresenceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AsyncDefaults.timeout = testTimeout
    }

    // XCTest invokes this method before executing the first test in the test suite. We use it to ensure that the global variables are initialized at the same moment, and in the same order, as they would have been when we used the Quick testing framework.
    override class var defaultTestSuite: XCTestSuite {
        _ = getParams

        return super.defaultTestSuite
    }

    // RTP1

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    func skipped__test__009__Presence__ProtocolMessage_bit_flag__when_no_members_are_present() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        channel.attach()

        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        let transport = client.internal.transport as! TestProxyTransport
        let attached = transport.protocolMessagesReceived.filter { $0.action == .attached }[0]

        XCTAssertEqual(attached.flags & 0x1, 0)
        XCTAssertFalse(attached.hasPresence)
        XCTAssertFalse(channel.presence.syncComplete)
        XCTAssertFalse(channel.internal.presenceMap.syncComplete)
    }

    func skipped__test__010__Presence__ProtocolMessage_bit_flag__when_members_are_present() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        var disposable = [ARTRealtime]()
        defer {
            for clientItem in disposable {
                clientItem.dispose()
                clientItem.close()
            }
        }

        let channelName = test.uniqueChannelName()
        disposable += [AblyTests.addMembersSequentiallyToChannel(channelName, members: 250, options: options)]

        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)
        channel.attach()

        XCTAssertFalse(channel.presence.syncComplete)
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        let transport = client.internal.transport as! TestProxyTransport
        let attached = transport.protocolMessagesReceived.filter { $0.action == .attached }[0]

        // There are members present on the channel
        XCTAssertEqual(attached.flags & 0x1, 1)
        XCTAssertTrue(attached.hasPresence)

        expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)

        XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .sync }.count, 3)
    }

    // RTP18

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP18a, RTP18b
    func skipped__test__011__Presence__realtime_system_reserves_the_right_to_initiate_a_sync_of_the_presence_members_at_any_point_once_a_channel_is_attached__should_do_a_new_sync_whenever_a_SYNC_ProtocolMessage_is_received_with_a_channel_attribute_and_a_new_sync_sequence_identifier_in_the_channelSerial_attribute() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)
        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        XCTAssertFalse(channel.internal.presenceMap.syncInProgress)
        expect(channel.internal.presenceMap.members).to(beEmpty())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.present) { msg in
                if msg.clientId != "a" {
                    return
                }
                XCTAssertFalse(channel.presence.syncComplete)
                var aClientHasLeft = false
                channel.presence.subscribe(.leave) { _ in
                    if aClientHasLeft {
                        return
                    }
                    aClientHasLeft = true
                    done()
                }
            }

            // Inject a SYNC Presence message (first page)
            let sync1Message = ARTProtocolMessage()
            sync1Message.action = .sync
            sync1Message.channel = channel.name
            sync1Message.channelSerial = "sequenceid:cursor"
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
            sync2Message.channelSerial = "sequenceid:" // indicates SYNC is complete
            sync2Message.timestamp = Date()
            sync2Message.presence = [
                ARTPresenceMessage(clientId: "a", action: .leave, connectionId: "another", id: "another:1:0"),
            ]
            delay(0.5) {
                transport.receive(sync2Message)
            }
        }

        XCTAssertTrue(channel.presence.syncComplete)
        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                guard let members = members, members.count == 1 else {
                    fail("Should at least have 1 member"); done(); return
                }
                XCTAssertEqual(members[0].clientId, "b")
                done()
            }
        }
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP18c, RTP18b
    func skipped__test__012__Presence__realtime_system_reserves_the_right_to_initiate_a_sync_of_the_presence_members_at_any_point_once_a_channel_is_attached__when_a_SYNC_is_sent_with_no_channelSerial_attribute_then_the_sync_data_is_entirely_contained_within_that_ProtocolMessage() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)
        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        XCTAssertFalse(channel.internal.presenceMap.syncInProgress)
        expect(channel.internal.presenceMap.members).to(beEmpty())

        waitUntil(timeout: testTimeout) { done in
            var aClientHasLeft = false
            channel.presence.subscribe(.leave) { _ in
                if aClientHasLeft {
                    return
                }
                aClientHasLeft = true
                done()
            }

            // Inject a SYNC Presence message (entirely contained)
            let syncMessage = ARTProtocolMessage()
            syncMessage.action = .sync
            syncMessage.channel = channel.name
            syncMessage.timestamp = Date()
            syncMessage.presence = [
                ARTPresenceMessage(clientId: "a", action: .present, connectionId: "another", id: "another:0:0"),
                ARTPresenceMessage(clientId: "b", action: .present, connectionId: "another", id: "another:0:1"),
                ARTPresenceMessage(clientId: "a", action: .leave, connectionId: "another", id: "another:1:0"),
            ]
            transport.receive(syncMessage)
        }

        XCTAssertTrue(channel.presence.syncComplete)
        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                guard let members = members, members.count == 1 else {
                    fail("Should at least have 1 member"); done(); return
                }
                XCTAssertEqual(members[0].clientId, "b")
                done()
            }
        }
    }

    // RTP19

    func skipped__test__013__Presence__PresenceMap_has_existing_members_when_a_SYNC_is_started__should_ensure_that_members_no_longer_present_on_the_channel_are_removed_from_the_local_PresenceMap_once_the_sync_is_complete() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let channelName = test.uniqueChannelName()
        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 2, options: options)

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)
        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                if let members {
                    XCTAssertEqual(members.count, 2) // synced
                } else {
                    XCTFail("Expected members to be non-nil")
                }
                done()
            }
        }

        XCTAssertEqual(channel.internal.presenceMap.members.count, 2)
        // Inject a local member
        let localMember = ARTPresenceMessage(clientId: NSUUID().uuidString, action: .enter, connectionId: "another", id: "another:0:0")
        channel.internal.presenceMap.add(localMember)
        XCTAssertEqual(channel.internal.presenceMap.members.count, 3)
        XCTAssertEqual(channel.internal.presenceMap.members.filter { memberKey, _ in memberKey.contains(localMember.clientId!) }.count, 1)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                guard let members = members, members.count == 3 else {
                    fail("Should at least have 3 members"); done(); return
                }
                XCTAssertEqual(members.filter { $0.clientId == localMember.clientId }.count, 1)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.leave) { leave in
                XCTAssertEqual(leave.clientId, localMember.clientId)
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
                XCTAssertNil(error)
                guard let members = members, members.count == 2 else {
                    fail("Should at least have 2 members"); done(); return
                }
                expect(members.filter { $0.clientId == localMember.clientId }).to(beEmpty())
                done()
            }
        }
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP19a
    func skipped__test__014__Presence__PresenceMap_has_existing_members_when_a_SYNC_is_started__should_emit_a_LEAVE_event_for_each_existing_member_if_the_PresenceMap_has_existing_members_when_an_ATTACHED_message_is_received_without_a_HAS_PRESENCE_flag() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)

        // Inject local members
        channel.internal.presenceMap.add(ARTPresenceMessage(clientId: "tester1", action: .enter, connectionId: "another", id: "another:0:0"))
        channel.internal.presenceMap.add(ARTPresenceMessage(clientId: "tester2", action: .enter, connectionId: "another", id: "another:0:1"))

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            transport.setListenerAfterProcessingIncomingMessage { protocolMessage in
                if protocolMessage.action == .attached {
                    XCTAssertFalse(protocolMessage.hasPresence)
                    partialDone()
                }
            }
            channel.presence.subscribe(.leave) { leave in
                if let clientId = leave.clientId {
                    XCTAssertTrue(clientId.hasPrefix("tester"))
                } else {
                    XCTFail("Expected leave.clientId to be non-nil")
                }
                XCTAssertEqual(leave.action, ARTPresenceAction.leave)
                expect(leave.timestamp).to(beCloseTo(Date(), within: 0.5))
                XCTAssertNil(leave.id)
                partialDone() // 2 times
            }
            channel.attach { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                expect(members).to(beEmpty())
                done()
            }
        }
    }

    // RTP4
    func skipped__test__002__Presence__should_receive_all_250_members() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        var clientSource: ARTRealtime!
        defer { clientSource.dispose(); clientSource.close() }
        
        let channelName = test.uniqueChannelName()
        clientSource = AblyTests.addMembersSequentiallyToChannel(channelName, members: 250, options: options)

        let clientTarget = ARTRealtime(options: options)
        defer { clientTarget.close() }
        let channel = clientTarget.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            var pending = 250
            channel.presence.subscribe { member in
                XCTAssertEqual(member.action, ARTPresenceAction.present)
                pending -= 1
                if pending == 0 {
                    done()
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                if let members {
                    XCTAssertEqual(members.count, 250)
                } else {
                    XCTFail("Expected members to be non-nil")
                }
                done()
            }
        }
    }

    // RTP6

    // RTP6a
    func test__015__Presence__subscribe__with_no_arguments_should_subscribe_a_listener_to_all_presence_messages() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        let client1 = AblyTests.newRealtime(options).client
        defer { client1.close() }
        
        let channelName = test.uniqueChannelName()
        let channel1 = client1.channels.get(channelName)
        // We want to make sure that the ENTER presence action that we publish
        // gets sent by Realtime as a PRESENCE protocol message, and not in the
        // channel’s initial post-attach SYNC. So, we wait for any initial SYNC
        // to complete before publishing any presence actions.
        attachAndWaitForInitialPresenceSyncToComplete(client: client1, channel: channel1)

        let client2 = ARTRealtime(options: options)
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        var receivedMembers = [ARTPresenceMessage]()
        channel1.presence.subscribe { member in
            receivedMembers.append(member)
        }

        waitUntil(timeout: testTimeout) { done in
            channel2.presence.enterClient("john", data: "online") { _ in
                channel2.presence.updateClient("john", data: "away") { _ in
                    channel2.presence.leaveClient("john", data: nil) { _ in
                        done()
                    }
                }
            }
        }

        expect(receivedMembers).toEventually(haveCount(3), timeout: testTimeout)
        if receivedMembers.count != 3 {
            return
        }

        XCTAssertEqual(receivedMembers[0].action, ARTPresenceAction.enter)
        XCTAssertEqual(receivedMembers[0].data as? NSObject, "online" as NSObject?)
        XCTAssertEqual(receivedMembers[0].clientId, "john")

        XCTAssertEqual(receivedMembers[1].action, ARTPresenceAction.update)
        XCTAssertEqual(receivedMembers[1].data as? NSObject, "away" as NSObject?)
        XCTAssertEqual(receivedMembers[1].clientId, "john")

        XCTAssertEqual(receivedMembers[2].action, ARTPresenceAction.leave)
        XCTAssertEqual(receivedMembers[2].data as? NSObject, "away" as NSObject?)
        XCTAssertEqual(receivedMembers[2].clientId, "john")
    }

    // RTP7

    // RTP7a
    func test__016__Presence__unsubscribe__with_no_arguments_unsubscribes_the_listener_if_previously_subscribed_with_an_action_specific_subscription() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        let listener = channel.presence.subscribe { _ in }!
        XCTAssertEqual(channel.internal.presenceEventEmitter.anyListeners.count, 1)
        channel.presence.unsubscribe(listener)
        XCTAssertEqual(channel.internal.presenceEventEmitter.anyListeners.count, 0)
    }

    // RTP5

    // RTP5a

    func test__018__Presence__Channel_state_change_side_effects__if_the_channel_enters_the_FAILED_state__all_queued_presence_messages_should_fail_immediately() throws{
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            let protocolError = AblyTests.newErrorProtocolMessage()
            channel.presence.enterClient("user", data: nil) { error in
                XCTAssertTrue(error === protocolError.error)
                XCTAssertEqual(channel.presence.internal.pendingPresence.count, 0)
                done()
            }
            XCTAssertEqual(channel.presence.internal.pendingPresence.count, 1)
            client.internal.rest.queue.async {
                channel.internal.onError(protocolError)
            }
        }
    }

    func skipped__test__019__Presence__Channel_state_change_side_effects__if_the_channel_enters_the_FAILED_state__should_clear_the_PresenceMap_including_local_members_and_does_not_emit_any_presence_events() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.enterClient("user", data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
            channel.presence.subscribe { message in
                XCTAssertEqual(message.clientId, "user")
                channel.presence.unsubscribe()
                partialDone()
            }
        }

        XCTAssertEqual(channel.internal.presenceMap.members.count, 1)
        XCTAssertEqual(channel.internal.presenceMap.localMembers.count, 1)

        channel.subscribe { _ in
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

    func test__020__Presence__Channel_state_change_side_effects__if_the_channel_enters_the_DETACHED_state__all_queued_presence_messages_should_fail_immediately() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.once(.attaching) { _ in
                channel.detach()
            }
            channel.presence.enterClient("user", data: nil) { error in
                XCTAssertNotNil(error)
                XCTAssertEqual(client.internal.queuedMessages.count, 0)
                done()
            }
        }
    }

    func test__021__Presence__Channel_state_change_side_effects__if_the_channel_enters_the_DETACHED_state__should_clear_the_PresenceMap_including_local_members_and_does_not_emit_any_presence_events() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.enterClient("user", data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
            channel.presence.subscribe { message in
                XCTAssertEqual(message.clientId, "user")
                channel.presence.unsubscribe()
                partialDone()
            }
        }

        XCTAssertEqual(channel.internal.presenceMap.members.count, 1)
        XCTAssertEqual(channel.internal.presenceMap.localMembers.count, 1)

        channel.subscribe { _ in
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

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP5b
    func skipped__test__017__Presence__Channel_state_change_side_effects__if_a_channel_enters_the_ATTACHED_state_then_all_queued_presence_messages_will_be_sent_immediately_and_a_presence_SYNC_may_be_initiated() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client1 = AblyTests.newRealtime(options).client
        defer { client1.dispose(); client1.close() }
        
        let channelName = test.uniqueChannelName()
        let channel1 = client1.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel1.presence.enterClient("Client 1", data: nil) { errorInfo in
                XCTAssertNil(errorInfo)
                done()
            }
        }

        let client2 = AblyTests.newRealtime(options).client
        defer { client2.dispose(); client2.close() }
        let channel2 = client2.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel2.presence.enterClient("Client 2", data: nil) { error in
                XCTAssertNil(error)
                XCTAssertEqual(client2.internal.queuedMessages.count, 0)
                XCTAssertEqual(channel2.state, ARTRealtimeChannelState.attached)
                partialDone()
            }
            channel2.presence.subscribe(.enter) { _ in
                if channel2.presence.syncComplete {
                    XCTAssertEqual(channel2.internal.presenceMap.members.count, 2)
                } else {
                    XCTAssertEqual(channel2.internal.presenceMap.members.count, 1)
                }
                channel2.presence.unsubscribe()
                partialDone()
            }

            XCTAssertEqual(client2.internal.queuedMessages.count, 1)
            XCTAssertFalse(channel2.presence.syncComplete)
            XCTAssertEqual(channel2.internal.presenceMap.members.count, 0)
        }

        guard let transport = client2.internal.transport as? TestProxyTransport else {
            fail("Transport should be a test proxy"); return
        }

        XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .sync }.count, 1)

        expect(channel2.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
        XCTAssertEqual(channel2.internal.presenceMap.members.count, 2)
    }

    // RTP5f

    func test__022__Presence__Channel_state_change_side_effects__channel_enters_the_SUSPENDED_state__all_queued_presence_messages_should_fail_immediately() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)
            channel.once(.attaching) { stateChange in
                XCTAssertNil(stateChange.reason)
                XCTAssertEqual(channel.presence.internal.pendingPresence.count, 1)
                channel.internalAsync { _internal in
                    _internal.setSuspended(.init(state: .error, errorInfo: ARTErrorInfo.create(withCode: 1234, message: "unknown error")))
                }
                partialDone()
            }
            channel.once(.suspended) { _ in
                // All queued presence messages will fail immediately
                XCTAssertEqual(channel.presence.internal.pendingPresence.count, 0)
                partialDone()
            }
            channel.presence.enterClient("tester", data: nil) { error in
                guard let error = error else {
                    fail("Error is nil"); partialDone(); return
                }
                XCTAssertEqual(error.code, 1234)
                expect(error.message).to(contain("unknown error"))
                partialDone()
            }
        }
    }

    func test__023__Presence__Channel_state_change_side_effects__channel_enters_the_SUSPENDED_state__members_map_is_preserved_and_only_members_that_changed_between_ATTACHED_states_should_result_in_presence_events() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let channelName = test.uniqueChannelName()

        let clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 2, options: options)
        defer { clientMembers.dispose(); clientMembers.close() }
        
        options.clientId = "leaves"
        let leavesClient = AblyTests.newRealtime(options).client
        defer { leavesClient.dispose(); leavesClient.close() }
        
        options.clientId = "main"
        options.disconnectedRetryTimeout = 0.5
        options.suspendedRetryTimeout = 1.0
        let mainClient = AblyTests.newRealtime(options).client
        defer {
            mainClient.simulateRestoreInternetConnection()
            mainClient.dispose()
            mainClient.close()
        }
        
        // Move to SUSPENDED
        let ttlHookToken = mainClient.overrideConnectionStateTTL(1.0)
        defer { ttlHookToken.remove() }

        let leavesChannel = leavesClient.channels.get(channelName)
        let mainChannel = mainClient.channels.get(channelName)
        
        var oldConnectionId = ""
        
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            mainChannel.presence.subscribe { message in
                if message.clientId == "main" {
                    XCTAssertTrue(message.action == ARTPresenceAction.enter || message.action == ARTPresenceAction.present)
                    partialDone()
                }
                else if message.clientId == "leaves" {
                    XCTAssertTrue(message.action == ARTPresenceAction.enter || message.action == ARTPresenceAction.present)
                    partialDone()
                }
            }
            mainChannel.presence.enter(nil) { error in
                XCTAssertNil(error)
                oldConnectionId = mainChannel.internal.connectionId
                partialDone()
            }
            leavesChannel.presence.enter(nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }
        
        mainChannel.presence.unsubscribe()
        
        waitUntil(timeout: testTimeout) { done in
            mainChannel.presence.get { members, error in
                XCTAssertNil(error)
                if let members {
                    XCTAssertEqual(members.count, 4) // "main", "user1", "user2", "leaves"
                } else {
                    XCTFail("Expected members to be non-nil")
                }
                done()
            }
        }

        var presenceEvents = [ARTPresenceMessage]()

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            mainChannel.presence.subscribe { presence in
                guard presence.clientId != mainClient.clientId, presence.action != .enter else { return } // ignore ENTER from "main" after re-attach, since it's not "between ATTACHED states"
                presenceEvents += [presence]
                delay(1) {
                    partialDone() // Wait a bit to make sure we don't receive any other presence messages
                }
            }
            mainChannel.once(.suspended) { _ in
                mainChannel.internalSync { _internal in
                    XCTAssertEqual(_internal.presenceMap.members.count, 4) // "main", "user1", "user2", "leaves"
                    XCTAssertEqual(_internal.presenceMap.localMembers.count, 1) // "main"
                }
                leavesChannel.presence.leave(nil) { error in
                    XCTAssertNil(error)
                    mainClient.simulateRestoreInternetConnection()
                    partialDone()
                }
                partialDone()
            }
            mainChannel.once(.attached) { stateChange in
                XCTAssertNil(stateChange.reason)
                partialDone()
            }
            mainClient.simulateNoInternetConnection()
        }
        XCTAssertEqual(presenceEvents.count, 1)
        XCTAssertEqual(presenceEvents[0].action, ARTPresenceAction.leave)
        XCTAssertEqual(presenceEvents[0].clientId, "leaves")
        
        mainChannel.presence.unsubscribe()
        
        guard let transport = mainClient.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }
        
        // Same can be achieved with sleep for more than 15 seconds for the Realtime to send synthesised presence LEAVE
        // for the mainClient’s original connection after not receiving a heartbeat.
        transport.receive(AblyTests.newPresenceProtocolMessage(id: "\(mainChannel.internal.connectionId):0:0", channel: mainChannel.name, action: .leave, clientId: mainClient.clientId!, connectionId: oldConnectionId))
        
        waitUntil(timeout: testTimeout) { done in
            mainChannel.presence.get { members, error in
                XCTAssertNil(error)
                guard let members = members else {
                    fail("Members is nil"); done(); return
                }
                XCTAssertEqual(members.count, 3) // "main", "user1", "user2"
                expect(members).to(allPass { (member: ARTPresenceMessage?) in member!.action != .absent })
                done()
            }
        }

        mainChannel.internalSync { _internal in
            XCTAssertEqual(_internal.presenceMap.members.count, 3) // "main", "user1", "user2"
            XCTAssertEqual(_internal.presenceMap.localMembers.count, 1) // "main"
        }
    }

    // RTP8

    // RTP8a
    func skipped__test__024__Presence__enter__should_enter_the_current_client__optionally_with_the_data_provided() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"

        let client1 = ARTRealtime(options: options)
        defer { client1.close() }
        
        let channelName = test.uniqueChannelName()
        let channel1 = client1.channels.get(channelName)

        let client2 = ARTRealtime(options: options)
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel1.attach { err in
                XCTAssertNil(err)
                channel1.presence.subscribe(.enter) { member in
                    XCTAssertEqual(member.clientId, options.clientId)
                    XCTAssertEqual(member.data as? NSObject, "online" as NSObject?)
                    done()
                }
                channel2.presence.enter("online")
            }
        }
    }

    // RTP7

    // RTP7b
    func test__025__Presence__unsubscribe__with_a_single_action_argument_unsubscribes_the_provided_listener_to_all_presence_messages_for_that_action() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        let listener = channel.presence.subscribe(.present) { _ in }!
        XCTAssertEqual(channel.internal.presenceEventEmitter.listeners.count, 1)
        channel.presence.unsubscribe(.present, listener: listener)
        XCTAssertEqual(channel.internal.presenceEventEmitter.listeners.count, 0)
    }

    // RTP6

    // RTP6c
    func test__026__Presence__subscribe__should_implicitly_attach_the_channel() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        XCTAssertEqual(channel.state, ARTRealtimeChannelState.initialized)
        channel.presence.subscribe { _ in }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        channel.detach()
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)

        channel.presence.subscribe(.present) { _ in }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
    }

    // RTP6c
    func test__027__Presence__subscribe__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(test.uniqueChannelName())
        channel.internal.onError(AblyTests.newErrorProtocolMessage())
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(attachCallback: { errorInfo in
                XCTAssertNotNil(errorInfo)

                channel.presence.subscribe(.enter, onAttach: { errorInfo in
                    XCTAssertNotNil(errorInfo)
                    done()
                }) { _ in }
            }) { _ in }
        }
    }

    // RTP6c
    func test__028__Presence__subscribe__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            let error = AblyTests.newErrorProtocolMessage()
            channel.presence.subscribe(attachCallback: { errorInfo in
                XCTAssertNotNil(errorInfo)

                channel.presence.subscribe(.enter, onAttach: { errorInfo in
                    XCTAssertNotNil(errorInfo)
                    done()
                }) { _ in }
            }) { _ in }
            AblyTests.queue.async {
                channel.internal.onError(error)
            }
        }
    }

    // RTP6

    // RTP6b
    func test__029__Presence__subscribe__with_a_single_action_argument() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        let client1 = ARTRealtime(options: options)
        defer { client1.close() }
        
        let channelName = test.uniqueChannelName()
        let channel1 = client1.channels.get(channelName)

        let client2 = ARTRealtime(options: options)
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        var count = 0
        channel1.presence.subscribe(.update) { member in
            XCTAssertEqual(member.action, ARTPresenceAction.update)
            XCTAssertEqual(member.clientId, "john")
            XCTAssertEqual(member.data as? NSObject, "away" as NSObject?)
            count += 1
        }

        waitUntil(timeout: testTimeout) { done in
            channel2.presence.enterClient("john", data: "online") { error in
                XCTAssertNil(error)
                channel2.presence.updateClient("john", data: "away") { error in
                    XCTAssertNil(error)
                    channel2.presence.leaveClient("john", data: nil) { error in
                        XCTAssertNil(error)
                        done()
                    }
                }
            }
        }

        expect(count).toEventually(equal(1), timeout: testTimeout)
    }

    // RTP8

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP8b
    func skipped__test__030__Presence__enter__optionally_a_callback_can_be_provided_that_is_called_for_success() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"

        let client1 = ARTRealtime(options: options)
        defer { client1.close() }
        
        let channelName = test.uniqueChannelName()
        let channel1 = client1.channels.get(channelName)

        let client2 = ARTRealtime(options: options)
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel1.presence.subscribe(.enter) { member in
                XCTAssertEqual(member.clientId, options.clientId)
                XCTAssertEqual(member.data as? NSObject, "online" as NSObject?)
                done()
            }
            channel2.presence.enter("online") { error in
                XCTAssertNil(error)
            }
        }
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP8b
    func skipped__test__031__Presence__enter__optionally_a_callback_can_be_provided_that_is_called_for_failure() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"

        let client1 = ARTRealtime(options: options)
        defer { client1.close() }
        
        let channelName = test.uniqueChannelName()
        let channel1 = client1.channels.get(channelName)

        let client2 = ARTRealtime(options: options)
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel1.presence.subscribe(.enter) { _ in
                fail("shouldn't be called")
            }
            let protocolError = AblyTests.newErrorProtocolMessage()
            channel2.presence.enter("online") { error in
                XCTAssertTrue(error === protocolError.error)
                done()
            }
            delay(0.1) {
                channel2.internal.onError(protocolError)
            }
        }
    }

    // RTP8c
    func test__032__Presence__enter__entering_without_an_explicit_PresenceMessage_clientId_should_implicitly_use_the_clientId_of_the_current_connection() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        // We want to make sure that the ENTER presence action that we publish
        // gets sent by Realtime as a PRESENCE protocol message, and not in the
        // channel’s initial post-attach SYNC. So, we wait for any initial SYNC
        // to complete before publishing any presence actions.
        attachAndWaitForInitialPresenceSyncToComplete(client: client, channel: channel)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.subscribe(.enter) { message in
                XCTAssertEqual(message.clientId, "john")
                channel.presence.unsubscribe()
                partialDone()
            }
            channel.presence.enter("online") { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        let transport = client.internal.transport as! TestProxyTransport
        let sent = transport.protocolMessagesSent.filter { $0.action == .presence }[0].presence![0]
        XCTAssertEqual(sent.action, ARTPresenceAction.enter)
        XCTAssertNil(sent.clientId)

        let received = transport.protocolMessagesReceived.filter { $0.action == .presence }[0].presence![0]
        XCTAssertEqual(received.action, ARTPresenceAction.enter)
        XCTAssertEqual(received.clientId, "john")
    }

    // RTP8

    // RTP8j (former RTP8f)
    func test__033__Presence__enter__should_result_in_an_error_immediately_if_the_connection_state_is_connected_and_the_client_is_anonymous() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        
        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected))
        
        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter(nil) { error in
                XCTAssertEqual(error?.code, Int(ARTState.noClientId.rawValue))
                done()
            }
        }
    }
    
    // RTP8j
    func test__033__Presence__enter__should_result_in_an_error_immediately_if_the_connection_state_is_connected_and_the_client_is_wildcard() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        options.clientId = "*"
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        
        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected))
        
        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter(nil) { error in
                XCTAssertEqual(error?.code, Int(ARTState.noClientId.rawValue))
                done()
            }
        }
    }

    // RTP8g
    func test__034__Presence__enter__should_result_in_an_error_immediately_if_the_channel_is_DETACHED() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.attach { _ in
                channel.detach { _ in done() }
            }
        }

        XCTAssertEqual(channel.state, ARTRealtimeChannelState.detached)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter(nil) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                done()
            }
        }
    }

    // RTP8g
    func test__035__Presence__enter__should_result_in_an_error_immediately_if_the_channel_is_FAILED() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            AblyTests.queue.async {
                channel.internal.onError(AblyTests.newErrorProtocolMessage())
                done()
            }
        }

        XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter(nil) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                done()
            }
        }
    }

    // RTP8i
    func test__036__Presence__enter__should_result_in_an_error_if_Ably_service_determines_that_the_client_is_unidentified() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter(nil) { error in
                XCTAssertEqual(error?.code, Int(ARTErrorCode.invalidClientId.rawValue))
                done()
            }
        }
    }

    // RTP9

    // RTP9a
    func test__037__Presence__update__should_update_the_data_for_the_present_member_with_a_value() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(test.uniqueChannelName())
        // We want to make sure that the ENTER presence action that we publish
        // gets sent by Realtime as a PRESENCE protocol message, and not in the
        // channel’s initial post-attach SYNC. So, we wait for any initial SYNC
        // to complete before publishing any presence actions.
        attachAndWaitForInitialPresenceSyncToComplete(client: client, channel: channel)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.enter) { member in
                XCTAssertNil(member.data)
                done()
            }
            channel.presence.enter(nil)
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.update) { member in
                XCTAssertEqual(member.data as? NSObject, "online" as NSObject?)
                done()
            }
            channel.presence.update("online")
        }
    }

    // RTP9a
    func skipped__test__038__Presence__update__should_update_the_data_for_the_present_member_with_null() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.enter) { member in
                XCTAssertEqual(member.data as? NSObject, "online" as NSObject?)
                done()
            }
            channel.presence.enter("online")
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.update) { member in
                XCTAssertNil(member.data)
                done()
            }
            channel.presence.update(nil)
        }
    }

    // RTP9

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP9b
    func skipped__test__039__Presence__update__should_enter_current_client_into_the_channel_if_the_client_was_not_already_entered() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        XCTAssertEqual(channel.internal.presenceMap.members.count, 0)
        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.enter) { member in
                XCTAssertEqual(member.clientId, "john")
                XCTAssertEqual(member.data as? NSObject, "online" as NSObject?)
                done()
            }
            channel.presence.update("online")
        }
    }

    // RTP9

    // RTP9c
    func test__040__Presence__update__optionally_a_callback_can_be_provided_that_is_called_for_success() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.update("online") { error in
                XCTAssertNil(error)
                done()
            }
        }
    }

    // RTP9c
    func test__041__Presence__update__optionally_a_callback_can_be_provided_that_is_called_for_failure() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            let protocolError = AblyTests.newErrorProtocolMessage()
            channel.once(.attaching) { _ in
                AblyTests.queue.async {
                    channel.internal.onError(protocolError)
                }
            }
            (client.internal.transport as! TestProxyTransport).actionsIgnored += [.attached]
            channel.presence.update("online") { error in
                XCTAssertTrue(error === protocolError.error)
                done()
            }
        }
    }

    // RTP9d
    func test__042__Presence__update__update_without_an_explicit_PresenceMessage_clientId_should_implicitly_use_the_clientId_of_the_current_connection() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("online") { error in
                channel.presence.update("offline") { error in
                    XCTAssertNil(error)
                    done()
                }
            }
        }

        let transport = client.internal.transport as! TestProxyTransport
        let sent = transport.protocolMessagesSent.filter { $0.action == .presence }[1].presence![0]
        XCTAssertEqual(sent.action, ARTPresenceAction.update)
        XCTAssertNil(sent.clientId)

        let receivedPresenceProtocolMessages = transport.protocolMessagesReceived.filter { $0.action == .presence }
        let receivedPresenceMessages = receivedPresenceProtocolMessages.flatMap { $0.presence! }
        let received = receivedPresenceMessages.filter { $0.action == .update }[0]
        XCTAssertEqual(received.action, ARTPresenceAction.update)
        XCTAssertEqual(received.clientId, "john")
    }

    // RTP10

    // RTP10a
    func skipped__test__043__Presence__leave__should_leave_the_current_client_from_the_channel_and_the_data_will_be_updated_with_the_value_provided() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.enter) { member in
                XCTAssertEqual(member.data as? NSObject, "online" as NSObject?)
                done()
            }
            channel.presence.enter("online")
        }

        expect(channel.internal.presenceMap.members).toEventually(haveCount(1), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.leave) { member in
                XCTAssertEqual(member.data as? NSObject, "offline" as NSObject?)
                done()
            }
            channel.presence.leave("offline")
        }

        expect(channel.internal.presenceMap.members).toEventually(haveCount(0), timeout: testTimeout)
    }

    // RTP10a
    func skipped__test__044__Presence__leave__should_leave_the_current_client_with_no_data() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.enter) { member in
                XCTAssertEqual(member.data as? NSObject, "online" as NSObject?)
                done()
            }
            channel.presence.enter("online")
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.leave) { member in
                XCTAssertEqual(member.data as? NSObject, "online" as NSObject?)
                done()
            }
            channel.presence.leave(nil)
        }
    }

    // RTP2
    func skipped__test__003__Presence__should_be_used_a_PresenceMap_to_maintain_a_list_of_members() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        var clientSecondary: ARTRealtime!
        defer { clientSecondary.dispose(); clientSecondary.close() }
        
        let channelName = test.uniqueChannelName()
        clientSecondary = AblyTests.addMembersSequentiallyToChannel(channelName, members: 100, options: options)

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                done()
            }
        }

        channel.presence.unsubscribe()
        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                guard let members = members else {
                    fail("Members is nil"); done(); return
                }
                XCTAssertEqual(members.count, 100)
                done()
            }
        }
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP2

    // RTP2a
    func skipped__test__045__Presence__PresenceMap__all_incoming_presence_messages_must_be_compared_for_newness_with_the_matching_member_already_in_the_PresenceMap() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.subscribe { presence in
                XCTAssertEqual(presence.clientId, "tester")
                XCTAssertEqual(presence.action, .enter)
                channel.presence.unsubscribe()
                partialDone()
            }
            channel.presence.enterClient("tester", data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        guard let intialPresenceMessage = channel.internal.presenceMap.members["\(channel.internal.connectionId):tester"] else {
            fail("Missing Presence message"); return
        }

        XCTAssertEqual(intialPresenceMessage.memberKey(), "\(client.connection.id!):tester")

        var compareForNewnessMethodCalls = 0
        let hook = ARTPresenceMessage.testSuite_injectIntoClassMethod(#selector(ARTPresenceMessage.isNewerThan(_:))) {
            compareForNewnessMethodCalls += 1
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enterClient("tester", data: nil) { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let updatedPresenceMessage = channel.internal.presenceMap.members["\(channel.internal.connectionId):tester"] else {
            fail("Missing Presence message"); return
        }

        XCTAssertEqual(intialPresenceMessage.memberKey(), updatedPresenceMessage.memberKey())
        expect(intialPresenceMessage.timestamp).to(beLessThan(updatedPresenceMessage.timestamp))

        XCTAssertEqual(compareForNewnessMethodCalls, 1)

        hook?.remove()
    }

    // RTP2b

    // RTP2b1
    func test__053__Presence__PresenceMap__compare_for_newness__presence_message_has_a_connectionId_which_is_not_an_initial_substring_of_its_id__compares_them_by_timestamp_numerically() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let now = NSDate()
        let channelName = test.uniqueChannelName()
        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 101, options: options)

        let clientSubscribed = AblyTests.newRealtime(options).client
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
            transport.setAfterIncomingMessageModifier { protocolMessage in
                // Receive the first Sync message from Ably service
                if protocolMessage.action == .sync {
                    // Inject a fabricated Presence message
                    let presenceMessage = ARTProtocolMessage()
                    presenceMessage.action = .presence
                    presenceMessage.channel = protocolMessage.channel
                    presenceMessage.timestamp = Date()
                    presenceMessage.presence = presenceData

                    transport.receive(presenceMessage)

                    // Simulate an end to the sync
                    let endSyncMessage = ARTProtocolMessage()
                    endSyncMessage.action = .sync
                    endSyncMessage.channel = protocolMessage.channel
                    endSyncMessage.channelSerial = "validserialprefix:" // with no part after the `:` this indicates the end to the SYNC
                    endSyncMessage.timestamp = Date()

                    transport.setAfterIncomingMessageModifier(nil)
                    transport.receive(endSyncMessage)

                    // Stop the next sync message from Ably service because we already injected the end of the sync
                    transport.actionsIgnored = [.sync]

                    done()
                }
                return protocolMessage
            }
            channelSubscribed.attach()
        }

        waitUntil(timeout: testTimeout) { done in
            channelSubscribed.presence.get { members, error in
                XCTAssertNil(error)
                guard let members = members else {
                    fail("Members is nil"); done(); return
                }
                XCTAssertEqual(members.count, 102) // 100 initial members + "b" + "c", client "a" is discarded
                expect(members).to(allPass { (member: ARTPresenceMessage?) in member!.action != .absent })
                expect(members.filter { $0.clientId == "a" }).to(beEmpty())
                XCTAssertEqual(members.filter { $0.clientId == "b" }.count, 1)
                XCTAssertEqual(members.filter { $0.clientId! == "b" }.first?.timestamp, now as Date)
                XCTAssertEqual(members.filter { $0.clientId == "c" }.count, 1)
                XCTAssertEqual(members.filter { $0.clientId! == "c" }.first?.timestamp, now as Date)
                done()
            }
        }
    }

    // RTP2b2
    func test__052__Presence__PresenceMap__compare_for_newness__split_the_id_of_both_presence_messages() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let now = NSDate()
        let channelName = test.uniqueChannelName()
        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 101, options: options)

        let clientSubscribed = AblyTests.newRealtime(options).client
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
            transport.setAfterIncomingMessageModifier { protocolMessage in
                // Receive the first Sync message from Ably service
                if protocolMessage.action == .sync {
                    // Inject a fabricated Presence message
                    let presenceMessage = ARTProtocolMessage()
                    presenceMessage.action = .presence
                    presenceMessage.channel = protocolMessage.channel
                    presenceMessage.timestamp = Date()
                    presenceMessage.presence = presenceData

                    transport.receive(presenceMessage)

                    // Simulate an end to the sync
                    let endSyncMessage = ARTProtocolMessage()
                    endSyncMessage.action = .sync
                    endSyncMessage.channel = protocolMessage.channel
                    endSyncMessage.channelSerial = "validserialprefix:" // with no part after the `:` this indicates the end to the SYNC
                    endSyncMessage.timestamp = Date()

                    transport.setAfterIncomingMessageModifier(nil)
                    transport.receive(endSyncMessage)

                    // Stop the next sync message from Ably service because we already injected the end of the sync
                    transport.actionsIgnored = [.sync]

                    done()
                }
                return protocolMessage
            }
            channelSubscribed.attach()
        }

        waitUntil(timeout: testTimeout) { done in
            channelSubscribed.presence.get { members, error in
                XCTAssertNil(error)
                guard let members = members else {
                    fail("Members is nil"); done(); return
                }
                XCTAssertEqual(members.count, 102) // 100 initial members + "b" + "c", client "a" is discarded
                expect(members).to(allPass { (member: ARTPresenceMessage?) in member!.action != .absent })
                expect(members.filter { $0.clientId == "a" }).to(beEmpty())
                XCTAssertEqual(members.filter { $0.clientId == "b" }.count, 1)
                XCTAssertEqual(members.filter { $0.clientId! == "b" }.first?.timestamp, now as Date)
                XCTAssertEqual(members.filter { $0.clientId == "c" }.count, 1)
                XCTAssertEqual(members.filter { $0.clientId! == "c" }.first?.timestamp, now as Date)
                done()
            }
        }
    }

    // RTP2c

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    func skipped__test__054__Presence__PresenceMap__all_presence_messages_from_a_SYNC_must_also_be_compared_for_newness_in_the_same_way_as_they_would_from_a_PRESENCE__discard_members_where_messages_have_arrived_before_the_SYNC() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let timeBeforeSync = NSDate()
        let channelName = test.uniqueChannelName()
        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 120, options: options)

        guard let membersConnectionId = clientMembers?.connection.id else {
            fail("Members client isn't connected"); return
        }

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        channel.presence.subscribe(.leave) { leave in
            XCTAssertEqual(leave.clientId, "user110")
            fail("Should not fire Leave event for member `user110` because it's out of date")
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)
            transport.setBeforeIncomingMessageModifier { protocolMessage in
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
            }
            channel.internal.presenceMap.testSuite_injectIntoMethod(after: #selector(ARTPresenceMap.endSync)) {
                XCTAssertFalse(channel.internal.presenceMap.syncInProgress)
                XCTAssertEqual(channel.internal.presenceMap.members.count, 120)
                XCTAssertEqual(channel.internal.presenceMap.members.filter { _, presence in presence.clientId == "user110" && presence.action == .present }.count, 1)
                partialDone()
            }
            channel.attach { error in
                XCTAssertNil(error)
                partialDone()
            }
        }
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    func skipped__test__055__Presence__PresenceMap__all_presence_messages_from_a_SYNC_must_also_be_compared_for_newness_in_the_same_way_as_they_would_from_a_PRESENCE__accept_members_where_message_have_arrived_after_the_SYNC() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let channelName = test.uniqueChannelName()
        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 120, options: options)

        guard let membersConnectionId = clientMembers?.connection.id else {
            fail("Members client isn't connected"); return
        }

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        waitUntil(timeout: testTimeout.multiplied(by: 2)) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            channel.presence.subscribe(.leave) { leave in
                XCTAssertEqual(leave.clientId, "user110")
                partialDone()
            }
            transport.setBeforeIncomingMessageModifier { protocolMessage in
                if protocolMessage.action == .sync {
                    let injectLeave = ARTPresenceMessage()
                    injectLeave.action = .leave
                    injectLeave.connectionId = membersConnectionId
                    injectLeave.clientId = "user110"
                    injectLeave.timestamp = Date() + 1
                    protocolMessage.presence?.append(injectLeave)
                    transport.setBeforeIncomingMessageModifier(nil)
                    partialDone()
                }
                return protocolMessage
            }
            channel.internal.presenceMap.testSuite_injectIntoMethod(after: #selector(ARTPresenceMap.endSync)) {
                XCTAssertFalse(channel.internal.presenceMap.syncInProgress)
                XCTAssertEqual(channel.internal.presenceMap.members.count, 119)
                expect(channel.internal.presenceMap.members.filter { _, presence in presence.clientId == "user110" }).to(beEmpty())
                partialDone()
            }
            channel.attach { error in
                XCTAssertNil(error)
                partialDone()
            }
        }
    }

    // RTP2d
    func skipped__test__046__Presence__PresenceMap__if_action_of_ENTER_arrives__it_should_be_added_to_the_presence_map_with_the_action_set_to_PRESENT() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.subscribe(.enter) { _ in
                partialDone()
            }
            channel.presence.enterClient("tester", data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        XCTAssertEqual(channel.internal.presenceMap.members.filter { _, presence in presence.action == .present }.count, 1)
        expect(channel.internal.presenceMap.members.filter { _, presence in presence.action == .enter }).to(beEmpty())
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP2d
    func skipped__test__047__Presence__PresenceMap__if_action_of_UPDATE_arrives__it_should_be_added_to_the_presence_map_with_the_action_set_to_PRESENT() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)
            channel.presence.subscribe(.update) { _ in
                partialDone()
            }
            channel.presence.enterClient("tester", data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
            channel.presence.updateClient("tester", data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        XCTAssertEqual(channel.internal.presenceMap.members.count, 1)
        XCTAssertEqual(channel.internal.presenceMap.members.filter { _, presence in presence.action == .present }.count, 1)
        expect(channel.internal.presenceMap.members.filter { _, presence in presence.action == .update }).to(beEmpty())
    }

    // RTP2d
    func test__048__Presence__PresenceMap__if_action_of_PRESENT_arrives__it_should_be_added_to_the_presence_map_with_the_action_set_to_PRESENT() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let channelName = test.uniqueChannelName()
        var clientMembers: ARTRealtime!
        defer { clientMembers.dispose(); clientMembers.close() }
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 1, options: options)

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.internal.presenceMap.testSuite_injectIntoMethod(after: #selector(ARTPresenceMap.endSync)) {
                XCTAssertFalse(channel.internal.presenceMap.syncInProgress)
                partialDone()
            }
            channel.attach { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        XCTAssertEqual(channel.internal.presenceMap.members.count, 1)
    }

    // RTP2e
    func skipped__test__049__Presence__PresenceMap__if_a_SYNC_is_not_in_progress__then_when_a_presence_message_with_an_action_of_LEAVE_arrives__that_memberKey_should_be_deleted_from_the_presence_map__if_present() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        let channelName = test.uniqueChannelName()
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 20, options: options)

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)
        channel.attach()

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }
        waitUntil(timeout: testTimeout) { done in
            transport.setListenerAfterProcessingIncomingMessage { protocolMessage in
                if protocolMessage.action == .sync {
                    done()
                }
            }
        }

        expect(channel.internal.presenceMap.syncInProgress).toEventually(beFalse(), timeout: testTimeout)

        guard let user11MemberKey = channel.internal.presenceMap.members["\(clientMembers?.connection.id ?? ""):user11"]?.memberKey() else {
            fail("user11 memberKey is not present"); return
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(.leave) { presence in
                XCTAssertEqual(presence.clientId, "user11")
                done()
            }
            clientMembers?.channels.get(channelName).presence.leaveClient("user11", data: nil)
        }
        channel.presence.unsubscribe()

        channel.internalSync { _internal in
            expect(_internal.presenceMap.members.filter { _, presence in presence.memberKey() == user11MemberKey }).to(beEmpty())
        }
    }

    // RTP2f
    func skipped__test__050__Presence__PresenceMap__if_a_SYNC_is_in_progress__then_when_a_presence_message_with_an_action_of_LEAVE_arrives__it_should_be_stored_in_the_presence_map_with_the_action_set_to_ABSENT() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let channelName = test.uniqueChannelName()

        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 20, options: options)

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        var hook: AspectToken?
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)

            channel.presence.subscribe(.leave) { leave in
                XCTAssertEqual(leave.clientId, "user11")
                partialDone()
            }

            hook = channel.internal.presenceMap.testSuite_getArgument(
                from: #selector(ARTPresenceMap.internalAdd(_:withSessionId:)),
                at: 0
            ) { arg in
                let m = arg as? ARTPresenceMessage
                if m?.clientId == "user11", m?.action == .absent {
                    partialDone()
                }
            }

            channel.attach { error in
                XCTAssertNil(error)
                XCTAssertTrue(channel.internal.presenceMap.syncInProgress)

                // Inject a fabricated Presence message
                let leaveMessage = ARTProtocolMessage()
                leaveMessage.action = .presence
                leaveMessage.channel = channel.name
                leaveMessage.timestamp = Date()
                leaveMessage.presence = [
                    ARTPresenceMessage(clientId: "user11", action: .leave, connectionId: "another", id: "another:123:0", timestamp: Date()),
                ]
                transport.receive(leaveMessage)
            }
        }
        hook?.remove()
        channel.presence.unsubscribe()

        expect(channel.internal.presenceMap.syncInProgress).toEventually(beFalse(), timeout: testTimeout)
        expect(channel.internal.presenceMap.members.filter { _, presence in presence.action == .leave }).to(beEmpty())
        expect(channel.internal.presenceMap.members.filter { _, presence in presence.action == .absent }).to(beEmpty())

        // A single clientId may be present multiple times on the same channel via different client connections and that's way user11 is present because user11 presences messages were in distinct connections.
        XCTAssertEqual(channel.internal.presenceMap.members.count, 20)
    }

    // RTP2g
    func skipped__test__051__Presence__PresenceMap__any_incoming_presence_message_that_passes_the_newness_check_should_be_emitted_on_the_Presence_object__with_an_event_name_set_to_its_original_action() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.enterClient("tester", data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
            channel.presence.subscribe(.enter) { _ in
                partialDone()
            }
        }

        channel.internalSync { _internal in
            XCTAssertEqual(_internal.presenceMap.members.filter { _, presence in presence.action == .present }.count, 1)
            expect(_internal.presenceMap.members.filter { _, presence in presence.action == .enter }).to(beEmpty())
        }
    }

    // RTP8

    // RTP8h
    func test__056__Presence__enter__should_result_in_an_error_if_the_client_does_not_have_required_presence_permission() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.token = try getTestToken(for: test, clientId: "john", capability: "{ \"cannotpresence:john\":[\"publish\"] }")
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

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
    func test__057__Presence__update__should_result_in_an_error_immediately_if_the_client_is_anonymous() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.update(nil) { error in
                XCTAssertEqual(error?.code, Int(ARTErrorCode.invalidClientId.rawValue))
                done()
            }
        }
    }

    // RTP9e
    func test__058__Presence__update__should_result_in_an_error_immediately_if_the_channel_is_DETACHED() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        channel.attach()
        channel.detach()
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.update(nil) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                done()
            }
        }
    }

    // RTP9e
    func test__059__Presence__update__should_result_in_an_error_immediately_if_the_channel_is_FAILED() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        AblyTests.queue.async {
            channel.internal.onError(AblyTests.newErrorProtocolMessage())
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.update(nil) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                done()
            }
        }
    }

    // RTP9e
    func test__060__Presence__update__should_result_in_an_error_if_the_client_does_not_have_required_presence_permission() throws {
        let test = Test()
        let options = try AblyTests.clientOptions(for: test)
        options.token = try getTestToken(for: test, clientId: "john", capability: "{ \"cannotpresence:john\":[\"publish\"] }")
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

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
    func test__061__Presence__update__should_result_in_an_error_if_Ably_service_determines_that_the_client_is_unidentified() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.update(nil) { error in
                XCTAssertEqual(error?.code, Int(ARTErrorCode.invalidClientId.rawValue))
                done()
            }
        }
    }

    // RTP10

    // RTP10b
    func test__062__Presence__leave__optionally_a_callback_can_be_provided_that_is_called_for_success() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("online") { error in
                XCTAssertNil(error)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.leave("offline") { error in
                XCTAssertNil(error)
                done()
            }
        }
    }

    // RTP10b
    func test__063__Presence__leave__optionally_a_callback_can_be_provided_that_is_called_for_failure() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("online") { error in
                XCTAssertNil(error)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let sentError = ARTErrorInfo.create(withCode: 0, message: "test error")
            let transport = client.internal.transport as! TestProxyTransport
            transport.enableReplaceAcksWithNacks(with: sentError)
            channel.presence.leave("offline") { error in
                XCTAssertTrue(error === sentError)
                transport.disableReplaceAcksWithNacks()
                done()
            }
        }
    }

    func test__064__Presence__leave__should_raise_an_error_if_client_is_not_present() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.presence.leave("offline") { error in
                XCTAssertEqual(error?.code, Int(ARTErrorCode.invalidClientId.rawValue))
                done()
            }
        }
    }

    // RTP10c
    func test__065__Presence__leave__entering_without_an_explicit_PresenceMessage_clientId_should_implicitly_use_the_clientId_of_the_current_connection() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("online") { error in
                channel.presence.leave(nil) { error in
                    XCTAssertNil(error)
                    done()
                }
            }
        }

        let transport = client.internal.transport as! TestProxyTransport

        let sent = transport.protocolMessagesSent.filter { $0.action == .presence }[1].presence![0]
        XCTAssertEqual(sent.action, ARTPresenceAction.leave)
        XCTAssertNil(sent.clientId)

        let receivedPresenceProtocolMessages = transport.protocolMessagesReceived.filter { $0.action == .presence }
        let receivedPresenceMessages = receivedPresenceProtocolMessages.flatMap { $0.presence! }
        let received = receivedPresenceMessages.filter { $0.action == .leave }[0]
        XCTAssertEqual(received.action, ARTPresenceAction.leave)
        XCTAssertEqual(received.clientId, "john")
    }

    // RTP10d
    func test__066__Presence__leave__if_the_client_is_not_currently_ENTERED__Ably_will_respond_with_an_ACK_and_the_request_will_succeed() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.leave(nil) { error in
                XCTAssertNil(error)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("online") { error in
                XCTAssertNil(error)
                channel.presence.leave(nil) { error in
                    XCTAssertNil(error)
                    channel.presence.leave(nil) { error in
                        XCTAssertNil(error)
                        done()
                    }
                }
            }
        }
    }

    // RTP8

    // RTP8d
    func test__067__Presence__enter__implicitly_attaches_the_Channel() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        XCTAssertEqual(channel.state, ARTRealtimeChannelState.initialized)
        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("online") { error in
                XCTAssertNil(error)
                done()
            }
            XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
        }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.attached)
    }

    // RTP8d
    func test__068__Presence__enter__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        AblyTests.queue.async {
            channel.internal.onError(AblyTests.newErrorProtocolMessage())
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("online") { error in
                XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                done()
            }
        }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)
    }

    // RTP8d
    func test__069__Presence__enter__should_result_in_an_error_if_the_channel_is_in_the_DETACHED_state() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.attach { error in
                XCTAssertNil(error)
                partialDone()
            }
            channel.detach { error in
                XCTAssertNil(error)
                partialDone()
            }
        }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.detached)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("online") { error in
                XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                done()
            }
        }
    }

    // RTP10

    // RTP10e
    func test__070__Presence__leave__should_result_in_an_error_immediately_if_the_client_is_anonymous() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.leave(nil) { error in
                XCTAssertEqual(error?.code, Int(ARTErrorCode.invalidClientId.rawValue))
                done()
            }
        }
    }

    // RTP10e
    func test__071__Presence__leave__should_result_in_an_error_immediately_if_the_channel_is_DETACHED() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter(nil) { error in
                XCTAssertNil(error)
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
    func test__072__Presence__leave__should_result_in_an_error_immediately_if_the_channel_is_FAILED() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter(nil) { error in
                XCTAssertNil(error)
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
    func test__073__Presence__leave__should_result_in_an_error_if_the_client_does_not_have_required_presence_permission() throws {
        let test = Test()
        let options = try AblyTests.clientOptions(for: test)
        options.token = try getTestToken(for: test, clientId: "john", capability: "{ \"cannotpresence:other\":[\"publish\"] }")
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.leaveClient("other", data: nil) { error in
                expect(error!.message).to(contain("Channel denied access based on given capability"))
                done()
            }
        }
    }

    // RTP10e
    func test__074__Presence__leave__should_result_in_an_error_if_Ably_service_determines_that_the_client_is_unidentified() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.leave(nil) { error in
                XCTAssertEqual(error?.code, Int(ARTErrorCode.invalidClientId.rawValue))
                done()
            }
        }
    }

    // RTP6

    // RTP6c
    func test__075__Presence__subscribe__should_implicitly_attach_the_channel() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        XCTAssertEqual(channel.state, ARTRealtimeChannelState.initialized)
        channel.presence.subscribe { _ in }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        channel.detach()
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)

        channel.presence.subscribe(.present) { _ in }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
    }

    // RTP6c
    func test__076__Presence__subscribe__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        let protocolError = AblyTests.newErrorProtocolMessage()
        AblyTests.queue.async {
            channel.internal.onError(protocolError)
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.subscribe(attachCallback: { error in
                XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)
                XCTAssertNotNil(error)
                done()
            }, callback: { _ in
                fail("Should not be called")
            })
        }
    }

    // RTP6c
    func test__077__Presence__subscribe__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            let error = AblyTests.newErrorProtocolMessage()
            channel.presence.subscribe(attachCallback: { error in
                XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)
                XCTAssertNotNil(error)
                done()
            }, callback: { _ in
                fail("Should not be called")
            })
            AblyTests.queue.async {
                channel.internal.onError(error)
            }
        }
    }

    // RTP8

    // RTP8e
    func test__078__Presence__enter__optional_data_can_be_included_when_entering_a_channel() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        options.clientId = "john"
        let client1 = AblyTests.newRealtime(options).client
        defer { client1.close() }
        
        let channelName = test.uniqueChannelName()
        let channel1 = client1.channels.get(channelName)
        // We want to make sure that the ENTER presence action that we publish
        // gets sent by Realtime as a PRESENCE protocol message, and not in the
        // channel’s initial post-attach SYNC. So, we wait for any initial SYNC
        // to complete before publishing any presence actions.
        attachAndWaitForInitialPresenceSyncToComplete(client: client1, channel: channel1)

        options.clientId = "mary"
        let client2 = ARTRealtime(options: options)
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        let expectedData = ["data": 123]

        waitUntil(timeout: testTimeout) { done in
            let partlyDone = AblyTests.splitDone(2, done: done)
            channel1.presence.subscribe(.enter) { member in
                XCTAssertEqual(member.data as? NSObject, expectedData as NSObject?)
                partlyDone()
            }
            channel2.presence.enter(expectedData) { error in
                XCTAssertNil(error)
                partlyDone()
            }
        }
    }

    // RTP8e
    func test__079__Presence__enter__should_emit_the_data_attribute_in_the_LEAVE_event_when_data_is_provided_when_entering_but_no_data_is_provided_when_leaving() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        options.clientId = "john"
        let client1 = ARTRealtime(options: options)
        defer { client1.close() }
        
        let channelName = test.uniqueChannelName()
        let channel1 = client1.channels.get(channelName)

        options.clientId = "mary"
        let client2 = ARTRealtime(options: options)
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        let expectedData = "data"

        waitUntil(timeout: testTimeout) { done in
            channel2.presence.enter(expectedData) { error in
                XCTAssertNil(error)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel1.attach { err in
                XCTAssertNil(err)
                let partlyDone = AblyTests.splitDone(2, done: done)
                channel1.presence.subscribe(.leave) { member in
                    XCTAssertEqual(member.data as? NSObject, expectedData as NSObject?)
                    partlyDone()
                }
                channel2.presence.leave(nil) { error in
                    XCTAssertNil(error)
                    partlyDone()
                }
            }
        }
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP17

    func skipped__test__080__Presence__private_and_internal_PresenceMap_containing_only_members_that_match_the_current_connectionId__any_ENTER__PRESENT__UPDATE_or_LEAVE_event_that_matches_the_current_connectionId_should_be_applied_to_this_object() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let channelName = test.uniqueChannelName()

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
                XCTAssertEqual(presence.action, ARTPresenceAction.enter)
                XCTAssertEqual(presence.connectionId, currentConnectionId)
                XCTAssertEqual(channelA.internal.presenceMap.members.count, 1)
                XCTAssertEqual(channelA.internal.presenceMap.localMembers.count, 1)
                channelA.presence.unsubscribe()
                partialDone()
            }
            channelB.presence.subscribe { presence in
                guard let currentConnectionId = clientB.connection.id else {
                    fail("ClientB should be connected"); partialDone(); return
                }
                expect(presence.action).to(equal(ARTPresenceAction.enter) || equal(ARTPresenceAction.present))
                XCTAssertNotEqual(presence.connectionId, currentConnectionId)
                XCTAssertEqual(channelB.internal.presenceMap.members.count, 1)
                XCTAssertEqual(channelB.internal.presenceMap.localMembers.count, 0)
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
                XCTAssertEqual(presence.action, ARTPresenceAction.enter)
                XCTAssertNotEqual(presence.connectionId, currentConnectionId)
                XCTAssertEqual(channelA.internal.presenceMap.members.count, 2)
                XCTAssertEqual(channelA.internal.presenceMap.localMembers.count, 1)
                channelA.presence.unsubscribe()
                partialDone()
            }
            channelB.presence.subscribe { presence in
                guard let currentConnectionId = clientB.connection.id else {
                    fail("ClientB should be connected"); partialDone(); return
                }
                XCTAssertEqual(presence.action, ARTPresenceAction.enter)
                XCTAssertEqual(presence.connectionId, currentConnectionId)
                XCTAssertEqual(channelB.internal.presenceMap.members.count, 2)
                XCTAssertEqual(channelB.internal.presenceMap.localMembers.count, 1)
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
                XCTAssertEqual(presence.action, ARTPresenceAction.update)
                XCTAssertEqual(presence.data as? String, "hello")
                XCTAssertNotEqual(presence.connectionId, currentConnectionId)
                XCTAssertEqual(channelA.internal.presenceMap.members.count, 2)
                XCTAssertEqual(channelA.internal.presenceMap.localMembers.count, 1)
                channelA.presence.unsubscribe()
                partialDone()
            }
            channelB.presence.subscribe { presence in
                guard let currentConnectionId = clientB.connection.id else {
                    fail("ClientB should be connected"); partialDone(); return
                }
                XCTAssertEqual(presence.action, ARTPresenceAction.update)
                XCTAssertEqual(presence.data as? String, "hello")
                XCTAssertEqual(presence.connectionId, currentConnectionId)
                XCTAssertEqual(channelB.internal.presenceMap.members.count, 2)
                XCTAssertEqual(channelB.internal.presenceMap.localMembers.count, 1)
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
                XCTAssertEqual(presence.action, ARTPresenceAction.leave)
                XCTAssertEqual(presence.data as? String, "bye")
                XCTAssertNotEqual(presence.connectionId, currentConnectionId)
                XCTAssertEqual(channelA.internal.presenceMap.members.count, 1)
                XCTAssertEqual(channelA.internal.presenceMap.localMembers.count, 1)
                channelA.presence.unsubscribe()
                partialDone()
            }
            channelB.presence.subscribe { presence in
                guard let currentConnectionId = clientB.connection.id else {
                    fail("ClientB should be connected"); partialDone(); return
                }
                XCTAssertEqual(presence.action, ARTPresenceAction.leave)
                XCTAssertEqual(presence.data as? String, "bye")
                XCTAssertEqual(presence.connectionId, currentConnectionId)
                XCTAssertEqual(channelB.internal.presenceMap.members.count, 1)
                XCTAssertEqual(channelB.internal.presenceMap.localMembers.count, 0)
                channelB.presence.unsubscribe()
                partialDone()
            }
            channelB.presence.leave("bye")
        }
    }

    // RTP17a
    func skipped__test__081__Presence__private_and_internal_PresenceMap_containing_only_members_that_match_the_current_connectionId__all_members_belonging_to_the_current_connection_are_published_as_a_PresenceMessage_on_the_Channel_by_the_server_irrespective_of_whether_the_client_has_permission_to_subscribe_or_the_Channel_is_configured_to_publish_presence_events() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let channelName = test.uniqueChannelName()
        let clientId = NSUUID().uuidString
        options.tokenDetails = try getTestTokenDetails(for: test, clientId: clientId, capability: "{\"\(channelName)\":[\"presence\",\"publish\"]}")
        // Prevent channel name to be prefixed by test-*
        options.testOptions.channelNamePrefix = nil
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.enterClient(clientId, data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
            channel.presence.subscribe(.enter) { presence in
                XCTAssertEqual(presence.clientId, clientId)
                partialDone()
            }
        }
        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                if let members {
                    XCTAssertEqual(members.count, 1)
                } else {
                    XCTFail("Expected members to be non-nil")
                }
                XCTAssertEqual(channel.internal.presenceMap.members.count, 1)
                XCTAssertEqual(channel.internal.presenceMap.localMembers.count, 1)
                done()
            }
        }
    }

    // RTP17b

    func skipped__test__082__Presence__private_and_internal_PresenceMap_containing_only_members_that_match_the_current_connectionId__events_applied_to_presence_map__should_be_applied_to_ENTER__PRESENT_or_UPDATE_events_with_a_connectionId_that_matches_the_current_client_s_connectionId() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(test.uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.subscribe(.enter) { presence in
                XCTAssertEqual(presence.clientId, "one")
                channel.presence.unsubscribe()
                partialDone()
            }
            channel.presence.enterClient("one", data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        guard let connectionId = client.connection.id else {
            fail("connectionId is empty"); return
        }

        channel.internalSync { _internal in
            XCTAssertEqual(_internal.presenceMap.localMembers.count, 1)
        }

        let additionalMember = ARTPresenceMessage(
            clientId: "two",
            action: .enter,
            connectionId: connectionId,
            id: connectionId + ":0:0"
        )

        // Inject an additional member into the myMember set, then force a suspended state
        client.simulateSuspended(beforeSuspension: { done in
            channel.internal.presenceMap.localMembers[additionalMember.clientId!] = additionalMember
            done()
        })
        expect(client.connection.state).toEventually(equal(.suspended), timeout: testTimeout)

        XCTAssertEqual(channel.internal.presenceMap.localMembers.count, 2)

        channel.internalSync { _internal in
            XCTAssertEqual(_internal.presenceMap.localMembers.count, 2)
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)

            channel.once(.attached) { stateChange in
                XCTAssertNil(stateChange.reason)
                partialDone()
            }

            // Await Sync
            channel.internal.presenceMap.onceSyncEnds { _ in
                // Should remove the "two" member that was added manually because the connectionId
                // doesn't match and it's not synthesized, it will be re-entered.
                XCTAssertEqual(channel.internal.presenceMap.localMembers.count, 1)

                partialDone()
            }

            channel.presence.subscribe(.enter) { presence in
                XCTAssertEqual(presence.clientId, "two")
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

        XCTAssertFalse(channel.presence.syncComplete)
        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { presences, error in
                XCTAssertNil(error)
                guard let presences = presences else {
                    fail("Presences is nil"); done(); return
                }
                XCTAssertTrue(channel.presence.syncComplete)
                XCTAssertEqual(presences.count, 2)
                expect(presences.map { $0.clientId }).to(contain(["one", "two"]))
                done()
            }
        }
    }
    
    // RTP17i, RTP17g
    func test__200__Presence__PresenceMap_should_perform_re_entry_whenever_a_channel_moves_into_the_attached_state_and_presence_message_consists_of_enter_action_with_client_id_and_data() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = AblyTests.newRealtime(options).client
        let transport = client.internal.transport as! TestProxyTransport
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(test.uniqueChannelName())
        
        var firstMsgId = ""
        var secondMsgId = ""
        let firstClient = "client1"
        let secondClient = "client2"
        let firstClientData = "client1data"
        let secondClientData = "client2data"
        
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.once(.attached) { stateChange in
                channel.presence.enterClient(firstClient, data: firstClientData)
                channel.presence.enterClient(secondClient, data: secondClientData)
            }
            channel.presence.subscribe(.enter) { presenceMessage in
                if presenceMessage.clientId == firstClient {
                    firstMsgId = presenceMessage.id!
                    partialDone()
                }
                else if presenceMessage.clientId == secondClient {
                    secondMsgId = presenceMessage.id!
                    partialDone()
                }
            }
            channel.attach()
        }
        channel.presence.unsubscribe()
        
        expect(channel.internal.presenceMap.localMembers).to(haveCount(2))
        
        // All pending messages should complete (receive ACK or NACK) before disconnect for valid count of transport.protocolMessagesSent
        client.waitForPendingMessages()
        client.simulateLostConnection()
        
        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
        
        // RTP17i
        
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
        expect(channel.internal.presenceMap.localMembers).to(haveCount(2))
        
        let newTransport = client.internal.transport as! TestProxyTransport
        expect(newTransport).toNot(beIdenticalTo(transport))

        var sentPresenceMessages = newTransport.protocolMessagesSent.filter({ $0.action == .presence }).compactMap { $0.presence?.first }
        
        expect(sentPresenceMessages).to(haveCount(2))

        let client1PresenceMessage = try XCTUnwrap(sentPresenceMessages.first(where: { $0.clientId == firstClient }))
        let client2PresenceMessage = try XCTUnwrap(sentPresenceMessages.first(where: { $0.clientId == secondClient }))
        
        // RTP17i - already attached with resume flag set
        
        let attachedMessage = ARTProtocolMessage()
        attachedMessage.action = .attached
        attachedMessage.channel = channel.name
        attachedMessage.flags = 4 // resume flag

        newTransport.receive(attachedMessage)
        sentPresenceMessages = newTransport.protocolMessagesSent.filter({ $0.action == .presence }).compactMap { $0.presence?.first }
        expect(sentPresenceMessages).to(haveCount(2)) // no changes in sentPresenceMessages => no presense messages sent

        // RTP17g
        
        expect(client1PresenceMessage.id).to(equal(firstMsgId))
        expect(client2PresenceMessage.id).to(equal(secondMsgId))
        
        expect(client1PresenceMessage.action).to(equal(ARTPresenceAction.enter))
        expect(client2PresenceMessage.action).to(equal(ARTPresenceAction.enter))
        
        expect(client1PresenceMessage.data as? String).to(equal(firstClientData))
        expect(client2PresenceMessage.data as? String).to(equal(secondClientData))
    }
    
    func skipped__test__083__Presence__private_and_internal_PresenceMap_containing_only_members_that_match_the_current_connectionId__events_applied_to_presence_map__should_be_applied_to_any_LEAVE_event_with_a_connectionId_that_matches_the_current_client_s_connectionId_and_is_not_a_synthesized() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        client.internal.shouldImmediatelyReconnect = false
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(test.uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.subscribe(.enter) { presence in
                XCTAssertEqual(presence.clientId, "one")
                channel.presence.unsubscribe()
                partialDone()
            }
            channel.presence.enterClient("one", data: nil) { error in
                XCTAssertNil(error)
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
                XCTAssertEqual(presence.clientId, "one")
                channel.presence.unsubscribe()
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { presences, error in
                XCTAssertNil(error)
                guard let presences = presences else {
                    fail("Presences is nil"); done(); return
                }
                XCTAssertTrue(channel.internal.presenceMap.syncComplete)
                XCTAssertEqual(presences.count, 1)
                expect(presences.map { $0.clientId }).to(contain(["one"]))
                done()
            }
        }
    }

    // RTP15d
    func test__004__Presence__callback_can_be_provided_that_will_be_called_upon_success() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enterClient("Client 1", data: nil) { errorInfo in
                XCTAssertNil(errorInfo)
                done()
            }
        }
    }

    // RTP15d
    func test__005__Presence__callback_can_be_provided_that_will_be_called_upon_failure() throws {
        let test = Test()
        let options = try AblyTests.clientOptions(for: test)
        options.token = try getTestToken(for: test, capability: "{ \"room\":[\"subscribe\"] }")
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enterClient("Client 1", data: nil) { errorInfo in
                guard let errorInfo = errorInfo else {
                    fail("ErrorInfo is empty"); done()
                    return
                }
                XCTAssertEqual(errorInfo.code, ARTErrorCode.operationNotPermittedWithProvidedCapability.intValue)
                done()
            }
        }
    }

    // RTP15c
    func test__006__Presence__should_also_ensure_that_using_updateClient_has_no_side_effects_on_a_client_that_has_entered_normally_using_Presence_enter() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter(nil) { error in
                XCTAssertNil(error)
                channel.presence.updateClient("john", data: "mobile") { error in
                    XCTAssertNil(error)
                    done()
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, _ in
                XCTAssertEqual(members!.first!.data as? String, "mobile")
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
    func reusableTestsTestPresencePerformMethod(for test: Test, testCase: TestCase_ReusableTestsTestPresencePerformMethod, beforeEach contextBeforeEach: (() -> Void)? = nil, afterEach contextAfterEach: (() -> Void)? = nil, _ performMethod: @escaping (ARTRealtimePresence, ((ARTErrorInfo?) -> Void)?) -> Void) throws {
        func test__should_implicitly_attach_the_Channel() throws {
            contextBeforeEach?()

            let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
            defer { client.dispose(); client.close() }
            let channel = client.channels.get(test.uniqueChannelName())

            XCTAssertEqual(channel.state, ARTRealtimeChannelState.initialized)
            waitUntil(timeout: testTimeout) { done in
                // Call: enterClient, updateClient and leaveClient
                performMethod(channel.presence) { errorInfo in
                    XCTAssertNil(errorInfo)
                    done()
                }
                XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
            }
            XCTAssertEqual(channel.state, ARTRealtimeChannelState.attached)

            contextAfterEach?()
        }

        func test__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() throws {
            contextBeforeEach?()

            let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
            defer { client.dispose(); client.close() }
            let channel = client.channels.get(test.uniqueChannelName())

            let expectedErrorMessage = "Something has failed"
            AblyTests.queue.async {
                channel.internal.onError(AblyTests.newErrorProtocolMessage(message: expectedErrorMessage))
            }

            waitUntil(timeout: testTimeout) { done in
                // Call: enterClient, updateClient and leaveClient
                performMethod(channel.presence) { error in
                    XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                    XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)
                    guard let reason = channel.errorReason else {
                        fail("Reason is empty"); done(); return
                    }
                    XCTAssertEqual(reason.message, expectedErrorMessage)
                    done()
                }
            }

            contextAfterEach?()
        }

        func test__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() throws {
            contextBeforeEach?()

            let client = AblyTests.newRealtime(try AblyTests.commonAppSetup(for: test)).client
            defer { client.dispose(); client.close() }
            let channel = client.channels.get(test.uniqueChannelName())

            waitUntil(timeout: testTimeout) { done in
                let error = AblyTests.newErrorProtocolMessage()
                channel.once(.attaching) { _ in
                    AblyTests.queue.async {
                        channel.internal.onError(error)
                    }
                }
                (client.internal.transport as! TestProxyTransport).actionsIgnored += [.attached]
                // Call: enterClient, updateClient and leaveClient
                performMethod(channel.presence) { errorInfo in
                    XCTAssertEqual(errorInfo, error.error)
                    done()
                }
            }

            contextAfterEach?()
        }

        switch testCase {
        case .should_implicitly_attach_the_Channel:
            try test__should_implicitly_attach_the_Channel()
        case .should_result_in_an_error_if_the_channel_is_in_the_FAILED_state:
            try test__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state()
        case .should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state:
            try test__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state()
        }
    }

    func reusableTestsWrapper__Presence__enterClient__reusableTestsTestPresencePerformMethod(testCase: TestCase_ReusableTestsTestPresencePerformMethod) throws {
        let test = Test()
        try reusableTestsTestPresencePerformMethod(for: test, testCase: testCase) { $0.enterClient("john", data: nil, callback: $1) }
    }

    func test__084__Presence__enterClient__should_implicitly_attach_the_Channel() throws {
        try reusableTestsWrapper__Presence__enterClient__reusableTestsTestPresencePerformMethod(testCase: .should_implicitly_attach_the_Channel)
    }

    func test__085__Presence__enterClient__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() throws {
        try reusableTestsWrapper__Presence__enterClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_is_in_the_FAILED_state)
    }

    func test__086__Presence__enterClient__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() throws {
        try reusableTestsWrapper__Presence__enterClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state)
    }

    func reusableTestsWrapper__Presence__updateClient__reusableTestsTestPresencePerformMethod(testCase: TestCase_ReusableTestsTestPresencePerformMethod) throws {
        let test = Test()
        try reusableTestsTestPresencePerformMethod(for: test, testCase: testCase) { $0.updateClient("john", data: nil, callback: $1) }
    }

    func test__087__Presence__updateClient__should_implicitly_attach_the_Channel() throws {
        try reusableTestsWrapper__Presence__updateClient__reusableTestsTestPresencePerformMethod(testCase: .should_implicitly_attach_the_Channel)
    }

    func test__088__Presence__updateClient__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() throws {
        try reusableTestsWrapper__Presence__updateClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_is_in_the_FAILED_state)
    }

    func test__089__Presence__updateClient__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() throws {
        try reusableTestsWrapper__Presence__updateClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state)
    }

    func reusableTestsWrapper__Presence__leaveClient__reusableTestsTestPresencePerformMethod(testCase: TestCase_ReusableTestsTestPresencePerformMethod) throws {
        let test = Test()
        try reusableTestsTestPresencePerformMethod(for: test, testCase: testCase) { $0.leaveClient("john", data: nil, callback: $1) }
    }

    func test__090__Presence__leaveClient__should_implicitly_attach_the_Channel() throws {
        try reusableTestsWrapper__Presence__leaveClient__reusableTestsTestPresencePerformMethod(testCase: .should_implicitly_attach_the_Channel)
    }

    func test__091__Presence__leaveClient__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() throws {
        try reusableTestsWrapper__Presence__leaveClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_is_in_the_FAILED_state)
    }

    func test__092__Presence__leaveClient__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() throws {
        try reusableTestsWrapper__Presence__leaveClient__reusableTestsTestPresencePerformMethod(testCase: .should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state)
    }

    // RTP15f
    func test__007__Presence__should_indicate_an_error_if_the_client_is_identified_and_has_a_valid_clientId_and_the_clientId_argument_does_not_match_the_client_s_clientId() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.clientId = "john"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enter("browser") { error in
                XCTAssertNil(error)
                channel.presence.updateClient("tester", data: "mobile") { error in
                    expect(error!.message).to(contain("mismatched clientId"))
                    done()
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, _ in
                XCTAssertEqual(members?.first?.data as? String, "browser")
                done()
            }
        }
    }

    // RTP16

    // RTP16a
    func test__093__Presence__Connection_state_conditions__all_presence_messages_are_published_immediately_if_the_connection_is_CONNECTED() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enterClient("user", data: nil) { error in
                XCTAssertNil(error)
                XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(client.internal.queuedMessages.count, 0)
                done()
            }
            XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.connecting)
            XCTAssertEqual(client.internal.queuedMessages.count, 1)
        }
    }

    // RTP16b
    func test__094__Presence__Connection_state_conditions__all_presence_messages_will_be_queued_and_delivered_as_soon_as_the_connection_state_returns_to_CONNECTED() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        XCTAssertTrue(client.internal.options.queueMessages)

        waitUntil(timeout: testTimeout) { done in
            channel.attach { _ in
                client.internal.onDisconnected()
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enterClient("user", data: nil) { error in
                XCTAssertNil(error)
                XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(client.internal.queuedMessages.count, 0)
                done()
            }
            XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.disconnected)
            XCTAssertEqual(client.internal.queuedMessages.count, 1)
        }
    }

    // RTP16b
    func test__095__Presence__Connection_state_conditions__all_presence_messages_will_be_lost_if_queueMessages_has_been_explicitly_set_to_false() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.queueMessages = false
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        XCTAssertFalse(client.internal.options.queueMessages)

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            channel.attach { _ in
                client.internal.onDisconnected()
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enterClient("user", data: nil) { error in
                XCTAssertNotNil(error)
                done()
            }
            XCTAssertEqual(client.internal.queuedMessages.count, 0)
        }
    }

    // RTP16c
    func test__096__Presence__Connection_state_conditions__should_result_in_an_error_if_the_connection_state_is_INITIALIZED_and_queueMessages_has_been_explicitly_set_to_false() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.autoConnect = false
        options.queueMessages = false
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.initialized)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enterClient("user", data: nil) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.invalidTransportHandle.intValue)
                XCTAssertEqual(channel.presence.internal.pendingPresence.count, 0)
                done()
            }
            XCTAssertEqual(channel.presence.internal.pendingPresence.count, 0)
        }
    }

    func test__097__Presence__Connection_state_conditions__should_result_in_an_error_if_the_connection_state_is__suspended() throws {
        let test = Test()
        try testResultsInErrorWithConnectionState(.suspended, for: test, channelName: test.uniqueChannelName()) { client in
            AblyTests.queue.async {
                client.internal.onSuspended()
            }
        }
    }

    func test__098__Presence__Connection_state_conditions__should_result_in_an_error_if_the_connection_state_is__closed() throws {
        let test = Test()
        try testResultsInErrorWithConnectionState(.closed, for: test, channelName: test.uniqueChannelName()) { client in
            client.close()
        }
    }

    func test__099__Presence__Connection_state_conditions__should_result_in_an_error_if_the_connection_state_is__failed() throws {
        let test = Test()
        try testResultsInErrorWithConnectionState(.failed, for: test, channelName: test.uniqueChannelName()) { client in
            AblyTests.queue.async {
                client.internal.onError(AblyTests.newErrorProtocolMessage())
            }
        }
    }

    // RTP11

    func test__106__Presence__get__query__waitForSync_should_be_true_by_default() {
        XCTAssertTrue(ARTRealtimePresenceQuery().waitForSync)
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTP11a
    func skipped__test__100__Presence__get__should_return_a_list_of_current_members_on_the_channel() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        var disposable = [ARTRealtime]()
        defer {
            for clientItem in disposable {
                clientItem.dispose()
                clientItem.close()
            }
        }

        let expectedData = "online"

        let channelName = test.uniqueChannelName()
        disposable += [AblyTests.addMembersSequentiallyToChannel(channelName, members: 150, data: expectedData as AnyObject?, options: options)]

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        let hook = ARTRealtimePresenceQuery.testSuite_injectIntoClassMethod(#selector(ARTRealtimePresenceQuery.init as () -> ARTRealtimePresenceQuery)) { // Default initialiser: referring to the no-parameter variant of `init` as one of several overloaded methods requires an explicit `as <signature>` cast
        }
        defer { hook?.remove() }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                if let members {
                    XCTAssertEqual(members.count, 150)
                } else {
                    XCTFail("Expected members to be non-nil")
                }
                expect(members!.first).to(beAnInstanceOf(ARTPresenceMessage.self))
                expect(members).to(allPass { member in
                    NSRegularExpression.match(member.clientId, pattern: "^user(\\d+)$")
                        && (member.data as? String) == expectedData
                })
                done()
            }
        }
    }

    // RTP11b
    func test__101__Presence__get__should_implicitly_attach_the_channel() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        XCTAssertEqual(channel.state, ARTRealtimeChannelState.initialized)
        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { membersPage, error in
                XCTAssertNil(error)
                XCTAssertNotNil(membersPage)
                done()
            }
            XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
        }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.attached)
    }

    // RTP11b
    func test__102__Presence__get__should_result_in_an_error_if_the_channel_is_in_the_FAILED_state() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

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
        XCTAssertEqual(channelError.message, protocolError.message)
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                XCTAssertEqual(channel.errorReason, protocolError)
                XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)
                XCTAssertNil(members)
                done()
            }
        }
    }

    // RTP11b
    func test__103__Presence__get__should_result_in_an_error_if_the_channel_moves_to_the_FAILED_state() throws {
        let test = Test()
        let client = AblyTests.newRealtime(try AblyTests.commonAppSetup(for: test)).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

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
            channel.presence.get { members, error in
                guard let error = error else {
                    fail("Error is empty"); done(); return
                }
                XCTAssertEqual(error.message, protocolError.message)
                XCTAssertNil(members)
                done()
            }
        }

        XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)
    }

    // RTP11b
    func test__104__Presence__get__should_result_in_an_error_if_the_channel_is_in_the_DETACHED_state() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.attach()
            channel.detach { error in
                XCTAssertNil(error)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertEqual(error?.code, ARTErrorCode.channelOperationFailedInvalidState.intValue)
                XCTAssertNil(members)
                XCTAssertEqual(channel.state, ARTRealtimeChannelState.detached)
                done()
            }
        }
    }

    // RTP11b
    func test__105__Presence__get__should_result_in_an_error_if_the_channel_moves_to_the_DETACHED_state() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        
        let channelName = test.uniqueChannelName()
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 120, options: options)

        let channel = client.channels.get(channelName)
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            channel.presence.get { members, error in
                guard let error = error else {
                    fail("Error is nil"); done(); return
                }
                XCTAssertEqual(error.message, "channel is being DETACHED")
                XCTAssertNil(members)
                partialDone()
            }
            channel.detach { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)
    }

    // RTP11d

    func test__107__Presence__get__If_the_Channel_is_in_the_SUSPENDED_state_then__by_default__results_in_an_error() throws {
        let test = Test()
        try testSuspendedStateResultsInError(for: test, channelName: test.uniqueChannelName()) { channel, callback in
            channel.presence.get(callback)
        }
    }

    func test__108__Presence__get__If_the_Channel_is_in_the_SUSPENDED_state_then__if_waitForSync_is_true__results_in_an_error() throws {
        let test = Test()
        try testSuspendedStateResultsInError(for: test, channelName: test.uniqueChannelName()) { channel, callback in
            let params = ARTRealtimePresenceQuery()
            params.waitForSync = true
            channel.presence.get(params, callback: callback)
        }
    }

    func test__109__Presence__get__If_the_Channel_is_in_the_SUSPENDED_state_then__if_waitForSync_is_false__returns_the_members_in_the_current_PresenceMap() throws {
        let test = Test()
        let (channel, client) = try getSuspendedChannel(named: test.uniqueChannelName(), for: test)
        defer { client.dispose(); client.close() }

        var msgs = [String: ARTPresenceMessage]()
        for i in 0 ..< 3 {
            let msg = ARTPresenceMessage(clientId: "client\(i)", action: .present, connectionId: "foo", id: "foo:0:0")
            msgs[msg.clientId!] = msg
            channel.internal.presenceMap.internalAdd(msg)
        }

        channel.presence.get(getParams) { result, err in
            XCTAssertNil(err)
            XCTAssertNotNil(result)
            guard let result = result else {
                return
            }
            var resultByClient = [String: ARTPresenceMessage]()
            for msg in result {
                resultByClient[msg.clientId ?? "(no clientId)"] = msg
            }
            XCTAssertEqual(resultByClient, msgs)
        }
    }

    // RTP11c

    // RTP11c1
    func skipped__test__110__Presence__get__Query__set_of_params___waitForSync_is_true__should_wait_until_SYNC_is_complete_before_returning_a_list_of_members() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        var clientSecondary: ARTRealtime!
        defer { clientSecondary.dispose(); clientSecondary.close() }
        
        let channelName = test.uniqueChannelName()
        clientSecondary = AblyTests.addMembersSequentiallyToChannel(channelName, members: 150, options: options)

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        let query = ARTRealtimePresenceQuery()
        XCTAssertTrue(query.waitForSync)

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                let transport = client.internal.transport as! TestProxyTransport
                transport.setListenerBeforeProcessingIncomingMessage { protocolMessage in
                    if protocolMessage.action == .sync {
                        XCTAssertEqual(protocolMessage.presence!.count, 100)
                        channel.presence.get(query) { members, error in
                            XCTAssertNil(error)
                            if let members {
                                XCTAssertEqual(members.count, 150)
                            } else {
                                XCTFail("Expected members to be non-nil")
                            }
                            done()
                        }
                        transport.setListenerBeforeProcessingIncomingMessage(nil)
                    }
                }
            }
        }
    }

    // RTP11c1
    func test__111__Presence__get__Query__set_of_params___waitForSync_is_false__should_return_immediately_the_known_set_of_presence_members() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        var clientSecondary: ARTRealtime!
        defer { clientSecondary.dispose(); clientSecondary.close() }
        
        let channelName = test.uniqueChannelName()
        clientSecondary = AblyTests.addMembersSequentiallyToChannel(channelName, members: 150, options: options)

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        let query = ARTRealtimePresenceQuery()
        query.waitForSync = false

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            
            let transport = client.internal.transport as! TestProxyTransport
            var alreadySawSync = false
            transport.setBeforeIncomingMessageModifier { message in
                if message.action == .sync {
                    // Ignore next SYNC so that the sync process never finishes.
                    if alreadySawSync {
                        return nil
                    }
                    alreadySawSync = true
                    partialDone()
                }
                return message
            }

            channel.attach { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get(query) { members, error in
                XCTAssertNil(error)
                if let members {
                    XCTAssertEqual(members.count, 100)
                } else {
                    XCTFail("Expected members to be non-nil")
                }
                done()
            }
        }
    }

    // RTP11c2
    func test__112__Presence__get__Query__set_of_params___should_return_members_filtered_by_clientId() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let now = NSDate()

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
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
            channel.attach { error in
                XCTAssertNil(error)

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
                XCTAssertNil(error)
                guard let members = members else {
                    fail("Members is nil"); done(); return
                }
                XCTAssertEqual(members.count, 1)
                expect(members).to(allPass { (member: ARTPresenceMessage?) in member!.action != .absent })
                expect(members.filter { $0.clientId == "a" }).to(beEmpty())
                XCTAssertEqual(members.filter { $0.clientId == "b" }.count, 1)
                expect(members.filter { $0.clientId == "c" }).to(beEmpty())
                done()
            }
        }
    }

    // RTP11c3
    func test__113__Presence__get__Query__set_of_params___should_return_members_filtered_by_connectionId() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let now = NSDate()
        let channelName = test.uniqueChannelName()
        var clientMembers: ARTRealtime?
        defer { clientMembers?.dispose(); clientMembers?.close() }
        clientMembers = AblyTests.addMembersSequentiallyToChannel(channelName, members: 101, options: options)

        let clientSubscribed = AblyTests.newRealtime(options).client
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
            transport.setAfterIncomingMessageModifier { protocolMessage in
                // Receive the first Sync message from Ably service
                if protocolMessage.action == .sync {
                    // Inject a fabricated Presence message
                    let presenceMessage = ARTProtocolMessage()
                    presenceMessage.action = .presence
                    presenceMessage.channel = protocolMessage.channel
                    presenceMessage.timestamp = Date()
                    presenceMessage.presence = presenceData

                    transport.receive(presenceMessage)

                    // Simulate an end to the sync
                    let endSyncMessage = ARTProtocolMessage()
                    endSyncMessage.action = .sync
                    endSyncMessage.channel = protocolMessage.channel
                    endSyncMessage.channelSerial = "validserialprefix:" // with no part after the `:` this indicates the end to the SYNC
                    endSyncMessage.timestamp = Date()

                    transport.setAfterIncomingMessageModifier(nil)
                    transport.receive(endSyncMessage)

                    // Stop the next sync message from Ably service because we already injected the end of the sync
                    transport.actionsIgnored = [.sync]

                    done()
                }
                return protocolMessage
            }
            channelSubscribed.attach()
        }

        let query = ARTRealtimePresenceQuery()
        query.connectionId = "one"

        waitUntil(timeout: testTimeout) { done in
            channelSubscribed.presence.get(query) { members, error in
                XCTAssertNil(error)
                guard let members = members else {
                    fail("Members is nil"); done(); return
                }
                XCTAssertEqual(members.count, 2)
                expect(members).to(allPass { (member: ARTPresenceMessage?) in member!.action != .absent })
                expect(members.filter { $0.clientId == "a" }).to(beEmpty())
                XCTAssertEqual(members.filter { $0.clientId == "b" }.count, 1)
                XCTAssertEqual(members.filter { $0.clientId == "c" }.count, 1)
                done()
            }
        }
    }

    // RTP12

    // RTP12a
    func test__114__Presence__history__should_support_all_the_same_params_as_Rest() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        let rest = ARTRest(options: options)

        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }

        let channelName = test.uniqueChannelName()
        let channelRest = rest.channels.get(channelName)
        let channelRealtime = realtime.channels.get(channelName)

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
            }.toNot(throwError { err in fail("\(err)"); done() })
        }
        XCTAssertTrue(restPresenceHistoryMethodWasCalled)
        restPresenceHistoryMethodWasCalled = false

        waitUntil(timeout: testTimeout) { done in
            expect {
                try channelRealtime.presence.history(queryRealtime) { _, _ in
                    done()
                }
            }.toNot(throwError { err in fail("\(err)"); done() })
        }
        XCTAssertTrue(restPresenceHistoryMethodWasCalled)
    }

    // RTP12

    // RTP12c, RTP12d
    func test__115__Presence__history__should_return_a_PaginatedResult_page() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        var clientSecondary: ARTRealtime!
        defer { clientSecondary.dispose(); clientSecondary.close() }

        let expectedData = ["x", "y"]
        let expectedPattern = "^user(\\d+)$"
        
        let channelName = test.uniqueChannelName()
        clientSecondary = AblyTests.addMembersSequentiallyToChannel(channelName, members: 150, data: expectedData as AnyObject?, options: options)

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.history { membersPage, error in
                XCTAssertNil(error)
                guard let membersPage = membersPage else {
                    fail("membersPage is empty"); done(); return
                }
                expect(membersPage).to(beAnInstanceOf(ARTPaginatedResult<ARTPresenceMessage>.self))
                XCTAssertEqual(membersPage.items.count, 100)

                let members = membersPage.items
                expect(members).to(allPass { member in
                    NSRegularExpression.match(member.clientId, pattern: expectedPattern)
                        && (member.data as! [String]) == expectedData
                })

                XCTAssertTrue(membersPage.hasNext)
                XCTAssertFalse(membersPage.isLast)

                membersPage.next { nextPage, error in
                    XCTAssertNil(error)
                    guard let nextPage = nextPage else {
                        fail("nextPage is empty"); done(); return
                    }
                    expect(nextPage).to(beAnInstanceOf(ARTPaginatedResult<ARTPresenceMessage>.self))
                    XCTAssertEqual(nextPage.items.count, 50)

                    let members = nextPage.items
                    expect(members).to(allPass { member in
                        NSRegularExpression.match(member.clientId, pattern: expectedPattern)
                            && (member.data as! [String]) == expectedData
                    })

                    XCTAssertFalse(nextPage.hasNext)
                    XCTAssertTrue(nextPage.isLast)
                    done()
                }
            }
        }
    }

    // RTP13
    func skipped__test__008__Presence__Presence_syncComplete_returns_true_if_the_initial_SYNC_operation_has_completed() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        var disposable = [ARTRealtime]()
        defer {
            for clientItem in disposable {
                clientItem.dispose()
                clientItem.close()
            }
        }

        let channelName = test.uniqueChannelName()
        disposable += [AblyTests.addMembersSequentiallyToChannel(channelName, members: 250, options: options)]

        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(channelName)
        channel.attach()

        XCTAssertFalse(channel.presence.syncComplete)
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        let transport = client.internal.transport as! TestProxyTransport
        transport.setListenerBeforeProcessingIncomingMessage { protocolMessage in
            if protocolMessage.action == .sync {
                XCTAssertFalse(channel.presence.internal.syncComplete_nosync())
            }
        }

        expect(channel.presence.syncComplete).toEventually(beTrue(), timeout: testTimeout)
        XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .sync }.count, 3)
    }

    // RTP14

    // RTP14a, RTP14b, RTP14c, RTP14d
    func skipped__test__116__Presence__enterClient__enters_into_presence_on_a_channel_on_behalf_of_another_clientId() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())
        XCTAssertEqual(channel.internal.presenceMap.members.count, 0)

        let expectedData = ["test": 1]

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
            channel.presence.enterClient("test", data: expectedData) { error in
                XCTAssertNil(error)
                done()
            }
        }

        channel.presence.enterClient("john", data: nil)
        channel.presence.enterClient("sara", data: nil)
        expect(channel.internal.presenceMap.members).toEventually(haveCount(3), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, _ in
                guard let members = members?.reduce([String: ARTPresenceMessage](), { dictionary, item in
                    dictionary + [item.clientId ?? "": item]
                }) else { fail("No members"); done(); return }

                XCTAssertEqual(members["test"]!.data as? NSDictionary, expectedData as NSDictionary?)
                XCTAssertNotNil(members["john"])
                XCTAssertNotNil(members["sara"])
                done()
            }
        }

        XCTAssertEqual(encodeNumberOfCalls, 1)
        XCTAssertEqual(decodeNumberOfCalls, 1)
    }

    // RTP14d
    func test__117__Presence__enterClient__should_be_present_all_the_registered_members_on_a_presence_channel() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channelName = test.uniqueChannelName()
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
                XCTAssertNil(error)
                partialDone()
            }
            channel.presence.enterClient(max, data: nil) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.presence.get { members, error in
                XCTAssertNil(error)
                guard let members = members else {
                    fail("Members is nil"); done(); return
                }
                XCTAssertEqual(members.count, 2)
                let clientIds = members.map { $0.clientId }
                // Cannot guarantee the order
                expect(clientIds).to(equal([john, max]) || equal([max, john]))
                done()
            }
        }
    }

    // TP3a
    func test__118__Presence__presence_message_attributes__if_the_presence_message_does_not_contain_an_id__it_should_be_set_to_protocolMsgId_index() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
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
                    XCTAssertEqual(message.id, "protocolId:0")
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
