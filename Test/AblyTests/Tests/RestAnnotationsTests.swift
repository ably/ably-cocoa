import Ably
import Nimble
import XCTest

class RestAnnotationsTests: XCTestCase {
    // RSAN1
    // RSAN2
    // RSAN3
    func test__publish_delete_and_get_annotations() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.testOptions.channelNamePrefix = nil
        
        // Create realtime client
        let realtimeClient = ARTRealtime(options: options)
        defer { realtimeClient.dispose(); realtimeClient.close() }
        
        // Create rest client
        let restClient = ARTRest(options: options)
        
        // Channel name and options
        let channelName = test.uniqueChannelName(prefix: "mutable:")
        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = [.publish, .subscribe, .annotationPublish, .annotationSubscribe]
        
        // Get realtime channel with options
        let realtimeChannel = realtimeClient.channels.get(channelName, options: channelOptions)
        
        // Get rest channel
        let restChannel = restClient.channels.get(channelName)
        
        // Message and annotation to track
        var receivedMessage: ARTMessage!
        var receivedSummary: ARTMessage!
        var createdAnnotation: ARTAnnotation!

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            
            // Subscribe to messages
            realtimeChannel.subscribe { message in
                if message.action == .create {
                    receivedMessage = message

                    // When message is received, create and publish annotation via REST
                    let annotation = ARTOutboundAnnotation(
                        id: nil,
                        type: "reaction:multiple.v1",
                        clientId: nil,
                        name: "👍",
                        count: NSNumber(value: 10),
                        data: nil,
                        extras: nil
                    )
                    
                    // RSAN1
                    restChannel.annotations.publish(for: message, annotation: annotation) { error in
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
            
            // Subscribe to annotations
            realtimeChannel.annotations.subscribe { annotation in
                // only interested in the first annotation which is with action `create`
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
            
            // Wait for channel to be attached before publishing
            realtimeChannel.once(.attached) { stateChange in
                // Publish a message
                let message = ARTMessage(name: "test", data: "test message")
                realtimeChannel.publish([message])
                partialDone()
            }
            realtimeChannel.attach()
        }
        
        // RSAN2: Now delete the annotation
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
            restChannel.annotations.delete(for: receivedMessage, annotation: deleteAnnotation) { error in
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
            // RSAN3
            restChannel.annotations.getForMessageSerial(messageSerial, query: .init()) { paginatedResult, error in
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
    
    // RSAN1c4
    func test__idempotent_publishing_should_publish_annotation_with_implicit_id_only_once() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.testOptions.channelNamePrefix = nil
        options.idempotentRestPublishing = true // for visibility, true by default
        
        // Create realtime client
        let realtimeClient = ARTRealtime(options: options)
        defer { realtimeClient.dispose(); realtimeClient.close() }
        
        // Create rest client
        let restClient = ARTRest(options: options)
        
        // Channel name and options
        let channelName = test.uniqueChannelName(prefix: "mutable:")
        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = [.publish, .subscribe, .annotationPublish, .annotationSubscribe]
        
        // Get realtime channel with options
        let realtimeChannel = realtimeClient.channels.get(channelName, options: channelOptions)
        
        // Get rest channel
        let restChannel = restClient.channels.get(channelName)
        
        // Message and annotation to track
        var receivedMessage: ARTMessage!
        var createdAnnotation: ARTAnnotation!

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)
            
            // Subscribe to messages
            realtimeChannel.subscribe { message in
                if message.action == .create {
                    receivedMessage = message

                    // When message is received, create and publish annotation via REST
                    let annotation = ARTOutboundAnnotation(
                        id: nil,
                        type: "reaction:multiple.v1",
                        clientId: nil,
                        name: "👍",
                        count: NSNumber(value: 10),
                        data: nil,
                        extras: nil
                    )
                    
                    // RSAN1
                    restChannel.annotations.publish(for: receivedMessage, annotation: annotation) { error in
                        XCTAssertNil(error)
                        partialDone()
                    }
                }
            }
            
            // Subscribe to annotations
            realtimeChannel.annotations.subscribe { annotation in
                createdAnnotation = annotation
                
                // Verify annotation properties
                XCTAssertNotNil(annotation.id)
                XCTAssertEqual(annotation.action, .create)
                XCTAssertEqual(annotation.messageSerial, receivedMessage.serial)
                XCTAssertEqual(annotation.type, "reaction:multiple.v1")
                XCTAssertEqual(annotation.name, "👍")
                XCTAssertEqual(annotation.count?.intValue, 10)
                XCTAssertEqual(annotation.messageSerial, receivedMessage.serial)
                
                partialDone()
            }
            
            // Wait for channel to be attached before publishing
            realtimeChannel.once(.attached) { stateChange in
                // Publish a message
                let message = ARTMessage(name: "test", data: "test message")
                realtimeChannel.publish([message])
                partialDone()
            }
            realtimeChannel.attach()
        }
        
        // RSAN1c4: Now publish the created annotation again (to verify idempotent publishing)
        waitUntil(timeout: testTimeout) { done in
            // Convert the received ARTAnnotation to ARTOutboundAnnotation for publishing with the same ID
            let outboundAnnotation = ARTOutboundAnnotation(
                id: createdAnnotation.id,
                type: createdAnnotation.type,
                clientId: createdAnnotation.clientId,
                name: createdAnnotation.name,
                count: createdAnnotation.count,
                data: createdAnnotation.data,
                extras: createdAnnotation.extras
            )
            restChannel.annotations.publish(for: receivedMessage, annotation: outboundAnnotation) { error in
                XCTAssertNil(error) // no error, server ignores duplicate
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
            // RSAN3
            restChannel.annotations.getForMessageSerial(messageSerial, query: .init()) { paginatedResult, error in
                XCTAssertNil(error)
                
                guard let annotations = paginatedResult?.items, annotations.count == 1 else {
                    XCTFail("Should contain only one annotation.")
                    return
                }
                XCTAssertEqual(annotations[0].id, createdAnnotation.id)
                XCTAssertEqual(annotations[0].action, .create)
                XCTAssertEqual(annotations[0].type, "reaction:multiple.v1")
                XCTAssertEqual(annotations[0].name, "👍")
                XCTAssertEqual(annotations[0].count?.intValue, 10)
                
                done()
            }
        }
    }
    
    // RSAN1a4
    func test__publish_annotation_exceeding_max_message_size() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.testOptions.channelNamePrefix = nil

        let restClient = ARTRest(options: options)
        let channel = restClient.channels.get(test.uniqueChannelName(prefix: "mutable:"))
        
        let largeString = String(repeating: "f", count: ARTDefault.maxMessageSize() + 100) // Create a string larger than maxMessageSize
        
        waitUntil(timeout: testTimeout) { done in
            // Create an annotation with the large string as name
            let annotation = ARTOutboundAnnotation(
                id: nil,
                type: "test",
                clientId: nil,
                name: largeString,
                count: NSNumber(value: 1),
                data: nil,
                extras: nil
            )
            
            // Try to publish the annotation
            channel.annotations.publish(forMessageSerial: "test", annotation: annotation) { error in
                // Verify error code and message
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, 40009)
                XCTAssertTrue(error?.message.contains("exceeds maxMessageSize") ?? false)
                done()
            }
        }
    }
}
