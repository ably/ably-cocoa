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

@implementation ARTPushChannel {
    id<ARTHTTPAuthenticatedExecutor> _httpExecutor;
    __weak ARTLog *_logger;
    __weak ARTChannel *_channel;
    id<ARTEncoder> _jsonEncoder;
}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor withChannel:(ARTChannel *)channel {
    if (self == [super self]) {
        _httpExecutor = httpExecutor;
        _logger = [httpExecutor logger];
        _channel = channel;
        _jsonEncoder = [[ARTJsonLikeEncoder alloc] init];
    }
    return self;
}

- (void)subscribeForDevice:(ARTDeviceId *)deviceId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [_jsonEncoder encode:@{
        @"deviceId": deviceId,
        @"channel": _channel.name,
    }];
    [request setValue:[_jsonEncoder mimeType] forHTTPHeaderField:@"Content-Type"];

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

- (void)subscribeForClientId:(NSString *)clientId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [_jsonEncoder encode:@{
        @"clientId": clientId,
        @"channel": _channel.name,
    }];
    [request setValue:[_jsonEncoder mimeType] forHTTPHeaderField:@"Content-Type"];

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

- (void)unsubscribeForDevice:(NSString *)deviceId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"DELETE";
    request.HTTPBody = [_jsonEncoder encode:@{
        @"deviceId": deviceId,
        @"channel": _channel.name,
    }];
    [request setValue:[_jsonEncoder mimeType] forHTTPHeaderField:@"Content-Type"];

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

- (void)unsubscribeForClientId:(NSString *)clientId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"DELETE";
    request.HTTPBody = [_jsonEncoder encode:@{
        @"clientId": clientId,
        @"channel": _channel.name,
    }];
    [request setValue:[_jsonEncoder mimeType] forHTTPHeaderField:@"Content-Type"];

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

@end
