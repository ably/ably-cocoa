//
//  ARTHttp.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTHttp.h"
#import "ARTURLSessionServerTrust.h"

@interface ARTHttp ()

@property (readonly, strong, nonatomic) ARTURLSessionServerTrust *urlSession;

@end

@implementation ARTHttp

- (instancetype)init:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _urlSession = [[ARTURLSessionServerTrust alloc] init:queue];
    }
    return self;
}

- (void)dealloc {
    [_urlSession finishTasksAndInvalidate];
}

- (void)executeRequest:(NSMutableURLRequest *)request completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback {
    [self.logger debug:@"%@ %@", request.HTTPMethod, request.URL.absoluteString];
    [self.logger verbose:@"Headers %@", request.allHTTPHeaderFields];

    [_urlSession get:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (error) {
            [self.logger error:@"%@ %@: error %@", request.HTTPMethod, request.URL.absoluteString, error];
        } else {
            [self.logger debug:@"%@ %@: statusCode %ld", request.HTTPMethod, request.URL.absoluteString, (long)httpResponse.statusCode];
            [self.logger verbose:@"Headers %@", httpResponse.allHeaderFields];
            NSString *headerErrorMessage = httpResponse.allHeaderFields[@"X-Ably-ErrorMessage"];
            if (headerErrorMessage && ![headerErrorMessage isEqualToString:@""]) {
                [self.logger warn:@"%@", headerErrorMessage];
            }
        }
        callback(httpResponse, data, error);
    }];
}

@end
