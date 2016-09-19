//
//  RealtimeClientChannels.swift
//  ably
//
//  Created by Ricardo Pereira on 01/02/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import AblyRealtime
import Quick
import Nimble

// Swift isn't yet smart enough to do this automatically when bridging Objective-C APIs
extension ARTRealtimeChannels: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

class RealtimeClientChannels: QuickSpec {
    override func spec() {
        describe("Channels") {

            // RTS2
            it("should exist methods to check if a channel exists or iterate through the existing channels") {
                let client = ARTRealtime(options: AblyTests.commonAppSetup())
                defer { client.dispose(); client.close() }
                var disposable = [ARTRealtimeChannel]()

                disposable.append(client.channels.get("test1"))
                disposable.append(client.channels.get("test2"))
                disposable.append(client.channels.get("test3"))

                expect(client.channels.get("test2")).toNot(beNil())
                expect(client.channels.exists("test2")).to(beTrue())
                expect(client.channels.exists("testX")).to(beFalse())

                for channel in client.channels {
                    expect(disposable.contains(channel as! ARTRealtimeChannel)).to(beTrue())
                }
            }

            // RTS3
            context("get") {

                // RTS3a
                it("should create a new Channel if none exists or return the existing one") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    expect(client.channels.collection).to(haveCount(0))
                    let channel = client.channels.get("test")
                    expect(channel.name).to(equal("\(ARTChannels_getChannelNamePrefix!())-test"))

                    expect(client.channels.collection).to(haveCount(1))
                    expect(client.channels.get("test")).to(beIdenticalTo(channel))
                    expect(client.channels.collection).to(haveCount(1))
                }

                // RTS3b
                it("should be possible to specify a ChannelOptions") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let options = ARTChannelOptions()
                    let channel = client.channels.get("test", options: options)
                    expect(channel.options).to(beIdenticalTo(options))
                }

                // RTS3c
                it("accessing an existing Channel with options should update the options and then return the object") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    expect(client.channels.get("test").options).toNot(beNil())
                    let options = ARTChannelOptions()
                    let channel = client.channels.get("test", options: options)
                    expect(channel.options).to(beIdenticalTo(options))
                }

            }

            // RTS4
            context("release") {
                it("should release a channel") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }

                    let channel = client.channels.get("test")
                    channel.subscribe { _ in
                        fail("shouldn't happen")
                    }
                    channel.presence.subscribe { _ in
                        fail("shouldn't happen")
                    }
                    waitUntil(timeout: testTimeout) { done in
                        client.channels.release("test") { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                            done()
                        }
                    }

                    let sameChannel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        sameChannel.subscribe { _ in
                            sameChannel.presence.enterClient("foo", data: nil) { _ in
                                delay(0.0) { done() } // Delay to make sure EventEmitter finish its cycle.
                            }
                        }
                        sameChannel.publish("foo", data: nil)
                    }
                }
            }

        }
    }
}
