#import "AuthRevocationTests.h"

@implementation AuthRevocationTests

//RSA17d
- (void)test_revoke_tokens_without_targets_fail_with_correct_message {
    //given
    ARTRest *rest = [[ARTRest alloc] initWithKey:@"xxxx:xxxx"];
    NSArray<ARTTokenRevocationTarget *> *emptyTargets = @[];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Result of async"];
    __block BOOL triggered = NO;
    [rest.auth revokeTokens:emptyTargets issuedBefore:nil callback:^(ARTTokenRevocationResponse *_Nullable response, NSError *_Nullable error) {
        triggered = YES;
        if (error) {
            XCTAssertTrue([[error localizedDescription] isEqualToString:@"targets cannot be null or empty"]);
        } else {
            XCTFail("Expected error when targets are empty but no error returned");
        }
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:10.0];
    XCTAssertTrue(triggered, "targetsCallback is expected to be trigerred for test_revoke_tokens_without_targets_fail_with_correct_message");
}

@end
