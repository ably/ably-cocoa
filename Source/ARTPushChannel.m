//
//  ARTPushChannel.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushChannel.h"
#import "ARTHttp.h"
#import "ARTLog.h"
#import "ARTChannel.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTClientOptions.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTPushChannelSubscription.h"

const NSUInteger ARTDefaultLimit = 100;

@implementation ARTPushChannel {
    __weak ARTLog *_logger;
    __weak ARTChannel *_channel;
}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor withChannel:(ARTChannel *)channel {
    if (self == [super self]) {
        _httpExecutor = httpExecutor;
        _logger = [httpExecutor logger];
        _channel = channel;
    }
    return self;
}

- (NSString *)clientId {
    return [self clientId];
}

- (void)subscribe {
    [self subscribeClient:[self clientId]];
}

- (void)subscribeDevice:(ARTDeviceId *)deviceId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_httpExecutor defaultEncoder] encode:@{
        @"deviceId": deviceId,
        @"channel": _channel.name,
    }];
    [request setValue:[[_httpExecutor defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"subscribe notifications for device %@ in channel %@", deviceId, _channel.name];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            return;
        }
        if (error) {
            [_logger error:@"%@: subscribe notifications for device %@ in channel %@ failed (%@)", NSStringFromClass(self.class), deviceId, _channel.name, error.localizedDescription];
        }
        else {
            [_logger error:@"%@: subscribe notifications for device %@ in channel %@ failed with status code %ld", NSStringFromClass(self.class), deviceId, _channel.name, (long)response.statusCode];
        }
    }];
}

- (void)subscribeClient:(NSString *)clientId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_httpExecutor defaultEncoder] encode:@{
        @"clientId": clientId,
        @"channel": _channel.name,
    }];
    [request setValue:[[_httpExecutor defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"subscribe notifications for clientId %@ in channel %@", clientId, _channel.name];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            return;
        }
        if (error) {
            [_logger error:@"%@: subscribe notifications for clientId %@ in channel %@ failed (%@)", NSStringFromClass(self.class), clientId, _channel.name, error.localizedDescription];
        }
        else {
            [_logger error:@"%@: subscribe notifications for clientId %@ in channel %@ failed with status code %ld", NSStringFromClass(self.class), clientId, _channel.name, (long)response.statusCode];
        }
    }];
}

- (void)unsubscribe {
    [self unsubscribeClient:[self clientId]];
}

- (void)unsubscribeDevice:(NSString *)deviceId {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"deviceId" value:deviceId],
        [NSURLQueryItem queryItemWithName:@"channel" value:_channel.name],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [_logger debug:__FILE__ line:__LINE__ message:@"unsubscribe notifications for device %@ in channel %@", deviceId, _channel.name];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            return;
        }
        if (error) {
            [_logger error:@"%@: unsubscribe notifications for device %@ in channel %@ failed (%@)", NSStringFromClass(self.class), deviceId, _channel.name, error.localizedDescription];
        }
        else {
            [_logger error:@"%@: unsubscribe notifications for device %@ in channel %@ failed with status code %ld", NSStringFromClass(self.class), deviceId, _channel.name, (long)response.statusCode];
        }
    }];
}

- (void)unsubscribeClient:(NSString *)clientId {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"clientId" value:clientId],
        [NSURLQueryItem queryItemWithName:@"channel" value:_channel.name],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [_logger debug:__FILE__ line:__LINE__ message:@"unsubscribe notifications for clientId %@ in channel %@", clientId, _channel.name];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            return;
        }
        if (error) {
            [_logger error:@"%@: unsubscribe notifications for clientId %@ in channel %@ failed (%@)", NSStringFromClass(self.class), clientId, _channel.name, error.localizedDescription];
        }
        else {
            [_logger error:@"%@: unsubscribe notifications for clientId %@ in channel %@ failed with status code %ld", NSStringFromClass(self.class), clientId, _channel.name, (long)response.statusCode];
        }
    }];
}

- (void)subscriptions:(void(^)(ARTPaginatedResult<ARTPushChannelSubscription *> *result, ARTErrorInfo *error))callback {
    [self subscriptionsClient:[self clientId] limit:ARTDefaultLimit callback:callback error:nil];
}

- (BOOL)subscriptionsClient:(NSString *)clientId limit:(NSUInteger)limit callback:(void(^)(ARTPaginatedResult<ARTPushChannelSubscription *> *result, ARTErrorInfo *error))callback error:(NSError **)errorPtr {
    if (limit > 1000) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorLimit
                                        userInfo:@{NSLocalizedDescriptionKey:@"Limit supports up to 1000 results only"}];
        }
        return NO;
    }

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"clientId" value:clientId],
        [NSURLQueryItem queryItemWithName:@"limit" value:[[NSNumber numberWithUnsignedInteger:limit] stringValue]],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        ARTErrorInfo *error;
        return [[_httpExecutor defaultEncoder] decodePushChannelSubscriptions:data error:&error];
    };

    [ARTPaginatedResult executePaginated:_httpExecutor withRequest:request andResponseProcessor:responseProcessor callback:callback];
    return YES;
}

@end
