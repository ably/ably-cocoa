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
#import "ARTRealtime+Private.h"
#import "ARTTestUtil.h"
#import "ARTCrypto.h"

@interface ARTRealtimeChannelTest : XCTestCase
@end

@implementation ARTRealtimeChannelTest


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAttach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        [expectation fulfill];
                    }
                }];
                [channel attach];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testAttachBeforeConnect     {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach_before_connect"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_before_connect"];
        [channel attach];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachDetach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach_detach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_detach"];
        [channel attach];
        
        __block BOOL attached = NO;
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
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
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_detach_attach"];
        [channel attach];
        __block BOOL attached = false;
        __block int attachCount =0;
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
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


- (void)testSubscribeUnsubscribe {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"publish"];
    NSString * lostMessage = @"lost";
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"test"];
        id<ARTSubscription> __block subscription = [channel subscribe:^(ARTMessage *message) {
            if([[message content] isEqualToString:@"testString"]) {
                [subscription unsubscribe];
                [channel publish:lostMessage cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusOk, status.status);
                }];
            }
            else if([[message content] isEqualToString:lostMessage]) {
                XCTFail(@"unsubscribe failed");
            }
        }];

        [channel publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            NSString * finalMessage = @"final";
            [channel subscribe:^(ARTMessage * message) {
                if([[message content] isEqualToString:finalMessage]) {
                    [expectation fulfill];
                }
            }];
            [channel publish:finalMessage cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
 


- (void) testSuspendingDetachesChannel {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSuspendingDetachesChannel"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"channel"];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if(state == ARTRealtimeChannelAttached) {
                [realtime onSuspended];
            }
            else if(state != ARTRealtimeChannelAttaching) {
                XCTAssertEqual(ARTRealtimeChannelDetached, state);
                [channel publish:@"will_fail" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [expectation fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testFailingFailsChannel {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSuspendingDetachesChannel"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"channel"];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if(state == ARTRealtimeChannelAttached) {
                [realtime onError:nil];
            }
            else if(state != ARTRealtimeChannelAttaching) {
                XCTAssertEqual(ARTRealtimeChannelFailed, state);
                [channel publish:@"will_fail" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [expectation fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testGetChannels {
    XCTestExpectation *exp = [self expectationWithDescription:@"testGetChannels"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *c1 = [realtime channel:@"channel"];
        ARTRealtimeChannel *c2 = [realtime channel:@"channel2"];
        ARTRealtimeChannel *c3 = [realtime channel:@"channel3"];
        {
            NSDictionary * d = [realtime channels];
            XCTAssertEqual([[d allKeys] count], 3);
            XCTAssertEqualObjects([d valueForKey:@"channel"], c1);
            XCTAssertEqualObjects([d valueForKey:@"channel2"], c2);
            XCTAssertEqualObjects([d valueForKey:@"channel3"], c3);
        }
        [c3 releaseChannel];
        {
            NSDictionary * d = [realtime channels];
            XCTAssertEqual([[d allKeys] count], 2);
            XCTAssertEqualObjects([d valueForKey:@"channel"], c1);
            XCTAssertEqualObjects([d valueForKey:@"channel2"], c2);
        }
        
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testGetSameChannelWithParams {
    XCTestExpectation *exp = [self expectationWithDescription:@"testGetChannels"];
    NSString * channelName = @"channel";
    NSString * firstMessage = @"firstMessage";
    NSString * secondMessage = @"secondMessage";
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *c1 = [realtime channel:channelName];
        
        ARTIvParameterSpec * ivSpec = [[ARTIvParameterSpec alloc] initWithIv:[[NSData alloc]
                                                                              initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0]];
        
        NSData * keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
        ARTCipherParams * params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" keySpec:keySpec ivSpec:ivSpec];
        ARTRealtimeChannel *c2 = [realtime channel:channelName cipherParams:params];
        [c1 publish:firstMessage cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            [c2 publish:secondMessage cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
            }];
        }];
        __block int messageCount =0;
        [c1 subscribe:^(ARTMessage * message) {
            if(messageCount ==0) {
                XCTAssertEqualObjects([message content], firstMessage);
            }
            else if(messageCount ==1) {
                XCTAssertEqualObjects([message content], secondMessage);
                [exp fulfill];
            }
            messageCount++;
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

//TODO switch the keys over and confirm connection doesn't work.
/*
- (void)testAttachFail {
    XCTFail(@"TODO");
    return;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testAttachFail"];
    [self withRealtimeAlt:TestAlterationBadKeyValue cb:^(ARTRealtime *realtime) {
        ARTRealtimeChannel * channel = [realtime channel:@"invalidChannel"];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState channelState, ARTStatus *reason) {
            XCTAssertEqual(ARTRealtimeChannelFailed, channelState);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
*/



@end
