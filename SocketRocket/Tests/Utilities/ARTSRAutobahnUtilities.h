//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

///--------------------------------------
#pragma mark - Test Configuration
///--------------------------------------

extern NSString *ARTSRAutobahnTestAgentName(void);
extern NSURL *ARTSRAutobahnTestServerURL(void);

///--------------------------------------
#pragma mark - Validation
///--------------------------------------

extern NSDictionary<NSString *, id> *ARTSRAutobahnTestConfiguration(void);
extern BOOL ARTSRAutobahnIsValidResultBehavior(NSString *caseIdentifier, NSString *behavior);

///--------------------------------------
#pragma mark - Utilities
///--------------------------------------

extern BOOL ARTSRRunLoopRunUntil(BOOL (^predicate)(), NSTimeInterval timeout);

///--------------------------------------
#pragma mark - Setup
///--------------------------------------

extern NSUInteger ARTSRAutobahnTestCaseCount(void);
extern NSDictionary<NSString *, id> *ARTSRAutobahnTestCaseInfo(NSInteger caseNumber);

NS_ASSUME_NONNULL_END
