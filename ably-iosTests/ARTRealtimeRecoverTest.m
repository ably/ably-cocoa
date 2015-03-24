//
//  ARTRealtimeRecoverTest.m
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
#import "ARTRealtime+Test.h"


@interface ARTRealtimeRecoverTest : XCTestCase
{
    ARTRealtime * _realtime;
}
@end

@implementation ARTRealtimeRecoverTest

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

- (void)testRecoverDisconnected {
    //TODO ACTUALLY WRITE
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRecoverDisconnected"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testRecoverDisconnected constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        [realtime fakeDisconnect];
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
- (void)testRecoverImplicitConnect {
    XCTFail(@"TODO write test");
}

@end
