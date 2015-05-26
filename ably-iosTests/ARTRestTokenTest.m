//
//  ARTRestTokenTest.m
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
#import "ARTRest.h"
#import "ARTTestUtil.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTPayload.h"
#import "ARTTokenDetails+Private.h"
@interface ARTRestTokenTest : XCTestCase
{
    ARTRest *_rest;
    ARTRest *_rest2;
}

@end


@implementation ARTRestTokenTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _rest = nil;
    _rest2 = nil;
    [super tearDown];
}

- (void)testTokenSimple {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRestTimeBadHost"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.useTokenAuth = true;
        options.authOptions.clientId = @"testToken";
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthMethod authMethod = [auth getAuthMethod];
            XCTAssertEqual(authMethod, ARTAuthMethodToken);
            ARTRestChannel * c= [rest channel:@"getChannel"];
            [c publish:@"something" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [expectation fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



- (void)testInitWithBadToken {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInitWithToken"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.useTokenAuth = true;
        options.authOptions.clientId = @"testToken";
        options.authOptions.token = @"this_is_a_bad_token";
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthMethod authMethod = [auth getAuthMethod];
            XCTAssertEqual(authMethod, ARTAuthMethodToken);
            ARTRestChannel * c= [rest channel:@"getChannel"];
            [c publish:@"something" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusError, status.status);
                [expectation fulfill];
            }];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithBorrowedToken {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInitWithToken"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.useTokenAuth = true;
        options.authOptions.clientId = @"testToken";
        [ARTRest restWithOptions:options cb:^(ARTRest *firstRest) {
            _rest = firstRest;
            ARTAuth * auth = firstRest.auth;
            [auth authToken:^id<ARTCancellable>(ARTTokenDetails * details) {
                options.authOptions.token = details.token;
                options.authOptions.keySecret = nil;
                options.authOptions.keyName = nil;
                [ARTRest restWithOptions:options cb:^(ARTRest *secondRest) {
                    _rest = secondRest;
                    ARTAuthMethod authMethod = [auth getAuthMethod];
                    XCTAssertEqual(authMethod, ARTAuthMethodToken);
                    ARTRestChannel * c= [secondRest channel:@"getChannel"];
                    [c publish:@"something" cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        [expectation fulfill];
                    }];
                }];
                return nil;
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testUseTokenAuthForcesToken {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testUseTokenAuthForcesToken"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.useTokenAuth = true;
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthMethod authMethod = [auth getAuthMethod];
            XCTAssertEqual(authMethod, ARTAuthMethodToken);
            ARTRestChannel * c= [rest channel:@"getChannel"];
            [c publish:@"something" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [expectation fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testClientIdForcesToken {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testClientIdForcesToken"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.clientId = @"clientIdThatForcesToken";
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthMethod authMethod = [auth getAuthMethod];
            XCTAssertEqual(authMethod, ARTAuthMethodToken);
            ARTRestChannel * c= [rest channel:@"getChannel"];
            [c publish:@"something" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [expectation fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testAuthURLCallbackForcesToken {
    //TODO
    XCTFail(@"TODO");
    
}

-(void)testTTLDefaultOneHour {
    XCTestExpectation *exp= [self expectationWithDescription:@"testTTLDefaultOneHour"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.clientId = @"clientIdThatForcesToken";
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthOptions * authOptions = [auth getAuthOptions];
            XCTAssertEqual(authOptions.tokenDetails.expires - authOptions.tokenDetails.issued,  3600000);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testTTL {
    XCTestExpectation *exp= [self expectationWithDescription:@"testTTLDefaultOneHour"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.clientId = @"clientIdThatForcesToken";

        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthOptions * authOptions = [auth getAuthOptions];
            XCTAssertEqual(authOptions.tokenDetails.expires - authOptions.tokenDetails.issued,  3600000);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testTokenExpiresGetsReissued {
    XCTestExpectation *exp= [self expectationWithDescription:@"testTokenExpires"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.clientId = @"clientIdThatForcesToken";
        const int fiveSecondsMilli = 5000;
        options.authOptions.ttl = fiveSecondsMilli;
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthOptions * authOptions = [auth getAuthOptions];
            XCTAssertEqual(authOptions.tokenDetails.expires - authOptions.tokenDetails.issued,  fiveSecondsMilli);
            ARTRestChannel * c= [rest channel:@"getChannel"];
            NSString * oldToken = authOptions.tokenDetails.token;
            [c publish:@"something" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                sleep(6); // wait for token to expire
                [c publish:@"somethingElse" cb:^(ARTStatus *status) {
                    NSString * newToken = authOptions.tokenDetails.token;
                    XCTAssertFalse([newToken isEqualToString:oldToken]);
                    XCTAssertEqual(ARTStatusOk, status.status);
                    
                    [exp fulfill];
                }];
            }];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSameTokenIsUsed {
    XCTestExpectation *exp= [self expectationWithDescription:@"testSameTokenIsUsed"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.clientId = @"clientIdThatForcesToken";
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthOptions * authOptions = [auth getAuthOptions];
            ARTRestChannel * c= [rest channel:@"getChannel"];
            NSString * initialToken = authOptions.tokenDetails.token;
            [c publish:@"first" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                [c publish:@"second" cb:^(ARTStatus *status) {
                    [c publish:@"third" cb:^(ARTStatus *status) {
                        NSString * currentToken = authOptions.tokenDetails.token;
                        XCTAssertTrue([currentToken isEqualToString:initialToken]);
                        [exp fulfill];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testToken401GetsReissued {
    XCTestExpectation *exp= [self expectationWithDescription:@"testTokenExpires"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.clientId = @"clientIdThatForcesToken";
        const int fiveSecondsMilli = 5000;
        options.authOptions.ttl = fiveSecondsMilli;
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthOptions * authOptions = [auth getAuthOptions];
            XCTAssertEqual(authOptions.tokenDetails.expires - authOptions.tokenDetails.issued,  fiveSecondsMilli);
            
            // change the expires time to far in the future so the client
            //uses the expired token and receieves 401
            [authOptions.tokenDetails setExpiresTime:INT64_MAX];
            
            
            ARTRestChannel * c= [rest channel:@"getChannel"];
            NSString * oldToken = authOptions.tokenDetails.token;
            [c publish:@"something" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                sleep(6); // wait for token to expire
                [c publish:@"somethingElse" cb:^(ARTStatus *status) {
                    NSString * newToken = authOptions.tokenDetails.token;
                    XCTAssertFalse([newToken isEqualToString:oldToken]);
                    XCTAssertEqual(ARTStatusOk, status.status);
                    
                    [exp fulfill];
                }];
            }];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testReissuedTokenFailReturnsError {
    XCTestExpectation *exp= [self expectationWithDescription:@"testTokenExpires"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.clientId = @"clientIdThatForcesToken";
        const int fiveSecondsMilli = 5000;
        options.authOptions.ttl = fiveSecondsMilli;
        [ARTRest restWithOptions:options cb:^(ARTRest *rest) {
            _rest = rest;
            ARTAuth * auth = rest.auth;
            ARTAuthOptions * authOptions = [auth getAuthOptions];
            XCTAssertEqual(authOptions.tokenDetails.expires - authOptions.tokenDetails.issued,  fiveSecondsMilli);
            
            // change the expires time to far in the future so the client
            //uses the expired token and receieves 401
            [authOptions.tokenDetails setExpiresTime:INT64_MAX];

            ARTRestChannel * c= [rest channel:@"getChannel"];

            [c publish:@"something" cb:^(ARTStatus *status) {
                XCTAssertEqual(ARTStatusOk, status.status);
                sleep(6); // wait for token to expire
                
                // set badKeySecret so the token request fails due to invalid mac.
                [authOptions setKeySecretTo:@"badKeySecret"];

                [c publish:@"somethingElse" cb:^(ARTStatus *status) {
                    XCTAssertEqual(ARTStatusError, status.status);
                    [exp fulfill];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testUseTokenAuthThrowsWithNoMeansToCreateToken {
    XCTestExpectation *exp = [self expectationWithDescription:@"testUseTokenAuthThrowsWithNoMeansToCreateToken"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.useTokenAuth = true;
        options.authOptions.keyName = nil;
        options.authOptions.keySecret = nil;
        options.authOptions.token = nil;
        XCTAssertThrows([ARTRest restWithOptions:options cb:^(ARTRest *rest){}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testExpiredBorrowedTokenErrors {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testInitWithToken"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.useTokenAuth = true;
        options.authOptions.clientId = @"testToken";
        options.authOptions.ttl = 5000;
        [ARTRest restWithOptions:options cb:^(ARTRest *firstRest) {
            _rest = firstRest;
            ARTAuth * auth = firstRest.auth;
            [auth authToken:^id<ARTCancellable>(ARTTokenDetails * details) {
                options.authOptions.token = details.token;
                options.authOptions.keySecret = nil;
                options.authOptions.keyName = nil;
                [details setExpiresTime:INT_MAX]; //override expires time so we try to use the expired token
                [ARTRest restWithOptions:options cb:^(ARTRest *secondRest) {
                    _rest2 = secondRest;
                    ARTAuthMethod authMethod = [auth getAuthMethod];
                    XCTAssertEqual(authMethod, ARTAuthMethodToken);
                    ARTRestChannel * c= [secondRest channel:@"getChannel"];
                    [c publish:@"something" cb:^(ARTStatus *status) {
                        XCTAssertEqual(ARTStatusOk, status.status);
                        sleep(6);
                        [c publish:@"withExpiredToken" cb:^(ARTStatus *status) {
                            XCTAssertEqual(ARTStatusError, status.status);
                            [expectation fulfill];
                        }];
                    }];
                }];
                return nil;
            }];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
 //TODO implement
 
- (void)testNullParams {
    XCTFail(@"TODO write test");
}
- (void)testEmptyParams {
    XCTFail(@"TODO write test");
}
- (void)testExplicitTimestamp {
    XCTFail(@"TODO write test");
}
- (void)testExplicitInvalidTimestamp {
    XCTFail(@"TODO write test");
}

- (void)testSystemTimestamp {
    XCTFail(@"TODO write test");
}
- (void)testDuplicateNonce {
    XCTFail(@"TODO write test");
}

- (void)testClientId { //authclientid0
    XCTFail(@"TODO write test");
}
- (void)testSubsetKeyCapabilityGen {
    XCTFail(@"TODO write test");
}

- (void)testSpecifiedKeyGen {
    XCTFail(@"TODO write test");
}
- (void)testInvalidMac {
    XCTFail(@"TODO write test");
}
- (void)testSpecifiedTTL {
    XCTFail(@"TODO write test");
}
- (void)testExcessiveTTL {
    XCTFail(@"TODO write test");
}
- (void)testInvalidTTL {
    XCTFail(@"TODO write test");
}
*/


@end
