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
        var channel: ARTChannel! //ARTRestChannel
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
                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
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

                    channel.publish(nil, data: nil) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first
                        }
                    }

                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.data).toEventually(beNil(), timeout: testTimeout)
                }
            }

            context("with a Message object") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?

                    channel.publish([ARTMessage(name: name, data: data)]) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first
                        }
                    }

                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.data).toEventually(beNil(), timeout: testTimeout)
                }
            }

            // RSL1c
            context("with an array of Message objects") {
                it("publishes the messages in a single request and invokes callback with success") {
                    let oldExecutor = client.httpExecutor
                    defer { client.httpExecutor = oldExecutor}
                    client.httpExecutor = testHTTPExecutor

                    var publishError: ARTErrorInfo? = ARTErrorInfo.create(from: NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessages: [ARTMessage] = []

                    let messages = [
                        ARTMessage(name: "bar", data: "foo"),
                        ARTMessage(name: "bat", data: "baz")
                    ]
                    channel.publish(messages) { error in
                        publishError = error
                        client.httpExecutor = oldExecutor
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
                            expect(client.auth.method).to(equal(ARTAuthMethod.basic))
                            channel.history { page, error in
                                expect(error).to(beNil())
                                let item = page!.items[0] 
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
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            let message = ARTMessage(name: nil, data: "message")
                            expect(message.clientId).to(beNil())

                            channel.publish([message]) { error in
                                expect(error).to(beNil())
                                channel.history { page, error in
                                    expect(error).to(beNil())
                                    let item = page!.items[0] 
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
                                let item = page!.items[0] 
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
                    client.httpExecutor = testHTTPExecutor
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
                    client.httpExecutor = testHTTPExecutor
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
                                expect(page!.items).to(haveCount(0))
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
            pending("should provide an optional argument that allows the extras value to be specified") {
                // TODO: pushenabled doesn't appear to be working.
                let client = ARTRest(options: AblyTests.commonAppSetup())
                let channel = client.channels.get("pushenabled:test")
                let extras = ["push": ["key": "value"]] as ARTJsonCompatible

                expect((client.encoders["application/json"] as! ARTJsonLikeEncoder).message(from: [
                    "data": "foo",
                    "extras": ["push": ["key": "value"]]
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
                    let items = result.items.flatMap({ $0.data as? String })
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
                        let items = result.items.flatMap({ $0.data as? String })
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
                            let items = result.items.flatMap({ $0.data as? String })
                            expect(items.first).to(equal("m5"))

                            result.first { result, error in
                                guard let result = result else {
                                    fail("Result is empty"); return
                                }
                                expect(error).to(beNil())
                                expect(result.hasNext).to(beTrue())
                                expect(result.isLast).to(beFalse())
                                expect(result.items).to(haveCount(2))
                                let items = result.items.flatMap({ $0.data as? String })
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
                            let messageItems = items.flatMap({ $0.data as? String })
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
                            let messageItems = items.flatMap({ $0.data as? String })
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

                    let messages = (1...10).flatMap{ ARTMessage(name: nil, data: "message\($0)") }
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
                            let messageItems = items.flatMap({ $0.data as? String })
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
                    expect{ try channel.history(query, callback: { _ in }) }.to(throwError())

                    query.limit = 1000
                    expect{ try channel.history(query, callback: { _ in }) }.toNot(throwError())
                }

            }

        }

        // RSL3, RSP1
        describe("presence") {
            let presenceFixtures = appSetupJson["post_apps"]["channels"][0]["presence"]

            // RSP3
            context("get") {
                it("should return presence fixture data") {
                    let originalARTChannels_getChannelNamePrefix = ARTChannels_getChannelNamePrefix
                    defer { ARTChannels_getChannelNamePrefix = originalARTChannels_getChannelNamePrefix }
                    ARTChannels_getChannelNamePrefix = nil // Force that channel name is not changed.

                    let key = appSetupJson["cipher"]["key"].string!
                    let cipherParams = ARTCipherParams.init(
                        algorithm: appSetupJson["cipher"]["algorithm"].string!,
                        key: key as ARTCipherKeyCompatible,
                        iv: NSData(base64Encoded: appSetupJson["cipher"]["iv"].string!, options: NSData.Base64DecodingOptions.init(rawValue: 0))! as Data
                    )
                    let channel = client.channels.get("persisted:presence_fixtures", options:ARTChannelOptions.init(cipher: cipherParams))
                    var presenceMessages: [ARTPresenceMessage] = []

                    channel.presence.get() { result, _ in
                        if let items = result?.items {
                            presenceMessages.append(contentsOf:items)
                        }
                    }

                    expect(presenceMessages.count).toEventually(equal(presenceFixtures.count), timeout: testTimeout)
                    for message in presenceMessages {
                        let fixtureMessage = presenceFixtures.filter({ (key, value) -> Bool in
                            return message.clientId == value["clientId"].stringValue
                        }).first!.1

                        expect(message.data).toNot(beNil())
                        expect(message.action).to(equal(ARTPresenceAction.present))

                        let encodedFixture = channel.dataEncoder.decode(
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
            let dictionary = ["number":3, "name":"John"] as [String : Any]
            let array = ["John", "Mary"]
            let binaryData = "123456".data(using: .utf8)!

            // RSL4a
            it("payloads should be binary, strings, or objects capable of JSON representation") {
                let validCases = [
                    TestCase(value: nil, expected: JSON([:])),
                    TestCase(value: text, expected: JSON(["data": text])),
                    TestCase(value: integer, expected: JSON(["data": integer])),
                    TestCase(value: decimal, expected: JSON(["data": decimal])),
                    TestCase(value: dictionary, expected: ["data": JSON(dictionary).rawString()!, "encoding": "json"] as JSON),
                    TestCase(value: array, expected: JSON(["data": JSON(array).rawString()!, "encoding": "json"])),
                    TestCase(value: binaryData, expected: JSON(["data": binaryData.toBase64, "encoding": "base64"])),
                ]

                client.httpExecutor = testHTTPExecutor

                validCases.forEach { caseTest in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: caseTest.value) { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            var json = AblyTests.msgpackToJSON(httpBody as NSData)
                            if let s = json["data"].string, let data = try? JSONSerialization.jsonObject(with: s.data(using: .utf8)!) {
                                // Make sure the formatting is the same by parsing
                                // and reformatting in the same way as the test
                                // case.
                                json["data"] = JSON(JSON(data).rawString()!)
                            }
                            expect(json).to(equal(caseTest.expected))
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

                client.httpExecutor = testHTTPExecutor

                encodingCases.forEach { caseItem in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: caseItem.value, callback: { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            expect(AblyTests.msgpackToJSON(httpBody as NSData)["encoding"]).to(equal(caseItem.expected))
                            done()
                        })
                    }
                }
            }

            context("json") {
                // RSL4d1
                it("binary payload should be encoded as Base64 and represented as a JSON string") {
                    client.httpExecutor = testHTTPExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: binaryData, callback: { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.httpBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            // Binary
                            let json = AblyTests.msgpackToJSON(httpBody as NSData)
                            expect(json["data"].string).to(equal(binaryData.toBase64))
                            expect(json["encoding"]).to(equal("base64"))
                            done()
                        })
                    }
                }

                // RSL4d
                it("string payload should be represented as a JSON string") {
                    client.httpExecutor = testHTTPExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: text, callback: { error in
                            expect(error).to(beNil())

                            if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                                // String (UTF-8)
                                let json = AblyTests.msgpackToJSON(http as NSData)
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
                        client.httpExecutor = testHTTPExecutor
                        // JSON Array
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: array, callback: { error in
                                expect(error).to(beNil())

                                if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                                    // Array
                                    let json = AblyTests.msgpackToJSON(http as NSData)
                                    expect(JSON(data: json["data"].stringValue.data(using: String.Encoding.utf8)!).asArray).to(equal(array as NSArray?))
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
                        client.httpExecutor = testHTTPExecutor
                        // JSON Object
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: dictionary, callback: { error in
                                expect(error).to(beNil())

                                if let request = testHTTPExecutor.requests.last, let http = request.httpBody {
                                    // Dictionary
                                    let json = AblyTests.msgpackToJSON(http as NSData)
                                    expect(JSON(data: json["data"].stringValue.data(using: String.Encoding.utf8)!).asDictionary).to(equal(dictionary as NSDictionary?))
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
                        client.httpExecutor = testHTTPExecutor

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
                        let httpBodyAsJSON = AblyTests.msgpackToJSON(httpBody as NSData)
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
                        let message = (result!.items )[0]
                        expect(message.data is NSData).to(beTrue())
                        expect(message.encoding).to(equal("json/utf-8/cipher+aes-256-cbc"))
                        done()
                    }
                }
            }

            // RSL6b
            it("should deliver with encoding attribute set indicating the residual encoding and error should be emitted") {
                let options = AblyTests.commonAppSetup()
                options.logHandler = ARTLog(capturingOutput: true)
                let client = ARTRest(options: options)
                let channelOptions = ARTChannelOptions(cipher: ["key":ARTCrypto.generateRandomKey()] as ARTCipherParamsCompatible)
                let channel = client.channels.get("test", options: channelOptions)
                client.httpExecutor = testHTTPExecutor

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
                        let message = (result!.items )[0]
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
