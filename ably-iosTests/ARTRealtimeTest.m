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



@interface ARTRealtimeTest : XCTestCase {
    ARTRealtime *_realtime;
    ARTOptions *_options;
}


- (void)multipleSendName:(NSString *)name count:(int)count delay:(int)delay;


@end


const float TIMEOUT= 20.0;


@implementation ARTRealtimeTest


- (void)setUp {
    [super setUp];
    _options = [[ARTOptions alloc] init];
    _options.restHost = @"sandbox-rest.ably.io";
    _options.realtimeHost = @"sandbox-realtime.ably.io";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:_options cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}

- (void)testTime {
      XCTestExpectation *expectation = [self expectationWithDescription:@"time"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime time:^(ARTStatus status, NSDate *date) {
            NSLog(@"status in test time %d", status);
            XCTAssert(status == ARTStatusOk);
            // Expect local clock and server clock to be synced within 5 seconds
            XCTAssertEqualWithAccuracy([date timeIntervalSinceNow], 0.0, 5.0);
            if(status == ARTStatusOk) {
                [expectation fulfill];
            }
        }];
    }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttach {
    XCTFail(@"TODO crashes in websocket");
    return;
      XCTestExpectation *expectation = [self expectationWithDescription:@"attach"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constate...: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];
                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
                    if (state == ARTRealtimeChannelAttached) {
                        [expectation fulfill];
                    }
                }];
                [channel attach];
            }
            else {
                
            }
        }];
    }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testAttachOnce {
      XCTestExpectation *expectation = [self expectationWithDescription:@"attachOnce"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState state) {
            NSLog(@"testAttach constateOnce: %@", [ARTRealtime ARTRealtimeStateToStr:state]);
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime channel:@"attach"];

                [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus reason) {
                    if(state == ARTRealtimeChannelAttaching) {
                        [channel attach];
                    }
                    if (state == ARTRealtimeChannelAttached) {
                        [channel attach];
                        [expectation fulfill];
                    }
                }];
                [channel attach];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

}



- (void)testAttachBeforeConnectBinary {
      XCTestExpectation *expectation = [self expectationWithDescription:@"attach_before_connect"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_before_connect"];
        [channel attach];

        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }
        }];
    }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachDetach {
      XCTestExpectation *expectation = [self expectationWithDescription:@"attach_detach"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_detach"];
        [channel attach];

        __block BOOL attached = NO;
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                attached = YES;
                [channel detach];
            }
            if (attached && state == ARTRealtimeChannelDetached) {
                [expectation fulfill];
            }
        }];
    }];

    [self waitForExpectationsWithTimeout:TIMEOUT handler:nil];
}


- (void) testAttachDetachAttach {

      XCTestExpectation *expectation = [self expectationWithDescription:@"attach_detach_attach"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"attach_detach_attach"];
        [channel attach];
        __block BOOL attached = false;
        __block int attachCount =0;
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
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

-(void) testSkipsFromDetachingToAttaching {
    XCTFail(@"FFS");
    return;
      XCTestExpectation *expectation = [self expectationWithDescription:@"detaching_to_attaching"];
    [self withRealtime:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"detaching_to_attaching"];
        [channel attach];
        __block int attachCount=0;
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                [channel detach];
            }
            if(state == ARTRealtimeChannelDetaching) {
                [channel attach];
            }
            if(state == ARTRealtimeChannelDetached) {
                XCTFail(@"Should not have reached detached state");
            }
            if(state == ARTRealtimeChannelAttaching) {
                //TODO sort this fucking thing out.
               // if(attachCount ==1) {
                    [expectation fulfill];
              //  }
                attachCount++;
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    
}

- (void) testAttachMultipleChannels {
//TODO
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
    //VXTODO
}


- (void)testDetach {
    
  //  XCTFail(@"TODO THIS CRASHES");
  //  return;
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
  //  XCTFail(@"TODO THIS CRASHES");
  //  return;
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
      XCTestExpectation *expectation = [self expectationWithDescription:@"attaching_to_detaching"];
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
    
      XCTestExpectation *expectation = [self expectationWithDescription:@"testDetachingIgnoresDetach"];
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

- (void)testPublish {
    NSLog(@"testpublish happening");
      XCTestExpectation *expectation = [self expectationWithDescription:@"publish"];
    [self withRealtime:^(ARTRealtime *realtime) {
            NSLog(@"testpublish happening???");
        ARTRealtimeChannel *channel = [realtime channel:@"test"];
        id<ARTSubscription> subscription = [channel subscribe:^(ARTMessage *message) {
            XCTAssertEqualObjects(message.payload.payload, @"testString");
            [subscription unsubscribe];
            [expectation fulfill];
        }];
        
        [channel publish:@"testString" cb:^(ARTStatus status) {
                        NSLog(@"testpublish happening??? ffs");
            XCTAssertEqual(status, ARTStatusOk);
        }];
    }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



- (void)multipleSendName:(NSString *)name count:(int)count delay:(int)delay {
    __block int numReceived = 0;

    XCTestExpectation *e = [self expectationWithDescription:@"realtime"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:TIMEOUT handler:nil];

    [self withRealtime:^(ARTRealtime *realtime) {
          XCTestExpectation *expectation = [self expectationWithDescription:@"multiple_send"];
        ARTRealtimeChannel *channel = [realtime channel:name];

        [channel attach];
        [channel subscribeToStateChanges:^(ARTRealtimeChannelState state, ARTStatus status) {
            if (state == ARTRealtimeChannelAttached) {
                [channel subscribe:^(ARTMessage *message) {
                    ++numReceived;
                    if (numReceived == count) {
                        [expectation fulfill];
                    }
                }];

                [ARTTestUtil repeat:count delay:(delay / 1000.0) block:^(int i) {
                    NSString *msg = [NSString stringWithFormat:@"Test message (_multiple_send) %d", i];
                    [channel publish:msg withName:@"test_event" cb:^(ARTStatus status) {

                    }];
                }];
            }
        }];
        [self waitForExpectationsWithTimeout:((delay / 1000.0) * count * 2) handler:nil];
    }];

    XCTAssertEqual(numReceived, count);
}

- (void)testPublish_10_1000 {
    [self multipleSendName:@"multiple_send_10_1000" count:10 delay:1000];
}

- (void)testPublish_20_200 {
    [self multipleSendName:@"multiple_send_20_200" count:20 delay:200];
}



- (void)testStats {
      XCTestExpectation *expectation = [self expectationWithDescription:@"stats"];
    
    [self withRealtime:^(ARTRealtime *realtime) {
        [realtime stats:^(ARTStatus status, id<ARTPaginatedResult> result) {
            NSLog(@"stats called back with %@, %d", result, status);
            XCTAssertEqual(status, ARTStatusOk);
            XCTAssertNotNil([result current]);
            if(status == ARTStatusOk) {
                [expectation fulfill];
            }

        }];
    }];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistory {
      XCTestExpectation *expectation = [self expectationWithDescription:@"testHistory"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        ARTRealtimeChannel *channel = [realtime channel:@"persisted:testHistory"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void) testHistoryBothChannels {
      XCTestExpectation *expectation1 = [self expectationWithDescription:@"historyBothChanels1"];
      XCTestExpectation *expectation2 = [self expectationWithDescription:@"historyBothChanels2"];
    [self withRealtime:^(ARTRealtime  *realtime) {
        NSString * both = @"historyBoth";
        ARTRealtimeChannel *channel1 = [realtime channel:both];
        ARTRealtimeChannel *channel2 = [realtime channel:both];
        [channel1 publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel2 publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel1 history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    [expectation1 fulfill];
                    
                }];
                [channel2 history:^(ARTStatus status, id<ARTPaginatedResult> result) {
                    XCTAssertEqual(status, ARTStatusOk);
                    NSArray *messages = [result current];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects(@"testString2", [m0 content]);
                    XCTAssertEqualObjects(@"testString", [m1 content]);
                    [expectation2 fulfill];
                    
                    
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


@end
