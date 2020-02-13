//
//  DeltaCodec.swift
//  Ably
//
//  Created by Ricardo Pereira on 06/02/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

import Ably
import Quick
import Nimble
import DeltaCodec

class DeltaCodec: QuickSpec {
    override func spec() {
        describe("DeltaCodec") {

            context("decoding") {

                let testData: [String] = [
                    "{ foo: \"bar\", count: 1, status: \"active\" }",
                    "{ foo: \"bar\", count: 2, status: \"active\" }",
                    "{ foo: \"bar\", count: 2, status: \"inactive\" }",
                    "{ foo: \"bar\", count: 3, status: \"inactive\" }",
                    "{ foo: \"bar\", count: 3, status: \"active\" }"
                ]

                // RTL19
                it("should decode vcdiff encoded messages") {
                    let options = AblyTests.commonAppSetup()
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }

                    let channelOptions = ARTRealtimeChannelOptions()
                    channelOptions.modes = [.subscribe, .publish]
                    channelOptions.params = [
                        "delta": "vcdiff"
                    ]

                    let channel = client.channels.get("foo", options: channelOptions)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not be assigned"); return
                    }

                    var receivedMessages: [ARTMessage] = []
                    channel.subscribe { message in
                        receivedMessages.append(message)
                    }

                    for (i, data) in testData.enumerated() {
                        channel.publish(String(i), data: data)
                    }

                    expect(channel.errorReason).to(beNil())
                    expect(receivedMessages).toEventually(haveCount(testData.count))

                    for (i, message) in receivedMessages.enumerated() {
                        if let name = message.name, let expectedMessageIndex = Int(name) {
                            expect(i).to(equal(expectedMessageIndex))
                            expect(message.data as? String).to(equal(testData[expectedMessageIndex]))
                        }
                        else {
                            fail("Received message has an unexpected 'id': \(message)")
                        }
                    }

                    channel.unsubscribe()

                    let protocolMessages = transport.protocolMessagesReceived.filter({ $0.action == .message })
                    let messagesEncoding = (protocolMessages.reduce([], { $0 + ($1.messages ?? []) }).compactMap({ $0.encoding }))
                    expect(messagesEncoding).to(allPass(equal("utf-8/vcdiff")))
                }

            }

        }
    }
}
