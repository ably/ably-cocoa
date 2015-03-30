//
//  ARTRealtimeChannelTest.m
//  ably-ios
//
//  Created by vic on 13/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"


@interface ARTRealtimeChannelTest : XCTestCase
{
    ARTRealtime *_realtime;

}
@end

@implementation ARTRealtimeChannelTest


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

- (void)withRealtimeAlt:(TestAlteration) alt cb:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] withAlteration:alt cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}


- (void)testAttach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        [expectation fulfill];
                    }
                }];
                [channel attach];
            }
            else {
                
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testAttachBeforeConnect{
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach_before_connect"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_before_connect"];
        [channel attach];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachDetach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach_detach"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_detach"];
        [channel attach];
        
        __block BOOL attached = NO;
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                attached = YES;
                [channel detach];
            }
            if (attached && state == ARTRealtimeChannelDetached) {
                [expectation fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testAttachDetachAttach {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach_detach_attach"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_detach_attach"];
        [channel attach];
        __block BOOL attached = false;
        __block int attachCount =0;
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                attachCount++;
                attached = true;
                if(attachCount ==1) {
                    [channel detach];
                }
                else if( attachCount ==2 ) {
                    [expectation fulfill];
                }
            }
            if (attached && state == ARTRealtimeChannelDetached) {
                [channel attach];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSubscribeUnsubscribe{
    XCTestExpectation *expectation = [self expectationWithDescription:@"publish"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"test"];
        id<ARTSubscription> subscription = [channel subscribe:^(ARTMessage *message) {
            
            if([[message content] isEqualToString:@"testString"]) {
                [subscription unsubscribe];
                [channel publish:@"This should never arrive" cb:^(ARTStatus status) {
                    XCTAssertEqual(status, ARTStatusOk);
                }];
                [expectation fulfill];
            }
            else {
                XCTFail(@"unsubscribe failed");
                [expectation fulfill];
            }
            XCTAssertEqualObjects([message content], @"testString");
        }];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(ARTStatusOk, status);
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//TODO switch the keys over and confirm connection doesn't work.
- (void)testAttachFail {
    XCTFail(@"TODO");
    return;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testAttachFail"];
    [self withRealtimeAlt:TestAlterationBadKeyValue cb:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"invalidChannel"];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState channelState, ARTStatus status) {
            XCTAssertEqual(ARTRealtimeChannelFailed, channelState);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
 //msgpack not implemented yet
- (void)testAttacDetachBinary{
    XCTFail(@"TODO write test");
}
-(void) testAttachBinary {
    XCTFail(@"TODO write test");
}
- (void)testAttachBeforeConnectBinary {
    XCTFail(@"TODO write test");
}
 */

@end
