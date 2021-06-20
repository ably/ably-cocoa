//
//  ARTURLSessionServerTrust.m
//  ably
//
//  Created by Ricardo Pereira on 20/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "Ably/ARTURLSessionServerTrust.h"

@interface ARTURLSessionServerTrust() {
    NSURLSession *_session;
    dispatch_queue_t _queue;
}

@end

@implementation ARTURLSessionServerTrust

- (instancetype)init:(dispatch_queue_t)queue {
    if (self = [super init]) {
        _queue = queue;
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    }
    return self;
}

- (dispatch_queue_t)queue {
    return _queue;
}

- (void)finishTasksAndInvalidate {
    [_session finishTasksAndInvalidate];
}

- (NSObject<ARTCancellable> *)get:(NSURLRequest *)request completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback {
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(self->_queue, ^{
            callback((NSHTTPURLResponse *)response, data, error);
        });
    }];
    [task resume];
    return task;
}

@end
