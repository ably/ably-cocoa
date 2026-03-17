import Ably
import Nimble
import XCTest

class RealtimeAnnotationsTests: XCTestCase {
    // RTAN1
    // RTAN2
    // RTAN3
    // RTAN4
    // RTAN5
    func test__publish_delete_and_get_annotations() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.testOptions.channelNamePrefix = nil

        // Create realtime client
        let realtimeClient = ARTRealtime(options: options)
        defer { realtimeClient.dispose(); realtimeClient.close() }

        // Channel name and options
        let channelName = test.uniqueChannelName(prefix: "mutable:")
        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = [.publish, .subscribe, .annotationPublish, .annotationSubscribe]

        // Get realtime channel with options
        let realtimeChannel = realtimeClient.channels.get(channelName, options: channelOptions)

        // Message and annotation to track
        var receivedMessage: ARTMessage!
        var receivedSummary: ARTMessage!
        var createdAnnotation: ARTAnnotation!

        // Filtered by type annotations subscription callback calls counter
        var filteredCallbackCalls = 0

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)

            // Publish a message to annotate
            let message = ARTMessage(name: "test", data: "test message")
            realtimeChannel.publish([message])

            // Subscribe to messages
            realtimeChannel.subscribe { message in
                if message.action == .create {
                    receivedMessage = message

                    // When message is received, create and publish annotation via realtime
                    let annotation = ARTOutboundAnnotation(
                        id: nil,
                        type: "reaction:multiple.v1",
                        clientId: nil,
                        name: "👍",
                        count: 10,
                        data: nil,
                        extras: nil
                    )

                    // RTAN1
                    realtimeChannel.annotations.publish(for: message, annotation: annotation) { error in
                        XCTAssertNil(error)
                        partialDone()
                    }
                }
                else if message.action == .messageSummary {
                    receivedSummary = message
                    realtimeChannel.unsubscribe()

                    // Verify summary properties
                    XCTAssertEqual(receivedSummary.action, .messageSummary)
                    XCTAssertEqual(receivedSummary.serial, receivedMessage.serial)
                    XCTAssertEqual(receivedSummary.annotations?.summary?.count, 1)

                    partialDone()
                }
            }

            // RTAN4: Subscribe to annotations
            realtimeChannel.annotations.subscribe { annotation in
                // only interested in the first annotation which is with action `create` (testing RTAN5 along the way)
                realtimeChannel.annotations.unsubscribe()

                createdAnnotation = annotation

                // Verify annotation properties
                XCTAssertEqual(annotation.action, .create)
                XCTAssertEqual(annotation.messageSerial, receivedMessage.serial)
                XCTAssertEqual(annotation.type, "reaction:multiple.v1")
                XCTAssertEqual(annotation.name, "👍")
                XCTAssertEqual(annotation.count?.intValue, 10)

                // Verify it matches the message
                XCTAssertEqual(annotation.messageSerial, receivedMessage.serial)

                partialDone()
            }

            // RTAN4c
            realtimeChannel.annotations.subscribe("reaction:multiple.v1") { annotation in
                XCTAssertEqual(annotation.type, "reaction:multiple.v1")
                filteredCallbackCalls += 1
            }

            // RTAN4c
            realtimeChannel.annotations.subscribe("reaction:distinct.v1") { annotation in
                XCTFail("Callback shouldn't be called for this type.")
            }
        }

        XCTAssertEqual(filteredCallbackCalls, 1)

        guard let createdAnnotation else {
            XCTFail("Annotation should not be nil")
            return
        }

        // RTAN2: Now delete the annotation
        waitUntil(timeout: testTimeout) { done in
            let deleteAnnotation = ARTOutboundAnnotation(
                id: nil,
                type: createdAnnotation.type,
                clientId: nil,
                name: createdAnnotation.name,
                count: createdAnnotation.count,
                data: nil,
                extras: nil
            )
            realtimeChannel.annotations.delete(for: receivedMessage, annotation: deleteAnnotation) { error in
                XCTAssertNil(error)
                done()
            }
        }

        // After the annotations are published (and received via realtime), check it through the rest request:

        guard let messageSerial = receivedMessage.serial else {
            XCTFail("Message serial should not be nil")
            return
        }

        // Comment form ably-js 'annotations.test.js':
        // > Temporary anti-flake measure; can be removed after summary loop implements
        // > annotation resume (CHA-887)
        sleep(2)

        waitUntil(timeout: testTimeout) { done in
            // RTAN3
            realtimeChannel.annotations.getForMessageSerial(messageSerial, query: .init()) { paginatedResult, error in
                XCTAssertNil(error)

                guard let annotations = paginatedResult?.items, annotations.count == 2 else {
                    XCTFail("Should contain two annotations.")
                    return
                }
                XCTAssertEqual(annotations[0].action, .create)
                XCTAssertEqual(annotations[0].type, "reaction:multiple.v1")
                XCTAssertEqual(annotations[0].name, "👍")
                XCTAssertEqual(annotations[0].count?.intValue, 10)

                XCTAssertEqual(annotations[1].action, .delete)
                XCTAssertEqual(annotations[1].type, "reaction:multiple.v1")
                XCTAssertEqual(annotations[1].name, "👍")
                XCTAssertEqual(annotations[1].count?.intValue, 10)

                done()
            }
        }
    }

    // RTAN4e
    func test__if_annotation_subscribe_mode_is_missing_from_channel_options_then_subscription_will_not_work() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.testOptions.channelNamePrefix = nil

        // Create realtime client
        let realtimeClient = ARTRealtime(options: options)
        defer { realtimeClient.dispose(); realtimeClient.close() }

        // Channel name and options
        let channelName = test.uniqueChannelName(prefix: "mutable:")
        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = [.publish, .subscribe, .annotationPublish] // miss `annotationSubscribe`

        // Get realtime channel with options
        let realtimeChannel = realtimeClient.channels.get(channelName, options: channelOptions)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)

            // Publish a message to annotate
            let message = ARTMessage(name: "test", data: "test message")
            realtimeChannel.publish([message])

            // Subscribe to messages
            realtimeChannel.subscribe { message in
                if message.action == .create {
                    // When message is received, create and publish annotation via realtime
                    let annotation = ARTOutboundAnnotation(
                        id: nil,
                        type: "reaction:multiple.v1",
                        clientId: nil,
                        name: "👍",
                        count: NSNumber(value: 10),
                        data: nil,
                        extras: nil
                    )

                    // RTAN1
                    realtimeChannel.annotations.publish(for: message, annotation: annotation) { error in
                        XCTAssertNil(error)
                        partialDone()
                    }
                }
                else if message.action == .messageSummary {
                    realtimeChannel.unsubscribe()
                    partialDone()
                }
            }

            var callbackCalls = 0

            realtimeChannel.annotations.subscribe { annotation in
                callbackCalls += 1
            }

            // wait for possible annotations callback call
            delay(1.5) {
                XCTAssertEqual(callbackCalls, 0, "Annotation callback should not be called")
                partialDone()
            }
        }
    }

    // RTAN4d, RTL7g
    func test__annotations_subscribe_should_implicitly_attach_the_channel_if_options_attachOnSubscribe_is_true() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(test.uniqueChannelName())

        // Initialized
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.initialized)
        channel.annotations.subscribe { _ in }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        // Detaching
        channel.detach()
        channel.annotations.subscribe { _ in }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.detaching)
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        // Detached
        channel.detach()
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)
        channel.annotations.subscribe { _ in }
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
    }

    // RTAN4d, RTL7h
    func test__annotations_subscribe_should_not_implicitly_attach_the_channel_if_options_attachOnSubscribe_is_false() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }

        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.attachOnSubscribe = false
        let channel = client.channels.get(test.uniqueChannelName(), options: channelOptions)

        // Initialized
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.initialized)
        channel.annotations.subscribe(attachCallback: { _ in
            fail("Attach callback should not be called.")
        }) { _ in }
        // Make sure that channel stays initialized
        waitUntil(timeout: testTimeout) { done in
            delay(1) {
                XCTAssertEqual(channel.state, ARTRealtimeChannelState.initialized)
                done()
            }
        }
    }

    // RTAN4d, RTL7g
    func test__annotations_subscribe_should_result_in_an_error_if_channel_is_in_the_FAILED_state_and_options_attachOnSubscribe_is_true() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(test.uniqueChannelName())
        channel.internal.onError(AblyTests.newErrorProtocolMessage())
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)

        waitUntil(timeout: testTimeout) { done in
            channel.annotations.subscribe(attachCallback: { errorInfo in
                XCTAssertNotNil(errorInfo)

                channel.annotations.subscribe("foo", onAttach: { errorInfo in
                    XCTAssertNotNil(errorInfo)
                    done()
                }) { _ in }
            }) { _ in }
        }
    }

    // RTAN4d, RTL7g
    func test__annotations_subscribe_should_not_result_in_an_error_if_channel_is_in_the_FAILED_state_and_options_attachOnSubscribe_is_false() throws {
        let test = Test()
        let client = ARTRealtime(options: try AblyTests.commonAppSetup(for: test))
        defer { client.dispose(); client.close() }

        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.attachOnSubscribe = false
        let channel = client.channels.get(test.uniqueChannelName(), options: channelOptions)

        channel.internal.onError(AblyTests.newErrorProtocolMessage())
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)

        channel.annotations.subscribe(attachCallback: { _ in
            fail("Attach callback should not be called.")
        }) { _ in }
        // Make sure that channel stays failed
        waitUntil(timeout: testTimeout) { done in
            delay(1) {
                XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)
                done()
            }
        }
    }

    // RTAN1a
    func test__publish_annotation_exceeding_max_message_size() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.testOptions.channelNamePrefix = nil

        // Create realtime client
        let realtimeClient = ARTRealtime(options: options)
        defer { realtimeClient.dispose(); realtimeClient.close() }

        // Channel name and options
        let channelName = test.uniqueChannelName(prefix: "mutable:")
        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = [.publish, .subscribe, .annotationPublish, .annotationSubscribe]

        // Get channel with options
        let channel = realtimeClient.channels.get(channelName, options: channelOptions)

        // Wait for the channel to be ready
        waitUntil(timeout: testTimeout) { done in
            channel.once(.attached) { _ in
                done()
            }
            channel.attach()
        }

        // Create an annotation with a large name field that exceeds maxMessageSize
        let largeString = String(repeating: "f", count: realtimeClient.connection.maxMessageSize + 100)

        waitUntil(timeout: testTimeout) { done in
            // Create annotation with large name
            let annotation = ARTOutboundAnnotation(
                id: nil,
                type: "test",
                clientId: nil,
                name: largeString,
                count: NSNumber(value: 1),
                data: nil,
                extras: nil
            )

            // Try to publish the annotation - should fail with 40009
            channel.annotations.publish(forMessageSerial: "test", annotation: annotation) { error in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, 40009)
                XCTAssertTrue(error?.message.contains("exceeds maxMessageSize") ?? false)
                done()
            }
        }
    }
}
