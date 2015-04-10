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

@interface ARTRealtimeInitTest : XCTestCase
{
    ARTRealtime *_realtime;
    
}
@end

@implementation ARTRealtimeInitTest


- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _realtime = nil;
    [super tearDown];
}

-(void) getBaseOptions:(void (^)(ARTOptions * options)) cb {
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:cb];
}

-(void)testInitWithOptions {
    XCTestExpectation *expectation = [self expectationWithDescription:@"initWithOptions"];
    [self getBaseOptions:^(ARTOptions * options) {
        ARTRealtime * r = [[ARTRealtime alloc] initWithOptions:options];
        [r subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            
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
        ARTRealtime * r = [[ARTRealtime alloc] initWithOptions:options];
        [r subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            
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
        ARTRealtime * r = [[ARTRealtime alloc] initWithOptions:options];
        [r subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
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
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"initWithOptions"];
    [self getBaseOptions:^(ARTOptions * options) {
        NSString * key  = [[options.authOptions.keyId stringByAppendingString:@":"] stringByAppendingString:options.authOptions.keyValue];
        NSLog(@"key --------------%@", key);
        ARTRealtime * r = [[ARTRealtime alloc] initWithKey:key];
        [r subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if(state == ARTRealtimeFailed) { //this doesnt try to connect to sandbox so will fail.
                [expectation fulfill];
            }
            else {
                XCTAssertEqual(state, ARTRealtimeConnecting);
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
 //TODO implement
 
 -(void)testInitDefaultSecurity {
 
 }
 -(void)testLogHandlerNotCalled {
 
 }
 -(void)testLogHandleCalled {
 
 }
*/
@end
