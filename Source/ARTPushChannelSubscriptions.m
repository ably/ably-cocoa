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

@implementation ARTPushChannelSubscriptions {
    id<ARTHTTPAuthenticatedExecutor> _httpExecutor;
    __weak ARTLog* _logger;
}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor {
    if (self = [super init]) {
        _httpExecutor = httpExecutor;
        _logger = [httpExecutor logger];
    }
    return self;
}

- (void)save:(ARTPushChannelSubscription *)channelSubscription callback:(void (^)(ARTErrorInfo *error))callback {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [[_httpExecutor defaultEncoder] encodePushChannelSubscription:channelSubscription];
    [request setValue:[[_httpExecutor defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"save channel subscription with request %@", request];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
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
}

- (void)listChannels:(void (^)(ARTPaginatedResult<NSString *> * _Nullable, ARTErrorInfo *error))callback {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        return [[[_httpExecutor defaultEncoder] decodePushChannelSubscriptions:data error:nil] artMap:^NSString *(ARTPushChannelSubscription *item) {
            return ((ARTPushChannelSubscription *)item).channel;
        }];
    };
    [ARTPaginatedResult executePaginated:_httpExecutor withRequest:request andResponseProcessor:responseProcessor callback:callback];
}

- (void)list:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTPaginatedResult<ARTPushChannelSubscription *> *result, ARTErrorInfo *error))callback {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params asURLQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        return [[_httpExecutor defaultEncoder] decodePushChannelSubscriptions:data error:nil];
    };
    [ARTPaginatedResult executePaginated:_httpExecutor withRequest:request andResponseProcessor:responseProcessor callback:callback];
}

- (void)remove:(ARTPushChannelSubscription *)subscription callback:(void (^)(ARTErrorInfo *_Nullable))callback {
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
    [self removeWhere:where callback:callback];
}


- (void)removeWhere:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTErrorInfo *error))callback {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params asURLQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [_logger debug:__FILE__ line:__LINE__ message:@"remove channel subscription with request %@", request];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
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
