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

@interface ARTRealtimeRecoverTest : XCTestCase {
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
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        __block NSString * firstConnectionId = nil;
        options.recover = nil;
         _realtimeNonRecovered = [[ARTRealtime alloc] initWithOptions:options];
        [_realtime subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                firstConnectionId = [_realtime connectionId];
                ARTRealtimeChannel *channel = [_realtime channel:channelName];
                [channel publish:c1Message cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [_realtime onError:nil];
                }];
            }
            else if(state == ARTRealtimeFailed) {
                ARTRealtimeChannel * c2 = [_realtimeNonRecovered channel:channelName];
                [_realtimeNonRecovered subscribeToEventEmitter:^(ARTRealtimeConnectionState state) {
                    [c2 publish:c2Message cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        options.recover = [_realtime recoveryKey];
                        ARTRealtime * realtimeRecovered = [[ARTRealtime alloc] initWithOptions:options];
                        ARTRealtimeChannel * c3 = [realtimeRecovered channel:channelName];
                        [realtimeRecovered subscribeToEventEmitter:^(ARTRealtimeConnectionState cState) {
                            if(cState == ARTRealtimeConnected) {
                                XCTAssertEqualObjects([realtimeRecovered connectionKey], [_realtime connectionKey]);
                                XCTAssertEqualObjects([realtimeRecovered connectionId], firstConnectionId);
                                [c3 subscribe:^(ARTMessage * message) {
                                    XCTAssertEqualObjects(c2Message, [message content]);
                                    [expectation fulfill];
                                }];
                            }
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testRecoverFails {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRecoverDisconnected"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
        options.recover = @"bad_recovery_key:1234";
        _realtimeRecover = [[ARTRealtime alloc] initWithOptions:options];
        [_realtimeRecover subscribeToEventEmitter:^(ARTRealtimeConnectionState cState) {
            if(cState == ARTRealtimeConnected) {
                XCTAssertEqual([_realtimeRecover connectionErrorReason].code, 80008);
                [expectation fulfill];
            }
        }];
        [_realtimeRecover connect];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
