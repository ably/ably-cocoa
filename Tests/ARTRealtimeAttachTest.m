//
//  ARTRealtimeTest.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ARTRealtime+Private.h"
#import "ARTRealtimePresence.h"
#import "ARTRealtimeChannel.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTEventEmitter.h"
#import "ARTStatus.h"
#import "ARTAuth.h"
#import "ARTTokenParams.h"
#import "ARTTokenDetails.h"

@interface ARTRealtimeAttachTest : XCTestCase {
    ARTRealtime *_realtime;
}
@end

@implementation ARTRealtimeAttachTest

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
    [super tearDown];
}

- (void) testAttachOnce {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"attachOnce"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];

                __block bool hasAttached = false;
                [channel on:^(ARTErrorInfo *errorInfo) {
                    if(channel.state == ARTRealtimeChannelAttaching) {
                        XCTAssertNil(errorInfo);
                        [channel attach];
                    }
                    if (channel.state == ARTRealtimeChannelAttached) {
                        XCTAssertNil(errorInfo);
                        [channel attach];
                        
                        if(!hasAttached) {
                            hasAttached = true;
                            [channel detach];
                        }
                        else {
                            XCTFail(@"duplicate call to attach shouldnt happen");
                        }
                    }
                    if (channel.state == ARTRealtimeChannelDetached) {
                        [expectation fulfill];
                    }
                }];
                [channel attach];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

}

-(void) testSkipsFromDetachingToAttaching {
    __weak XCTestExpectation * expectation = [self expectationWithDescription:@"detaching_to_attaching"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"detaching_to_attaching"];
        [channel attach];
        __block bool detachedReached = false;
        
        [channel on:^(ARTErrorInfo *errorInfo) {
            if (channel.state == ARTRealtimeChannelAttached) {
                if(!detachedReached) {
                    [channel detach];
                }
            }
            else if(channel.state == ARTRealtimeChannelDetaching) {
                detachedReached = true;
                [channel attach];
            }
            else if(channel.state == ARTRealtimeChannelDetached) {
                XCTFail(@"Should not have reached detached state");
            }
            else if(channel.state == ARTRealtimeChannelAttaching) {
                if(detachedReached) {
                    [channel off];
                    [expectation fulfill];
                }
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

}

- (void) testAttachMultipleChannels {
    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:@"test_attach_multiple1"];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:@"test_attach_multiple2"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel1 = [realtime.channels get:@"test_attach_multiple1"];
        [channel1 attach];
        ARTRealtimeChannel *channel2 = [realtime.channels get:@"test_attach_multiple2"];
        [channel2 attach];

        [channel1 on:^(ARTErrorInfo *errorInfo) {
            if (channel1.state == ARTRealtimeChannelAttached) {
                [expectation1 fulfill];
            }
        }];
        [channel2 on:^(ARTErrorInfo *errorInfo) {
            if (channel2.state == ARTRealtimeChannelAttached) {
                [expectation2 fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testDetach {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"detach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime.channels get:@"detach"];
                [channel on:^(ARTErrorInfo *errorInfo) {
                    if (channel.state == ARTRealtimeChannelAttached) {
                        [channel detach];
                    }
                    else if(channel.state == ARTRealtimeChannelDetached) {
                        [expectation fulfill];
                    }
                }];
                [channel attach];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testDetaching {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"detach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block BOOL detachingHit = NO;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime.channels get:@"detach"];
                [channel on:^(ARTErrorInfo *errorInfo) {
                    if (channel.state == ARTRealtimeChannelAttached) {
                        [channel detach];
                    }
                    else if(channel.state == ARTRealtimeChannelDetaching) {
                        detachingHit = YES;
                    }
                    else if(channel.state == ARTRealtimeChannelDetached) {
                        if(detachingHit) {
                            [expectation fulfill];
                        }
                        else {
                            XCTFail(@"Detaching state not emitted prior to detached");
                        }
                    }
                }];
                [channel attach];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testSkipsFromAttachingToDetaching {
    __weak XCTestExpectation * expectation = [self expectationWithDescription:@"attaching_to_detaching"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"attaching_to_detaching"];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if (channel.state == ARTRealtimeChannelAttached) {
                XCTFail(@"Should not have made it to attached");
            }
            else if( channel.state == ARTRealtimeChannelAttaching) {
                [channel detach];
            }
            else if(channel.state == ARTRealtimeChannelDetaching) {
                [channel off];
                [expectation fulfill];
            }
            else if(channel.state == ARTRealtimeChannelDetached) {
                XCTFail(@"Should not have made it to detached");
                
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testDetachingIgnoresDetach {
    __weak XCTestExpectation * expectation = [self expectationWithDescription:@"testDetachingIgnoresDetach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime.channels get:@"testDetachingIgnoresDetach"];
                [channel on:^(ARTErrorInfo *errorInfo) {

                    if (channel.state == ARTRealtimeChannelAttached) {
                        [channel detach];
                    }
                    if( channel.state == ARTRealtimeChannelDetaching) {
                        [channel detach];
                    }
                    if(channel.state == ARTRealtimeChannelDetached) {
                        [expectation fulfill];
                    }
                }];
                [channel attach];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testAttachFailsOnFailedConnection {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testAttachFailsOnFailedConnection"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];
                __block bool hasFailed = false;
                [channel on:^(ARTErrorInfo *errorInfo) {
                    if (channel.state == ARTRealtimeChannelAttached) {
                        if(!hasFailed) {
                            XCTAssertNil(errorInfo);
                            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                        }
                    }
                    else if(channel.state == ARTRealtimeChannelFailed) {
                        XCTAssertNotNil(errorInfo);
                        [channel attach:^(ARTErrorInfo *errorInfo) {
                            XCTAssertNotNil(errorInfo);
                            [expectation fulfill];
                        }];
                    }
                }];
                [channel attach];
                [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
                    ARTRealtimeConnectionState state = stateChange.current;
                    if(state == ARTRealtimeFailed) {
                        hasFailed = true;
                        [channel attach];
                    }
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachRestricted {
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] withAlteration:TestAlterationRestrictCapability callback:^(ARTClientOptions * options) {
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testSimpleDisconnected"];

            ARTRealtime * realtime =[[ARTRealtime alloc] initWithOptions:options];
            _realtime = realtime;

            ARTRealtimeChannel * channel = [realtime.channels get:@"some_unpermitted_channel"];
            [channel on:^(ARTErrorInfo *errorInfo) {
                if(channel.state != ARTRealtimeChannelAttaching) {
                    XCTAssertEqual(channel.state, ARTRealtimeChannelFailed);
                    [expectation fulfill];
                    [channel off];
                }
            }];
            [channel attach];
        }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachingChannelFails {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testAttachingChannelFails"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel1 = [realtime.channels get:@"channel"];
        [channel1 on:^(ARTErrorInfo *errorInfo) {
            if (channel1.state == ARTRealtimeChannelAttaching) {
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            }
            else {
                XCTAssertEqual(ARTRealtimeChannelFailed, channel1.state);
                [exp fulfill];
            }
        }];
        [channel1 attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachedChannelFails {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testAttachedChannelFails"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel1 = [realtime.channels get:@"channel"];
        [channel1 on:^(ARTErrorInfo *errorInfo) {
            if (channel1.state == ARTRealtimeChannelAttached) {
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            }
            else if(channel1.state != ARTRealtimeChannelAttaching) {
                XCTAssertEqual(ARTRealtimeChannelFailed, channel1.state);
                [exp fulfill];
            }
        }];
        [channel1 attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testChannelClosesOnClose {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testChannelClosesOnClose"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel1 = [realtime.channels get:@"channel"];
        [channel1 on:^(ARTErrorInfo *errorInfo) {
            if (channel1.state == ARTRealtimeChannelAttached) {
                [realtime close];
            }
            else if(channel1.state != ARTRealtimeChannelAttaching) {
                XCTAssertEqual(ARTRealtimeChannelDetached, channel1.state);
                [exp fulfill];
            }
        }];
        [channel1 attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPresenceEnterRestricted {
    __weak XCTestExpectation *expect = [self expectationWithDescription:@"testSimpleDisconnected"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] withAlteration:TestAlterationRestrictCapability callback:^(ARTClientOptions *options) {
        // Connection
        options.clientId = @"some_client_id";
        options.autoConnect = false;

        ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];

        // FIXME: there is setupApp, testRealtime, testRest, ... try to unify them and then use this code
        ARTTokenParams *tokenParams = [[ARTTokenParams alloc] initWithClientId:options.clientId];
        tokenParams.capability = @"{\"canpublish:*\":[\"publish\"],\"canpublish:andpresence\":[\"presence\",\"publish\"],\"cansubscribe:*\":[\"subscribe\"]}";

        [realtime.auth authorise:tokenParams options:options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
            options.token = tokenDetails.token;
            [realtime connect];
        }];

        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            ARTErrorInfo *errorInfo = stateChange.reason;
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime.channels get:@"some_unpermitted_channel"];
                [channel.presence enter:@"not_allowed_here" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNotNil(errorInfo);
                    [expect fulfill];
                }];
            }
            else if (state == ARTRealtimeFailed) {
                if (errorInfo) {
                    XCTFail(@"%@", errorInfo);
                }
                else {
                    XCTFail();
                }
                [expect fulfill];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
