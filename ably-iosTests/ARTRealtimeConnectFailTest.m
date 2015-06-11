//
//  ARTRealtimeConnectFail.m
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

@interface ARTRealtimeConnectFailTest : XCTestCase
@end

@implementation ARTRealtimeConnectFailTest

- (void)setUp {
    
    [super setUp];
    
}

- (void)tearDown {

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



//TODO implement
/*
- (void)testNotFoundErrBadKeyId {
    XCTFail(@"TODO testNotFoundErrBadKeyId" );
    return;
    
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_connect_text"];
    [self withRealtimeAlt:TestAlterationBadKeyId cb:^(ARTRealtime *realtime) {
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            XCTAssertEqual(ARTRealtimeFailed, state);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testNotFoundErrBadKeyValue {
    
    XCTFail(@"testNotFoundErrBadKeyValue");
    return;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_connect_text"];
    [self withRealtimeAlt:TestAlterationBadKeyValue cb:^(ARTRealtime *realtime) {
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            XCTAssertEqual(ARTRealtimeFailed, state);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testDisonnectFail {
    
    XCTFail(@"testDisonnectFail");
    return;
    

    //TODO write this.
    XCTestExpectation *expectation = [self expectationWithDescription:@"test_connect_text"];
    [self withRealtimeAlt:TestAlterationNone cb:^(ARTRealtime *realtime) {
        __block int connectionCount=0;
        [realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
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

- (void)testTokenExpireFail {
    XCTFail(@"TODO write test");
}
- (void)testInvalidRecoverFail {
    XCTFail(@"TODO write test");
}
- (void)testUnknownRecoverFail {
    XCTFail(@"TODO write test");
}

- (void)testSuspendedFail {
    XCTFail(@"TODO write test");
}
*/

@end
