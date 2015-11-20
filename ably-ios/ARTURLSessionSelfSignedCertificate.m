//
//  ARTURLSessionSelfSignedCertificate.m
//  ably
//
//  Created by Ricardo Pereira on 20/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTURLSessionSelfSignedCertificate.h"

@interface ARTURLSessionSelfSignedCertificate() {
    NSURLSession *_session;
}

@end

@implementation ARTURLSessionSelfSignedCertificate

- (instancetype)init {
    if (self = [super init]) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    }
    return self;
}

- (void)get:(NSURLRequest *)request completion:(ARTHttpRequestCallback)callback {
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        callback((NSHTTPURLResponse *)response, data, error);
    }];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    completionHandler(NSURLSessionAuthChallengeUseCredential, [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust]);
}

@end
