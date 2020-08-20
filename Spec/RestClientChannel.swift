//
//  RestClientChannel.swift
//  ably
//
//  Created by Yavor Georgiev on 23.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Ably
import Nimble
import Quick
import Foundation
import SwiftyJSON

class RestClientChannel: QuickSpec {
    override func spec() {
        var client: ARTRest!
        var channel: ARTRestChannel!
        var testHTTPExecutor: TestProxyHTTPExecutor!

        beforeEach {
            let options = AblyTests.setupOptions(AblyTests.jsonRestOptions)
            client = ARTRest(options: options)
            channel = client.channels.get(ProcessInfo.processInfo.globallyUniqueString)
            testHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
        }

        // RSL1
        describe("publish") {
            let name = "foo"
            let data = "bar"

            // RSL1b
            context("with name and data arguments") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

                    channel.publish(name, data: data) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first
                        }
                    }

                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(equal(name), timeout: testTimeout)
                    expect(publishedMessage?.data as? String).toEventually(equal(data), timeout: testTimeout)
                }
            }

            // RSL1b, RSL1e
            context("with name only") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "io.ably.XCTest", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

                    channel.publish(name, data: nil) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first
                        }
                    }

                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(equal(name), timeout: testTimeout)
                    expect(publishedMessage?.data).toEventually(beNil(), timeout: testTimeout)
                }
            }

            // RSL1b, RSL1e
            context("with data only") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

                    channel.publish(nil, data: data) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first
                        }
                    }

                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.data as? String).toEventually(equal(data), timeout: testTimeout)
                }
            }

            // RSL1b, RSL1e
            context("with neither name nor data") {
                it("publishes the message and invokes callback with success") {
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
            }

            context("with a Message object") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish([ARTMessage(name: name, data: data)]) { error in
                            publishError = error
                            channel.history { result, _ in
                                publishedMessage = result?.items.first
                                done()
                            }
                        }
                    }

                    expect(publishError).to(beNil())
                    expect(publishedMessage?.name).to(equal(name))
                    expect(publishedMessage?.data as? String).to(equal(data))
                }
            }

            // RSL1c
            context("with an array of Message objects") {
                it("publishes the messages in a single request and invokes callback with success") {
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
            }

            // RSL1f
            context("Unidentified clients using Basic Auth") {
                // RSL1f1
                it("should publish message with the provided clientId") {
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
            }

            // RSL1g
            context("Identified clients with a clientId") {

                // RSL1g1
                context("when publishing a Message with the clientId attribute set to null") {

                    // RSL1g1a, RSL1g1b
                    it("should be unnecessary to set clientId of the Message before publishing") {
                        let options = AblyTests.commonAppSetup()
                        options.clientId = "john"
                        options.useTokenAuth = true
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            let message = ARTMessage(name: nil, data: "message")
                            expect(message.clientId).to(beNil())

                            channel.publish([message]) { error in
                                expect(error).to(beNil())
                                channel.history { page, error in
                                    expect(error).to(beNil())
                                    guard let page = page else {
                                        fail("Page is empty"); done(); return
                                    }
                                    guard let item = page.items.first else {
                                        fail("First item does not exist"); done(); return
                                    }
                                    expect(item.clientId).to(equal("john"))
                                    done()
                                }
                            }
                        }
                    }

                }

                // RSL1g2
                it("when publishing a Message with the clientId attribute set to the identified client’s clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let message = ARTMessage(name: nil, data: "message", clientId: options.clientId!)
                        channel.publish([message]) { error in
                            expect(error).to(beNil())
                            channel.history { page, error in
                                expect(error).to(beNil())
                                guard let page = page else {
                                    fail("Page is empty"); done(); return
                                }
                                guard let item = page.items.first else {
                                    fail("First item does not exist"); done(); return
                                }
                                expect(item.clientId).to(equal("john"))
                                done()
                            }
                        }
                    }
                }

                // RSL1g3
                it("when publishing a Message with a different clientId attribute value to the identified client’s clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRest(options: options)
                    client.internal.httpExecutor = testHTTPExecutor
                    let channel = client.channels.get("test")

                    // Reject before the message is sent to the server
                    let hook = channel.testSuite_injectIntoMethod(before: #selector(ARTChannel.publish(_:callback:))) {
                        testHTTPExecutor.http = nil
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let message = ARTMessage(name: nil, data: "message", clientId: "tester")
                        channel.publish([message]) { error in
                            expect(error!.code).to(equal(Int(ARTState.mismatchedClientId.rawValue)))
                            done()
                        }
                    }

                    hook.remove()
                    testHTTPExecutor.http = ARTHttp(AblyTests.queue, logger: options.logHandler)

                    // Remains available
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                // RSL1g4
                it("when publishing a Message with an explicit clientId that is incompatible with the identified client’s clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRest(options: options)
                    client.internal.httpExecutor = testHTTPExecutor
                    let channel = client.channels.get("test")

                    // Reject before the message is sent to the server
                    channel.testSuite_injectIntoMethod(before: #selector(ARTChannel.publish(_:callback:))) {
                        testHTTPExecutor.http = nil
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let message = ARTMessage(name: nil, data: "message", clientId: "tester")
                        channel.publish([message]) { error in
                            expect(error!.code).to(equal(Int(ARTState.mismatchedClientId.rawValue)))

                            testHTTPExecutor.http = ARTHttp(AblyTests.queue, logger: options.logHandler)
                            channel.history { page, error in
                                expect(error).to(beNil())
                                guard let page = page else {
                                    fail("Page is empty"); done(); return
                                }
                                expect(page.items).to(haveCount(0))
                                done()
                            }
                        }
                    }
                }

            }

            // RSL1h
            it("should provide an optional argument that allows the clientId value to be specified") {
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
            it("should provide an optional argument that allows the extras value to be specified") {
                let options = AblyTests.commonAppSetup()
                // Prevent channel name to be prefixed by test-*
                options.channelNamePrefix = nil
                let client = ARTRest(options: options)
                let channel = client.channels.get("pushenabled:test")
                let extras = ["notification": ["title": "Hello from Ably!"]] as ARTJsonCompatible

                expect((client.internal.encoders["application/json"] as! ARTJsonLikeEncoder).message(from: [
                    "data": "foo",
                    "extras": ["notification": ["title": "Hello from Ably!"]]
                ]).extras == extras).to(beTrue())

                waitUntil(timeout: testTimeout) { done in
                    channel.publish("name", data: "some data", extras: extras) { error in
                        if let error = error {
                            fail("unexpected error \(error)")
                            done(); return
                        }

                        var query = ARTDataQuery()
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
            context("If the total size of message(s) exceeds the maxMessageSize") {
                let channelName = "test-message-size"

                it("the client library should reject the publish and indicate an error") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get(channelName)
                    let messages = buildMessagesThatExceedMaxMessageSize()

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { error in
                            expect(error?.code).to(equal(40009))
                            expect(error?.message).to(contain("maximum message length exceeded"))
                            done()
                        }
                    }
                }

                it("also when using publish:data:clientId:extras") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get(channelName)
                    let name = buildStringThatExceedMaxMessageSize()

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(name, data: nil, extras: nil) { error in
                            expect(error?.code).to(equal(40009))
                            expect(error?.message).to(contain("maximum message length exceeded"))
                            done()
                        }
                    }
                }
            }

            // RSL1k
            context("idempotent publishing") {

                // TO3n
                it("idempotentRestPublishing option") {
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

                func assertMessagePayloadId(id: String?, expectedSerial: String) {
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

                // RSL1k1
                context("random idempotent publish id") {

                    it("should generate for one message with empty id") {
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

                    it("should generate for multiple messages with empty id") {
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
                }

                // RSL1k2
                it("should not generate for message with a non empty id") {
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

                it("should generate for internal message that is created in publish(name:data:) method") {
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
                it("should not generate for multiple messages with a non empty id") {
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

                it("should not generate when idempotentRestPublishing flag is off") {
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
                it("should have only one published message") {
                    client.internal.options.idempotentRestPublishing = true
                    client.internal.httpExecutor = testHTTPExecutor
                    client.internal.options.fallbackHostsUseDefault = true

                    let forceRetryError = ErrorSimulator(
                        value: 50000,
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
                it("should publish a message with implicit Id only once") {
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
            }
          
            // RSL1j
            it("should include attributes supplied by the caller in the encoded message") {
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
        }

        // RSL2
        describe("history") {

            // RSL2a
            it("should return a PaginatedResult page containing the first page of messages") {
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
            context("query arguments") {

                // RSL2b1
                it("start and end should filter messages between those two times") {
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
                it("start must be equal to or less than end and is unaffected by the request direction") {
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
                it("direction backwards or forwards") {
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
                it("limit items result") {
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
                it("limit supports up to 1000 items") {
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.limit) == 100

                    query.limit = 1001
                  expect{ try channel.history(query, callback: { _ , _  in }) }.to(throwError())

                    query.limit = 1000
                  expect{ try channel.history(query, callback: { _ , _  in }) }.toNot(throwError())
                }

            }

        }

        // RSL3, RSP1
        describe("presence") {
            let presenceFixtures = appSetupJson["post_apps"]["channels"][0]["presence"]

            // RSP3
            context("get") {
                it("should return presence fixture data") {
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
            }
        }

        // RSL4
        describe("message encoding") {

            struct TestCase {
                let value: Any?
                let expected: JSON
            }

            let text = "John"
            let integer = "5"
            let decimal = "65.33"
            let dictionary = ["number": 3, "name": "John"] as [String : Any]
            let array = ["John", "Mary"]
            let binaryData = "123456".data(using: .utf8)!

            // RSL4a
            it("payloads should be binary, strings, or objects capable of JSON representation") {
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
            it("encoding attribute should represent the encoding(s) applied in right to left") {
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

            context("json") {
                // RSL4d1
                it("binary payload should be encoded as Base64 and represented as a JSON string") {
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
                it("string payload should be represented as a JSON string") {
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
                context("json payload should be stringified either") {

                    it("as a JSON Array") {
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

                    it("as a JSON Object") {
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

                }

                // RSL4d4
                it("messages received should be decoded based on the encoding field") {
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
            }
        }

        // RSL5
        describe("message payload encryption") {

            // RSL5b
            context("should support AES encryption") {

                for encryptionKeyLength: UInt in [128, 256] {
                    it("\(encryptionKeyLength) CBC mode") {
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
                }

            }

        }

        // RSL6
        describe("message decoding") {

            // RSL6b
            it("should deliver with a binary payload when the payload was successfully decoded but it could not be decrypted") {
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
            it("should deliver with encoding attribute set indicating the residual encoding and error should be emitted") {
                let options = AblyTests.commonAppSetup()
                options.useBinaryProtocol = false
                options.logHandler = ARTLog(capturingOutput: true)
                let client = ARTRest(options: options)
                let channelOptions = ARTChannelOptions(cipher: ["key":ARTCrypto.generateRandomKey()] as ARTCipherParamsCompatible)
                let channel = client.channels.get("test", options: channelOptions)
                client.internal.httpExecutor = testHTTPExecutor

                let expectedMessage = ["something":1]
                let expectedData = try! JSONSerialization.data(withJSONObject: expectedMessage, options: JSONSerialization.WritingOptions(rawValue: 0))

                testHTTPExecutor.beforeProcessingDataResponse = { data in
                    let dataStr = String(data: data!, encoding: String.Encoding.utf8)!
                    return dataStr.replace("json/utf-8", withString: "invalid").data(using: String.Encoding.utf8)!
                }

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

    }
}
