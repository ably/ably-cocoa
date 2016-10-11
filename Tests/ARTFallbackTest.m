//
//  ARTFallbackTest.m
//  ably
//
//  Created by vic on 19/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ARTFallback.h"
#import "ARTDefault.h"
@interface ARTFallbackTest : XCTestCase
@end

@implementation ARTFallbackTest

- (void)testAllHostsIncludedOnce {
    ARTFallback *f = [[ARTFallback alloc] init];
    NSArray *defaultHosts = [ARTDefault fallbackHosts];
    NSSet *defaultSet = [NSSet setWithArray:defaultHosts];
    NSMutableArray *hostsRandomised = [NSMutableArray array];
    for(int i=0;i < [defaultHosts count]; i++) {
        [hostsRandomised addObject:[f popFallbackHost]];
    }
    //popping after all hosts are exhausted returns nil
    XCTAssertTrue([f popFallbackHost] == nil);
    
    // all fallback hosts are used in artfallback
    XCTAssertEqual([hostsRandomised count], [defaultHosts count]);
    bool inOrder = true;
    for(int i=0;i < [defaultHosts count]; i++) {
        if(![[defaultHosts objectAtIndex:i] isEqualToString:[hostsRandomised objectAtIndex:i]]) {
            inOrder = false;
            break;
        }
    }
    //check artfallback randomises the order.
    XCTAssertFalse(inOrder);
    
    //every member of fallbacks hosts are in the list of default hosts
    for(int i=0;i < [hostsRandomised count]; i++) {
        XCTAssertTrue([defaultSet containsObject:[hostsRandomised objectAtIndex:i]]);
    }    
}

- (void)testCustomFallbackHosts {
    __weak int (^originalARTFallback_getRandomHostIndex)(int) = ARTFallback_getRandomHostIndex;
    @try {
        ARTFallback_getRandomHostIndex = ^() {
            __block NSArray *hostIndexes = @[@1, @2, @0, @1, @0, @0];
            __block int i = 0;
            return ^int(int count) {
                NSNumber *hostIndex = hostIndexes[i];
                i++;
                return hostIndex.intValue;
            };
        }();

        NSArray *customHosts = @[@"testA.ably.com",
                                 @"testB.ably.com",
                                 @"testC.ably.com",
                                 @"testD.ably.com",
                                 @"testE.ably.com",
                                 @"testF.ably.com"];

        ARTFallback *f = [[ARTFallback alloc] initWithFallbackHosts:customHosts];

        XCTAssertEqualObjects([f popFallbackHost], @"testF.ably.com");
        XCTAssertEqualObjects([f popFallbackHost], @"testC.ably.com");
        XCTAssertEqualObjects([f popFallbackHost], @"testE.ably.com");
        XCTAssertEqualObjects([f popFallbackHost], @"testA.ably.com");
        XCTAssertEqualObjects([f popFallbackHost], @"testD.ably.com");
        XCTAssertEqualObjects([f popFallbackHost], @"testB.ably.com");

        XCTAssertEqual([f popFallbackHost], nil);
    }
    @finally {
        ARTFallback_getRandomHostIndex = originalARTFallback_getRandomHostIndex;
    }
}

@end
