import Ably
import Quick
import Nimble

class RestClientPresence: XCTestCase {
        

            // RSP3
            

                // RSP3a
                func skipped__test__002__Presence__get__should_return_a_PaginatedResult_page_containing_the_first_page_of_members() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.dispose()
                            clientItem.close()
                        }
                    }

                    let expectedData = "online"
                    let expectedPattern = "^user(\\d+)$"

                    // Load 150 members (2 pages)
                    disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 150, data:expectedData as AnyObject?, options: options)]

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { membersPage, error in
                            expect(error).to(beNil())

                            let membersPage = membersPage!
                            expect(membersPage).to(beAnInstanceOf(ARTPaginatedResult<ARTPresenceMessage>.self))
                            expect(membersPage.items).to(haveCount(100))

                            let members = membersPage.items 
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                    && (member!.data as? String) == expectedData
                            }))

                            expect(membersPage.hasNext).to(beTrue())
                            expect(membersPage.isLast).to(beFalse())

                            membersPage.next { nextPage, error in
                                expect(error).to(beNil())
                                let nextPage = nextPage!
                                expect(nextPage).to(beAnInstanceOf(ARTPaginatedResult<ARTPresenceMessage>.self))
                                expect(nextPage.items).to(haveCount(50))

                                let members = nextPage.items 
                                expect(members).to(allPass({ member in
                                    return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                        && (member!.data as? String) == expectedData
                                }))

                                expect(nextPage.hasNext).to(beFalse())
                                expect(nextPage.isLast).to(beTrue())
                                done()
                            }
                        }
                    }
                }

                // RSP3a1
                func test__003__Presence__get__limit_should_support_up_to_1000_items() {
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTPresenceQuery()
                    expect(query.limit).to(equal(100))

                    query.limit = 1001
                    expect{ try channel.presence.get(query, callback: { _, _ in }) }.to(throwError())

                    query.limit = 1000
                    expect{ try channel.presence.get(query, callback: { _, _ in }) }.toNot(throwError())
                }

                // RSP3a2
                func test__004__Presence__get__clientId_should_filter_members_by_the_provided_clientId() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    let realtime = ARTRealtime(options: options)
                    defer { realtime.close() }
                    let realtimeChannel = realtime.channels.get("test")

                    realtimeChannel.presence.enterClient("ana", data: "mobile")
                    realtimeChannel.presence.enterClient("john", data: "web")
                    realtimeChannel.presence.enterClient("casey", data: "mobile")

                    expect(realtimeChannel.internal.presenceMap.members).toEventually(haveCount(3), timeout: testTimeout)

                    let query = ARTPresenceQuery()
                    query.clientId = "john"

                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try channel.presence.get(query) { membersPage, error in
                                expect(error).to(beNil())
                                expect(membersPage!.items).to(haveCount(1))
                                let member = membersPage!.items[0]
                                expect(member.clientId).to(equal("john"))
                                expect(member.data as? NSObject).to(equal("web" as NSObject?))
                                done()
                            }
                        }.toNot(throwError())
                    }
                }

                // RSP3a3
                func test__005__Presence__get__connectionId_should_filter_members_by_the_provided_connectionId() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.dispose()
                            clientItem.close()
                        }
                    }

                    // One connection
                    disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 6, options: options)]

                    // Another connection
                    disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 3, startFrom: 7, options: options)]

                    let query = ARTRealtimePresenceQuery()
                    // Return all members from last connection (connectionId from the last connection)
                    query.connectionId = disposable.last!.connection.id!

                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try channel.presence.get(query) { membersPage, error in
                                expect(error).to(beNil())
                                expect(membersPage!.items).to(haveCount(3))
                                expect(membersPage!.hasNext).to(beFalse())
                                expect(membersPage!.isLast).to(beTrue())
                                expect(membersPage!.items).to(allPass({ member in
                                    let member = member!
                                    return NSRegularExpression.match(member.clientId, pattern: "^user(7|8|9)")
                                }))
                                done()
                            }
                        }.toNot(throwError())
                    }
                }

            // RSP4
            

                // RSP4a
                func test__006__Presence__history__should_return_a_PaginatedResult_page_containing_the_first_page_of_members() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    var realtime: ARTRealtime!
                    defer { realtime.dispose(); realtime.close() }

                    let expectedData = "online"
                    let expectedPattern = "^user(\\d+)$"
                    realtime = AblyTests.addMembersSequentiallyToChannel("test", members: 150, data: expectedData as AnyObject?, options: options)

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.history { membersPage, error in
                            expect(error).to(beNil())
                            guard let membersPage = membersPage else {
                                fail("Page is empty"); done(); return
                            }
                            expect(membersPage).to(beAnInstanceOf(ARTPaginatedResult<ARTPresenceMessage>.self))
                            expect(membersPage.items).to(haveCount(100))

                            let members = membersPage.items 
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                    && (member!.data as? String) == expectedData
                            }))

                            expect(membersPage.hasNext).to(beTrue())
                            expect(membersPage.isLast).to(beFalse())

                            membersPage.next { nextPage, error in
                                expect(error).to(beNil())
                                guard let nextPage = nextPage else {
                                    fail("nextPage is empty"); done(); return
                                }
                                expect(nextPage).to(beAnInstanceOf(ARTPaginatedResult<ARTPresenceMessage>.self))
                                expect(nextPage.items).to(haveCount(50))

                                let members = nextPage.items 
                                expect(members).to(allPass({ member in
                                    return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                        && (member!.data as? String) == expectedData
                                }))

                                expect(nextPage.hasNext).to(beFalse())
                                expect(nextPage.isLast).to(beTrue())
                                done()
                            }
                        }
                    }
                }

            // RSP4
            

                // RSP4b
                

                    // RSP4b2
                    // Disabled because there's something wrong in the Sandbox.
                    // More info at https://ably-real-time.slack.com/archives/C030C5YLY/p1614269570000400
                    func skipped__test__007__Presence__history__query_argument__direction_should_change_the_order_of_the_members() {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        var disposable = [ARTRealtime]()
                        defer {
                            for clientItem in disposable {
                                clientItem.dispose()
                                clientItem.close()
                            }
                        }

                        disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 10, data:nil, options: options)]

                        let query = ARTDataQuery()
                        expect(query.direction).to(equal(ARTQueryDirection.backwards))

                        waitUntil(timeout: testTimeout) { done in
                            expect {
                                try channel.presence.history(query) { membersPage, error in
                                    expect(error).to(beNil())
                                    let firstMember = membersPage!.items.first!
                                    expect(firstMember.clientId).to(equal("user10"))
                                    let lastMember = membersPage!.items.last!
                                    expect(lastMember.clientId).to(equal("user1"))
                                    done()
                                }
                            }.toNot(throwError())
                        }

                        query.direction = .forwards

                        waitUntil(timeout: testTimeout) { done in
                            expect {
                                try channel.presence.history(query) { membersPage, error in
                                    expect(error).to(beNil())
                                    let firstMember = membersPage!.items.first!
                                    expect(firstMember.clientId).to(equal("user1"))
                                    let lastMember = membersPage!.items.last!
                                    expect(lastMember.clientId).to(equal("user10"))
                                    done()
                                }
                            }.toNot(throwError())
                        }
                    }

            // RSP4
            

                // RSP4b
                

                    // RSP4b3
                    func test__009__Presence__history__query_argument__limit_supports_up_to_1000_members() {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        var realtime: ARTRealtime!
                        defer { realtime.dispose(); realtime.close() }
                        realtime = AblyTests.addMembersSequentiallyToChannel("test", members: 1, options: options)

                        let query = ARTDataQuery()
                        expect(query.limit).to(equal(100))
                        query.limit = 1

                        waitUntil(timeout: testTimeout) { done in
                            expect {
                                try channel.presence.history(query) { membersPage, error in
                                    expect(error).to(beNil())
                                    expect(membersPage!.items).to(haveCount(1))
                                    expect(membersPage!.hasNext).to(beFalse())
                                    expect(membersPage!.isLast).to(beTrue())
                                    done()
                                }
                            }.toNot(throwError())
                        }

                        query.limit = 1001

                        expect { try channel.presence.history(query) { _, _ in } }.to(throwError { (error: Error) in
                            expect(error._code).to(equal(ARTDataQueryError.limit.rawValue))
                        })
                    }

                // RSP3a3
                func test__008__Presence__history__connectionId_should_filter_members_by_the_provided_connectionId() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.dispose()
                            clientItem.close()
                        }
                    }

                    // One connection
                    disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 6, options: options)]

                    // Another connection
                    disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 3, startFrom: 7, options: options)]

                    let query = ARTRealtimePresenceQuery()
                    // Return all members from last connection (connectionId from the last connection)
                    query.connectionId = disposable.last!.connection.id!

                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try channel.presence.get(query) { membersPage, error in
                                expect(error).to(beNil())
                                expect(membersPage!.items).to(haveCount(3))
                                expect(membersPage!.hasNext).to(beFalse())
                                expect(membersPage!.isLast).to(beTrue())
                                expect(membersPage!.items).to(allPass({ member in
                                    let member = member 
                                    return NSRegularExpression.match(member!.clientId, pattern: "^user(7|8|9)")
                                }))
                                done()
                            }
                        }.toNot(throwError())
                    }
                }

            // RSP4
            

                // RSP4b
                

                    // RSP4b1
                    func test__010__Presence__history__query_argument__start_and_end_should_filter_members_between_those_two_times() {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        var disposable = [ARTRealtime]()
                        defer {
                            for clientItem in disposable {
                                clientItem.dispose()
                                clientItem.close()
                            }
                        }

                        let query = ARTDataQuery()

                        disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 25, options: options)]

                        waitUntil(timeout: testTimeout) { done in
                            client.time { time, error in
                                expect(error).to(beNil())
                                query.start = time
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            delay(1.5) { done() }
                        }

                        disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 3, options: options)]

                        waitUntil(timeout: testTimeout) { done in
                            client.time { time, error in
                                expect(error).to(beNil())
                                query.end = time
                                done()
                            }
                        }

                        disposable += [AblyTests.addMembersSequentiallyToChannel("test", members: 10, options: options)]

                        waitUntil(timeout: testTimeout) { done in
                            expect {
                                try channel.presence.history(query) { membersPage, error in
                                    expect(error).to(beNil())
                                    expect(membersPage!.items).to(haveCount(3))
                                    done()
                                }
                            }.toNot(throwError())
                        }
                    }

                    // RSP4b1
                    func test__011__Presence__history__query_argument__start_must_be_equal_to_or_less_than_end_and_is_unaffected_by_the_request_direction() {
                        let client = ARTRest(options: AblyTests.commonAppSetup())
                        let channel = client.channels.get("test")

                        let query = ARTDataQuery()
                        query.direction = .backwards
                        query.end = NSDate() as Date
                        query.start = query.end!.addingTimeInterval(10.0)

                        expect { try channel.presence.history(query) { _, _ in } }.to(throwError { (error: Error) in
                            expect(error._code).to(equal(ARTDataQueryError.timestampRange.rawValue))
                        })

                        query.direction = .forwards

                        expect { try channel.presence.history(query) { _, _ in } }.to(throwError { (error: Error) in
                            expect(error._code).to(equal(ARTDataQueryError.timestampRange.rawValue))
                        })
                    }

            // RSP5
            func test__001__Presence__presence_messages_retrieved_are_decoded_in_the_same_way_that_messages_are_decoded() {
                let options = AblyTests.commonAppSetup()
                let client = ARTRest(options: options)
                let channel = client.channels.get("test")

                let expectedData = ["test":1]

                waitUntil(timeout: testTimeout) { done in
                    channel.publish(nil, data: expectedData) { _ in done() }
                }

                let realtime = ARTRealtime(options: options)
                defer { realtime.dispose(); realtime.close() }
                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(2, done: done)
                    let channel = realtime.channels.get("test")
                    channel.presence.enterClient("john", data: expectedData) { _ in
                        partialDone()
                    }
                    channel.presence.subscribe { _ in
                        channel.presence.unsubscribe()
                        partialDone()
                    }
                }

                typealias Done = () -> Void
                func checkReceivedMessage<T: ARTBaseMessage>(_ done: @escaping Done) -> (ARTPaginatedResult<T>?, ARTErrorInfo?) -> Void {
                    return { membersPage, error in
                        expect(error).to(beNil())
                        let member = membersPage!.items[0]
                        expect(member.data as? NSDictionary).to(equal(expectedData as NSDictionary?))
                        done()
                    }
                }

                var decodeNumberOfCalls = 0
                let hook = channel.internal.dataEncoder.testSuite_injectIntoMethod(after: #selector(ARTDataEncoder.decode(_:encoding:))) {
                    decodeNumberOfCalls += 1
                }
                defer { hook.remove() }

                waitUntil(timeout: testTimeout) { done in
                    channel.history(checkReceivedMessage(done))
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.presence.history(checkReceivedMessage(done))
                }

                expect(decodeNumberOfCalls).to(equal(2))
            }
}
