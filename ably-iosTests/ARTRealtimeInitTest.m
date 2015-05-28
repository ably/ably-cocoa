//
//  ARTRealtimeInitTets.m
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
#import "ARTOptions+Private.h"
#import "ARTLog.h"

@interface ARTRealtimeInitTest : XCTestCase {
    ARTRealtime * _realtime;
}
@end

@implementation ARTRealtimeInitTest


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [ARTOptions getDefaultRestHost:@"rest.ably.io" modify:true];
    [ARTOptions getDefaultRealtimeHost:@"realtime.ably.io" modify:true];
    _realtime = nil;
    [super tearDown];
}



-(void) getBaseOptions:(void (^)(ARTOptions * options)) cb {
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:cb];
}


-(void)testInitWithOptions {
    XCTestExpectation *expectation = [self expectationWithDescription:@"initWithOptions"];
    [ARTTestUtil testRealtime:^(ARTRealtime * realtime) {
        _realtime = realtime;
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [expectation fulfill];
            }
            else {
                XCTAssertEqual(state, ARTRealtimeConnecting);
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testInitWithHost {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInitWithHost"];
    [self getBaseOptions:^(ARTOptions * options) {
        [options setRealtimeHost:@"some.bad.realtime.host" withRestHost:@"some.bad.rest.host"];
        ARTRealtime * realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeFailed) {
                [expectation fulfill];
            }
            else {
                XCTAssertEqual(state, ARTRealtimeConnecting);
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


-(void)testInitWithPort {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInitWithPort"];
    [self getBaseOptions:^(ARTOptions * options) {
        options.realtimePort = 9998;
        options.restPort = 9998;
        ARTRealtime * realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeFailed) {
                [expectation fulfill];
            }
            else {
                XCTAssertEqual(state, ARTRealtimeConnecting);
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testInitWithKey {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInitWithKey"];
    [ARTOptions getDefaultRestHost:@"sandbox-rest.ably.io" modify:true];
    [ARTOptions getDefaultRealtimeHost:@"sandbox-realtime.ably.io" modify:true];
    [self getBaseOptions:^(ARTOptions * options) {
        NSString * key  = [[options.authOptions.keyName
                            stringByAppendingString:@":"] stringByAppendingString:options.authOptions.keySecret];
        _realtime = [[ARTRealtime alloc] initWithKey:key];
        [_realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testInitAutoConnectDefault {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInitAutoConnectDefault"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [expectation fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testInitAutoConnectFalse {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInitAutoConnectDefault"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.autoConnect = false;
        ARTRealtime * realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeConnected) {
                [expectation fulfill];
            }
        }];
        [realtime connect];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
