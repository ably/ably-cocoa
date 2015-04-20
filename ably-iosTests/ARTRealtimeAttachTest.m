//
//  ARTRealtimeTest.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ARTRealtime.h"
#import "ARTTestUtil.h"



@interface ARTRealtimeAttachTest : XCTestCase {
    ARTRealtime *_realtime;
}
@end

@implementation ARTRealtimeAttachTest


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _realtime = nil;
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

- (void) testAttachOnce {
      XCTestExpectation *expectation = [self expectationWithDescription:@"attachOnce"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];

                __block bool hasAttached = false;
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
                    if(state == ARTRealtimeChannelAttaching) {
                        [channel attach];
                    }
                    if (state == ARTRealtimeChannelAttached) {
                        [channel attach];
                        
                        if(!hasAttached) {
                            [expectation fulfill];
                        }
                        else {
                            XCTFail(@"duplicate call to attach shouldnt happen");
                        }
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
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"detaching_to_attaching"];
        [channel attach];
        __block bool detachedReached = false;
        
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
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
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel1 = [realtime channel:@"test_attach_multiple1"];
        [channel1 attach];
        ARTRealtimeChannel *channel2 = [realtime channel:@"test_attach_multiple2"];
        [channel2 attach];

        [channel1 subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                [expectation1 fulfill];
            }
        }];
        [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                [expectation2 fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testDetach {
      XCTestExpectation *expectation = [self expectationWithDescription:@"detach"];
    [self withRealtime:^(ARTRealtime *realtime) {
        
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"detach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
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
    [self withRealtime:^(ARTRealtime *realtime) {
        __block BOOL detachingHit = NO;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"detach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
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
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attaching_to_detaching"];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
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
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"testDetachingIgnoresDetach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {

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

@end
