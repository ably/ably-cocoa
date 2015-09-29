//
//  RestClient.stats.swift
//  ably
//
//  Created by Yavor Georgiev on 11.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import ably
import SwiftyJSON
import Foundation

private func postTestStats(stats: JSON) -> ARTClientOptions {
    let options = AblyTests.commonAppSetup()
    let key = ("\(options.authOptions.keyName):\(options.authOptions.keySecret)" as NSString)
        .dataUsingEncoding(NSUTF8StringEncoding)!
        .base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))

    let request = NSMutableURLRequest(URL: NSURL(string: "https://\(options.restHost)/stats")!)
    request.HTTPMethod = "POST"
    request.HTTPBody = stats.rawData()
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Basic \(key)", forHTTPHeaderField: "Authorization")

    var responseError: NSError?
    var httpResponse: NSHTTPURLResponse?
    var requestCompleted = false

    NSURLSession.sharedSession()
        .dataTaskWithRequest(request) { _, response, error in
            responseError = error
            httpResponse = response as? NSHTTPURLResponse
            requestCompleted = true
        }.resume()

    while !requestCompleted {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Boolean(0))
    }

    if let error = responseError {
        XCTFail(error.localizedDescription)
    } else if let response = httpResponse {
        if response.statusCode != 201 {
            XCTFail("Posting stats fixtures failed")
        }
    }

    return options
}

private func queryStats(client: ARTRest, query: ARTStatsQuery) -> ARTPaginatedResult {
    var stats: ARTPaginatedResult?
    var status: ARTStatus?
    client.stats(query, callback: { (statsStatus, result) in
        stats = result
        status = statsStatus
    })

    while status == nil {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Boolean(0))
    }

    if status!.state != .Ok {
        XCTFail(status!.errorInfo.message)
    }

    return stats!
}

private func getPage(paginator: (ARTPaginatedResultCallback!) -> Void) -> ARTPaginatedResult {
    var newResult: ARTPaginatedResult?
    var status: ARTStatus?
    paginator({ (paginatorStatus, paginatorResult) in
        newResult = paginatorResult
        status = paginatorStatus
    })

    while status == nil {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Boolean(0))
    }

    if status!.state != .Ok {
        XCTFail(status!.errorInfo.message)
    }

    return newResult!
}

class RestClientStats: QuickSpec {
    override func spec() {
        describe("RestClient") {
            // RSC6
            context("stats") {
                // RSC6a
                context("result") {
                    let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
                    let dateComponents = NSDateComponents()
                    dateComponents.year = calendar.component(.CalendarUnitYear, fromDate: NSDate()) - 1
                    dateComponents.month = 2
                    dateComponents.day = 3
                    dateComponents.hour = 16
                    dateComponents.minute = 3
                    let date = calendar.dateFromComponents(dateComponents)!
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                    dateFormatter.dateFormat = "YYYY-MM-dd:HH:mm"

                    let statsFixtures: JSON = [
                        [
                            "intervalId": dateFormatter.stringFromDate(date), // 20XX-02-03:16:03
                            "inbound": [ "realtime": [ "messages": [ "count": 50, "data": 5000 ] ] ],
                            "outbound": [ "realtime": [ "messages": [ "count": 20, "data": 2000 ] ] ]
                        ],
                        [
                            "intervalId": dateFormatter.stringFromDate(date.dateByAddingTimeInterval(60)), // 20XX-02-03:16:04
                            "inbound": [ "realtime": [ "messages": [ "count": 60, "data": 6000 ] ] ],
                            "outbound": [ "realtime": [ "messages": [ "count": 10, "data": 1000 ] ] ]
                        ],
                        [
                            "intervalId": dateFormatter.stringFromDate(date.dateByAddingTimeInterval(120)), // 20XX-02-03:16:05
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
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .Forwards

                        let result = queryStats(client, query)
                        expect(result.items.count).to(equal(3))

                        let totalInbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.inbound.all.messages.count })
                        expect(totalInbound).to(equal(50 + 60 + 70))

                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.outbound.all.messages.count })
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }

                    it("should match hour-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .Forwards
                        query.unit = .Hour

                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.outbound.all.messages.count })

                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }

                    it("should match day-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.dateByAddingUnit(.CalendarUnitDay, value: 1, toDate: date, options: NSCalendarOptions(0))
                        query.direction = .Forwards
                        query.unit = .Month

                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.outbound.all.messages.count })

                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }

                    it("should match month-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.dateByAddingUnit(.CalendarUnitMonth, value: 1, toDate: date, options: NSCalendarOptions(0))
                        query.direction = .Forwards
                        query.unit = .Month

                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.outbound.all.messages.count })

                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }

                    it("should contain only one item when limit is 1 (backwards") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.dateByAddingTimeInterval(60) // 20XX-02-03:16:04
                        query.limit = 1

                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.outbound.all.messages.count })

                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(60))
                        expect(totalOutbound).to(equal(10))
                    }

                    it("should contain only one item when limit is 1 (forwards") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.dateByAddingTimeInterval(60) // 20XX-02-03:16:04
                        query.limit = 1
                        query.direction = .Forwards

                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, combine: { $0 + $1.outbound.all.messages.count })

                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50))
                        expect(totalOutbound).to(equal(20))
                    }

                    it("should be paginated according to the limit (backwards") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.dateByAddingTimeInterval(120) // 20XX-02-03:16:05
                        query.limit = 1


                        let firstPage = queryStats(client, query)
                        expect(firstPage.items.count).to(equal(1))
                        expect((firstPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(7000))
                        expect(firstPage.hasNext).to(beTrue())
                        expect(firstPage.isLast).to(beFalse())

                        let secondPage = getPage(firstPage.next)
                        expect(secondPage.items.count).to(equal(1))
                        expect((secondPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(6000))
                        expect(secondPage.hasNext).to(beTrue())
                        expect(secondPage.isLast).to(beFalse())

                        let thirdPage = getPage(secondPage.next)
                        expect(thirdPage.items.count).to(equal(1))
                        expect((thirdPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(5000))
                        expect(thirdPage.hasFirst).to(beTrue())
                        expect(thirdPage.isLast).to(beTrue())

                        let firstPageAgain = getPage(thirdPage.first)
                        expect(firstPageAgain.items.count).to(equal(1))
                        expect((firstPageAgain.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(7000))
                    }

                    it("should be paginated according to the limit (fowards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.dateByAddingTimeInterval(120) // 20XX-02-03:16:05
                        query.limit = 1
                        query.direction = .Forwards


                        let firstPage = queryStats(client, query)
                        expect(firstPage.items.count).to(equal(1))
                        expect((firstPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(5000))
                        expect(firstPage.hasNext).to(beTrue())
                        expect(firstPage.isLast).to(beFalse())

                        let secondPage = getPage(firstPage.next)
                        expect(secondPage.items.count).to(equal(1))
                        expect((secondPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(6000))
                        expect(secondPage.hasNext).to(beTrue())
                        expect(secondPage.isLast).to(beFalse())

                        let thirdPage = getPage(secondPage.next)
                        expect(thirdPage.items.count).to(equal(1))
                        expect((thirdPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(7000))
                        expect(thirdPage.hasFirst).to(beTrue())
                        expect(thirdPage.isLast).to(beTrue())

                        let firstPageAgain = getPage(thirdPage.first)
                        expect(firstPageAgain.items.count).to(equal(1))
                        expect((firstPageAgain.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(5000))
                    }
                }

                // RSC6b
                context("query") {
                    // RSC6b1
                    context("start") {
                        it("should throw when later than end") {
                            let client = ARTRest(key: "fake:key")
                            let query = ARTStatsQuery()

                            query.start = NSDate.distantFuture() as! NSDate
                            query.end = NSDate.distantPast() as! NSDate

                            expect{ client.stats(query, callback: nil) }.to(raiseException())
                        }
                    }

                    // RSC6b2
                    context("direction") {
                        it("should be backwards by default") {
                            let query = ARTStatsQuery()

                            expect(query.direction).to(equal(ARTQueryDirection.Backwards));
                        }
                    }

                    // RSC6b3
                    context("limit") {
                        it("should have a default value of 100") {
                            let query = ARTStatsQuery()

                            expect(query.limit).to(equal(100));
                        }

                        it("should throw when greater than 1000") {
                            let client = ARTRest(key: "fake:key")
                            let query = ARTStatsQuery()

                            query.limit = 1001;

                            expect{ client.stats(query, callback: nil) }.to(raiseException())
                        }
                    }

                    // RSC6b4
                    context("unit") {
                        it("should default to minute") {
                            let query = ARTStatsQuery()

                            expect(query.unit).to(equal(ARTStatsUnit.Minute))
                        }
                    }
                }
            }
        }
    }
}
