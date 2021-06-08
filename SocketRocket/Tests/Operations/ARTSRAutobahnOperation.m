//
// Copyright (c) 2016-present, Facebook, Inc.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.
//

#import "ARTSRAutobahnOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTSRAutobahnOperation ()

@property (nullable, nonatomic, copy, readonly) ARTSRAutobahnSocketTextMessageHandler textMessageHandler;
@property (nullable, nonatomic, copy, readonly) ARTSRAutobahnSocketDataMessageHandler dataMessageHandler;

@end

@implementation ARTSRAutobahnOperation

- (instancetype)initWithServerURL:(NSURL *)url
                  testCommandPath:(NSString *)path
                       caseNumber:(nullable NSNumber *)caseNumber
                            agent:(nullable NSString *)agent
               textMessageHandler:(nullable ARTSRAutobahnSocketTextMessageHandler)textMessageHandler
               dataMessageHandler:(nullable ARTSRAutobahnSocketDataMessageHandler)dataMessageHandler
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.path = (components.path ? [components.path stringByAppendingPathComponent:path] : path);

    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:2];
    if (caseNumber) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"case" value:caseNumber.stringValue]];
    }
    if (agent) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"agent" value:agent]];
    }
    components.queryItems = queryItems;
    self = [self initWithURL:components.URL];
    if (!self) return self;

    _textMessageHandler = [textMessageHandler copy];
    _dataMessageHandler = [dataMessageHandler copy];

    return self;
}

- (void)webSocket:(ARTSRWebSocket *)webSocket didReceiveMessageWithString:(NSString *)string
{
    if (self.textMessageHandler) {
        self.textMessageHandler(webSocket, string);
    }
}

- (void)webSocket:(ARTSRWebSocket *)webSocket didReceiveMessageWithData:(NSData *)data
{
    if (self.dataMessageHandler) {
        self.dataMessageHandler(webSocket, data);
    }
}

@end

ARTSRAutobahnOperation *ARTSRAutobahnTestOperation(NSURL *serverURL, NSInteger caseNumber, NSString *agent)
{
    return [[ARTSRAutobahnOperation alloc] initWithServerURL:serverURL
                                          testCommandPath:@"/runCase"
                                               caseNumber:@(caseNumber)
                                                    agent:agent
                                       textMessageHandler:^(ARTSRWebSocket * _Nonnull socket, NSString  * _Nullable message) {
                                           [socket sendString:message error:nil];
                                       }
                                       dataMessageHandler:^(ARTSRWebSocket * _Nonnull socket, NSData * _Nullable message) {
                                           [socket sendData:message error:nil];
                                       }];
}

extern ARTSRAutobahnOperation *ARTSRAutobahnTestResultOperation(NSURL *serverURL, NSInteger caseNumber, NSString *agent, ARTSRAutobahnTestResultHandler handler)
{
    return [[ARTSRAutobahnOperation alloc] initWithServerURL:serverURL
                                          testCommandPath:@"/getCaseStatus"
                                               caseNumber:@(caseNumber)
                                                    agent:agent
                                       textMessageHandler:^(ARTSRWebSocket * _Nonnull socket, NSString * _Nullable message) {
                                           NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
                                           NSDictionary *result = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:NULL];
                                           handler(result);
                                       }
                                       dataMessageHandler:nil];
}

extern ARTSRAutobahnOperation *ARTSRAutobahnTestCaseInfoOperation(NSURL *serverURL, NSInteger caseNumber, ARTSRAutobahnTestCaseInfoHandler handler)
{
    return [[ARTSRAutobahnOperation alloc] initWithServerURL:serverURL
                                          testCommandPath:@"/getCaseInfo"
                                               caseNumber:@(caseNumber)
                                                    agent:nil
                                       textMessageHandler:^(ARTSRWebSocket * _Nonnull socket, NSString * _Nullable message) {
                                           NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
                                           NSDictionary *result = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:NULL];
                                           handler(result);
                                       }
                                       dataMessageHandler:nil];
}

extern ARTSRAutobahnOperation *ARTSRAutobahnTestCaseCountOperation(NSURL *serverURL, NSString *agent, ARTSRAutobahnTestCaseCountHandler handler)
{
    return [[ARTSRAutobahnOperation alloc] initWithServerURL:serverURL
                                          testCommandPath:@"/getCaseCount"
                                               caseNumber:nil
                                                    agent:agent
                                       textMessageHandler:^(ARTSRWebSocket * _Nonnull socket, NSString * _Nullable message) {
                                           NSInteger count = [message integerValue];
                                           handler(count);
                                       }
                                       dataMessageHandler:nil];
}

extern ARTSRAutobahnOperation *ARTSRAutobahnTestUpdateReportsOperation(NSURL *serverURL, NSString *agent)
{
    return [[ARTSRAutobahnOperation alloc] initWithServerURL:serverURL
                                          testCommandPath:@"/updateReports"
                                               caseNumber:nil
                                                    agent:agent
                                       textMessageHandler:nil
                                       dataMessageHandler:nil];
}

NS_ASSUME_NONNULL_END
