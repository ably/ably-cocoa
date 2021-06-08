//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import "ARTSRAutobahnUtilities.h"

#import "ARTSRAutobahnOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTSRAutobahnUtilities : NSObject @end
@implementation ARTSRAutobahnUtilities @end

///--------------------------------------
#pragma mark - Test Configuration
///--------------------------------------

NSString *ARTSRAutobahnTestAgentName(void)
{
    return [NSBundle bundleForClass:[ARTSRAutobahnUtilities class]].bundleIdentifier;
}

NSURL *ARTSRAutobahnTestServerURL(void)
{
    return [NSURL URLWithString:@"ws://localhost:9001"];
}

///--------------------------------------
#pragma mark - Validation
///--------------------------------------

NSDictionary<NSString *, id> *ARTSRAutobahnTestConfiguration(void)
{
    static NSDictionary *configuration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *configurationURL = [[NSBundle bundleForClass:[ARTSRAutobahnUtilities class]] URLForResource:@"autobahn_configuration"
                                                                                          withExtension:@"json"];
        NSInputStream *readStream = [NSInputStream inputStreamWithURL:configurationURL];
        [readStream open];
        configuration = [NSJSONSerialization JSONObjectWithStream:readStream options:0 error:nil];
        [readStream close];
    });
    return configuration;
}

BOOL ARTSRAutobahnIsValidResultBehavior(NSString *caseIdentifier, NSString *behavior)
{
    if ([behavior isEqualToString:@"OK"]) {
        return YES;
    }

    NSArray *cases = ARTSRAutobahnTestConfiguration()[behavior];
    for (NSString *caseId in cases) {
        if ([caseIdentifier hasPrefix:caseId]) {
            return YES;
        }
    }
    return NO;
}

///--------------------------------------
#pragma mark - Utilities
///--------------------------------------

BOOL ARTSRRunLoopRunUntil(BOOL (^predicate)(), NSTimeInterval timeout)
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];

    NSTimeInterval timeoutTime = [timeoutDate timeIntervalSinceReferenceDate];
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];

    while (!predicate() && currentTime < timeoutTime) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        currentTime = [NSDate timeIntervalSinceReferenceDate];
    }
    return (currentTime <= timeoutTime);
}

///--------------------------------------
#pragma mark - Setup
///--------------------------------------

NSUInteger ARTSRAutobahnTestCaseCount(void)
{
    static NSUInteger count;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARTSRAutobahnOperation *operation = ARTSRAutobahnTestCaseCountOperation(ARTSRAutobahnTestServerURL(),
                                                                           ARTSRAutobahnTestAgentName(),
                                                                           ^(NSInteger caseCount) {
                                                                               count = caseCount;
                                                                           });
        [operation start];

        NSCAssert([operation waitUntilFinishedWithTimeout:10], @"Timed out fetching test case count.");
        NSCAssert(!operation.error, @"CaseGetter should have successfully returned the number of testCases. Instead got error %@", operation.error);
    });
    return count;
}

NSDictionary<NSString *, id> *ARTSRAutobahnTestCaseInfo(NSInteger caseNumber)
{
    __block NSDictionary *caseInfo = nil;
    ARTSRAutobahnOperation *operation = ARTSRAutobahnTestCaseInfoOperation(ARTSRAutobahnTestServerURL(), caseNumber, ^(NSDictionary * _Nullable info) {
        caseInfo = info;
    });
    [operation start];

    NSCAssert([operation waitUntilFinishedWithTimeout:10], @"Timed out fetching test case info %ld.", (long)caseNumber);
    NSCAssert(!operation.error, @"Updating the report should not have errored");
    return caseInfo;
}

NS_ASSUME_NONNULL_END
