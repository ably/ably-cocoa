#import "ARTPushChannel+Private.h"
#import "ARTHttp.h"
#import "ARTLog.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTRest+Private.h"
#import "ARTClientOptions.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTPushChannelSubscription.h"
#import "ARTChannel+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTNSMutableRequest+ARTPush.h"
#import "ARTPushActivationState.h"

@implementation ARTPushChannel {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTPushChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (void)subscribeDevice {
    [_internal subscribeDevice];
}

- (void)subscribeDevice:(ARTCallback)callback {
    [_internal subscribeDevice:callback];
}

- (void)subscribeClient {
    [_internal subscribeClient];
}

- (void)subscribeClient:(ARTCallback)callback {
    [_internal subscribeClient:callback];
}

- (void)unsubscribeDevice {
    [_internal unsubscribeDevice];
}

- (void)unsubscribeDevice:(ARTCallback)callback {
    [_internal unsubscribeDevice:callback];
}

- (void)unsubscribeClient {
    [_internal unsubscribeClient];
}

- (void)unsubscribeClient:(ARTCallback)callback {
    [_internal unsubscribeClient:callback];
}

- (BOOL)listSubscriptions:(NSStringDictionary *)params
                 callback:(ARTPaginatedPushChannelCallback)callback
                    error:(NSError *_Nullable *_Nullable)errorPtr {
    return [_internal listSubscriptions:params callback:callback error:errorPtr];
}

@end

const NSUInteger ARTDefaultLimit = 100;

@implementation ARTPushChannelInternal {
@private
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
@public
    __weak ARTRestInternal *_rest; // weak because rest may own self and always outlives it
    ARTLog *_logger;
    __weak ARTChannel *_channel; // weak because channel owns self
}

- (instancetype)init:(ARTRestInternal *)rest withChannel:(ARTChannel *)channel {
    if (self == [super self]) {
        _rest = rest;
        _queue = rest.queue;
        _userQueue = rest.userQueue;
        _logger = [rest logger];
        _channel = channel;
        _logger = channel.logger;
    }
    return self;
}

- (void)subscribeDevice {
    [self subscribeDevice:nil];
}

- (void)unsubscribeDevice {
    [self unsubscribeDevice:nil];
}

- (void)subscribeClient {
    [self subscribeClient:nil];
}

- (void)unsubscribeClient {
    [self unsubscribeClient:nil];
}

- (void)subscribeDevice:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
    ARTLocalDevice *device = [self getDevice:callback];
    if (![device isRegistered]) {
        return;
    }
    NSString *deviceId = device.id;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self->_rest defaultEncoder] encode:@{
        @"deviceId": deviceId,
        @"channel": self->_channel.name,
    } error:nil];
    [request setValue:[[self->_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];
    [request setDeviceAuthentication:deviceId localDevice:device];

    [self->_logger debug:__FILE__ line:__LINE__ message:@"subscribe notifications for device %@ in channel %@", deviceId, self->_channel.name];
    [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self->_logger error:@"%@: subscribe notifications for device %@ in channel %@ failed (%@)", NSStringFromClass(self.class), deviceId, self->_channel.name, error.localizedDescription];
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
});
}

- (void)subscribeClient:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
    NSString *clientId = [self getClientId:callback];
    if (!clientId) {
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[self->_rest defaultEncoder] encode:@{
        @"clientId": clientId,
        @"channel": self->_channel.name,
    } error:nil];
    [request setValue:[[self->_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [self->_logger debug:__FILE__ line:__LINE__ message:@"subscribe notifications for clientId %@ in channel %@", clientId, self->_channel.name];
    [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self->_logger error:@"%@: subscribe notifications for clientId %@ in channel %@ failed (%@)", NSStringFromClass(self.class), clientId, self->_channel.name, error.localizedDescription];
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
});
}

- (void)unsubscribeDevice:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
    ARTLocalDevice *device = [self getDevice:callback];
    if (![device isRegistered]) {
        return;
    }
    NSString *deviceId = device.id;

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"deviceId" value:deviceId],
        [NSURLQueryItem queryItemWithName:@"channel" value:self->_channel.name],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";
    [request setDeviceAuthentication:deviceId localDevice:device];

    [self->_logger debug:__FILE__ line:__LINE__ message:@"unsubscribe notifications for device %@ in channel %@", deviceId, self->_channel.name];
    [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self->_logger error:@"%@: unsubscribe notifications for device %@ in channel %@ failed (%@)", NSStringFromClass(self.class), deviceId, self->_channel.name, error.localizedDescription];
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
});
}

- (void)unsubscribeClient:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
    NSString *clientId = [self getClientId:callback];
    if (!clientId) {
        return;
    }

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"clientId" value:clientId],
        [NSURLQueryItem queryItemWithName:@"channel" value:self->_channel.name],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [self->_logger debug:__FILE__ line:__LINE__ message:@"unsubscribe notifications for clientId %@ in channel %@", clientId, self->_channel.name];
    [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self->_logger error:@"%@: unsubscribe notifications for clientId %@ in channel %@ failed (%@)", NSStringFromClass(self.class), clientId, self->_channel.name, error.localizedDescription];
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
});
}

- (BOOL)listSubscriptions:(NSStringDictionary *)params
                 callback:(ARTPaginatedPushChannelCallback)callback
                    error:(NSError * __autoreleasing *)errorPtr {
    if (callback) {
        ARTPaginatedPushChannelCallback userCallback = callback;
        callback = ^(ARTPaginatedResult<ARTPushChannelSubscription *> *result, ARTErrorInfo *error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    __block BOOL ret;
dispatch_sync(_queue, ^{
    NSMutableDictionary<NSString *, NSString *> *mutableParams = params ? [NSMutableDictionary dictionaryWithDictionary:params] : [[NSMutableDictionary alloc] init];

    if (!mutableParams[@"deviceId"] && !mutableParams[@"clientId"]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorMissingRequiredFields
                                        userInfo:@{NSLocalizedDescriptionKey:@"cannot list subscriptions with null device ID or null client ID"}];
        }
        ret = NO;
        return;
    }
    if (mutableParams[@"deviceId"] && mutableParams[@"clientId"]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorInvalidParameters
                                        userInfo:@{NSLocalizedDescriptionKey:@"cannot list subscriptions with device ID and client ID"}];
        }
        ret = NO;
        return;
    }

    mutableParams[@"concatFilters"] = @"true";

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = [mutableParams art_asURLQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
        return [self->_rest.encoders[response.MIMEType] decodePushChannelSubscriptions:data error:error];
    };

    [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
    ret = YES;
});
    return ret;
}

- (ARTLocalDevice *)getDevice:(ARTCallback)callback {
#if TARGET_OS_IOS
    ARTLocalDevice *device = [_rest device_nosync];
    if (![device isRegistered]) {
        if (callback) {
            ARTErrorInfo* errorInfo = device.activationState.isFailed ? device.activationError : [ARTErrorInfo createWithCode:0 message:@"cannot use device before device activation has finished"];
            callback(errorInfo);
        }
    }
    return device;
#else
    return nil;
#endif
}

- (NSString *)getClientId:(ARTCallback)callback {
    ARTLocalDevice *device = [self getDevice:callback];
    if (![device isRegistered]) {
        return nil;
    }
    if (!device.clientId) {
        if (callback) callback([ARTErrorInfo createWithCode:0 message:@"cannot subscribe/unsubscribe with null client ID"]);
        return nil;
    }
    return device.clientId;
}

@end
