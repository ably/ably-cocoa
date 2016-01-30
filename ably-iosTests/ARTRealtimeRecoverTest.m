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
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTRealtimeChannel.h"
#import "ARTTestUtil.h"
#import "ARTRealtime+Private.h"
#import "ARTEventEmitter.h"

@interface ARTRealtimeRecoverTest : XCTestCase {
    ARTRealtime * _realtime;
    ARTRealtime * _realtimeRecover;
    ARTRealtime * _realtimeNonRecovered;
    ARTClientOptions * _options;
}
@end

@implementation ARTRealtimeRecoverTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    if (_realtime) {
        [ARTTestUtil removeAllChannels:_realtime];
        [_realtime resetEventEmitter];
        [_realtime close];
    }
    _realtime = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
            _options = options;
            _realtime = [[ARTRealtime alloc] initWithOptions:options];
            cb(_realtime);
        }];
    }
    else {
        cb(_realtime);
    }
}

- (void)withRealtimeRecover:(NSString *) recover cb:(void (^)(ARTRealtime *realtime))cb {
    _options.recover = recover;
    _realtimeRecover = [[ARTRealtime alloc] initWithOptions:_options];
    cb(_realtimeRecover);
}

- (void)testRecoverDisconnected {
    NSString * channelName = @"chanName";
    NSString * c1Message = @"c1 says hi";
    NSString * c2Message= @"c2 says hi";

    XCTestExpectation *expectation = [self expectationWithDescription:@"testRecoverDisconnected"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];

        __block NSString *firstConnectionId = nil;
        [_realtime onAll:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            ARTErrorInfo *errorInfo = stateChange.reason;
            if (state == ARTRealtimeConnected) {
                firstConnectionId = [_realtime connectionId];

                ARTRealtimeChannel *channel = [_realtime.channels get:channelName];
                // Sending a message
                [channel publish:c1Message cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStateOk, status.state);
                    [_realtime onDisconnected];
                }];
            }
            else if (state == ARTRealtimeDisconnected) {
                options.recover = nil;
                _realtimeNonRecovered = [[ARTRealtime alloc] initWithOptions:options];

                ARTRealtimeChannel *c2 = [_realtimeNonRecovered.channels get:channelName];
                [_realtimeNonRecovered onAll:^(ARTConnectionStateChange *stateChange) {
                    ARTRealtimeConnectionState state2 = stateChange.current;
                    ARTErrorInfo *errorInfo = stateChange.reason;
                    if (state2 == ARTRealtimeConnected) {
                        // Sending other message to the same channel to check if the recovered connection receives it
                        [c2 publish:c2Message cb:^(ARTStatus *status) {
                            XCTAssertEqual(ARTStateOk, status.state);

                            options.recover = [_realtime recoveryKey];
                            XCTAssertFalse(options.recover == nil);
                            ARTRealtime *realtimeRecovered = [[ARTRealtime alloc] initWithOptions:options];
                            ARTRealtimeChannel *c3 = [realtimeRecovered.channels get:channelName];

                            [realtimeRecovered onAll:^(ARTConnectionStateChange *stateChange) {
                                ARTRealtimeConnectionState cState = stateChange.current;
                                ARTErrorInfo *errorInfo = stateChange.reason;
                                if (cState == ARTRealtimeConnected) {
                                    XCTAssertEqualObjects([realtimeRecovered connectionId], firstConnectionId);
                                    [c3 subscribe:^(ARTMessage *message, ARTErrorInfo *errorInfo) {
                                        XCTAssertEqualObjects(c2Message, [message content]);
                                        [expectation fulfill];
                                    }];
                                }
                            }];
                        }];
                    }
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testRecoverFails {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRecoverDisconnected"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] cb:^(ARTClientOptions *options) {
        options.recover = @"bad_recovery_key:1234";
        _realtimeRecover = [[ARTRealtime alloc] initWithOptions:options];
        [_realtimeRecover onAll:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState cState = stateChange.current;
            ARTErrorInfo *errorInfo = stateChange.reason;
            if (cState == ARTRealtimeFailed) {
                // 80018 - Invalid connectionKey: bad_recovery_key
                XCTAssertEqual(errorInfo.code, 80018);
                [expectation fulfill];
            }
        }];
        [_realtimeRecover connect];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
