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
#import "ARTRealtime+Private.h"

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
    //TODO ACTUALLY WRITE this using recover.
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRecoverDisconnected"];
    [self withRealtime:^(ARTRealtime *realtime) {

        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testRecoverDisconnected constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];
                __block bool hasAttached = false;
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
                    NSLog(@"channel state is %lu", state);
                    if (state == ARTRealtimeChannelAttached) {
                        if(!hasAttached)
                        {
                            hasAttached = true;
                            [realtime onError:nil];
                        }
                        else
                        {
                            //reconnction succeeded.
                            XCTFail(@"nearly there. Need to use recover api");
                            [expectation fulfill];
                        }
                        
                    }
                    if( hasAttached && state == ARTRealtimeChannelDetached) {
                        NSLog(@"connecting....");

                        [realtime connect];
                    }


                }];
                [channel attach];
            }
            else {
                
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
}
- (void)testRecoverImplicitConnect {
    XCTFail(@"TODO write test");
}

@end
