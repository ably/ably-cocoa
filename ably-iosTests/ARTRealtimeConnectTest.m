//
//  ARTRealtimeConnectTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"


@interface ARTRealtimeConnectTest : XCTestCase
{
    ARTRealtime * _realtime;
}
@end

@implementation ARTRealtimeConnectTest


- (void)setUp {
    
    [super setUp];
    
}

- (void)tearDown {
    _realtime = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}


- (void)testConnectText{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_connect_text"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

}


- (void)testConnectAfterClose {

    XCTestExpectation *expectation = [self expectationWithDescription:@"test_connect_text"];
    [self withRealtime:^(ARTRealtime *realtime) {
        __block int connectionCount=0;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                connectionCount++;
                if(connectionCount ==1) {
                    [realtime close];
                }
                else if( connectionCount ==2) {
                    [expectation fulfill];
                }
            }
            if( state == ARTRealtimeClosed && connectionCount ==1) {
                [realtime connect];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



/*
 //msgpack not implemented yet
 
- (void)testConnectHeartbeatBinary {
    XCTFail(@"TODO write test");
}
- (void)testConnectBinary{
    XCTFail(@"TODO write test");
}
 
 //heartbeat not implemented yet.
 - (void)testConnectHeartbeatText {
 XCTFail(@"TODO write test");
 }
 */
@end
