//
//  RestClient.stats.swift
//  ably
//
//  Created by Yavor Georgiev on 11.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Ably
import Nimble
import Quick
import SwiftyJSON
import Foundation

private func postTestStats(_ stats: JSON) -> ARTClientOptions {
    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions, forceNewApp: true);
    
    let keyBase64 = encodeBase64(options.key ?? "")

    let request = NSMutableURLRequest(url: URL(string: "\(AblyTests.clientOptions().restUrl().absoluteString)/stats")!)
    
    request.httpMethod = "POST"
    request.httpBody = try? stats.rawData()
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Basic \(keyBase64)", forHTTPHeaderField: "Authorization")
    
    let (_, responseError, httpResponse) = NSURLSessionServerTrustSync().get(request)

    if let error = responseError {
        XCTFail(error.localizedDescription)
    } else if let response = httpResponse {
        if response.statusCode != 201 {
            XCTFail("Posting stats fixtures failed: code response \(response.statusCode)")
        }
    }
    
    return options
}

private func queryStats(_ client: ARTRestInternal, _ query: ARTStatsQuery, file: FileString = #file, line: UInt = #line) -> ARTPaginatedResult<ARTStats> {
    let (stats, error) = (AblyTests.waitFor(timeout: testTimeout, file: file, line: line) { value in
        expect {
            try client.stats(query, callback: { result, err in
                value((result, err))
            })
        }.toNot(throwError() { _ in value(nil) })
    })!
    if let error = error {
        fail(error.message, file: file, line: line)
    }
    return stats!
}

class RestClientStats: QuickSpec {
    override func spec() {
        describe("RestClient") {
            // RSC6
            context("stats") {
                // RSC6a
                context("result") {
                    let calendar = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!
                    let dateComponents = NSDateComponents()
                    dateComponents.year = calendar.component(NSCalendar.Unit.year, from: NSDate() as Date) - 1
                    dateComponents.month = 2
                    dateComponents.day = 3
                    dateComponents.hour = 16
                    dateComponents.minute = 3
                    let date = calendar.date(from: dateComponents as DateComponents)!
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    dateFormatter.dateFormat = "YYYY-MM-dd:HH:mm"
                    
                    let statsFixtures: JSON = [
                        [
                            "intervalId": dateFormatter.string(from: date), // 20XX-02-03:16:03
                            "inbound": [ "realtime": [ "messages": [ "count": 50, "data": 5000 ] ] ],
                            "outbound": [ "realtime": [ "messages": [ "count": 20, "data": 2000 ] ] ]
                        ],
                        [
                            "intervalId": dateFormatter.string(from: date.addingTimeInterval(60)), // 20XX-02-03:16:04
                            "inbound": [ "realtime": [ "messages": [ "count": 60, "data": 6000 ] ] ],
                            "outbound": [ "realtime": [ "messages": [ "count": 10, "data": 1000 ] ] ]
                        ],
                        [
                            "intervalId": dateFormatter.string(from: date.addingTimeInterval(120)), // 20XX-02-03:16:05
                            "inbound": [ "realtime": [ "messages": [ "count": 70, "data": 7000 ] ] ],
                            "outbound": [ "realtime": [ "messages": [ "count": 40, "data": 4000 ] ] ],
                            "persisted": [ "presence": [ "count": 20, "data": 2000 ] ],
                            "connections": [ "tls": [ "peak": 20,  "opened": 10 ] ],
                            "channels": [ "peak": 50, "opened": 30 ],
                            "apiRequests": [ "succeeded": 50, "failed": 10 ],
                            "tokenRequests": [ "succeeded": 60, "failed": 20 ]
                        ]
                    ]
                    
                    var statsOptions = ARTClientOptions()

                    beforeEach {
                        statsOptions = postTestStats(statsFixtures)
                    }
                    
                    it("should match minute-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRestInternal(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .forwards
                        
                        let result = queryStats(client, query)
                        expect(result.items.count).to(equal(3))
                        
                        let totalInbound = result.items.reduce(0 as UInt, {
                            return $0 + $1.inbound.all.messages.count
                        })
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        
                        let totalOutbound = result.items.reduce(0 as UInt, {
                            return $0 + $1.outbound.all.messages.count
                        })
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should match hour-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRestInternal(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .forwards
                        query.unit = .hour
                        
                        let result = queryStats(client, query)
                        let totalInbound = result.items.reduce(0 as UInt, {
                            return $0 + $1.inbound.all.messages.count
                        })
                        let totalOutbound = result.items.reduce(0 as UInt, {
                            return $0 + $1.outbound.all.messages.count
                        })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should match day-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRestInternal(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.date(byAdding: .day, value: 1, to: date, options: NSCalendar.Options(rawValue: 0))
                        query.direction = .forwards
                        query.unit = .month
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should match month-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRestInternal(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.date(byAdding: .month, value: 1, to: date, options: NSCalendar.Options(rawValue: 0))
                        query.direction = .forwards
                        query.unit = .month
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should contain only one item when limit is 1 (backwards") {
                        let client = ARTRestInternal(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(60) // 20XX-02-03:16:04
                        query.limit = 1
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(60))
                        expect(totalOutbound).to(equal(10))
                    }
                    
                    it("should contain only one item when limit is 1 (forwards") {
                        let client = ARTRestInternal(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(60) // 20XX-02-03:16:04
                        query.limit = 1
                        query.direction = .forwards
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50))
                        expect(totalOutbound).to(equal(20))
                    }
                    
                    it("should be paginated according to the limit (backwards") {
                        let client = ARTRestInternal(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(120) // 20XX-02-03:16:05
                        query.limit = 1

                        let firstPage = queryStats(client, query)
                        expect(firstPage.items.count).to(equal(1))
                        expect((firstPage.items)[0].inbound.all.messages.data).to(equal(7000))
                        expect(firstPage.hasNext).to(beTrue())
                        expect(firstPage.isLast).to(beFalse())
                        
                        guard let secondPage: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            firstPage.next { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(secondPage.items.count).to(equal(1))
                        expect((secondPage.items)[0].inbound.all.messages.data).to(equal(6000))
                        expect(secondPage.hasNext).to(beTrue())
                        expect(secondPage.isLast).to(beFalse())
                        
                        guard let thirdPage: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            secondPage.next { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(thirdPage.items.count).to(equal(1))
                        expect((thirdPage.items)[0].inbound.all.messages.data).to(equal(5000))
                        expect(thirdPage.isLast).to(beTrue())
                        
                        guard let firstPageAgain: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            thirdPage.first { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(firstPageAgain.items.count).to(equal(1))
                        expect((firstPageAgain.items)[0].inbound.all.messages.data).to(equal(7000))
                    }
                    
                    it("should be paginated according to the limit (fowards)") {
                        let client = ARTRestInternal(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(120) // 20XX-02-03:16:05
                        query.limit = 1
                        query.direction = .forwards
                        
                        let firstPage = queryStats(client, query)
                        expect(firstPage.items.count).to(equal(1))
                        expect((firstPage.items)[0].inbound.all.messages.data).to(equal(5000))
                        expect(firstPage.hasNext).to(beTrue())
                        expect(firstPage.isLast).to(beFalse())
                        
                        guard let secondPage: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            firstPage.next { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(secondPage.items.count).to(equal(1))
                        expect((secondPage.items)[0].inbound.all.messages.data).to(equal(6000))
                        expect(secondPage.hasNext).to(beTrue())
                        expect(secondPage.isLast).to(beFalse())
                        
                        guard let thirdPage: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            secondPage.next { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(thirdPage.items.count).to(equal(1))
                        expect((thirdPage.items)[0].inbound.all.messages.data).to(equal(7000))
                        expect(thirdPage.isLast).to(beTrue())
                        
                        guard let firstPageAgain: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            thirdPage.first { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(firstPageAgain.items.count).to(equal(1))
                        expect((firstPageAgain.items)[0].inbound.all.messages.data).to(equal(5000))
                    }
                }
                
                // RSC6b
                context("query") {
                    // RSC6b1
                    context("start") {
                        it("should return an error when later than end") {
                            let client = ARTRestInternal(key: "fake:key")
                            let query = ARTStatsQuery()
                            
                            query.start = NSDate.distantFuture
                            query.end = NSDate.distantPast

                            expect{try client.stats(query, callback:{ status, result in })}.to(throwError())
                        }
                    }
                    
                    // RSC6b2
                    context("direction") {
                        it("should be backwards by default") {
                            let query = ARTStatsQuery()
                            
                            expect(query.direction).to(equal(ARTQueryDirection.backwards));
                        }
                    }
                    
                    // RSC6b3
                    context("limit") {
                        it("should have a default value of 100") {
                            let query = ARTStatsQuery()
                            
                            expect(query.limit).to(equal(100));
                        }
                        
                        it("should return an error when greater than 1000") {
                            let client = ARTRestInternal(key: "fake:key")
                            let query = ARTStatsQuery()
                            
                            query.limit = 1001;

                            expect{try client.stats(query, callback:{ status, result in })}.to(throwError())
                        }
                    }
                    
                    // RSC6b4
                    context("unit") {
                        it("should default to minute") {
                            let query = ARTStatsQuery()
                            
                            expect(query.unit).to(equal(ARTStatsGranularity.minute))
                        }
                    }
                }
            }
        }
    }
}
