//
//  RestClientPresence.swift
//  Ably
//
//  Created by Ricardo Pereira on 18/03/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble

class RestClientPresence: QuickSpec {
    override func spec() {
        describe("Presence") {

            // RSP3
            context("get") {

                // RSP3a
                it("should return a PaginatedResult page containing the first page of members") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.close()
                        }
                    }

                    let expectedData = "online"
                    let expectedPattern = "^user(\\d+)$"
                    waitUntil(timeout: testTimeout) { done in
                        // Load 150 members (2 pages)
                        disposable += AblyTests.addMembersSequentiallyToChannel("test", members: 150, data:expectedData, options: options) {
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { membersPage, error in
                            expect(error).to(beNil())

                            let membersPage = membersPage!
                            expect(membersPage).to(beAnInstanceOf(ARTPaginatedResult))
                            expect(membersPage.items).to(haveCount(100))

                            let members = membersPage.items as! [ARTPresenceMessage]
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                    && (member!.data as? NSObject) == expectedData
                            }))

                            expect(membersPage.hasNext).to(beTrue())
                            expect(membersPage.isLast).to(beFalse())

                            membersPage.next { nextPage, error in
                                expect(error).to(beNil())
                                let nextPage = nextPage!
                                expect(nextPage).to(beAnInstanceOf(ARTPaginatedResult))
                                expect(nextPage.items).to(haveCount(50))

                                let members = nextPage.items as! [ARTPresenceMessage]
                                expect(members).to(allPass({ member in
                                    return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                        && (member!.data as? NSObject) == expectedData
                                }))

                                expect(nextPage.hasNext).to(beFalse())
                                expect(nextPage.isLast).to(beTrue())
                                done()
                            }
                        }
                    }
                }

            }

            // RSP4
            context("history") {

                // RSP4a
                it("should return a PaginatedResult page containing the first page of members") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    var realtime: ARTRealtime!
                    defer { realtime.close() }

                    let expectedData = "online"
                    let expectedPattern = "^user(\\d+)$"
                    waitUntil(timeout: testTimeout) { done in
                        realtime = AblyTests.addMembersSequentiallyToChannel("test", members: 150, data: expectedData, options: options) {
                            done()
                        }.first
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.history { membersPage, error in
                            expect(error).to(beNil())

                            let membersPage = membersPage!
                            expect(membersPage).to(beAnInstanceOf(ARTPaginatedResult))
                            expect(membersPage.items).to(haveCount(100))

                            let members = membersPage.items as! [ARTPresenceMessage]
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                    && (member!.data as? NSObject) == expectedData
                            }))

                            expect(membersPage.hasNext).to(beTrue())
                            expect(membersPage.isLast).to(beFalse())

                            membersPage.next { nextPage, error in
                                expect(error).to(beNil())
                                let nextPage = nextPage!
                                expect(nextPage).to(beAnInstanceOf(ARTPaginatedResult))
                                expect(nextPage.items).to(haveCount(50))

                                let members = nextPage.items as! [ARTPresenceMessage]
                                expect(members).to(allPass({ member in
                                    return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                        && (member!.data as? NSObject) == expectedData
                                }))

                                expect(nextPage.hasNext).to(beFalse())
                                expect(nextPage.isLast).to(beTrue())
                                done()
                            }
                        }
                    }
                }

            }

            // RSP4
            context("history") {

                // RSP4b
                context("query argument") {

                    // RSP4b2
                    it("direction should change the order of the members") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        var disposable = [ARTRealtime]()
                        defer {
                            for clientItem in disposable {
                                clientItem.close()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            disposable += AblyTests.addMembersSequentiallyToChannel("test", members: 10, data:nil, options: options) {
                                done()
                            }
                        }

                        let query = ARTDataQuery()
                        expect(query.direction).to(equal(ARTQueryDirection.Backwards))

                        waitUntil(timeout: testTimeout) { done in
                            try! channel.presence.history(query) { membersPage, error in
                                expect(error).to(beNil())
                                let firstMember = membersPage!.items.first as! ARTPresenceMessage
                                expect(firstMember.clientId).to(equal("user10"))
                                let lastMember = membersPage!.items.last as! ARTPresenceMessage
                                expect(lastMember.clientId).to(equal("user1"))
                                done()
                            }
                        }

                        query.direction = .Forwards

                        waitUntil(timeout: testTimeout) { done in
                            try! channel.presence.history(query) { membersPage, error in
                                expect(error).to(beNil())
                                let firstMember = membersPage!.items.first as! ARTPresenceMessage
                                expect(firstMember.clientId).to(equal("user1"))
                                let lastMember = membersPage!.items.last as! ARTPresenceMessage
                                expect(lastMember.clientId).to(equal("user10"))
                                done()
                            }
                        }
                    }

                }

            }

            // RSP4
            context("history") {

                // RSP4b
                context("query argument") {

                    // RSP4b3
                    it("limit supports up to 1000 members") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        var realtime: ARTRealtime!
                        defer { realtime.close() }

                        waitUntil(timeout: testTimeout) { done in
                            realtime = AblyTests.addMembersSequentiallyToChannel("test", members: 1, options: options) {
                                done()
                            }.first
                        }

                        let query = ARTDataQuery()
                        expect(query.limit).to(equal(100))
                        query.limit = 1

                        waitUntil(timeout: testTimeout) { done in
                            try! channel.presence.history(query) { membersPage, error in
                                expect(error).to(beNil())
                                expect(membersPage!.items).to(haveCount(1))
                                expect(membersPage!.hasNext).to(beFalse())
                                expect(membersPage!.isLast).to(beTrue())
                                done()
                            }
                        }

                        query.limit = 1001

                        expect { try channel.presence.history(query) { _, _ in } }.to(throwError { (error: ErrorType) in
                            expect(error._code).to(equal(ARTDataQueryError.Limit.rawValue))
                        })
                    }
                }

            }

        }
    }
}

