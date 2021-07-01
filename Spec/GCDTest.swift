//
//  GCDTest.swift
//  Ably
//
//  Created by Mikey on 12/01/2021.
//  Copyright © 2021 Ably. All rights reserved.
//
import XCTest

class GCDTest: XCTestCase {
    func testScheduledBlockHandleDerefsBlockAfterInvoke() {
        let invokedExpectation = self.expectation(description: "scheduled block invoked")
        
        var object = NSObject()
        weak var weakObject = object
        
        var scheduledBlock = artDispatchScheduled(0, .main) { [object] in
            _ = object
            invokedExpectation.fulfill()
        }

        _ = scheduledBlock
        
        waitForExpectations(timeout: 2, handler: nil)
        scheduledBlock = nil

        object = NSObject()
        XCTAssertNil(weakObject)
    }
}
