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
#import "ARTAuthTokenParams.h"
#import "ARTAuthTokenDetails.h"

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
        [_realtime removeAllChannels];
        [_realtime.eventEmitter removeEvents];
        [_realtime close];
    }
    _realtime = nil;
    [super tearDown];
}

- (void) testAttachOnce {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attachOnce"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];

                __block bool hasAttached = false;
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
                    if(state == ARTRealtimeChannelAttaching) {
                        XCTAssertEqual(ARTStateOk, reason.state);
                        [channel attach];
                    }
                    if (state == ARTRealtimeChannelAttached) {
                        XCTAssertEqual(ARTStateOk, reason.state);
                        [channel attach];
                        
                        if(!hasAttached) {
                            hasAttached = true;
                            [channel detach];
                        }
                        else {
                            XCTFail(@"duplicate call to attach shouldnt happen");
                        }
                    }
                    if (state == ARTRealtimeChannelDetached) {
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
    XCTestExpectation *  expectation = [self expectationWithDescription:@"detaching_to_attaching"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"detaching_to_attaching"];
        [channel attach];
        __block bool detachedReached = false;
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttached) {
                if(!detachedReached) {
                    [channel detach];
                }
            }
            if(state == ARTRealtimeChannelDetaching) {
                detachedReached = true;
                [channel attach];
            }
            if(state == ARTRealtimeChannelDetached) {
                XCTFail(@"Should not have reached detached state");
            }
            if(state == ARTRealtimeChannelAttaching) {
                if(detachedReached) {
                    [expectation fulfill];
                }
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

}

- (void) testAttachMultipleChannels {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"test_attach_multiple1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"test_attach_multiple2"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel1 = [realtime channel:@"test_attach_multiple1"];
        [channel1 attach];
        ARTRealtimeChannel *channel2 = [realtime channel:@"test_attach_multiple2"];
        [channel2 attach];

        [channel1 subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttached) {
                [expectation1 fulfill];
            }
        }];
        [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttached) {
                [expectation2 fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testDetach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"detach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"detach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        [channel detach];
                    }
                    else if(state == ARTRealtimeChannelDetached) {
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"detach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        __block BOOL detachingHit = NO;
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"detach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        [channel detach];
                    }
                    else if(state == ARTRealtimeChannelDetaching) {
                        detachingHit = YES;
                    }
                    else if(state == ARTRealtimeChannelDetached) {
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
    XCTestExpectation *  expectation = [self expectationWithDescription:@"attaching_to_detaching"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime channel:@"attaching_to_detaching"];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttached) {
                XCTFail(@"Should not have made it to attached");
            }
            else if( state == ARTRealtimeChannelAttaching) {
                [channel detach];
            }
            else if(state == ARTRealtimeChannelDetaching) {
                [expectation fulfill];
            }
            else if(state == ARTRealtimeChannelDetached) {
                XCTFail(@"Should not have made it to detached");
                
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testDetachingIgnoresDetach {
    XCTestExpectation *  expectation = [self expectationWithDescription:@"testDetachingIgnoresDetach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"testDetachingIgnoresDetach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {

                    if (state == ARTRealtimeChannelAttached) {
                        [channel detach];
                    }
                    if( state == ARTRealtimeChannelDetaching) {
                        [channel detach];
                    }
                    if(state == ARTRealtimeChannelDetached) {
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"testAttachFailsOnFailedConnection"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];
                __block bool hasFailed = false;
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        if(!hasFailed) {
                            XCTAssertEqual(ARTStateOk, reason.state);
                            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                        }
                    }
                    else if(state == ARTRealtimeChannelFailed) {
                        [channel attach];
                        XCTAssertEqual(ARTStateError, reason.state);
                        [expectation fulfill];
                    }
                }];
                [channel attach];
                [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSimpleDisconnected"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] withAlteration:TestAlterationRestrictCapability cb:^(ARTClientOptions * options) {

            ARTRealtime * realtime =[[ARTRealtime alloc] initWithOptions:options];
            _realtime = realtime;

            ARTRealtimeChannel * channel = [realtime channel:@"some_unpermitted_channel"];
            [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus *reason) {
                if(cState != ARTRealtimeChannelAttaching) {
                    XCTAssertEqual(cState, ARTRealtimeChannelFailed);
                    [expectation fulfill];
                }
            }];
            [channel attach];
        }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testAttachingChannelFails {
    XCTestExpectation *exp = [self expectationWithDescription:@"testAttachingChannelFails"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel1 = [realtime channel:@"channel"];
        [channel1 subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttaching) {
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            }
            else {
                XCTAssertEqual(ARTRealtimeChannelFailed, state);
                [exp fulfill];
            }
        }];
        [channel1 attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachedChannelFails {
    XCTestExpectation *exp = [self expectationWithDescription:@"testAttachedChannelFails"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel1 = [realtime channel:@"channel"];
        [channel1 subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttached) {
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            }
            else if(state != ARTRealtimeChannelAttaching) {
                XCTAssertEqual(ARTRealtimeChannelFailed, state);
                [exp fulfill];
            }
        }];
        [channel1 attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testChannelClosesOnClose {
    XCTestExpectation *exp = [self expectationWithDescription:@"testChannelClosesOnClose"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel1 = [realtime channel:@"channel"];
        [channel1 subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus *reason) {
            if (state == ARTRealtimeChannelAttached) {
                [realtime close];
            }
            else if(state != ARTRealtimeChannelAttaching) {
                XCTAssertEqual(ARTRealtimeChannelDetached, state);
                [exp fulfill];
            }
        }];
        [channel1 attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPresenceEnterRestricted {
    XCTestExpectation *expect = [self expectationWithDescription:@"testSimpleDisconnected"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] withAlteration:TestAlterationRestrictCapability cb:^(ARTClientOptions *options) {
        // Connection
        options.clientId = @"some_client_id";
        options.autoConnect = false;

        ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];

        // FIXME: there is setupApp, testRealtime, testRest, ... try to unify them and then use this code
        ARTAuthTokenParams *tokenParams = [[ARTAuthTokenParams alloc] initWithClientId:options.clientId];
        tokenParams.capability = @"{\"canpublish:*\":[\"publish\"],\"canpublish:andpresence\":[\"presence\",\"publish\"],\"cansubscribe:*\":[\"subscribe\"]}";

        [realtime.auth authorise:tokenParams options:options callback:^(ARTAuthTokenDetails *tokenDetails, NSError *error) {
            options.token = tokenDetails.token;
            [realtime connect];
        }];

        [realtime.eventEmitter on:^(ARTRealtimeConnectionState state, ARTErrorInfo *errorInfo) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"some_unpermitted_channel"];
                [channel.presence enter:@"not_allowed_here" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStateError, status.state);
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
