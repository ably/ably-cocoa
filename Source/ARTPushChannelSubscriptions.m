//
//  ARTPushChannelSubscriptions.m
//  Ably
//
//  Created by Ricardo Pereira on 20/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushChannelSubscriptions.h"
#import "ARTHttp.h"
#import "ARTLog.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTPushChannelSubscription.h"
#import "ARTClientOptions.h"
#import "ARTEncoder.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTRest+Private.h"

@implementation ARTPushChannelSubscriptions {
    __weak ARTRest *_rest;
    __weak ARTLog* _logger;
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _queue = rest.queue;
        _userQueue = rest.userQueue;
    }
    return self;
}

- (void)save:(ARTPushChannelSubscription *)channelSubscription callback:(void (^)(ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [[_rest defaultEncoder] encodePushChannelSubscription:channelSubscription error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"save channel subscription with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            [_logger debug:__FILE__ line:__LINE__ message:@"channel subscription saved successfully"];
        }
        else if (error) {
            [_logger error:@"%@: save channel subscription failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
        }
        else {
            [_logger error:@"%@: save channel subscription failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)listChannels:(void (^)(ARTPaginatedResult<NSString *> * _Nullable, ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult *, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
        return [[[_rest defaultEncoder] decodePushChannelSubscriptions:data error:error] artMap:^NSString *(ARTPushChannelSubscription *item) {
            return ((ARTPushChannelSubscription *)item).channel;
        }];
    };
    [ARTPaginatedResult executePaginated:_rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)list:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTPaginatedResult<ARTPushChannelSubscription *> *result, ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult *, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params asURLQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
        return [[_rest defaultEncoder] decodePushChannelSubscriptions:data error:error];
    };
    [ARTPaginatedResult executePaginated:_rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)remove:(ARTPushChannelSubscription *)subscription callback:(void (^)(ARTErrorInfo *_Nullable))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if ((subscription.deviceId && subscription.clientId) || (!subscription.deviceId && !subscription.clientId)) {
        callback([ARTErrorInfo createWithCode:0 message:@"ARTChannelSubscription cannot be for both a deviceId and a clientId"]);
        return;
    }
    NSMutableDictionary *where = [[NSMutableDictionary alloc] init];
    where[@"channel"] = subscription.channel;
    if (subscription.deviceId) {
        where[@"deviceId"] = subscription.deviceId;
    } else {
        where[@"clientId"] = subscription.clientId;
    }
    [self _removeWhere:where callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
});
}


- (void)removeWhere:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [self _removeWhere:params callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)_removeWhere:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTErrorInfo *error))callback {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params asURLQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [_logger debug:__FILE__ line:__LINE__ message:@"remove channel subscription with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            [_logger debug:__FILE__ line:__LINE__ message:@"%@: channel subscription removed successfully", NSStringFromClass(self.class)];
        }
        else if (error) {
            [_logger error:@"%@: remove channel subscription failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
        }
        else {
            [_logger error:@"%@: remove channel subscription failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
        }
    }];
}

@end
