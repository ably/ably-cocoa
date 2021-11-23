import Ably
import Nimble
import Quick
import Aspects

// Swift isn't yet smart enough to do this automatically when bridging Objective-C APIs
extension ARTRestChannels: Sequence {
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self.iterate())
    }
}

private func beAChannel(named expectedValue: String) -> Predicate<ARTChannel> {
    return Predicate.define("be a channel with name \"\(expectedValue)\"") { actualExpression, msg -> PredicateResult in
        let actualValue = try! actualExpression.evaluate()
        let m = msg.appended(details: "\"\(actualValue?.name ?? "nil")\" instead")
        return PredicateResult(status: PredicateStatus(bool: actualValue?.name == expectedValue), message: m)
    }
}
        private var client: ARTRest!
        private var channelName: String!

        private let cipherParams: ARTCipherParams? = nil

class RestClientChannels: XCTestCase {

override class var defaultTestSuite : XCTestSuite {
    let _ = client
    let _ = channelName
    let _ = cipherParams

    return super.defaultTestSuite
}


        func beforeEach() {
print("START HOOK: RestClientChannels.beforeEach")

            client = ARTRest(key: "fake:key")
            channelName = ProcessInfo.processInfo.globallyUniqueString
print("END HOOK: RestClientChannels.beforeEach")

        }

        
            
                // RSN1
                func test__001__RestClient__channels__should_return_collection_of_channels() {
beforeEach()

                    let _: ARTRestChannels = client.channels
                }

                // RSN3
                
                    // RSN3a
                    func test__003__RestClient__channels__get__should_return_a_channel() {
beforeEach()

                        let channel = client.channels.get(channelName).internal
                        expect(channel).to(beAChannel(named: channelName))

                        let sameChannel = client.channels.get(channelName).internal
                        expect(sameChannel).to(beIdenticalTo(channel))
                    }

                    // RSN3b
                    func test__004__RestClient__channels__get__should_return_a_channel_with_the_provided_options() {
beforeEach()

                        let options = ARTChannelOptions(cipher: cipherParams)
                        let channel = client.channels.get(channelName, options: options)

                        expect(channel.internal).to(beAChannel(named: channelName))
                        expect(channel.internal.options).to(beIdenticalTo(options))
                    }

                    // RSN3b
                    func test__005__RestClient__channels__get__should_not_replace_the_options_on_an_existing_channel_when_none_are_provided() {
beforeEach()

                        let options = ARTChannelOptions(cipher: cipherParams)
                        let channel = client.channels.get(channelName, options: options).internal

                        let newButSameChannel = client.channels.get(channelName).internal

                        expect(newButSameChannel).to(beIdenticalTo(channel))
                        expect(newButSameChannel.options).to(beIdenticalTo(options))
                    }

                    // RSN3c
                    func test__006__RestClient__channels__get__should_replace_the_options_on_an_existing_channel_when_new_ones_are_provided() {
beforeEach()

                        let channel = client.channels.get(channelName).internal
                        let oldOptions = channel.options

                        let newOptions = ARTChannelOptions(cipher: cipherParams)
                        let newButSameChannel = client.channels.get(channelName, options: newOptions).internal

                        expect(newButSameChannel).to(beIdenticalTo(channel))
                        expect(newButSameChannel.options).to(beIdenticalTo(newOptions))
                        expect(newButSameChannel.options).notTo(beIdenticalTo(oldOptions))
                    }

                // RSN2
                
                    func test__007__RestClient__channels__channelExists__should_check_if_a_channel_exists() {
beforeEach()

                        expect(client.channels.exists(channelName)).to(beFalse())

                        client.channels.get(channelName)

                        expect(client.channels.exists(channelName)).to(beTrue())
                    }

                // RSN4
                
                    func test__008__RestClient__channels__releaseChannel__should_release_a_channel() {
beforeEach()

                        weak var channel: ARTRestChannelInternal!

                        autoreleasepool {
                            channel = client.channels.get(channelName).internal

                            expect(channel).to(beAChannel(named: channelName))
                            client.channels.release(channel.name)
                        }

                        expect(channel).to(beNil())
                    }

                // RSN2
                func test__002__RestClient__channels__should_be_enumerable() {
beforeEach()

                    let channels = [
                        client.channels.get(channelName).internal,
                        client.channels.get(String(channelName.reversed())).internal
                    ]

                    for channel in client.channels {
                        expect(channels).to(contain((channel as! ARTRestChannel).internal))
                    }
                }
}
