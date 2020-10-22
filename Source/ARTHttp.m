//
//  ARTHttp.m
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTHttp.h"
#import "ARTURLSessionServerTrust.h"
#import "ARTConstants.h"

@interface ARTHttp ()

@property (readonly, strong, nonatomic) id<ARTURLSession> urlSession;

@end

Class configuredUrlSessionClass = nil;

#pragma mark - ARTHttp

@implementation ARTHttp {
    ARTLog *_logger;
    _Nullable dispatch_queue_t _queue;
}

+ (void)setURLSessionClass:(const Class)urlSessionClass {
    configuredUrlSessionClass = urlSessionClass;
}

- (instancetype)init:(dispatch_queue_t)queue logger:(ARTLog *)logger {
    self = [super init];
    if (self) {
        const Class urlSessionClass = configuredUrlSessionClass ? configuredUrlSessionClass : [ARTURLSessionServerTrust class];
        _urlSession = [[urlSessionClass alloc] init:queue];
        _logger = logger;
    }
    return self;
}

- (ARTLog *)logger {
    return _logger;
}

- (void)dealloc {
    [_urlSession finishTasksAndInvalidate];
}

- (NSObject<ARTCancellable> *)executeRequest:(NSMutableURLRequest *)request completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback {
    NSString *requestBodyStr = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    if (!requestBodyStr) {
        requestBodyStr = [request.HTTPBody base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    }
    [self.logger debug:@"--> %@ %@\n  Body: %@\n  Headers: %@", request.HTTPMethod, request.URL.absoluteString, requestBodyStr, request.allHTTPHeaderFields];

    return [_urlSession get:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            [self.logger error:@"<-- %@ %@: error %@", request.HTTPMethod, request.URL.absoluteString, error];
        } else {
            NSString *responseDataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!responseDataStr) {
                responseDataStr = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
            }
            [self.logger debug:@"<-- %@ %@: statusCode %ld\n  Data: %@\n  Headers: %@\n", request.HTTPMethod, request.URL.absoluteString, (long)httpResponse.statusCode, responseDataStr, httpResponse.allHeaderFields];
            NSString *headerErrorMessage = httpResponse.allHeaderFields[ARTHttpHeaderFieldErrorMessageKey];
            if (headerErrorMessage && ![headerErrorMessage isEqualToString:@""]) {
                [self.logger warn:@"%@", headerErrorMessage];
            }
        }
        callback(httpResponse, data, error);
    }];
}

@end
