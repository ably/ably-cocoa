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
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTRealtimePresence.h"
#import "ARTEventEmitter.h"
#import "ARTTestUtil.h"
#import "ARTCrypto.h"
#import "ARTPayload+Private.h"

@interface ARTRealtimeChannelTest : XCTestCase {
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
}
@end

@implementation ARTRealtimeChannelTest


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _realtime = nil;
    _realtime2 = nil;
    [super tearDown];
}

- (void)testAttach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
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
        _realtime = realtime;
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
        _realtime = realtime;
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
        _realtime = realtime;
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
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"test"];
        id<ARTSubscription> __block subscription = [channel subscribe:^(ARTMessage *message, ARTErrorInfo *errorInfo) {
            if([[message content] isEqualToString:@"testString"]) {
                [subscription unsubscribe];
                [channel publish:lostMessage cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStateOk, status.state);
                }];
            }
            else if([[message content] isEqualToString:lostMessage]) {
                XCTFail(@"unsubscribe failed");
            }
        }];

        [channel publish:@"testString" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStateOk, status.state);
            NSString * finalMessage = @"final";
            [channel subscribe:^(ARTMessage * message, ARTErrorInfo *errorInfo) {
                if([[message content] isEqualToString:finalMessage]) {
                    [expectation fulfill];
                }
            }];
            [channel publish:finalMessage cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStateOk, status.state);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
 


- (void) testSuspendingDetachesChannel {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSuspendingDetachesChannel"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"channel"];
        __block bool gotCb=false;
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if(state == ARTRealtimeChannelAttached) {
                [realtime onSuspended];
            }
            else if(state == ARTRealtimeChannelDetached) {
                if(!gotCb) {
                    [channel publish:@"will_fail" cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStateError, status.state);
                        XCTAssertEqual(90001, status.errorInfo.code);
                        gotCb = true;
                        [realtime close];
                        [expectation fulfill];
                    }];
                }
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testFailingFailsChannel {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSuspendingDetachesChannel"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"channel"];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if(state == ARTRealtimeChannelAttached) {
                [realtime onError:nil withErrorInfo:nil];
            }
            else if(state == ARTRealtimeChannelFailed) {
                [channel publish:@"will_fail" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStateError, status.state);
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
        _realtime = realtime;
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
        _realtime = realtime;
        ARTRealtimeChannel *c1 = [realtime channel:channelName];
        ARTIvParameterSpec * ivSpec = [[ARTIvParameterSpec alloc] initWithIv:[[NSData alloc]
                                                                              initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0]];
        
        NSData * keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
        ARTCipherParams * params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" keySpec:keySpec ivSpec:ivSpec];
        ARTRealtimeChannel *c2 = [realtime channel:channelName cipherParams:params];
        [c1 publish:firstMessage cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStateOk, status.state);
            [c2 publish:secondMessage cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStateOk, status.state);
            }];
        }];
        __block int messageCount =0;
        [c1 subscribe:^(ARTMessage * message, ARTErrorInfo *errorInfo) {
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


- (void)testAttachFails {
    XCTestExpectation *exp = [self expectationWithDescription:@"testAttachFails"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"attach"];
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            if (state == ARTRealtimeConnected) {
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        // FIXME: create proper methods to transition each state.
                        [realtime onError:nil withErrorInfo:nil];
                    }
                }];
                [channel attach];
            }
            else if(state == ARTRealtimeFailed) {
                ARTErrorInfo *errorInfo = [channel attach];
                XCTAssert(errorInfo);
                XCTAssertEqual(errorInfo.code, 90000);
                [exp fulfill];
                
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testDetachFails {
    XCTestExpectation *exp = [self expectationWithDescription:@"testDetachFails"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"attach"];
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            if (state == ARTRealtimeConnected) {
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        [realtime onError:nil withErrorInfo:nil];
                    }
                }];
                [channel attach];
            }
            else if(state == ARTRealtimeFailed) {
                ARTErrorInfo *errorInfo = [channel detach];
                XCTAssert(errorInfo);
                XCTAssertEqual(errorInfo.code, 90000);
                [exp fulfill];
                
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/**
 Currently the payloadArraySizeLimit is default to INT_MAX. Here we bring that number down to 2
 To show that publishing an array over the limit throws an exception.
 */
-(void) testPublishTooManyInArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPublishTooManyInArray"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"channel"];
        NSArray * messages = @[@"test1", @"test2", @"test3"];
        [ARTPayload getPayloadArraySizeLimit:2 modify:true];
        XCTAssertThrows([channel publish:messages cb:^(ARTStatus *status) {}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testClientIdPreserved {
    NSString *firstClientId = @"firstClientId";
    NSString *channelName = @"channelName";

    XCTestExpectation *exp = [self expectationWithDescription:@"testClientIdPreserved"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] withDebug:YES cb:^(ARTClientOptions *options) {
        // First instance
        options.clientId = firstClientId;
        ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:channelName];

        // Second instance
        options.clientId = @"secondClientId";
        ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = realtime2;
        ARTRealtimeChannel *channel2 = [realtime channel:channelName];

        [channel2.presence subscribe:^(ARTPresenceMessage * message) {
            XCTAssertEqualObjects(message.clientId, firstClientId);
            [exp fulfill];
        }];

        [channel.presence enter:@"enter" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStateOk, status.state);
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
@end
