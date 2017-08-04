//
//  RestClient.channels.swift
//  ably
//
//  Created by Yavor Georgiev on 21.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Ably
import Nimble
import Quick
import Aspects

// Swift isn't yet smart enough to do this automatically when bridging Objective-C APIs
extension ARTRestChannels: Sequence {
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}

private func beAChannel(named channelName: String) -> Predicate<ARTChannel> {
    return Predicate.fromDeprecatedClosure { actualExpression, failureMessage in
        let channel = try! actualExpression.evaluate()
        failureMessage.expected = "expected \(String(describing: channel))"
        failureMessage.postfixMessage = "be a channel"

        return channel?.name == channelName
    }
}

class RestClientChannels: QuickSpec {
    override func spec() {
        var client: ARTRest!
        var channelName: String!

        beforeEach {
            client = ARTRest(key: "fake:key")
            channelName = ProcessInfo.processInfo.globallyUniqueString
            ARTChannels_getChannelNamePrefix = { "RestClientChannels-" }
        }

        let cipherParams: ARTCipherParams? = nil

        describe("RestClient") {
            context("channels") {
                // RSN1
                it("should return collection of channels") {
                    let _: ARTRestChannels = client.channels
                }

                // RSN3
                context("get") {
                    // RSN3a
                    it("should return a channel") {
                        let channel = client.channels.get(channelName)
                        expect(channel).to(beAChannel(named: "\(ARTChannels_getChannelNamePrefix!())-\(channelName!)"))

                        let sameChannel = client.channels.get(channelName)
                        expect(sameChannel).to(beIdenticalTo(channel))
                    }

                    // RSN3b
                    it("should return a channel with the provided options") {
                        let options = ARTChannelOptions(cipher: cipherParams)
                        let channel = client.channels.get(channelName, options: options)

                        expect(channel).to(beAChannel(named: "\(ARTChannels_getChannelNamePrefix!())-\(channelName!)"))
                        expect(channel.options).to(beIdenticalTo(options))
                    }

                    // RSN3b
                    it("should not replace the options on an existing channel when none are provided") {
                        let options = ARTChannelOptions(cipher: cipherParams)
                        let channel = client.channels.get(channelName, options: options)

                        let newButSameChannel = client.channels.get(channelName)

                        expect(newButSameChannel).to(beIdenticalTo(channel))
                        expect(newButSameChannel.options).to(beIdenticalTo(options))
                    }

                    // RSN3c
                    it("should replace the options on an existing channel when new ones are provided") {
                        let channel = client.channels.get(channelName)
                        let oldOptions = channel.options

                        let newOptions = ARTChannelOptions(cipher: cipherParams)
                        let newButSameChannel = client.channels.get(channelName, options: newOptions)

                        expect(newButSameChannel).to(beIdenticalTo(channel))
                        expect(newButSameChannel.options).to(beIdenticalTo(newOptions))
                        expect(newButSameChannel.options).notTo(beIdenticalTo(oldOptions))
                    }
                }

                // RSN2
                context("channelExists") {
                    it("should check if a channel exists") {
                        expect(client.channels.exists(channelName)).to(beFalse())

                        client.channels.get(channelName)

                        expect(client.channels.exists(channelName)).to(beTrue())
                    }
                }

                // RSN4
                context("releaseChannel") {
                    it("should release a channel") {
                        weak var channel: ARTRestChannel!

                        autoreleasepool {
                            channel = client.channels.get(channelName)

                            expect(channel).to(beAChannel(named: "\(ARTChannels_getChannelNamePrefix!())-\(channelName!)"))
                            client.channels.release(channel.name)
                        }

                        expect(channel).to(beNil())
                    }
                }

                // RSN2
                it("should be enumerable") {
                    let channels = [
                        client.channels.get(channelName),
                        client.channels.get(String(channelName.characters.reversed()))
                    ]

                    for channel in client.channels {
                        expect(channels).to(contain(channel as! ARTRestChannel))
                    }
                }
            }
        }
    }
}
