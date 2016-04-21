//
//  RestClient.stats.swift
//  ably
//
//  Created by Yavor Georgiev on 11.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import SwiftyJSON
import Foundation

private func postTestStats(stats: JSON) -> ARTClientOptions {
    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions, forceNewApp: true);
    
    let keyBase64 = encodeBase64(options.key ?? "")

    let request = NSMutableURLRequest(URL: NSURL(string: "\(AblyTests.clientOptions().restUrl().absoluteString)/stats")!)
    
    request.HTTPMethod = "POST"
    request.HTTPBody = try? stats.rawData()
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

private func queryStats(client: ARTRest, _ query: ARTStatsQuery) -> ARTPaginatedResult {
    var stats: ARTPaginatedResult?
    let dummyError = ARTErrorInfo()
    var error: ARTErrorInfo? = dummyError

    try! client.stats(query, callback: { result, err in
        stats = result
        error = err
    })

    while error === dummyError {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Bool(0))
    }
    
    if let error = error {
        XCTFail(error.message)
    }
    
    return stats!
}

private func getPage(paginator: ((ARTPaginatedResult?, ARTErrorInfo?) -> Void) -> Void) -> ARTPaginatedResult {
    var newResult: ARTPaginatedResult?
    let dummyError = ARTErrorInfo()
    var error: ARTErrorInfo? = dummyError
    paginator({ paginatorResult, err in
        newResult = paginatorResult
        error = err
    })
    
    while error === dummyError {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CFTimeInterval(0.1), Bool(0))
    }
    
    if let error = error {
        XCTFail(error.message)
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
                    dateComponents.year = calendar.component(NSCalendarUnit.Year, fromDate: NSDate()) - 1
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
                        
                        let totalInbound = result.items.reduce(0 as UInt, combine: {
                            if let stats = $1 as? ARTStats {
                                return $0 + stats.inbound.all.messages.count
                            }
                            return $0
                        })
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        
                        let totalOutbound = result.items.reduce(0 as UInt, combine: {
                            if let stats = $1 as? ARTStats {
                                return $0 + stats.outbound.all.messages.count
                            }
                            return $0
                        })
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should match hour-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .Forwards
                        query.unit = .Hour
                        
                        let result = queryStats(client, query)
                        let totalInbound = result.items.reduce(0 as UInt, combine: {
                            if let stats = $1 as? ARTStats {
                                return $0 + stats.inbound.all.messages.count
                            }
                            return $0
                        })
                        let totalOutbound = result.items.reduce(0 as UInt, combine: {
                            if let stats = $1 as? ARTStats {
                                return $0 + stats.outbound.all.messages.count
                            }
                            return $0
                        })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should match day-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.dateByAddingUnit(.Day, value: 1, toDate: date, options: NSCalendarOptions(rawValue: 0))
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
                        query.end = calendar.dateByAddingUnit(.Month, value: 1, toDate: date, options: NSCalendarOptions(rawValue: 0))
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
                        it("should return an error when later than end") {
                            let client = ARTRest(key: "fake:key")
                            let query = ARTStatsQuery()
                            
                            query.start = NSDate.distantFuture()
                            query.end = NSDate.distantPast()

                            expect{try client.stats(query, callback:{ status, result in })}.to(throwError())
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
                        
                        it("should return an error when greater than 1000") {
                            let client = ARTRest(key: "fake:key")
                            let query = ARTStatsQuery()
                            
                            query.limit = 1001;

                            expect{try client.stats(query, callback:{ status, result in })}.to(throwError())
                        }
                    }
                    
                    // RSC6b4
                    context("unit") {
                        it("should default to minute") {
                            let query = ARTStatsQuery()
                            
                            expect(query.unit).to(equal(ARTStatsGranularity.Minute))
                        }
                    }
                }
            }
        }
    }
}
