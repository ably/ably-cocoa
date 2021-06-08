//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import "ARTSRTWebSocketOperation.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ARTSRAutobahnSocketTextMessageHandler)(ARTSRWebSocket *socket, NSString  * _Nullable message);
typedef void(^ARTSRAutobahnSocketDataMessageHandler)(ARTSRWebSocket *socket, NSData  * _Nullable message);

@interface ARTSRAutobahnOperation : ARTSRTWebSocketOperation

- (instancetype)initWithServerURL:(NSURL *)url
                  testCommandPath:(NSString *)path
                       caseNumber:(nullable NSNumber *)caseNumber
                            agent:(nullable NSString *)agent
               textMessageHandler:(nullable ARTSRAutobahnSocketTextMessageHandler)textMessageHandler
               dataMessageHandler:(nullable ARTSRAutobahnSocketDataMessageHandler)dataMessageHandler;

@end

extern ARTSRAutobahnOperation *ARTSRAutobahnTestOperation(NSURL *serverURL, NSInteger caseNumber, NSString *agent);

typedef void(^ARTSRAutobahnTestResultHandler)(NSDictionary *_Nullable result);
extern ARTSRAutobahnOperation *ARTSRAutobahnTestResultOperation(NSURL *serverURL, NSInteger caseNumber, NSString *agent, ARTSRAutobahnTestResultHandler handler);

typedef void(^ARTSRAutobahnTestCaseInfoHandler)(NSDictionary *_Nullable caseInfo);
extern ARTSRAutobahnOperation *ARTSRAutobahnTestCaseInfoOperation(NSURL *serverURL, NSInteger caseNumber, ARTSRAutobahnTestCaseInfoHandler handler);

typedef void(^ARTSRAutobahnTestCaseCountHandler)(NSInteger caseCount);
extern ARTSRAutobahnOperation *ARTSRAutobahnTestCaseCountOperation(NSURL *serverURL, NSString *agent, ARTSRAutobahnTestCaseCountHandler handler);

extern ARTSRAutobahnOperation *ARTSRAutobahnTestUpdateReportsOperation(NSURL *serverURL, NSString *agent);

NS_ASSUME_NONNULL_END
