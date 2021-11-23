import Ably
import Nimble
import Quick
import Foundation
import SwiftyJSON
        private var client: ARTRest!
        private var channel: ARTRestChannel!
        private var testHTTPExecutor: TestProxyHTTPExecutor!
                private let channelName = "test-message-size"

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

                    expect(baseIdData.bytes.count) == 9
                    expect(serial).to(equal(expectedSerial))
                }
            private let presenceFixtures = appSetupJson["post_apps"]["channels"][0]["presence"]

            private let text = "John"
            private let integer = "5"
            private let decimal = "65.33"
            private let dictionary = ["number": 3, "name": "John"] as [String : Any]
            private let array = ["John", "Mary"]
            private let binaryData = "123456".data(using: .utf8)!

                private func testSupportsAESEncryptionWithKeyLength(_ encryptionKeyLength: UInt) {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    client.internal.httpExecutor = testHTTPExecutor
                    
                    let params: ARTCipherParams = ARTCrypto.getDefaultParams([
                        "key": ARTCrypto.generateRandomKey(encryptionKeyLength)
                    ])
                    expect(params.algorithm).to(equal("AES"))
                    expect(params.keyLength).to(equal(encryptionKeyLength))
                    expect(params.mode).to(equal("CBC"))
                    
                    let channelOptions = ARTChannelOptions(cipher: params)
                    let channel = client.channels.get("test", options: channelOptions)
                    
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish("test", data: "message1") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                    
                    guard let httpBody = testHTTPExecutor.requests.last?.httpBody else {
                        fail("HTTPBody is empty")
                        return
                    }
                    let httpBodyAsJSON = AblyTests.msgpackToJSON(httpBody)
                    expect(httpBodyAsJSON["encoding"].string).to(equal("utf-8/cipher+aes-\(encryptionKeyLength)-cbc/base64"))
                    expect(httpBodyAsJSON["name"].string).to(equal("test"))
                    expect(httpBodyAsJSON["data"].string).toNot(equal("message1"))
                    
                    waitUntil(timeout: testTimeout) { done in
                        channel.history { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("PaginatedResult is empty"); done()
                                return
                            }
                            expect(result.hasNext).to(beFalse())
                            expect(result.isLast).to(beTrue())
                            let items = result.items
                            if result.items.isEmpty {
                                fail("PaginatedResult has no items"); done()
                                return
                            }
                            expect(items[0].name).to(equal("test"))
                            expect(items[0].data as? String).to(equal("message1"))
                            done()
                        }
                    }
                }

class RestClientChannel: XCTestCase {

override class var defaultTestSuite : XCTestSuite {
    let _ = client
    let _ = channel
    let _ = testHTTPExecutor
    let _ = channelName
    let _ = presenceFixtures
    let _ = text
    let _ = integer
    let _ = decimal
    let _ = dictionary
    let _ = array
    let _ = binaryData

    return super.defaultTestSuite
}


        func beforeEach() {
print("START HOOK: RestClientChannel.beforeEach")

            let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
            client = ARTRest(options: options)
            channel = client.channels.get(ProcessInfo.processInfo.globallyUniqueString)
            testHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
print("END HOOK: RestClientChannel.beforeEach")

        }

        // RSL1
        
            struct PublishArgs {
                static let name = "foo"
                static let data = "bar"
            }

            // RSL1b
            
                func test__005__publish__with_name_and_data_arguments__publishes_the_message_and_invokes_callback_with_success() {
beforeEach()

                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

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
beforeEach()

                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "io.ably.XCTest", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

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
beforeEach()

                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

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
beforeEach()

                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: nil) { error in
                            publishError = error
                            channel.history { result, _ in
                                publishedMessage = result?.items.first
                                done()
                            }
                        }
                    }

                    expect(publishError).to(beNil())
                    expect(publishedMessage?.name).to(beNil())
                    expect(publishedMessage?.data).to(beNil())
                }

            
                func test__009__publish__with_a_Message_object__publishes_the_message_and_invokes_callback_with_success() {
beforeEach()

                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish([ARTMessage(name: PublishArgs.name, data: PublishArgs.data)]) { error in
                            publishError = error
                            channel.history { result, _ in
                                publishedMessage = result?.items.first
                                done()
                            }
                        }
                    }

                    expect(publishError).to(beNil())
                    expect(publishedMessage?.name).to(equal(PublishArgs.name))
                    expect(publishedMessage?.data as? String).to(equal(PublishArgs.data))
                }

            // RSL1c
            
                func test__010__publish__with_an_array_of_Message_objects__publishes_the_messages_in_a_single_request_and_invokes_callback_with_success() {
beforeEach()

                    let oldExecutor = client.internal.httpExecutor
                    defer { client.internal.httpExecutor = oldExecutor}
                    client.internal.httpExecutor = testHTTPExecutor

                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessages: [ARTMessage] = []

                    let messages = [
                        ARTMessage(name: "bar", data: "foo"),
                        ARTMessage(name: "bat", data: "baz")
                    ]
                    channel.publish(messages) { error in
                        publishError = error
                        client.internal.httpExecutor = oldExecutor
                        channel.history { result, _ in
                            if let items = result?.items {
                                publishedMessages.append(contentsOf:items)
                            }
                        }
                    }

                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessages.count).toEventually(equal(messages.count), timeout: testTimeout)
                    for (i, publishedMessage) in publishedMessages.reversed().enumerated() {
                        expect(publishedMessage.data as? NSObject).to(equal(messages[i].data as? NSObject))
                        expect(publishedMessage.name).to(equal(messages[i].name))
                    }
                    expect(testHTTPExecutor.requests.count).to(equal(1))
                }

            // RSL1f
            
                // RSL1f1
                func test__011__publish__Unidentified_clients_using_Basic_Auth__should_publish_message_with_the_provided_clientId() {
beforeEach()

                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish([ARTMessage(name: nil, data: "message", clientId: "tester")]) { error in
                            expect(error).to(beNil())
                            expect(client.auth.internal.method).to(equal(ARTAuthMethod.basic))
                            channel.history { page, error in
                                expect(error).to(beNil())
                                guard let page = page else {
                                    fail("Page is empty"); done(); return
                                }
                                guard let item = page.items.first else {
                                    fail("First item does not exist"); done(); return
                                }
                                expect(item.clientId).to(equal("tester"))
                                done()
                            }
                        }
                    }
                }

            // RSA7e
            

                // RSA7e1
                func test__012__publish__ClientOptions_clientId__should_include_the_clientId_as_a_querystring_parameter_in_realtime_connection_requests() {
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john-doe"
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        client.channels.get("RSA7e1")
                            .publish(nil, data: "foo") { error in
                                expect(error).to(beNil())
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
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john-doe"
                    let client = ARTRest(options: options)
                    testHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
                    client.internal.httpExecutor = testHTTPExecutor
                    waitUntil(timeout: testTimeout) { done in
                        client.channels.get("RSA7e1")
                            .publish(nil, data: "foo") { error in
                                expect(error).to(beNil())
                                guard let request = testHTTPExecutor.requests.first else {
                                    fail("No request found")
                                    return
                                }
                                let clientIdBase64Encoded = options.clientId?
                                    .data(using: .utf8)?
                                    .base64EncodedString()
                                expect(request.allHTTPHeaderFields?["X-Ably-ClientId"]).to(equal(clientIdBase64Encoded))
                                done()
                            }
                    }
                }

            // RSL1m
            

                // RSL1m1
                func test__014__publish__Message_clientId__publishing_with_no_clientId_when_the_clientId_is_set_to_some_value_in_the_client_options_should_result_in_a_message_received_with_the_clientId_property_set_to_that_value() {
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client-rest"
                    let expectedClientId = options.clientId
                    let rest = ARTRest(options: options)
                    options.clientId = "client-realtime"
                    let realtime = ARTRealtime(options: options)

                    let subscriber = realtime.channels.get("ch1")
                    waitUntil(timeout: testTimeout) { done in
                        subscriber.once(.attached) { _ in
                            done()
                        }
                    }

                    let publisher = rest.channels.get("ch1")
                    waitUntil(timeout: testTimeout) { done in
                        subscriber.subscribe { message in
                            expect(message.clientId).to(equal(expectedClientId))
                            subscriber.unsubscribe()
                            done()
                        }
                        publisher.publish("check clientId", data: nil) { error in
                            expect(error).to(beNil())
                        }
                    }
                }

                // RSL1m2
                func test__015__publish__Message_clientId__publishing_with_a_clientId_set_to_the_same_value_as_the_clientId_in_the_client_options_should_result_in_a_message_received_with_the_clientId_property_set_to_that_value() {
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client-rest"
                    let expectedClientId = options.clientId!
                    let rest = ARTRest(options: options)
                    options.clientId = "client-realtime"
                    let realtime = ARTRealtime(options: options)

                    let subscriber = realtime.channels.get("ch1")
                    waitUntil(timeout: testTimeout) { done in
                        subscriber.once(.attached) { _ in
                            done()
                        }
                    }

                    let publisher = rest.channels.get("ch1")
                    waitUntil(timeout: testTimeout) { done in
                        subscriber.subscribe { message in
                            expect(message.clientId).to(equal(expectedClientId))
                            subscriber.unsubscribe()
                            done()
                        }
                        publisher.publish("check clientId", data: nil, clientId: expectedClientId) { error in
                            expect(error).to(beNil())
                        }
                    }
                }

                // RSL1m3
                func test__016__publish__Message_clientId__publishing_with_a_clientId_set_to_a_value_from_an_unidentified_client_should_result_in_a_message_received_with_the_clientId_property_set_to_that_value() {
beforeEach()

                    let expectedClientId = "client-rest"
                    let options = AblyTests.commonAppSetup()
                    let rest = ARTRest(options: options)
                    let realtime = ARTRealtime(options: options)

                    let subscriber = realtime.channels.get("ch1")
                    waitUntil(timeout: testTimeout) { done in
                        subscriber.once(.attached) { _ in
                            done()
                        }
                    }

                    let publisher = rest.channels.get("ch1")
                    waitUntil(timeout: testTimeout) { done in
                        subscriber.subscribe { message in
                            expect(message.clientId).to(equal(expectedClientId))
                            subscriber.unsubscribe()
                            done()
                        }
                        publisher.publish("check clientId", data: nil, clientId: expectedClientId) { error in
                            expect(error).to(beNil())
                        }
                    }
                }

                // RSL1m4
                func test__017__publish__Message_clientId__publishing_with_a_clientId_set_to_a_different_value_from_the_clientId_in_the_client_options_should_result_in_a_message_being_rejected_by_the_server() {
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client-rest"
                    let rest = ARTRest(options: options)
                    options.clientId = "client-realtime"
                    let realtime = ARTRealtime(options: options)

                    let subscriber = realtime.channels.get("ch1")
                    waitUntil(timeout: testTimeout) { done in
                        subscriber.once(.attached) { _ in
                            done()
                        }
                    }

                    let publisher = rest.channels.get("ch1")
                    waitUntil(timeout: testTimeout) { done in
                        subscriber.subscribe { message in
                            fail("Should not receive the message")
                        }
                        publisher.publish("check clientId", data: nil, clientId: "foo") { error in
                            expect(error?.code).to(equal(Int(ARTState.mismatchedClientId.rawValue)))
                            done()
                        }
                    }
                }

            // https://github.com/ably/ably-cocoa/issues/1074 and related with RSL1m
            func test__001__publish__should_not_fail_sending_a_message_with_no_clientId_in_the_client_options_and_credentials_that_can_assume_any_clientId() {
beforeEach()

                let options = AblyTests.clientOptions()
                options.authCallback = { _, callback in
                    getTestTokenDetails(clientId: "*") { token, error in
                        callback(token, error)
                    }
                }

                let rest = ARTRest(options: options)
                let channel = rest.channels.get("#1074")

                waitUntil(timeout: testTimeout) { done in
                    // The first attempt encodes the message before requesting auth credentials so there's no clientId
                    channel.publish("first message", data: nil) { error in
                        expect(error).to(beNil())
                        done()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.publish("second message", data: nil) { error in
                        expect(error).to(beNil())
                        done()
                    }
                }
            }

            // RSL1h
            func test__002__publish__should_provide_an_optional_argument_that_allows_the_clientId_value_to_be_specified() {
beforeEach()

                let options = AblyTests.commonAppSetup()
                options.clientId = "john"
                let client = ARTRest(options: options)
                let channel = client.channels.get("test")
                waitUntil(timeout: testTimeout) { done in
                    channel.publish("name", data: "some data", clientId: "tester") { error in
                        expect(error!.message).to(contain("invalid clientId"))
                        done()
                    }
                }
            }

            // RSL1h, RSL6a2
            func test__003__publish__should_provide_an_optional_argument_that_allows_the_extras_value_to_be_specified() {
beforeEach()

                let options = AblyTests.commonAppSetup()
                // Prevent channel name to be prefixed by test-*
                options.channelNamePrefix = nil
                let client = ARTRest(options: options)
                let channel = client.channels.get("pushenabled:test")
                let extras = ["notification": ["title": "Hello from Ably!"]] as ARTJsonCompatible

                expect((client.internal.encoders["application/json"] as! ARTJsonLikeEncoder).message(from: [
                    "data": "foo",
                    "extras": ["notification": ["title": "Hello from Ably!"]]
                ])?.extras == extras).to(beTrue())

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
                            expect(message.extras == extras).to(beTrue())
                            done()
                        }
                    }
                }
            }

            // RSL1i
            

                func test__018__publish__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__the_client_library_should_reject_the_publish_and_indicate_an_error() {
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get(channelName)
                    let messages = buildMessagesThatExceedMaxMessageSize()

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { error in
                            expect(error?.code).to(equal(ARTErrorCode.maxMessageLengthExceeded.intValue))
                            done()
                        }
                    }
                }

                func test__019__publish__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__also_when_using_publish_data_clientId_extras() {
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get(channelName)
                    let name = buildStringThatExceedMaxMessageSize()

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(name, data: nil, extras: nil) { error in
                            expect(error?.code).to(equal(ARTErrorCode.maxMessageLengthExceeded.intValue))
                            done()
                        }
                    }
                }

            // RSL1k
            

                // TO3n
                func test__020__publish__idempotent_publishing__idempotentRestPublishing_option() {
beforeEach()

                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "2")) == true
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "2.0.0")) == true
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.1")) == false
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.1.2")) == false
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.2")) == true
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.2.2")) == true
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.0")) == false
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "1.0.5")) == false
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "0.9")) == false
                    expect(ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: "0.9.1")) == false

                    // Current version
                    let options = AblyTests.clientOptions()
                    expect(options.idempotentRestPublishing) == true
                }

                // RSL1k1
                

                    func test__027__publish__idempotent_publishing__random_idempotent_publish_id__should_generate_for_one_message_with_empty_id() {
beforeEach()

                        let message = ARTMessage(name: nil, data: "foo")
                        expect(message.id).to(beNil())

                        let rest = ARTRest(key: "xxxx:xxxx")
                        rest.internal.options.idempotentRestPublishing = true
                        let mockHTTPExecutor = MockHTTPExecutor()
                        rest.internal.httpExecutor = mockHTTPExecutor
                        let channel = rest.channels.get("idempotent")

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([message]) { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
                            fail("Body from the last request is empty"); return
                        }

                        let json = AblyTests.msgpackToJSON(encodedBody)
                        assertMessagePayloadId(id: json.arrayValue.first?["id"].string, expectedSerial: "0")
                        expect(message.id).to(beNil())
                    }

                    func test__028__publish__idempotent_publishing__random_idempotent_publish_id__should_generate_for_multiple_messages_with_empty_id() {
beforeEach()

                        let message1 = ARTMessage(name: nil, data: "foo1")
                        expect(message1.id).to(beNil())
                        let message2 = ARTMessage(name: "john", data: "foo2")
                        expect(message2.id).to(beNil())

                        let rest = ARTRest(key: "xxxx:xxxx")
                        rest.internal.options.idempotentRestPublishing = true
                        let mockHTTPExecutor = MockHTTPExecutor()
                        rest.internal.httpExecutor = mockHTTPExecutor
                        let channel = rest.channels.get("idempotent")

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([message1, message2]) { error in
                                expect(error).to(beNil())
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
                        expect(id1?.split(separator: ":").first).to(equal(id2?.split(separator: ":").first))
                    }

                // RSL1k2
                func test__021__publish__idempotent_publishing__should_not_generate_for_message_with_a_non_empty_id() {
beforeEach()

                    let message = ARTMessage(name: nil, data: "foo")
                    message.id = "123"

                    let rest = ARTRest(key: "xxxx:xxxx")
                    rest.internal.options.idempotentRestPublishing = true
                    let mockHTTPExecutor = MockHTTPExecutor()
                    rest.internal.httpExecutor = mockHTTPExecutor
                    let channel = rest.channels.get("idempotent")

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish([message]) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
                        fail("Body from the last request is empty"); return
                    }

                    let json = AblyTests.msgpackToJSON(encodedBody)
                    expect(json.arrayValue.first?["id"].string).to(equal("123"))
                }

                func test__022__publish__idempotent_publishing__should_generate_for_internal_message_that_is_created_in_publish_name_data___method() {
beforeEach()

                    let rest = ARTRest(key: "xxxx:xxxx")
                    rest.internal.options.idempotentRestPublishing = true
                    let mockHTTPExecutor = MockHTTPExecutor()
                    rest.internal.httpExecutor = mockHTTPExecutor
                    let channel = rest.channels.get("idempotent")

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish("john", data: "foo") { error in
                            expect(error).to(beNil())
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
beforeEach()

                    let message1 = ARTMessage(name: nil, data: "foo1")
                    expect(message1.id).to(beNil())
                    let message2 = ARTMessage(name: "john", data: "foo2")
                    message2.id = "123"

                    let rest = ARTRest(key: "xxxx:xxxx")
                    rest.internal.options.idempotentRestPublishing = true
                    let mockHTTPExecutor = MockHTTPExecutor()
                    rest.internal.httpExecutor = mockHTTPExecutor
                    let channel = rest.channels.get("idempotent")

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish([message1, message2]) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
                        fail("Body from the last request is empty"); return
                    }

                    let json = AblyTests.msgpackToJSON(encodedBody)
                    expect(json.arrayValue.first?["id"].string).to(beNil())
                    expect(json.arrayValue.last?["id"].string).to(equal("123"))
                }

                func test__024__publish__idempotent_publishing__should_not_generate_when_idempotentRestPublishing_flag_is_off() {
beforeEach()

                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.idempotentRestPublishing = false

                    let message1 = ARTMessage(name: nil, data: "foo1")
                    expect(message1.id).to(beNil())
                    let message2 = ARTMessage(name: "john", data: "foo2")
                    expect(message2.id).to(beNil())

                    let rest = ARTRest(options: options)
                    let mockHTTPExecutor = MockHTTPExecutor()
                    rest.internal.httpExecutor = mockHTTPExecutor
                    let channel = rest.channels.get("idempotent")

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish([message1, message2]) { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let encodedBody = mockHTTPExecutor.requests.last?.httpBody else {
                        fail("Body from the last request is empty"); return
                    }

                    let json = AblyTests.msgpackToJSON(encodedBody)
                    expect(json.arrayValue.first?["id"].string).to(beNil())
                    expect(json.arrayValue.last?["id"].string).to(beNil())
                }

                // RSL1k4
                func test__025__publish__idempotent_publishing__should_have_only_one_published_message() {
beforeEach()

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

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { error in
                            expect(error).toNot(beNil())
                            done()
                        }
                    }

                    expect(testHTTPExecutor.requests.count) == 2

                    waitUntil(timeout: testTimeout) { done in
                        channel.history { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("No result"); done(); return
                            }
                            expect(result.items.count) == 3
                            done()
                        }
                    }
                }

                // RSL1k5
                func test__026__publish__idempotent_publishing__should_publish_a_message_with_implicit_Id_only_once() {
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    let rest = ARTRest(options: options)
                    rest.internal.options.idempotentRestPublishing = true
                    let channel = rest.channels.get("idempotent")

                    let message = ARTMessage(name: "unique", data: "foo")
                    message.id = "123"

                    for _ in 1...4 {
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([message]) { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.history { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("No result"); done(); return
                            }
                            expect(result.items.count) == 1
                            expect(result.items.first?.id).to(equal("123"))
                            done()
                        }
                    }
                }
          
            // RSL1j
            func test__004__publish__should_include_attributes_supplied_by_the_caller_in_the_encoded_message() {
beforeEach()

                let options = AblyTests.commonAppSetup()
                let client = ARTRest(options: options)
                let proxyHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
                client.internal.httpExecutor = proxyHTTPExecutor

                let channel = client.channels.get("foo")
                let message = ARTMessage(name: nil, data: "")
                message.id = "123"
                message.name = "tester"

                waitUntil(timeout: testTimeout) { done in
                    channel.publish([message]) { error in
                        expect(error).to(beNil())
                        done()
                    }
                }

                guard let encodedBody = proxyHTTPExecutor.requests.last?.httpBody else {
                    fail("Body from the last request is empty"); return
                }

                guard let jsonMessage = AblyTests.msgpackToJSON(encodedBody).array?.first else {
                    fail("Body from the last request is invalid"); return
                }
                expect(jsonMessage["name"].string).to(equal("tester"))
                expect(jsonMessage["data"].string).to(equal(""))
                expect(jsonMessage["id"].string).to(equal(message.id))
            }

        // RSL2
        

            // RSL2a
            func test__029__history__should_return_a_PaginatedResult_page_containing_the_first_page_of_messages() {
beforeEach()

                let client = ARTRest(options: AblyTests.commonAppSetup())
                let channel = client.channels.get("foo")

                waitUntil(timeout: testTimeout) { done in
                    channel.publish([
                        .init(name: nil, data: "m1"),
                        .init(name: nil, data: "m2"),
                        .init(name: nil, data: "m3"),
                        .init(name: nil, data: "m4"),
                        .init(name: nil, data: "m5"),
                    ],
                    callback: { error in
                        expect(error).to(beNil())
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
                    expect(error).to(beNil())
                    expect(result.hasNext).to(beTrue())
                    expect(result.isLast).to(beFalse())
                    expect(result.items).to(haveCount(2))
                    let items = result.items.compactMap({ $0.data as? String })
                    expect(items.first).to(equal("m1"))
                    expect(items.last).to(equal("m2"))

                    result.next { result, error in
                        guard let result = result else {
                            fail("Result is empty"); return
                        }
                        expect(error).to(beNil())
                        expect(result.hasNext).to(beTrue())
                        expect(result.isLast).to(beFalse())
                        expect(result.items).to(haveCount(2))
                        let items = result.items.compactMap({ $0.data as? String })
                        expect(items.first).to(equal("m3"))
                        expect(items.last).to(equal("m4"))

                        result.next { result, error in
                            guard let result = result else {
                                fail("Result is empty"); return
                            }
                            expect(error).to(beNil())
                            expect(result.hasNext).to(beFalse())
                            expect(result.isLast).to(beTrue())
                            expect(result.items).to(haveCount(1))
                            let items = result.items.compactMap({ $0.data as? String })
                            expect(items.first).to(equal("m5"))

                            result.first { result, error in
                                guard let result = result else {
                                    fail("Result is empty"); return
                                }
                                expect(error).to(beNil())
                                expect(result.hasNext).to(beTrue())
                                expect(result.isLast).to(beFalse())
                                expect(result.items).to(haveCount(2))
                                let items = result.items.compactMap({ $0.data as? String })
                                expect(items.first).to(equal("m1"))
                                expect(items.last).to(equal("m2"))
                            }
                        }
                    }
                }
            }

            // RSL2b
            

                // RSL2b1
                func test__030__history__query_arguments__start_and_end_should_filter_messages_between_those_two_times() {
beforeEach()

                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.direction) == ARTQueryDirection.backwards
                    expect(query.limit) == 100

                    waitUntil(timeout: testTimeout) { done in
                        client.time { time, _ in
                            query.start = time
                            done()
                        }
                    }

                    let messages = [
                        ARTMessage(name: nil, data: "message1"),
                        ARTMessage(name: nil, data: "message2")
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
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("PaginatedResult is empty"); done()
                                return
                            }
                            expect(result.hasNext).to(beFalse())
                            expect(result.isLast).to(beTrue())
                            let items = result.items
                            if items.count != 2 {
                                fail("PaginatedResult has no items"); done()
                                return
                            }
                            let messageItems = items.compactMap({ $0.data as? String })
                            expect(messageItems.first).to(equal("message2"))
                            expect(messageItems.last).to(equal("message1"))
                            done()
                        }
                    }
                }

                // RSL2b1
                func test__031__history__query_arguments__start_must_be_equal_to_or_less_than_end_and_is_unaffected_by_the_request_direction() {
beforeEach()

                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    query.direction = .backwards
                    query.end = NSDate() as Date
                    query.start = query.end!.addingTimeInterval(10.0)

                    expect { try channel.history(query) { _, _ in } }.to(throwError { (error: Error) in
                        expect(error._code).to(equal(ARTDataQueryError.timestampRange.rawValue))
                    })

                    query.direction = .forwards

                    expect { try channel.history(query) { _, _ in } }.to(throwError { (error: Error) in
                        expect(error._code).to(equal(ARTDataQueryError.timestampRange.rawValue))
                    })
                }

                // RSL2b2
                func test__032__history__query_arguments__direction_backwards_or_forwards() {
beforeEach()

                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.direction) == ARTQueryDirection.backwards
                    query.direction = .forwards

                    let messages = [
                        ARTMessage(name: nil, data: "message1"),
                        ARTMessage(name: nil, data: "message2")
                    ]
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { _ in
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        try! channel.history(query) { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("PaginatedResult is empty"); done()
                                return
                            }
                            expect(result.hasNext).to(beFalse())
                            expect(result.isLast).to(beTrue())
                            let items = result.items
                            if items.count != 2 {
                                fail("PaginatedResult has no items"); done()
                                return
                            }
                            let messageItems = items.compactMap({ $0.data as? String })
                            expect(messageItems.first).to(equal("message1"))
                            expect(messageItems.last).to(equal("message2"))
                            done()
                        }
                    }
                }

                // RSL2b3
                func test__033__history__query_arguments__limit_items_result() {
beforeEach()

                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.limit) == 100
                    query.limit = 2

                    let messages = (1...10).compactMap{ ARTMessage(name: nil, data: "message\($0)") }
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { _ in
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        try! channel.history(query) { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("PaginatedResult is empty"); done()
                                return
                            }
                            expect(result.hasNext).to(beTrue())
                            expect(result.isLast).to(beFalse())
                            let items = result.items
                            if items.count != 2 {
                                fail("PaginatedResult has no items"); done()
                                return
                            }
                            let messageItems = items.compactMap({ $0.data as? String })
                            expect(messageItems.first).to(equal("message10"))
                            expect(messageItems.last).to(equal("message9"))
                            done()
                        }
                    }
                }

                // RSL2b3
                func test__034__history__query_arguments__limit_supports_up_to_1000_items() {
beforeEach()

                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.limit) == 100

                    query.limit = 1001
                  expect{ try channel.history(query, callback: { _ , _  in }) }.to(throwError())

                    query.limit = 1000
                  expect{ try channel.history(query, callback: { _ , _  in }) }.toNot(throwError())
                }

        // RSL3, RSP1
        

            // RSP3
            
                func skipped__test__035__presence__get__should_return_presence_fixture_data() {
beforeEach()

                    let options = AblyTests.commonAppSetup()
                    options.channelNamePrefix = nil
                    client = ARTRest(options: options)
                    let key = appSetupJson["cipher"]["key"].string!
                    let cipherParams = ARTCipherParams.init(
                        algorithm: appSetupJson["cipher"]["algorithm"].string!,
                        key: key as ARTCipherKeyCompatible,
                        iv: Data(base64Encoded: appSetupJson["cipher"]["iv"].string!, options: Data.Base64DecodingOptions.init(rawValue: 0))!
                    )
                    let channel = client.channels.get("persisted:presence_fixtures", options: ARTChannelOptions(cipher: cipherParams))
                    var presenceMessages: [ARTPresenceMessage] = []

                    channel.presence.get() { result, _ in
                        if let items = result?.items {
                            presenceMessages.append(contentsOf:items)
                        }
                        else {
                            fail("expected items to not be empty")
                        }
                    }

                    expect(presenceMessages.count).toEventually(equal(presenceFixtures.count), timeout: testTimeout)
                    for message in presenceMessages {
                        let fixtureMessage = presenceFixtures.filter({ (key, value) -> Bool in
                            return message.clientId == value["clientId"].stringValue
                        }).first!.1

                        expect(message.data).toNot(beNil())
                        expect(message.action).to(equal(ARTPresenceAction.present))

                        let encodedFixture = channel.internal.dataEncoder.decode(
                            fixtureMessage["data"].object,
                            encoding:fixtureMessage.asDictionary!["encoding"] as? String
                        )
                        expect(message.data as? NSObject).to(equal(encodedFixture.data as? NSObject));
                    }
                }

        // RSL4
        

            struct TestCase {
                let value: Any?
                let expected: JSON
            }

            // RSL4a
            func test__036__message_encoding__payloads_should_be_binary__strings__or_objects_capable_of_JSON_representation() {
beforeEach()

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

                validCases.forEach { caseTest in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: caseTest.value) { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                                XCTFail("HTTPBody is nil");
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
                            expect(json).to(equal(mergedWithExpectedJSON))
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
beforeEach()

                let encodingCases = [
                    TestCase(value: text, expected: JSON.null),
                    TestCase(value: dictionary, expected: "json"),
                    TestCase(value: array, expected: "json"),
                    TestCase(value: binaryData, expected: "base64"),
                ]

                client.internal.httpExecutor = testHTTPExecutor

                encodingCases.forEach { caseItem in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: caseItem.value, callback: { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            expect(AblyTests.msgpackToJSON(httpBody)["encoding"]).to(equal(caseItem.expected))
                            done()
                        })
                    }
                }
            }

            
                // RSL4d1
                func test__038__message_encoding__json__binary_payload_should_be_encoded_as_Base64_and_represented_as_a_JSON_string() {
beforeEach()

                    client.internal.httpExecutor = testHTTPExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: binaryData, callback: { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            // Binary
                            let json = AblyTests.msgpackToJSON(httpBody)
                            expect(json["data"].string).to(equal(binaryData.toBase64))
                            expect(json["encoding"]).to(equal("base64"))
                            done()
                        })
                    }
                }

                // RSL4d
                func test__039__message_encoding__json__string_payload_should_be_represented_as_a_JSON_string() {
beforeEach()

                    client.internal.httpExecutor = testHTTPExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: text, callback: { error in
                            expect(error).to(beNil())

                            if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                                // String (UTF-8)
                                let json = AblyTests.msgpackToJSON(http)
                                expect(json["data"].string).to(equal(text))
                                expect(json["encoding"].string).to(beNil())
                            }
                            else {
                                XCTFail("No request or HTTP body found")
                            }
                            done()
                        })
                    }
                }

                // RSL4d3
                

                    func test__041__message_encoding__json__json_payload_should_be_stringified_either__as_a_JSON_Array() {
beforeEach()

                        client.internal.httpExecutor = testHTTPExecutor
                        // JSON Array
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: array, callback: { error in
                                expect(error).to(beNil())

                                if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                                    // Array
                                    let json = AblyTests.msgpackToJSON(http)
                                    expect(try! JSON(data: json["data"].stringValue.data(using: .utf8)!).asArray).to(equal(array as NSArray?))
                                    expect(json["encoding"].string).to(equal("json"))
                                }
                                else {
                                    XCTFail("No request or HTTP body found")
                                }
                                done()
                            })
                        }
                    }

                    func test__042__message_encoding__json__json_payload_should_be_stringified_either__as_a_JSON_Object() {
beforeEach()

                        client.internal.httpExecutor = testHTTPExecutor
                        // JSON Object
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: dictionary, callback: { error in
                                expect(error).to(beNil())

                                if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                                    // Dictionary
                                    let json = AblyTests.msgpackToJSON(http)
                                    expect(try! JSON(data: json["data"].stringValue.data(using: .utf8)!).asDictionary).to(equal(dictionary as NSDictionary?))
                                    expect(json["encoding"].string).to(equal("json"))
                                }
                                else {
                                    XCTFail("No request or HTTP body found")
                                }
                                done()
                            })
                        }
                    }

                // RSL4d4
                func test__040__message_encoding__json__messages_received_should_be_decoded_based_on_the_encoding_field() {
beforeEach()

                    let cases = [text, integer, decimal, dictionary, array, binaryData] as [Any]

                    cases.forEach { caseTest in
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: caseTest, callback: { error in
                                expect(error).to(beNil())
                                done()
                            })
                        }
                    }

                    var totalReceived = 0
                    channel.history { result, error in
                        expect(error).to(beNil())
                        guard let result = result else {
                            XCTFail("Result is nil")
                            return
                        }
                        expect(result.hasNext).to(beFalse())

                        for (index, item) in (result.items.reversed().enumerated()) {
                            totalReceived += 1

                            switch item.data {
                            case let value as NSDictionary:
                                expect(value).to(equal(cases[index] as? NSDictionary))
                                break
                            case let value as NSArray:
                                expect(value).to(equal(cases[index] as? NSArray))
                                break
                            case let value as NSData:
                                expect(value).to(equal(cases[index] as? NSData))
                                break
                            case let value as NSString:
                                expect(value).to(equal(cases[index] as? NSString))
                                break
                            default:
                                XCTFail("Payload with unknown format")
                                break
                            }
                        }
                    }
                    expect(totalReceived).toEventually(equal(cases.count), timeout: testTimeout)
                }

        // RSL5
        

            // RSL5b
            
                
                func test__043__message_payload_encryption__should_support_AES_encryption__128_CBC_mode() {
beforeEach()

                    testSupportsAESEncryptionWithKeyLength(128)
                }
                
                func test__044__message_payload_encryption__should_support_AES_encryption__256_CBC_mode() {
beforeEach()

                    testSupportsAESEncryptionWithKeyLength(256)
                }

        // RSL6
        

            // RSL6b
            func test__045__message_decoding__should_deliver_with_a_binary_payload_when_the_payload_was_successfully_decoded_but_it_could_not_be_decrypted() {
beforeEach()

                let options = AblyTests.commonAppSetup()
                let clientEncrypted = ARTRest(options: options)

                let channelOptions = ARTChannelOptions(cipher: ["key":ARTCrypto.generateRandomKey()] as ARTCipherParamsCompatible)
                let channelEncrypted = clientEncrypted.channels.get("test", options: channelOptions)

                let expectedMessage = ["something":1]

                waitUntil(timeout: testTimeout) { done in
                    channelEncrypted.publish(nil, data: expectedMessage) { error in
                        done()
                    }
                }

                let client = ARTRest(options: options)
                let channel = client.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    channel.history { result, error in
                        expect(error).to(beNil())
                        guard let result = result else {
                            fail("Result is empty"); done(); return
                        }
                        guard let message = result.items.first else {
                            fail("First item does not exist"); done(); return
                        }
                        expect(message.data is NSData).to(beTrue())
                        expect(message.encoding).to(equal("json/utf-8/cipher+aes-256-cbc"))
                        done()
                    }
                }
            }

            // RSL6b
            func test__046__message_decoding__should_deliver_with_encoding_attribute_set_indicating_the_residual_encoding_and_error_should_be_emitted() {
beforeEach()

                let options = AblyTests.commonAppSetup()
                options.useBinaryProtocol = false
                options.logHandler = ARTLog(capturingOutput: true)
                let client = ARTRest(options: options)
                let channelOptions = ARTChannelOptions(cipher: ["key":ARTCrypto.generateRandomKey()] as ARTCipherParamsCompatible)
                let channel = client.channels.get("test", options: channelOptions)
                client.internal.httpExecutor = testHTTPExecutor

                let expectedMessage = ["something":1]
                let expectedData = try! JSONSerialization.data(withJSONObject: expectedMessage, options: JSONSerialization.WritingOptions(rawValue: 0))

                testHTTPExecutor.setListenerProcessingDataResponse({ data in
                    let dataStr = String(data: data!, encoding: String.Encoding.utf8)!
                    return dataStr.replace("json/utf-8", withString: "invalid").data(using: String.Encoding.utf8)!
                })

                waitUntil(timeout: testTimeout) { done in
                    channel.publish(nil, data: expectedMessage) { error in
                        done()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.history { result, error in
                        expect(error).to(beNil())
                        guard let result = result else {
                            fail("Result is empty"); done(); return
                        }
                        guard let message = result.items.first else {
                            fail("First item does not exist"); done(); return
                        }
                        expect(message.data as? NSData).to(equal(expectedData as NSData?))
                        expect(message.encoding).to(equal("invalid"))

                        let logs = options.logHandler.captured
                        let line = logs.reduce("") { $0 + "; " + $1.toString() } //Reduce in one line
                        expect(line).to(contain("Failed to decode data: unknown encoding: 'invalid'"))
                        done()
                    }
                }
            }
}
