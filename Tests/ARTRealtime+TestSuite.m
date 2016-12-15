//
//  ARTRealtime+TestSuite.m
//  Ably
//
//  Created by Ricardo Pereira on 19/09/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#import "ARTRealtime+TestSuite.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTRealtimeChannels+Private.h"

@implementation ARTRealtime (TestSuite)

- (void)testSuite_waitForConnectionToClose:(XCTestCase *)testCase {
    if (self.connection.state == ARTRealtimeConnected) {
        __weak XCTestExpectation *expectation = [testCase expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];

        [self.channels.collection enumerateKeysAndObjectsUsingBlock:^(NSString *channelName, ARTRealtimeChannel *channel, BOOL *stop) {
            [channel off];
            [channel unsubscribe];
            [channel.presence unsubscribe];
        }];
        [self.connection off];

        [self.connection once:ARTRealtimeConnectionEventClosed callback:^(ARTConnectionStateChange *stateChange) {
            [expectation fulfill];
        }];

        [self close];

        [testCase waitForExpectationsWithTimeout:1.0 handler:nil];
    }
}

@end
