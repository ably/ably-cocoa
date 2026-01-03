#import "ARTPushChannel+Private.h"
#import "ARTHttp.h"
#import "ARTInternalLog.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTRest+Private.h"
#import "ARTClientOptions.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTPushChannelSubscription.h"
#import "ARTChannel+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTNSMutableRequest+ARTPush.h"
#import "ARTGCD.h"

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
    [_internal subscribeDeviceWithWrapperSDKAgents:nil];
}

- (void)subscribeDevice:(ARTCallback)callback {
    [_internal subscribeDeviceWithWrapperSDKAgents:nil completion:callback];
}

- (void)subscribeClient {
    [_internal subscribeClientWithWrapperSDKAgents:nil];
}

- (void)subscribeClient:(ARTCallback)callback {
    [_internal subscribeClientWithWrapperSDKAgents:nil completion:callback];
}

- (void)unsubscribeDevice {
    [_internal unsubscribeDeviceWithWrapperSDKAgents:nil];
}

- (void)unsubscribeDevice:(ARTCallback)callback {
    [_internal unsubscribeDeviceWithWrapperSDKAgents:nil completion:callback];
}

- (void)unsubscribeClient {
    [_internal unsubscribeClientWithWrapperSDKAgents:nil];
}

- (void)unsubscribeClient:(ARTCallback)callback {
    [_internal unsubscribeClientWithWrapperSDKAgents:nil completion:callback];
}

- (BOOL)listSubscriptions:(NSStringDictionary *)params
                 callback:(ARTPaginatedPushChannelCallback)callback
                    error:(NSError *_Nullable *_Nullable)errorPtr {
    return [_internal listSubscriptions:params wrapperSDKAgents:nil callback:callback error:errorPtr];
}

@end

const NSUInteger ARTDefaultLimit = 100;

@implementation ARTPushChannelInternal {
@private
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
@public
    __weak ARTRestInternal *_rest; // weak because rest may own self and always outlives it
    ARTInternalLog *_logger;
    __weak ARTChannel *_channel; // weak because channel owns self
}

- (instancetype)init:(ARTRestInternal *)rest withChannel:(ARTChannel *)channel logger:(ARTInternalLog *)logger {
    if (self == [super self]) {
        _rest = rest;
        _queue = rest.queue;
        _userQueue = rest.userQueue;
        _logger = logger;
        _channel = channel;
    }
    return self;
}

- (void)subscribeDeviceWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents {
    [self subscribeDeviceWithWrapperSDKAgents:wrapperSDKAgents completion:nil];
}

- (void)unsubscribeDeviceWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents {
    [self unsubscribeDeviceWithWrapperSDKAgents:wrapperSDKAgents completion:nil];
}

- (void)subscribeClientWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents {
    [self subscribeClientWithWrapperSDKAgents:wrapperSDKAgents completion:nil];
}

- (void)unsubscribeClientWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents {
    [self unsubscribeClientWithWrapperSDKAgents:wrapperSDKAgents completion:nil];
}

- (void)subscribeDeviceWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents completion:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

art_dispatch_async(_queue, ^{
    ARTLocalDevice *device = [self getDevice:callback];
    if (![device isRegistered]) {
        return;
    }
    NSString *deviceId = device.id;

    NSDictionary *bodyDict = @{
        @"deviceId": deviceId,
        @"channel": self->_channel.name,
    };
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self->_rest buildRequest:@"POST"
                                                        path:@"/push/channelSubscriptions"
                                                     baseUrl:self->_rest.baseUrl
                                                      params:nil
                                                        body:bodyDict
                                                     headers:nil
                                                       error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
    
    [request setDeviceAuthentication:deviceId localDevice:device];

    ARTLogDebug(self->_logger, @"subscribe notifications for device %@ in channel %@", deviceId, self->_channel.name);
    [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:wrapperSDKAgents completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            ARTLogError(self->_logger, @"%@: subscribe notifications for device %@ in channel %@ failed (%@)", NSStringFromClass(self.class), deviceId, self->_channel.name, error.localizedDescription);
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
});
}

- (void)subscribeClientWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents completion:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

art_dispatch_async(_queue, ^{
    NSString *clientId = [self getClientId:callback];
    if (!clientId) {
        return;
    }

    NSDictionary *bodyDict = @{
        @"clientId": clientId,
        @"channel": self->_channel.name,
    };
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self->_rest buildRequest:@"POST"
                                                        path:@"/push/channelSubscriptions"
                                                     baseUrl:self->_rest.baseUrl
                                                      params:nil
                                                        body:bodyDict
                                                     headers:nil
                                                       error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }

    ARTLogDebug(self->_logger, @"subscribe notifications for clientId %@ in channel %@", clientId, self->_channel.name);
    [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:wrapperSDKAgents completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            ARTLogError(self->_logger, @"%@: subscribe notifications for clientId %@ in channel %@ failed (%@)", NSStringFromClass(self.class), clientId, self->_channel.name, error.localizedDescription);
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
});
}

- (void)unsubscribeDeviceWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents completion:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

art_dispatch_async(_queue, ^{
    ARTLocalDevice *device = [self getDevice:callback];
    if (![device isRegistered]) {
        return;
    }
    NSString *deviceId = device.id;

    NSMutableDictionary<NSString *, NSString *> *params = @{
        @"deviceId": deviceId,
        @"channel": self->_channel.name,
    }.mutableCopy;
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self->_rest buildRequest:@"DELETE"
                                                        path:@"/push/channelSubscriptions"
                                                     baseUrl:self->_rest.baseUrl
                                                      params:params
                                                        body:nil
                                                     headers:nil
                                                       error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }

    [request setDeviceAuthentication:deviceId localDevice:device];

    ARTLogDebug(self->_logger, @"unsubscribe notifications for device %@ in channel %@", deviceId, self->_channel.name);
    [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:wrapperSDKAgents completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            ARTLogError(self->_logger, @"%@: unsubscribe notifications for device %@ in channel %@ failed (%@)", NSStringFromClass(self.class), deviceId, self->_channel.name, error.localizedDescription);
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
});
}

- (void)unsubscribeClientWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents completion:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

art_dispatch_async(_queue, ^{
    NSString *clientId = [self getClientId:callback];
    if (!clientId) {
        return;
    }

    NSMutableDictionary<NSString *, NSString *> *params = @{
        @"clientId": clientId,
        @"channel": self->_channel.name,
    }.mutableCopy;
    
    NSError *error = nil;
    NSMutableURLRequest *request = [self->_rest buildRequest:@"DELETE"
                                                        path:@"/push/channelSubscriptions"
                                                     baseUrl:self->_rest.baseUrl
                                                      params:params
                                                        body:nil
                                                     headers:nil
                                                       error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }

    ARTLogDebug(self->_logger, @"unsubscribe notifications for clientId %@ in channel %@", clientId, self->_channel.name);
    [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:wrapperSDKAgents completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            ARTLogError(self->_logger, @"%@: unsubscribe notifications for clientId %@ in channel %@ failed (%@)", NSStringFromClass(self.class), clientId, self->_channel.name, error.localizedDescription);
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
});
}

- (BOOL)listSubscriptions:(NSStringDictionary *)params
         wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                 callback:(ARTPaginatedPushChannelCallback)callback
                    error:(NSError * __autoreleasing *)errorPtr {
    if (callback) {
        ARTPaginatedPushChannelCallback userCallback = callback;
        callback = ^(ARTPaginatedResult<ARTPushChannelSubscription *> *result, ARTErrorInfo *error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    __block BOOL ret;
art_dispatch_sync(_queue, ^{
    NSMutableDictionary<NSString *, NSString *> *mutableParams = params.mutableCopy ?: [NSMutableDictionary dictionary];

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

    NSError *error = nil;
    NSMutableURLRequest *request = [self->_rest buildRequest:@"GET"
                                                        path:@"/push/channelSubscriptions"
                                                     baseUrl:nil
                                                      params:mutableParams
                                                        body:nil
                                                     headers:nil
                                                       error:&error];
    if (error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        ret = NO;
        return;
    }

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
        return [self->_rest.encoders[response.MIMEType] decodePushChannelSubscriptions:data error:error];
    };

    [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor wrapperSDKAgents:wrapperSDKAgents logger:self->_logger callback:callback];
    ret = YES;
});
    return ret;
}

- (ARTLocalDevice *)getDevice:(ARTCallback)callback {
    #if TARGET_OS_IOS
    ARTLocalDevice *device = [_rest device_nosync];
    #else
    ARTLocalDevice *device = nil;
    #endif
    if (![device isRegistered]) {
        if (callback) callback([ARTErrorInfo createWithCode:0 message:@"cannot use device before device activation has finished"]);
    }
    return device;
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
