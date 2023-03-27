import Ably
import Foundation
import Nimble
import XCTest
import SwiftyJSON

private var client: ARTRest!
private var testHTTPExecutor: TestProxyHTTPExecutor!

private func assertMessagePayloadId(id: String?, expectedSerial: String) {
    guard let id = id else {
        fail("Message.id from payload is nil"); return
    }

    let idParts = id.split(separator: ":")

    if idParts.count != 2 {
        fail("Message.id from payload should have baseId and serial separated by a colon"); return
    }

    let baseId = String(idParts[0])
    let serial = String(idParts[1])

    guard let baseIdData = Data(base64Encoded: baseId) else {
        fail("BaseId should be a base64 encoded string"); return
    }

    XCTAssertEqual(baseIdData.bytes.count, 9)
    XCTAssertEqual(serial, expectedSerial)
}

private let presenceFixtures = appSetupJson["post_apps"]["channels"][0]["presence"]

private let text = "John"
private let integer = "5"
private let decimal = "65.33"
private let dictionary = ["number": 3, "name": "John"] as [String: Any]
private let array = ["John", "Mary"]
private let binaryData = "123456".data(using: .utf8)!

private func testSupportsAESEncryptionWithKeyLength(_ encryptionKeyLength: UInt, channelName: String) {
    let options = AblyTests.commonAppSetup()
    let client = ARTRest(options: options)
    client.internal.httpExecutor = testHTTPExecutor

    let params: ARTCipherParams = ARTCrypto.getDefaultParams([
        "key": ARTCrypto.generateRandomKey(encryptionKeyLength),
    ])
    XCTAssertEqual(params.algorithm, "AES")
    XCTAssertEqual(params.keyLength, encryptionKeyLength)
    XCTAssertEqual(params.mode, "CBC")

    let channelOptions = ARTChannelOptions(cipher: params)
    let channel = client.channels.get(channelName, options: channelOptions)

    waitUntil(timeout: testTimeout) { done in
        channel.publish("test", data: "message1") { error in
            XCTAssertNil(error)
            done()
        }
    }

    guard let httpBody = testHTTPExecutor.requests.last?.httpBody else {
        fail("HTTPBody is empty")
        return
    }
    let httpBodyAsJSON = AblyTests.msgpackToJSON(httpBody)
    XCTAssertEqual(httpBodyAsJSON["encoding"].string, "utf-8/cipher+aes-\(encryptionKeyLength)-cbc/base64")
    XCTAssertEqual(httpBodyAsJSON["name"].string, "test")
    XCTAssertNotEqual(httpBodyAsJSON["data"].string, "message1")

    waitUntil(timeout: testTimeout) { done in
        channel.history { result, error in
            XCTAssertNil(error)
            guard let result = result else {
                fail("PaginatedResult is empty"); done()
                return
            }
            XCTAssertFalse(result.hasNext)
            XCTAssertTrue(result.isLast)
            let items = result.items
            if result.items.isEmpty {
                fail("PaginatedResult has no items"); done()
                return
            }
            XCTAssertEqual(items[0].name, "test")
            XCTAssertEqual(items[0].data as? String, "message1")
            done()
        }
    }
}

private let mockLogHandler = InternalLogHandler(logHandler: MockVersion2LogHandler())

class RestClientChannelTests: XCTestCase {
    // XCTest invokes this method before executing the first test in the test suite. We use it to ensure that the global variables are initialized at the same moment, and in the same order, as they would have been when we used the Quick testing framework.
    override class var defaultTestSuite: XCTestSuite {
        _ = client
        _ = testHTTPExecutor
        _ = presenceFixtures
        _ = text
        _ = integer
        _ = decimal
        _ = dictionary
        _ = array
        _ = binaryData

        return super.defaultTestSuite
    }

    enum PublishArgs {
        static let name = "foo"
        static let data = "bar"
    }

    struct TestCase {
        let value: Any?
        let expected: JSON
    }

    override func setUp() {
        super.setUp()

        let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
        client = ARTRest(options: options)
        testHTTPExecutor = TestProxyHTTPExecutor(mockLogHandler)
    }

    // RSL1

    // RSL1b

    func test__005__publish__with_name_and_data_arguments__publishes_the_message_and_invokes_callback_with_success() {
        var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
        var publishedMessage: ARTMessage?

        let channel = client.channels.get(uniqueChannelName())
        
        channel.publish(PublishArgs.name, data: PublishArgs.data) { error in
            publishError = error
            channel.history { result, _ in
                publishedMessage = result?.items.first
            }
        }

        expect(publishError).toEventually(beNil(), timeout: testTimeout)
        expect(publishedMessage?.name).toEventually(equal(PublishArgs.name), timeout: testTimeout)
        expect(publishedMessage?.data as? String).toEventually(equal(PublishArgs.data), timeout: testTimeout)
    }

    // RSL1b, RSL1e

    func test__006__publish__with_name_only__publishes_the_message_and_invokes_callback_with_success() {
        var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "io.ably.XCTest", code: -1, userInfo: nil))
        var publishedMessage: ARTMessage?

        let channel = client.channels.get(uniqueChannelName())
        
        channel.publish(PublishArgs.name, data: nil) { error in
            publishError = error
            channel.history { result, _ in
                publishedMessage = result?.items.first
            }
        }

        expect(publishError).toEventually(beNil(), timeout: testTimeout)
        expect(publishedMessage?.name).toEventually(equal(PublishArgs.name), timeout: testTimeout)
        expect(publishedMessage?.data).toEventually(beNil(), timeout: testTimeout)
    }

    // RSL1b, RSL1e

    func test__007__publish__with_data_only__publishes_the_message_and_invokes_callback_with_success() {
        var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
        var publishedMessage: ARTMessage?

        let channel = client.channels.get(uniqueChannelName())
        
        channel.publish(nil, data: PublishArgs.data) { error in
            publishError = error
            channel.history { result, _ in
                publishedMessage = result?.items.first
            }
        }

        expect(publishError).toEventually(beNil(), timeout: testTimeout)
        expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
        expect(publishedMessage?.data as? String).toEventually(equal(PublishArgs.data), timeout: testTimeout)
    }

    // RSL1b, RSL1e

    func test__008__publish__with_neither_name_nor_data__publishes_the_message_and_invokes_callback_with_success() {
        var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
        var publishedMessage: ARTMessage?

        let channel = client.channels.get(uniqueChannelName())
        
        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: nil) { error in
                publishError = error
                channel.history { result, _ in
                    publishedMessage = result?.items.first
                    done()
                }
            }
        }

        XCTAssertNil(publishError)
        XCTAssertNil(publishedMessage?.name)
        XCTAssertNil(publishedMessage?.data)
    }

    func test__009__publish__with_a_Message_object__publishes_the_message_and_invokes_callback_with_success() {
        var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
        var publishedMessage: ARTMessage?

        let channel = client.channels.get(uniqueChannelName())
        
        waitUntil(timeout: testTimeout) { done in
            channel.publish([ARTMessage(name: PublishArgs.name, data: PublishArgs.data)]) { error in
                publishError = error
                channel.history { result, _ in
                    publishedMessage = result?.items.first
                    done()
                }
            }
        }

        XCTAssertNil(publishError)
        XCTAssertEqual(publishedMessage?.name, PublishArgs.name)
        XCTAssertEqual(publishedMessage?.data as? String, PublishArgs.data)
    }

    // RSL1c

    func test__010__publish__with_an_array_of_Message_objects__publishes_the_messages_in_a_single_request_and_invokes_callback_with_success() {
        let oldExecutor = client.internal.httpExecutor
        defer { client.internal.httpExecutor = oldExecutor }
        client.internal.httpExecutor = testHTTPExecutor

        var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
        var publishedMessages: [ARTMessage] = []

        let messages = [
            ARTMessage(name: "bar", data: "foo"),
            ARTMessage(name: "bat", data: "baz"),
        ]
        
        let channel = client.channels.get(uniqueChannelName())
        
        channel.publish(messages) { error in
            publishError = error
            client.internal.httpExecutor = oldExecutor
            channel.history { result, _ in
                if let items = result?.items {
                    publishedMessages.append(contentsOf: items)
                }
            }
        }

        expect(publishError).toEventually(beNil(), timeout: testTimeout)
        expect(publishedMessages.count).toEventually(equal(messages.count), timeout: testTimeout)
        for (i, publishedMessage) in publishedMessages.reversed().enumerated() {
            XCTAssertEqual(publishedMessage.data as? NSObject, messages[i].data as? NSObject)
            XCTAssertEqual(publishedMessage.name, messages[i].name)
        }
        XCTAssertEqual(testHTTPExecutor.requests.count, 1)
    }

    // RSL1f

    // RSL1f1
    func test__011__publish__Unidentified_clients_using_Basic_Auth__should_publish_message_with_the_provided_clientId() {
        let client = ARTRest(options: AblyTests.commonAppSetup())
        let channel = client.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.publish([ARTMessage(name: nil, data: "message", clientId: "tester")]) { error in
                XCTAssertNil(error)
                XCTAssertEqual(client.auth.internal.method, ARTAuthMethod.basic)
                channel.history { page, error in
                    XCTAssertNil(error)
                    guard let page = page else {
                        fail("Page is empty"); done(); return
                    }
                    guard let item = page.items.first else {
                        fail("First item does not exist"); done(); return
                    }
                    XCTAssertEqual(item.clientId, "tester")
                    done()
                }
            }
        }
    }

    // RSA7e

    // RSA7e1
    func test__012__publish__ClientOptions_clientId__should_include_the_clientId_as_a_querystring_parameter_in_realtime_connection_requests() {
        let options = AblyTests.commonAppSetup()
        options.clientId = "john-doe"
        let client = AblyTests.newRealtime(options)
        defer { client.dispose(); client.close() }
        waitUntil(timeout: testTimeout) { done in
            client.channels.get(uniqueChannelName(prefix: "RSA7e1"))
                .publish(nil, data: "foo") { error in
                    XCTAssertNil(error)
                    guard let connection = client.internal.transport as? TestProxyTransport else {
                        fail("No connection found")
                        return
                    }
                    expect(connection.lastUrl!.query).to(haveParam("clientId", withValue: options.clientId))
                    done()
                }
        }
    }

    // RSA7e2
    func test__013__publish__ClientOptions_clientId__should_include_an_X_Ably_ClientId_header_with_value_set_to_the_clientId_as_Base64_encoded_string_in_REST_connection_requests() {
        let options = AblyTests.commonAppSetup()
        options.clientId = "john-doe"
        let client = ARTRest(options: options)
        testHTTPExecutor = TestProxyHTTPExecutor(mockLogHandler)
        client.internal.httpExecutor = testHTTPExecutor
        waitUntil(timeout: testTimeout) { done in
            client.channels.get(uniqueChannelName(prefix: "RSA7e1"))
                .publish(nil, data: "foo") { error in
                    XCTAssertNil(error)
                    guard let request = testHTTPExecutor.requests.first else {
                        fail("No request found")
                        return
                    }
                    let clientIdBase64Encoded = options.clientId?
                        .data(using: .utf8)?
                        .base64EncodedString()
                    XCTAssertEqual(request.allHTTPHeaderFields?["X-Ably-ClientId"], clientIdBase64Encoded)
                    done()
                }
        }
    }

    // RSL1m

    // RSL1m1
    func test__014__publish__Message_clientId__publishing_with_no_clientId_when_the_clientId_is_set_to_some_value_in_the_client_options_should_result_in_a_message_received_with_the_clientId_property_set_to_that_value() {
        let options = AblyTests.commonAppSetup()
        options.clientId = "client-rest"
        let expectedClientId = options.clientId
        let rest = ARTRest(options: options)
        options.clientId = "client-realtime"
        let realtime = ARTRealtime(options: options)

        let chanelName = uniqueChannelName(prefix: "ch1")
        
        let subscriber = realtime.channels.get(chanelName)
        waitUntil(timeout: testTimeout) { done in
            subscriber.once(.attached) { _ in
                done()
            }
        }

        let publisher = rest.channels.get(chanelName)
        waitUntil(timeout: testTimeout) { done in
            subscriber.subscribe { message in
                XCTAssertEqual(message.clientId, expectedClientId)
                subscriber.unsubscribe()
                done()
            }
            publisher.publish("check clientId", data: nil) { error in
                XCTAssertNil(error)
            }
        }
    }

    // RSL1m2
    func test__015__publish__Message_clientId__publishing_with_a_clientId_set_to_the_same_value_as_the_clientId_in_the_client_options_should_result_in_a_message_received_with_the_clientId_property_set_to_that_value() {
        let options = AblyTests.commonAppSetup()
        options.clientId = "client-rest"
        let expectedClientId = options.clientId!
        let rest = ARTRest(options: options)
        options.clientId = "client-realtime"
        let realtime = ARTRealtime(options: options)

        let chanelName = uniqueChannelName(prefix: "ch1")
        
        let subscriber = realtime.channels.get(chanelName)
        waitUntil(timeout: testTimeout) { done in
            subscriber.once(.attached) { _ in
                done()
            }
        }

        let publisher = rest.channels.get(chanelName)
        waitUntil(timeout: testTimeout) { done in
            subscriber.subscribe { message in
                XCTAssertEqual(message.clientId, expectedClientId)
                subscriber.unsubscribe()
                done()
            }
            publisher.publish("check clientId", data: nil, clientId: expectedClientId) { error in
                XCTAssertNil(error)
            }
        }
    }

    // RSL1m3
    func test__016__publish__Message_clientId__publishing_with_a_clientId_set_to_a_value_from_an_unidentified_client_should_result_in_a_message_received_with_the_clientId_property_set_to_that_value() {
        let expectedClientId = "client-rest"
        let options = AblyTests.commonAppSetup()
        let rest = ARTRest(options: options)
        let realtime = ARTRealtime(options: options)

        let chanelName = uniqueChannelName(prefix: "ch1")
        
        let subscriber = realtime.channels.get(chanelName)
        waitUntil(timeout: testTimeout) { done in
            subscriber.once(.attached) { _ in
                done()
            }
        }

        let publisher = rest.channels.get(chanelName)
        waitUntil(timeout: testTimeout) { done in
            subscriber.subscribe { message in
                XCTAssertEqual(message.clientId, expectedClientId)
                subscriber.unsubscribe()
                done()
            }
            publisher.publish("check clientId", data: nil, clientId: expectedClientId) { error in
                XCTAssertNil(error)
            }
        }
    }

    // RSL1m4
    func test__017__publish__Message_clientId__publishing_with_a_clientId_set_to_a_different_value_from_the_clientId_in_the_client_options_should_result_in_a_message_being_rejected_by_the_server() {
        let options = AblyTests.commonAppSetup()
        options.clientId = "client-rest"
        let rest = ARTRest(options: options)
        options.clientId = "client-realtime"
        let realtime = ARTRealtime(options: options)

        let chanelName = uniqueChannelName(prefix: "ch1")
        
        let subscriber = realtime.channels.get(chanelName)
        waitUntil(timeout: testTimeout) { done in
            subscriber.once(.attached) { _ in
                done()
            }
        }

        let publisher = rest.channels.get(chanelName)
        waitUntil(timeout: testTimeout) { done in
            subscriber.subscribe { _ in
                fail("Should not receive the message")
            }
            publisher.publish("check clientId", data: nil, clientId: "foo") { error in
                XCTAssertEqual(error?.code, Int(ARTState.mismatchedClientId.rawValue))
                done()
            }
        }
    }

    // https://github.com/ably/ably-cocoa/issues/1074 and related with RSL1m
    func test__001__publish__should_not_fail_sending_a_message_with_no_clientId_in_the_client_options_and_credentials_that_can_assume_any_clientId() {
        let options = AblyTests.clientOptions()
        options.authCallback = { _, callback in
            getTestTokenDetails(clientId: "*") { token, error in
                callback(token, error)
            }
        }

        let rest = ARTRest(options: options)
        let channel = rest.channels.get(uniqueChannelName(prefix: "issue-1074"))

        waitUntil(timeout: testTimeout) { done in
            // The first attempt encodes the message before requesting auth credentials so there's no clientId
            channel.publish("first message", data: nil) { error in
                XCTAssertNil(error)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.publish("second message", data: nil) { error in
                XCTAssertNil(error)
                done()
            }
        }
    }

    // RSL1h
    func test__002__publish__should_provide_an_optional_argument_that_allows_the_clientId_value_to_be_specified() {
        let options = AblyTests.commonAppSetup()
        options.clientId = "john"
        let client = ARTRest(options: options)
        let channel = client.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.publish("name", data: "some data", clientId: "tester") { error in
                expect(error!.message).to(contain("invalid clientId"))
                done()
            }
        }
    }

    // RSL1h, RSL6a2
    func test__003__publish__should_provide_an_optional_argument_that_allows_the_extras_value_to_be_specified() {
        let options = AblyTests.commonAppSetup()
        // Prevent channel name to be prefixed by test-*
        options.channelNamePrefix = nil
        let client = ARTRest(options: options)
        let channel = client.channels.get(uniqueChannelName(prefix: "pushenabled:test"))
        let extras = ["push": ["notification": ["title": "Hello from Ably!"]]] as ARTJsonCompatible

        XCTAssertTrue((client.internal.encoders["application/json"] as! ARTJsonLikeEncoder).message(from: [
            "data": "foo",
            "extras": ["push": ["notification": ["title": "Hello from Ably!"]]],
        ])?.extras == extras)

        waitUntil(timeout: testTimeout) { done in
            channel.publish("name", data: "some data", extras: extras) { error in
                if let error = error {
                    fail("unexpected error \(error)")
                    done(); return
                }

                let query = ARTDataQuery()
                query.limit = 1

                try! channel.history(query) { messages, error in
                    if let error = error {
                        fail("unexpected error \(error)")
                        done(); return
                    }
                    guard let message = messages?.items.first else {
                        fail("expected published message in history")
                        done(); return
                    }
                    XCTAssertTrue(message.extras == extras)
                    done()
                }
            }
        }
    }

    // RSL1i

    func test__018__publish__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__the_client_library_should_reject_the_publish_and_indicate_an_error() {
        let options = AblyTests.commonAppSetup()
        let client = ARTRest(options: options)
        let channel = client.channels.get(uniqueChannelName())
        let messages = buildMessagesThatExceedMaxMessageSize()

        waitUntil(timeout: testTimeout) { done in
            channel.publish(messages) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.maxMessageLengthExceeded.intValue)
                done()
            }
        }
    }

    func test__019__publish__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__also_when_using_publish_data_clientId_extras() {
        let options = AblyTests.commonAppSetup()
        let client = ARTRest(options: options)
        let channel = client.channels.get(uniqueChannelName())
        let name = buildStringThatExceedMaxMessageSize()

        waitUntil(timeout: testTimeout) { done in
            channel.publish(name, data: nil, extras: nil) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.maxMessageLengthExceeded.intValue)
                done()
            }
        }
    }

    // RSL1k

    // TO3n
    func test__020__publish__idempotent_publishing__idempotentRestPublishing_option() {
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "2"), true)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "2.0.0"), true)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.1"), false)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.1.2"), false)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.2"), true)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.2.2"), true)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.0"), false)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.0.5"), false)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "0.9"), false)
        XCTAssertEqual(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "0.9.1"), false)

        // Current version
        let options = AblyTests.clientOptions()
        XCTAssertEqual(options.idempotentRestPublishing, true)
    }

    // RSL1k1

    func test__027__publish__idempotent_publishing__random_idempotent_publish_id__should_generate_for_one_message_with_empty_id() {
        let message = ARTMessage(name: nil, data: "foo")
        XCTAssertNil(message.id)

        let rest = ARTRest(key: "xxxx:xxxx")
        rest.internal.options.idempotentRestPublishing = true
        let mockHTTPExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHTTPExecutor
        let channel = rest.channels.get(uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.publish([message]) { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
            fail("Body from the last request is empty"); return
        }

        let json = AblyTests.msgpackToJSON(encodedBody)
        assertMessagePayloadId(id: json.arrayValue.first?["id"].string, expectedSerial: "0")
        XCTAssertNil(message.id)
    }

    func test__028__publish__idempotent_publishing__random_idempotent_publish_id__should_generate_for_multiple_messages_with_empty_id() {
        let message1 = ARTMessage(name: nil, data: "foo1")
        XCTAssertNil(message1.id)
        let message2 = ARTMessage(name: "john", data: "foo2")
        XCTAssertNil(message2.id)

        let rest = ARTRest(key: "xxxx:xxxx")
        rest.internal.options.idempotentRestPublishing = true
        let mockHTTPExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHTTPExecutor
        let channel = rest.channels.get(uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.publish([message1, message2]) { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
            fail("Body from the last request is empty"); return
        }

        let json = AblyTests.msgpackToJSON(encodedBody)
        let id1 = json.arrayValue.first?["id"].string
        assertMessagePayloadId(id: id1, expectedSerial: "0")
        let id2 = json.arrayValue.last?["id"].string
        assertMessagePayloadId(id: id2, expectedSerial: "1")

        // Same Base ID
        XCTAssertEqual(id1?.split(separator: ":").first, id2?.split(separator: ":").first)
    }

    // RSL1k2
    func test__021__publish__idempotent_publishing__should_not_generate_for_message_with_a_non_empty_id() {
        let message = ARTMessage(name: nil, data: "foo")
        message.id = "123"

        let rest = ARTRest(key: "xxxx:xxxx")
        rest.internal.options.idempotentRestPublishing = true
        let mockHTTPExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHTTPExecutor
        let channel = rest.channels.get(uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.publish([message]) { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
            fail("Body from the last request is empty"); return
        }

        let json = AblyTests.msgpackToJSON(encodedBody)
        XCTAssertEqual(json.arrayValue.first?["id"].string, "123")
    }

    func test__022__publish__idempotent_publishing__should_generate_for_internal_message_that_is_created_in_publish_name_data___method() {
        let rest = ARTRest(key: "xxxx:xxxx")
        rest.internal.options.idempotentRestPublishing = true
        let mockHTTPExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHTTPExecutor
        let channel = rest.channels.get(uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.publish("john", data: "foo") { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
            fail("Body from the last request is empty"); return
        }

        let json = AblyTests.msgpackToJSON(encodedBody)
        assertMessagePayloadId(id: json["id"].string, expectedSerial: "0")
    }

    // RSL1k3
    func test__023__publish__idempotent_publishing__should_not_generate_for_multiple_messages_with_a_non_empty_id() {
        let message1 = ARTMessage(name: nil, data: "foo1")
        XCTAssertNil(message1.id)
        let message2 = ARTMessage(name: "john", data: "foo2")
        message2.id = "123"

        let rest = ARTRest(key: "xxxx:xxxx")
        rest.internal.options.idempotentRestPublishing = true
        let mockHTTPExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHTTPExecutor
        let channel = rest.channels.get(uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.publish([message1, message2]) { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
            fail("Body from the last request is empty"); return
        }

        let json = AblyTests.msgpackToJSON(encodedBody)
        XCTAssertNil(json.arrayValue.first?["id"].string)
        XCTAssertEqual(json.arrayValue.last?["id"].string, "123")
    }

    func test__024__publish__idempotent_publishing__should_not_generate_when_idempotentRestPublishing_flag_is_off() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.idempotentRestPublishing = false

        let message1 = ARTMessage(name: nil, data: "foo1")
        XCTAssertNil(message1.id)
        let message2 = ARTMessage(name: "john", data: "foo2")
        XCTAssertNil(message2.id)

        let rest = ARTRest(options: options)
        let mockHTTPExecutor = MockHTTPExecutor()
        rest.internal.httpExecutor = mockHTTPExecutor
        let channel = rest.channels.get(uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.publish([message1, message2]) { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
            fail("Body from the last request is empty"); return
        }

        let json = AblyTests.msgpackToJSON(encodedBody)
        XCTAssertNil(json.arrayValue.first?["id"].string)
        XCTAssertNil(json.arrayValue.last?["id"].string)
    }

    // RSL1k4
    @available(*, deprecated, message: "This test is marked as deprecated so as to not trigger a compiler warning for using the -ARTClientOptions.fallbackHostsUseDefault property. Remove this deprecation when removing the property.")
    func test__025__publish__idempotent_publishing__should_have_only_one_published_message() {
        client.internal.options.idempotentRestPublishing = true
        client.internal.httpExecutor = testHTTPExecutor
        client.internal.options.fallbackHostsUseDefault = true

        let forceRetryError = ErrorSimulator(
            value: ARTErrorCode.internalError.intValue,
            description: "force retry",
            statusCode: 500,
            shouldPerformRequest: true,
            stubData: nil
        )

        testHTTPExecutor.simulateIncomingServerErrorOnNextRequest(forceRetryError)

        let messages = [
            ARTMessage(name: nil, data: "test1"),
            ARTMessage(name: nil, data: "test2"),
            ARTMessage(name: nil, data: "test3"),
        ]

        let channel = client.channels.get(uniqueChannelName())
        
        waitUntil(timeout: testTimeout) { done in
            channel.publish(messages) { error in
                XCTAssertNotNil(error)
                done()
            }
        }

        XCTAssertEqual(testHTTPExecutor.requests.count, 2)

        waitUntil(timeout: testTimeout) { done in
            channel.history { result, error in
                XCTAssertNil(error)
                guard let result = result else {
                    fail("No result"); done(); return
                }
                XCTAssertEqual(result.items.count, 3)
                done()
            }
        }
    }

    // RSL1k5
    func test__026__publish__idempotent_publishing__should_publish_a_message_with_implicit_Id_only_once() {
        let options = AblyTests.commonAppSetup()
        let rest = ARTRest(options: options)
        rest.internal.options.idempotentRestPublishing = true
        let channel = rest.channels.get(uniqueChannelName())

        let message = ARTMessage(name: "unique", data: "foo")
        message.id = "123"

        for _ in 1 ... 4 {
            waitUntil(timeout: testTimeout) { done in
                channel.publish([message]) { error in
                    XCTAssertNil(error)
                    done()
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.history { result, error in
                XCTAssertNil(error)
                guard let result = result else {
                    fail("No result"); done(); return
                }
                XCTAssertEqual(result.items.count, 1)
                XCTAssertEqual(result.items.first?.id, "123")
                done()
            }
        }
    }

    // RSL1j
    func test__004__publish__should_include_attributes_supplied_by_the_caller_in_the_encoded_message() {
        let options = AblyTests.commonAppSetup()
        let client = ARTRest(options: options)
        let proxyHTTPExecutor = TestProxyHTTPExecutor(mockLogHandler)
        client.internal.httpExecutor = proxyHTTPExecutor

        let channel = client.channels.get(uniqueChannelName())
        let message = ARTMessage(name: nil, data: "")
        message.id = "123"
        message.name = "tester"

        waitUntil(timeout: testTimeout) { done in
            channel.publish([message]) { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let encodedBody = proxyHTTPExecutor.requests.last?.httpBody else {
            fail("Body from the last request is empty"); return
        }

        guard let jsonMessage = AblyTests.msgpackToJSON(encodedBody).array?.first else {
            fail("Body from the last request is invalid"); return
        }
        XCTAssertEqual(jsonMessage["name"].string, "tester")
        XCTAssertEqual(jsonMessage["data"].string, "")
        XCTAssertEqual(jsonMessage["id"].string, message.id)
    }

    // RSL2

    // RSL2a
    func test__029__history__should_return_a_PaginatedResult_page_containing_the_first_page_of_messages() {
        let client = ARTRest(options: AblyTests.commonAppSetup())
        let channel = client.channels.get(uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.publish([
                .init(name: nil, data: "m1"),
                .init(name: nil, data: "m2"),
                .init(name: nil, data: "m3"),
                .init(name: nil, data: "m4"),
                .init(name: nil, data: "m5"),
            ],
            callback: { error in
                XCTAssertNil(error)
                done()
            })
        }

        let query = ARTDataQuery()
        query.direction = .forwards
        query.limit = 2

        try! channel.history(query) { result, error in
            guard let result = result else {
                fail("Result is empty"); return
            }
            XCTAssertNil(error)
            XCTAssertTrue(result.hasNext)
            XCTAssertFalse(result.isLast)
            XCTAssertEqual(result.items.count, 2)
            let items = result.items.compactMap { $0.data as? String }
            XCTAssertEqual(items.first, "m1")
            XCTAssertEqual(items.last, "m2")

            result.next { result, error in
                guard let result = result else {
                    fail("Result is empty"); return
                }
                XCTAssertNil(error)
                XCTAssertTrue(result.hasNext)
                XCTAssertFalse(result.isLast)
                XCTAssertEqual(result.items.count, 2)
                let items = result.items.compactMap { $0.data as? String }
                XCTAssertEqual(items.first, "m3")
                XCTAssertEqual(items.last, "m4")

                result.next { result, error in
                    guard let result = result else {
                        fail("Result is empty"); return
                    }
                    XCTAssertNil(error)
                    XCTAssertFalse(result.hasNext)
                    XCTAssertTrue(result.isLast)
                    XCTAssertEqual(result.items.count, 1)
                    let items = result.items.compactMap { $0.data as? String }
                    XCTAssertEqual(items.first, "m5")

                    result.first { result, error in
                        guard let result = result else {
                            fail("Result is empty"); return
                        }
                        XCTAssertNil(error)
                        XCTAssertTrue(result.hasNext)
                        XCTAssertFalse(result.isLast)
                        XCTAssertEqual(result.items.count, 2)
                        let items = result.items.compactMap { $0.data as? String }
                        XCTAssertEqual(items.first, "m1")
                        XCTAssertEqual(items.last, "m2")
                    }
                }
            }
        }
    }

    // RSL2b

    // RSL2b1
    func test__030__history__query_arguments__start_and_end_should_filter_messages_between_those_two_times() {
        let client = ARTRest(options: AblyTests.commonAppSetup())
        let channel = client.channels.get(uniqueChannelName())

        let query = ARTDataQuery()
        XCTAssertEqual(query.direction, ARTQueryDirection.backwards)
        XCTAssertEqual(query.limit, 100)

        waitUntil(timeout: testTimeout) { done in
            client.time { time, _ in
                query.start = time
                done()
            }
        }

        let messages = [
            ARTMessage(name: nil, data: "message1"),
            ARTMessage(name: nil, data: "message2"),
        ]
        waitUntil(timeout: testTimeout) { done in
            channel.publish(messages) { _ in
                client.time { time, _ in
                    query.end = time
                    done()
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            delay(0.2) {
                channel.publish(nil, data: "message3") { _ in
                    done()
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            try! channel.history(query) { result, error in
                XCTAssertNil(error)
                guard let result = result else {
                    fail("PaginatedResult is empty"); done()
                    return
                }
                XCTAssertFalse(result.hasNext)
                XCTAssertTrue(result.isLast)
                let items = result.items
                if items.count != 2 {
                    fail("PaginatedResult has no items"); done()
                    return
                }
                let messageItems = items.compactMap { $0.data as? String }
                XCTAssertEqual(messageItems.first, "message2")
                XCTAssertEqual(messageItems.last, "message1")
                done()
            }
        }
    }

    // RSL2b1
    func test__031__history__query_arguments__start_must_be_equal_to_or_less_than_end_and_is_unaffected_by_the_request_direction() {
        let client = ARTRest(options: AblyTests.commonAppSetup())
        let channel = client.channels.get(uniqueChannelName())

        let query = ARTDataQuery()
        query.direction = .backwards
        query.end = NSDate() as Date
        query.start = query.end!.addingTimeInterval(10.0)

        expect { try channel.history(query) { _, _ in } }.to(throwError { (error: Error) in
            XCTAssertEqual(error._code, ARTDataQueryError.timestampRange.rawValue)
        })

        query.direction = .forwards

        expect { try channel.history(query) { _, _ in } }.to(throwError { (error: Error) in
            XCTAssertEqual(error._code, ARTDataQueryError.timestampRange.rawValue)
        })
    }

    // RSL2b2
    func test__032__history__query_arguments__direction_backwards_or_forwards() {
        let client = ARTRest(options: AblyTests.commonAppSetup())
        let channel = client.channels.get(uniqueChannelName())

        let query = ARTDataQuery()
        XCTAssertEqual(query.direction, ARTQueryDirection.backwards)
        query.direction = .forwards

        let messages = [
            ARTMessage(name: nil, data: "message1"),
            ARTMessage(name: nil, data: "message2"),
        ]
        waitUntil(timeout: testTimeout) { done in
            channel.publish(messages) { _ in
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            try! channel.history(query) { result, error in
                XCTAssertNil(error)
                guard let result = result else {
                    fail("PaginatedResult is empty"); done()
                    return
                }
                XCTAssertFalse(result.hasNext)
                XCTAssertTrue(result.isLast)
                let items = result.items
                if items.count != 2 {
                    fail("PaginatedResult has no items"); done()
                    return
                }
                let messageItems = items.compactMap { $0.data as? String }
                XCTAssertEqual(messageItems.first, "message1")
                XCTAssertEqual(messageItems.last, "message2")
                done()
            }
        }
    }

    // RSL2b3
    func test__033__history__query_arguments__limit_items_result() {
        let client = ARTRest(options: AblyTests.commonAppSetup())
        let channel = client.channels.get(uniqueChannelName())

        let query = ARTDataQuery()
        XCTAssertEqual(query.limit, 100)
        query.limit = 2

        let messages = (1 ... 10).compactMap { ARTMessage(name: nil, data: "message\($0)") }
        waitUntil(timeout: testTimeout) { done in
            channel.publish(messages) { _ in
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            try! channel.history(query) { result, error in
                XCTAssertNil(error)
                guard let result = result else {
                    fail("PaginatedResult is empty"); done()
                    return
                }
                XCTAssertTrue(result.hasNext)
                XCTAssertFalse(result.isLast)
                let items = result.items
                if items.count != 2 {
                    fail("PaginatedResult has no items"); done()
                    return
                }
                let messageItems = items.compactMap { $0.data as? String }
                XCTAssertEqual(messageItems.first, "message10")
                XCTAssertEqual(messageItems.last, "message9")
                done()
            }
        }
    }

    // RSL2b3
    func test__034__history__query_arguments__limit_supports_up_to_1000_items() {
        let client = ARTRest(options: AblyTests.commonAppSetup())
        let channel = client.channels.get(uniqueChannelName())

        let query = ARTDataQuery()
        XCTAssertEqual(query.limit, 100)

        query.limit = 1001
        expect { try channel.history(query, callback: { _, _ in }) }.to(throwError())

        query.limit = 1000
        expect { try channel.history(query, callback: { _, _ in }) }.toNot(throwError())
    }

    // RSL3, RSP1

    // RSP3

    func skipped__test__035__presence__get__should_return_presence_fixture_data() {
        let options = AblyTests.commonAppSetup()
        options.channelNamePrefix = nil
        client = ARTRest(options: options)
        let key = appSetupJson["cipher"]["key"].string!
        let cipherParams = ARTCipherParams(
            algorithm: appSetupJson["cipher"]["algorithm"].string!,
            key: key as ARTCipherKeyCompatible,
            iv: Data(base64Encoded: appSetupJson["cipher"]["iv"].string!, options: Data.Base64DecodingOptions(rawValue: 0))!
        )
        let channel = client.channels.get("persisted:presence_fixtures", options: ARTChannelOptions(cipher: cipherParams))
        var presenceMessages: [ARTPresenceMessage] = []

        channel.presence.get { result, _ in
            if let items = result?.items {
                presenceMessages.append(contentsOf: items)
            } else {
                fail("expected items to not be empty")
            }
        }

        expect(presenceMessages.count).toEventually(equal(presenceFixtures.count), timeout: testTimeout)
        for message in presenceMessages {
            let fixtureMessage = presenceFixtures.filter { _, value -> Bool in
                message.clientId == value["clientId"].stringValue
            }.first!.1

            XCTAssertNotNil(message.data)
            XCTAssertEqual(message.action, ARTPresenceAction.present)

            let encodedFixture = channel.internal.dataEncoder.decode(
                fixtureMessage["data"].object,
                encoding: fixtureMessage.asDictionary!["encoding"] as? String
            )
            XCTAssertEqual(message.data as? NSObject, encodedFixture.data as? NSObject)
        }
    }

    // RSL4

    // RSL4a
    func test__036__message_encoding__payloads_should_be_binary__strings__or_objects_capable_of_JSON_representation() {
        let validCases: [TestCase]
        if #available(iOS 11.0, *) {
            validCases = [
                TestCase(value: nil, expected: JSON([:])),
                TestCase(value: text, expected: JSON(["data": text])),
                TestCase(value: integer, expected: JSON(["data": integer])),
                TestCase(value: decimal, expected: JSON(["data": decimal])),
                TestCase(value: dictionary, expected: ["data": JSON(dictionary).rawString(options: [.sortedKeys])!, "encoding": "json"] as JSON),
                TestCase(value: array, expected: JSON(["data": JSON(array).rawString(options: [.sortedKeys])!, "encoding": "json"])),
                TestCase(value: binaryData, expected: JSON(["data": binaryData.toBase64, "encoding": "base64"])),
            ]
        } else {
            validCases = [
                TestCase(value: nil, expected: JSON([:])),
                TestCase(value: text, expected: JSON(["data": text])),
                TestCase(value: integer, expected: JSON(["data": integer])),
                TestCase(value: decimal, expected: JSON(["data": decimal])),
                TestCase(value: dictionary, expected: ["data": JSON(dictionary).rawString()!, "encoding": "json"] as JSON),
                TestCase(value: array, expected: JSON(["data": JSON(array).rawString()!, "encoding": "json"])),
                TestCase(value: binaryData, expected: JSON(["data": binaryData.toBase64, "encoding": "base64"])),
            ]
        }

        client.internal.options.idempotentRestPublishing = false
        client.internal.httpExecutor = testHTTPExecutor

        let channel = client.channels.get(uniqueChannelName())
        
        validCases.forEach { caseTest in
            waitUntil(timeout: testTimeout) { done in
                channel.publish(nil, data: caseTest.value) { error in
                    XCTAssertNil(error)
                    guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                        XCTFail("HTTPBody is nil")
                        done(); return
                    }
                    var json = AblyTests.msgpackToJSON(httpBody)
                    if let s = json["data"].string, let data = try? JSONSerialization.jsonObject(with: s.data(using: .utf8)!) {
                        // Make sure the formatting is the same by parsing
                        // and reformatting in the same way as the test case.
                        if #available(iOS 11.0, *) {
                            json["data"] = JSON(JSON(data).rawString(options: [.sortedKeys])!)
                        } else {
                            json["data"] = JSON(JSON(data).rawString()!)
                        }
                    }
                    let mergedWithExpectedJSON = try! json.merged(with: caseTest.expected)
                    XCTAssertEqual(json, mergedWithExpectedJSON)
                    done()
                }
            }
        }

        let invalidCases = [5, 56.33, NSDate()] as [Any]

        invalidCases.forEach { caseItem in
            waitUntil(timeout: testTimeout) { done in
                expect { channel.publish(nil, data: caseItem, callback: nil) }.toNot(raiseException())
                done()
            }
        }
    }

    // RSL4b
    func test__037__message_encoding__encoding_attribute_should_represent_the_encoding_s__applied_in_right_to_left() {
        let encodingCases = [
            TestCase(value: text, expected: JSON.null),
            TestCase(value: dictionary, expected: "json"),
            TestCase(value: array, expected: "json"),
            TestCase(value: binaryData, expected: "base64"),
        ]

        client.internal.httpExecutor = testHTTPExecutor

        let channel = client.channels.get(uniqueChannelName())
        
        encodingCases.forEach { caseItem in
            waitUntil(timeout: testTimeout) { done in
                channel.publish(nil, data: caseItem.value, callback: { error in
                    XCTAssertNil(error)
                    guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                        XCTFail("HTTPBody is nil")
                        done(); return
                    }
                    XCTAssertEqual(AblyTests.msgpackToJSON(httpBody)["encoding"], caseItem.expected)
                    done()
                })
            }
        }
    }

    // RSL4d1
    func test__038__message_encoding__json__binary_payload_should_be_encoded_as_Base64_and_represented_as_a_JSON_string() {
        client.internal.httpExecutor = testHTTPExecutor
        
        let channel = client.channels.get(uniqueChannelName())
        
        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: binaryData, callback: { error in
                XCTAssertNil(error)
                guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                    XCTFail("HTTPBody is nil")
                    done(); return
                }
                // Binary
                let json = AblyTests.msgpackToJSON(httpBody)
                XCTAssertEqual(json["data"].string, binaryData.toBase64)
                XCTAssertEqual(json["encoding"], "base64")
                done()
            })
        }
    }

    // RSL4d
    func test__039__message_encoding__json__string_payload_should_be_represented_as_a_JSON_string() {
        client.internal.httpExecutor = testHTTPExecutor
        
        let channel = client.channels.get(uniqueChannelName())
        
        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: text, callback: { error in
                XCTAssertNil(error)

                if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                    // String (UTF-8)
                    let json = AblyTests.msgpackToJSON(http)
                    XCTAssertEqual(json["data"].string, text)
                    XCTAssertNil(json["encoding"].string)
                } else {
                    XCTFail("No request or HTTP body found")
                }
                done()
            })
        }
    }

    // RSL4d3

    func test__041__message_encoding__json__json_payload_should_be_stringified_either__as_a_JSON_Array() {
        client.internal.httpExecutor = testHTTPExecutor
        
        let channel = client.channels.get(uniqueChannelName())
        
        // JSON Array
        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: array, callback: { error in
                XCTAssertNil(error)

                if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                    // Array
                    let json = AblyTests.msgpackToJSON(http)
                    XCTAssertEqual(try! JSON(data: json["data"].stringValue.data(using: .utf8)!).asArray, array as NSArray?)
                    XCTAssertEqual(json["encoding"].string, "json")
                } else {
                    XCTFail("No request or HTTP body found")
                }
                done()
            })
        }
    }

    func test__042__message_encoding__json__json_payload_should_be_stringified_either__as_a_JSON_Object() {
        client.internal.httpExecutor = testHTTPExecutor
        
        let channel = client.channels.get(uniqueChannelName())
        
        // JSON Object
        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: dictionary, callback: { error in
                XCTAssertNil(error)

                if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                    // Dictionary
                    let json = AblyTests.msgpackToJSON(http)
                    XCTAssertEqual(try! JSON(data: json["data"].stringValue.data(using: .utf8)!).asDictionary, dictionary as NSDictionary?)
                    XCTAssertEqual(json["encoding"].string, "json")
                } else {
                    XCTFail("No request or HTTP body found")
                }
                done()
            })
        }
    }

    // RSL4d4
    func test__040__message_encoding__json__messages_received_should_be_decoded_based_on_the_encoding_field() {
        let cases = [text, integer, decimal, dictionary, array, binaryData] as [Any]

        let channel = client.channels.get(uniqueChannelName())
        
        cases.forEach { caseTest in
            waitUntil(timeout: testTimeout) { done in
                channel.publish(nil, data: caseTest, callback: { error in
                    XCTAssertNil(error)
                    done()
                })
            }
        }

        var totalReceived = 0
        channel.history { result, error in
            XCTAssertNil(error)
            guard let result = result else {
                XCTFail("Result is nil")
                return
            }
            XCTAssertFalse(result.hasNext)

            for (index, item) in result.items.reversed().enumerated() {
                totalReceived += 1

                switch item.data {
                case let value as NSDictionary:
                    XCTAssertEqual(value, cases[index] as? NSDictionary)
                case let value as NSArray:
                    XCTAssertEqual(value, cases[index] as? NSArray)
                case let value as NSData:
                    XCTAssertEqual(value, cases[index] as? NSData)
                case let value as NSString:
                    XCTAssertEqual(value, cases[index] as? NSString)
                default:
                    XCTFail("Payload with unknown format")
                }
            }
        }
        expect(totalReceived).toEventually(equal(cases.count), timeout: testTimeout)
    }

    // RSL5

    // RSL5b

    func test__043__message_payload_encryption__should_support_AES_encryption__128_CBC_mode() {
        testSupportsAESEncryptionWithKeyLength(128, channelName: uniqueChannelName())
    }

    func test__044__message_payload_encryption__should_support_AES_encryption__256_CBC_mode() {
        testSupportsAESEncryptionWithKeyLength(256, channelName: uniqueChannelName())
    }

    // RSL6

    // RSL6b
    func test__045__message_decoding__should_deliver_with_a_binary_payload_when_the_payload_was_successfully_decoded_but_it_could_not_be_decrypted() {
        let options = AblyTests.commonAppSetup()
        let clientEncrypted = ARTRest(options: options)

        let channelName = uniqueChannelName()
        let channelOptions = ARTChannelOptions(cipher: ["key": ARTCrypto.generateRandomKey()] as ARTCipherParamsCompatible)
        let channelEncrypted = clientEncrypted.channels.get(channelName, options: channelOptions)

        let expectedMessage = ["something": 1]

        waitUntil(timeout: testTimeout) { done in
            channelEncrypted.publish(nil, data: expectedMessage) { _ in
                done()
            }
        }

        let client = ARTRest(options: options)
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel.history { result, error in
                XCTAssertNil(error)
                guard let result = result else {
                    fail("Result is empty"); done(); return
                }
                guard let message = result.items.first else {
                    fail("First item does not exist"); done(); return
                }
                XCTAssertTrue(message.data is NSData)
                XCTAssertEqual(message.encoding, "json/utf-8/cipher+aes-256-cbc")
                done()
            }
        }
    }

    // RSL6b
    func test__046__message_decoding__should_deliver_with_encoding_attribute_set_indicating_the_residual_encoding_and_error_should_be_emitted() {
        let options = AblyTests.commonAppSetup()
        options.useBinaryProtocol = false
        options.logHandler = ARTLog(capturingOutput: true)
        let client = ARTRest(options: options)
        let channelOptions = ARTChannelOptions(cipher: ["key": ARTCrypto.generateRandomKey()] as ARTCipherParamsCompatible)
        let channel = client.channels.get(uniqueChannelName(), options: channelOptions)
        client.internal.httpExecutor = testHTTPExecutor

        let expectedMessage = ["something": 1]
        let expectedData = try! JSONSerialization.data(withJSONObject: expectedMessage, options: JSONSerialization.WritingOptions(rawValue: 0))

        testHTTPExecutor.setListenerProcessingDataResponse { data in
            let dataStr = String(data: data!, encoding: String.Encoding.utf8)!
            return dataStr.replace("json/utf-8", withString: "invalid").data(using: String.Encoding.utf8)!
        }

        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: expectedMessage) { _ in
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.history { result, error in
                XCTAssertNil(error)
                guard let result = result else {
                    fail("Result is empty"); done(); return
                }
                guard let message = result.items.first else {
                    fail("First item does not exist"); done(); return
                }
                XCTAssertEqual(message.data as? NSData, expectedData as NSData?)
                XCTAssertEqual(message.encoding, "invalid")

                let logs = options.logHandler.captured
                let line = logs.reduce("") { $0 + "; " + $1.toString() } // Reduce in one line
                expect(line).to(contain("Failed to decode data: unknown encoding: 'invalid'"))
                done()
            }
        }
    }
    
    // RSL8a, CHD2b, CHS2b, CHO2a
    func test__047__status__with_subscribers__returns_a_channel_details_object_populated_with_channel_metrics() {
        let options = AblyTests.commonAppSetup()
        options.clientId = "Client 1"
        let rest = ARTRest(options: options)
        let realtime = ARTRealtime(options: options)
        let channelName = uniqueChannelName()
        let realtimeChannel = realtime.channels.get(channelName)
        let restChannel = rest.channels.get(channelName)
        
        waitUntil(timeout: testTimeout) { done in
            realtimeChannel.presence.enter(nil) { error in
                XCTAssertNil(error)
                done()
            }
        }
        waitUntil(timeout: testTimeout) { done in
            restChannel.status { details, error in
                XCTAssertNil(error)
                guard let details = details else {
                    fail("Channel details are empty"); done()
                    return
                }
                XCTAssertEqual(details.status.occupancy.metrics.connections, 1) // CHM2a
                XCTAssertEqual(details.status.occupancy.metrics.publishers, 1) // CHM2e
                XCTAssertEqual(details.status.occupancy.metrics.subscribers, 1) // CHM2f
                XCTAssertEqual(details.status.occupancy.metrics.presenceMembers, 1) // CHM2c
                XCTAssertEqual(details.status.occupancy.metrics.presenceConnections, 1) // CHM2b
                XCTAssertEqual(details.status.occupancy.metrics.presenceSubscribers, 1) // CHM2d
                done()
            }
        }
    }
    
    func test__48__channel_name_can_contain_slash_character_which_is_url_encoded_in_the_rest_request_path() throws {
        client.internal.httpExecutor = testHTTPExecutor
        let channel = client.channels.get(uniqueChannelName(prefix: "beforeSlash/afterSlash"))
        
        channel.publish(nil, data: nil)
        
        let url = try XCTUnwrap(testHTTPExecutor.requests.first?.url)
        let urlEncodedChannelName = try XCTUnwrap(channel.name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed))

        XCTAssert(channel.name.contains("/"))
        XCTAssertFalse(urlEncodedChannelName.contains("/"))
        XCTAssert(url.absoluteString.contains(urlEncodedChannelName))
    }
}
