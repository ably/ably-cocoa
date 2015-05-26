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
            _options = options;
            [ARTRealtime realtimeWithOptions:_options cb:^(ARTRealtime *realtime) {
                _realtime = realtime;
                cb(_realtime);
            }];

        }];
    }
    else {
        cb(_realtime);
        
    }

}

- (void)withRealtimeRecover:(NSString *) recover cb:(void (^)(ARTRealtime *realtime))cb {
    _options.recover = recover;
    [ARTRealtime realtimeWithOptions:_options cb:^(ARTRealtime *realtime) {
        _realtimeRecover = realtime;
        cb(_realtimeRecover);
    }];
}

- (void)withRealtimeExtra:(void (^)(ARTRealtime *realtime))cb {
    _options.recover= nil;
    [ARTRealtime realtimeWithOptions:_options cb:^(ARTRealtime *realtime) {
        _realtimeNonRecovered = realtime;
        cb(_realtimeNonRecovered);
    }];
}

- (void)testRecoverDisconnected {
    NSString * channelName = @"chanName";
    NSString * c1Message = @"c1 says hi";
    NSString * c2Message= @"c2 says hi";
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRecoverDisconnected"];
    [self withRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:channelName];
                [channel publish:c1Message cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                    [realtime onError:nil];
                }];
            }
            else if(state == ARTRealtimeFailed) {
                [self withRealtimeExtra:^(ARTRealtime *realtime2) {
                    ARTRealtimeChannel * c2 = [realtime2 channel:channelName];
                    [realtime2 subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
                        [c2 publish:c2Message cb:^(ARTStatus *status) {
                            XCTAssertEqual(ARTStatusOk, status.status);
                            [self withRealtimeRecover:[realtime recoveryKey] cb:^(ARTRealtime *realtimeRecovered) {
                                ARTRealtimeChannel * c3 = [realtimeRecovered channel:channelName];
                                __block bool gotC1Message = false;
                                [realtimeRecovered subscribeToStateChanges:^(ARTRealtimeConnectionState cState) {
                                    if(cState == ARTRealtimeConnected) {
                                        XCTAssertEqualObjects([realtimeRecovered connectionKey], [realtime connectionKey]);
                                        XCTAssertEqualObjects([realtimeRecovered connectionId], [realtime connectionId]);
                                        [c3 subscribe:^(ARTMessage * message) {
                                            if([[message content] isEqualToString:c1Message]) {
                                                gotC1Message = true;
                                            }
                                            else {
                                                XCTAssertTrue(gotC1Message);
                                                XCTAssertEqualObjects(c2Message, [message content]);
                                                [expectation fulfill];
                                            }
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

@end
