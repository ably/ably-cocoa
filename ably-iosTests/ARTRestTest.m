//
//  ARTRestTest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTAppSetup.h"

@interface ARTRestTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;
    float _timeout;
}

- (void)withRest:(void(^)(ARTRest *))cb;

@end

//const float REST_TIMEOUT =[ARTAppSetup timeout];

@implementation ARTRestTest

- (void)setUp {
    [super setUp];
    _options = [[ARTOptions alloc] init];
    _options.restHost = [ARTAppSetup restHost];
    _timeout = [ARTAppSetup timeout];
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

- (void)withRest:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        [ARTAppSetup setupApp:_options cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}



//TODO RM
- (void)testSomething {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSomething"];
    NSLog(@"ABOUT TO TEST SOMETHING");
    [self withRest:^(ARTRest *rest) {
        NSLog(@"WELL THEN");
        ARTRestChannel *channel = [rest channel:@"test"];
        [channel publish:@"testString" cb:^(ARTStatus status) {

            NSLog(@"this sux %d", status);
            XCTAssertEqual(status, ARTStatusOk);
            if(status == ARTStatusOk) {
                [expectation fulfill];
            }

        }];
    }];
    
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}


- (void)testPublish {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPublish"];
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"test"];
        [channel publish:@"testString" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [expectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}



//VXTODO place in iOS status doc
- (void)testRestPresence {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"persisted:presence_fixtures"];
        [channel presence:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            if(status != ARTStatusOk) {
                XCTFail(@"not an ok status");
                [expectation fulfill];
                return;
            }
            NSArray *presence = [result current];
            XCTAssertEqual(4, presence.count);
            ARTPresenceMessage *p0 = presence[0];
            ARTPresenceMessage *p1 = presence[1];
            ARTPresenceMessage *p2 = presence[2];
            ARTPresenceMessage *p3 = presence[3];


            // This is assuming the results are coming back sorted by clientId
            // in alphabetical order. This seems to be the case at the time of
            // writing, but may change in the future

            XCTAssertEqualObjects(@"client_bool", p0.clientId);
            XCTAssertEqualObjects(@"true", [p0 content]);

            XCTAssertEqualObjects(@"client_int", p1.clientId);
            XCTAssertEqualObjects(@"24", [p1 content]);

            XCTAssertEqualObjects(@"client_json", p2.clientId);
            XCTAssertEqualObjects(@"{\"test\":\"This is a JSONObject clientData payload\"}", [p2 content]);

            XCTAssertEqualObjects(@"client_string", p3.clientId);
            XCTAssertEqualObjects(@"This is a string clientData payload", [p3 content]);


            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}



//TODO put into ios status doc
-(void) testHistoryForwardPagination
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryForwardPagination"];
    [self withRest:^(ARTRest  *rest) {
        ARTRestChannel *channel = [rest channel:@"histChan"];
        [channel publish:@"testString1" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel publish:@"testString3" cb:^(ARTStatus status) {
                    XCTAssertEqual(status, ARTStatusOk);
                    [channel publish:@"testString4" cb:^(ARTStatus status) {
                        XCTAssertEqual(status, ARTStatusOk);
                        [channel publish:@"testString5" cb:^(ARTStatus status) {
                            XCTAssertEqual(status, ARTStatusOk);
                            [channel historyWithParams:@{@"limit" : @"2",
                                                         @"direction" : @"forwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                XCTAssertEqual(status, ARTStatusOk);
                                XCTAssertTrue([result hasFirst]);
                                XCTAssertTrue([result hasNext]);
                                NSArray * page = [result current];
                                XCTAssertEqual([page count], 2);
                                ARTMessage * firstMessage = [page objectAtIndex:0];
                                ARTMessage * secondMessage =[page objectAtIndex:1];
                                XCTAssertEqualObjects(@"testString1", [firstMessage content]);
                                XCTAssertEqualObjects(@"testString2", [secondMessage content]);
                                [result getNext:^(ARTStatus status, id<ARTPaginatedResult> result2) {
                                    XCTAssertEqual(status, ARTStatusOk);
                                    XCTAssertTrue([result2 hasFirst]);
                                    NSArray * page = [result2 current];
                                    XCTAssertEqual([page count], 2);
                                    ARTMessage * firstMessage = [page objectAtIndex:0];
                                    ARTMessage * secondMessage =[page objectAtIndex:1];
                                    XCTAssertEqualObjects(@"testString3", [firstMessage content]);
                                    XCTAssertEqualObjects(@"testString4", [secondMessage content]);
                                    
                                    [result2 getNext:^(ARTStatus status, id<ARTPaginatedResult> result3) {
                                        XCTAssertEqual(status, ARTStatusOk);
                                        XCTAssertTrue([result3 hasFirst]);
                                        XCTAssertFalse([result3 hasNext]);
                                        NSArray * page = [result3 current];
                                        XCTAssertEqual([page count], 1);
                                        ARTMessage * firstMessage = [page objectAtIndex:0];
                                        XCTAssertEqualObjects(@"testString5", [firstMessage content]);
                                        [expectation fulfill];
                                    }];
                                }];
                                 
                            }];
                        }];
                    }];
                }];
            }];
        }];
    }];
    //TODO TIMER
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}


//TODO ios status doc
-(void) testHistoryBackwardPagination
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testHistoryBackwardagination"];
    [self withRest:^(ARTRest  *rest) {
        ARTRestChannel *channel = [rest channel:@"histBackChan"];
        [channel publish:@"testString1" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [channel publish:@"testString2" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusOk);
                [channel publish:@"testString3" cb:^(ARTStatus status) {
                    XCTAssertEqual(status, ARTStatusOk);
                    [channel publish:@"testString4" cb:^(ARTStatus status) {
                        XCTAssertEqual(status, ARTStatusOk);
                        [channel publish:@"testString5" cb:^(ARTStatus status) {
                            XCTAssertEqual(status, ARTStatusOk);
                            [channel historyWithParams:@{@"limit" : @"2",
                                                         @"direction" : @"backwards"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
                                                             XCTAssertEqual(status, ARTStatusOk);
                                                             XCTAssertTrue([result hasFirst]);
                                                             XCTAssertTrue([result hasNext]);
                                                             NSArray * page = [result current];
                                                             XCTAssertEqual([page count], 2);
                                                             ARTMessage * firstMessage = [page objectAtIndex:0];
                                                             ARTMessage * secondMessage =[page objectAtIndex:1];
                                                             XCTAssertEqualObjects(@"testString5", [firstMessage content]);
                                                             XCTAssertEqualObjects(@"testString4", [secondMessage content]);
                                                             [result getNext:^(ARTStatus status, id<ARTPaginatedResult> result2) {
                                                                 XCTAssertEqual(status, ARTStatusOk);
                                                                 XCTAssertTrue([result2 hasFirst]);
                                                                 NSArray * page = [result2 current];
                                                                 XCTAssertEqual([page count], 2);
                                                                 ARTMessage * firstMessage = [page objectAtIndex:0];
                                                                 ARTMessage * secondMessage =[page objectAtIndex:1];
                                                                 XCTAssertEqualObjects(@"testString3", [firstMessage content]);
                                                                 XCTAssertEqualObjects(@"testString2", [secondMessage content]);
                                                                 
                                                                 [result2 getNext:^(ARTStatus status, id<ARTPaginatedResult> result3) {
                                                                     XCTAssertEqual(status, ARTStatusOk);
                                                                     XCTAssertTrue([result3 hasFirst]);
                                                                     XCTAssertFalse([result3 hasNext]);
                                                                     NSArray * page = [result3 current];
                                                                     XCTAssertEqual([page count], 1);
                                                                     ARTMessage * firstMessage = [page objectAtIndex:0];
                                                                     XCTAssertEqualObjects(@"testString1", [firstMessage content]);
                                                                     [expectation fulfill];
                                                                 }];
                                                             }];
                                                             
                                                         }];
                        }];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}




-(void) testPresenceHistory
{//- (id<ARTCancellable>)presenceHistory:(ARTPaginatedResultCb)cb {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresenceHistory"];
    [self withRest:^(ARTRest  *rest) {
        ARTRestChannel *channel = [rest channel:@"persisted:presence_fixtures"];
        [channel presenceHistory:^(ARTStatus status, id<ARTPaginatedResult> result) {

            XCTAssertEqual(status, ARTStatusOk);
            NSLog(@"retrieved history %@", [result current]);
            
            NSArray * page = [result current];
            ARTMessage * first = [page objectAtIndex:0];
            NSLog(@"first content is %@",[first content]);
            
            XCTFail(@"TODO implmement this test");
            //TODO check result
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}




-(void) testChannel
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testChannel"];
    [self withRest:^(ARTRest *rest) {
        ARTRestChannel *channel = [rest channel:@"testChannel"];
        
        /**
         TODO show that cipher params works.
         */

            [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:_timeout handler:nil];

}


- (void)testRestStats {
    XCTestExpectation *expectation = [self expectationWithDescription:@"stats"];
    [self withRest:^(ARTRest *rest) {
        [rest stats:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            XCTAssertNotNil([result current]);
            XCTAssertFalse([result hasNext]);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}




//TODO move this into the setup section of the test? Will this impact realtime?
-(void) populateStats:(ARTRest *) rest channel:(ARTRestChannel *) channel
{
    //TODO put some stats into the app so that I can pull it out again and verify it works.
    /*
    ARTMessage *message = [[ARTMessage alloc] init];
    message.name = name;
    message.payload =[ARTPayload payloadWithPayload:payload encoding:@""];
    message = [message encode:channel.payloadEncoder];
    
    NSData *encodedMessage = [self.rest.defaultEncoder encodeMessage:message];
    NSDictionary *headers = @{@"Content-Type":rest.defaultEncoding};
    
    NSString *path = [NSString stringWithFormat:@"%@/stats", channel.basePath];
    return [self.rest post:path headers:headers body:encodedMessage authenticated:YES cb:^(ARTHttpResponse *response) {
        ARTStatus status = response.status >= 200 && response.status < 300 ? ARTStatusOk : ARTStatusError;
        NSLog(@"publish response is %@", response);
        cb(status);
    }];
     */
    
}

- (void)testRestStatsWithParams {
    XCTestExpectation *expectation = [self expectationWithDescription:@"stats"];
    [self withRest:^(ARTRest *rest) {
        [rest statsWithParams:@{@"limit" : @"1"} cb:^(ARTStatus status, id<ARTPaginatedResult> result) {
            XCTAssertEqual(status, ARTStatusOk);
            XCTAssertNotNil([result current]);
            XCTAssertFalse([result hasNext]);
            NSArray * page = [result current];
            NSLog(@"page is %@", page);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:_timeout handler:nil];
}





@end
