import Ably
import Quick
import Nimble

// Swift isn't yet smart enough to do this automatically when bridging Objective-C APIs
extension ARTRealtimeChannels: Sequence {
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self.iterate())
    }
}

class RealtimeClientChannels: XCTestCase {
        

            // RTS2
            func test__001__Channels__should_exist_methods_to_check_if_a_channel_exists_or_iterate_through_the_existing_channels() {
                let client = ARTRealtime(options: AblyTests.commonAppSetup())
                defer { client.dispose(); client.close() }
                var disposable = [String]()

                disposable.append(client.channels.get("test1").name)
                disposable.append(client.channels.get("test2").name)
                disposable.append(client.channels.get("test3").name)

                expect(client.channels.get("test2")).toNot(beNil())
                expect(client.channels.exists("test2")).to(beTrue())
                expect(client.channels.exists("testX")).to(beFalse())

                for channel in client.channels {
                    expect(disposable.contains((channel as! ARTRealtimeChannel).name)).to(beTrue())
                }
            }

            // RTS3
            

                // RTS3a
                func test__002__Channels__get__should_create_a_new_Channel_if_none_exists_or_return_the_existing_one() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    expect(client.channels.internal.collection).to(haveCount(0))
                    let channel = client.channels.get("test")
                    expect(channel.name).to(equal("\(options.channelNamePrefix!)-test"))

                    expect(client.channels.internal.collection).to(haveCount(1))
                    expect(client.channels.get("test").internal).to(beIdenticalTo(channel.internal))
                    expect(client.channels.internal.collection).to(haveCount(1))
                }

                // RTS3b
                func test__003__Channels__get__should_be_possible_to_specify_a_ChannelOptions() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    let options = ARTRealtimeChannelOptions()
                    let channel = client.channels.get("test", options: options)
                    expect(channel.options).to(beIdenticalTo(options))
                }

                // RTS3c
                func test__004__Channels__get__accessing_an_existing_Channel_with_options_should_update_the_options_and_then_return_the_object() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    expect(client.channels.get("test").options).to(beNil())
                    let options = ARTRealtimeChannelOptions()
                    let channel = client.channels.get("test", options: options)
                    expect(channel.options).to(beIdenticalTo(options))
                }

            // RTS4
            
                func test__005__Channels__release__should_release_a_channel() {
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
                            expect(channel.state).to(equal(ARTRealtimeChannelState.detached))
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
