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
 
    ARTRealtime * _realtimeRecover;
    ARTRealtime * _realtimeNonRecovered;
    
    ARTOptions * _options;
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
                _options = options;
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}

- (void)withRealtimeRecover:(NSString *) recover cb:(void (^)(ARTRealtime *realtime))cb {
    
    _options.recover = recover;
    _realtimeRecover = [[ARTRealtime alloc] initWithOptions:_options];
    cb(_realtimeRecover);
}
- (void)withRealtimeExtra:(void (^)(ARTRealtime *realtime))cb {
    
    
    _options.recover= nil;
    _realtimeNonRecovered = [[ARTRealtime alloc] initWithOptions:_options];
    cb(_realtimeNonRecovered);
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
    NSString * channelName = @"chanName";
    NSString * c1Message = @"c1 says hi";
    NSString * c2Message= @"c2 says hi";
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRecoverDisconnected"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:channelName];
                [channel publish:c1Message cb:^(ARTStatus status) {
                    XCTAssertEqual(ARTStatusOk, status);
                    [realtime onError:nil];
                }];
            }
            else if(state == ARTRealtimeFailed) {
                [self withRealtimeExtra:^(ARTRealtime *realtime2) {
                    [realtime2 subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
                        ARTRealtimeChannel * c2 = [realtime2 channel:channelName];
                        [c2 publish:c2Message cb:^(ARTStatus status) {
                            XCTAssertEqual(ARTStatusOk, status);
                            [self withRealtimeRecover:[realtime getRecovery] cb:^(ARTRealtime *realtimeRecovered) {
                                [realtimeRecovered subscribeToStateChanges:^(ARTRealtimeConnectionState cState) {
                                    if(cState == ARTRealtimeConnected) {
                                        ARTRealtimeChannel * c3 = [realtimeRecovered channel:channelName];
                                        [c3 subscribe:^(ARTMessage * message) {
                                            XCTAssertEqualObjects(c2Message, [message content]);
                                            [expectation fulfill];
                                        }];
                                    }
                                    
                                }];
                            }];
                        }];
                    }];
                }];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:100 handler:nil];
    
}

//testRecoverDisconnected uses implicit connect, no need for this test.
/*
- (void)testRecoverImplicitConnect {
    XCTFail(@"TODO write test");
}
*/
@end
