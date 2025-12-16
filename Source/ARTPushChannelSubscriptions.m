#import "ARTPushChannelSubscriptions+Private.h"
#import "ARTHttp.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTPushChannelSubscription.h"
#import "ARTClientOptions.h"
#import "ARTEncoder.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTRest+Private.h"
#import "ARTTypes.h"
#import "ARTNSMutableRequest+ARTPush.h"
#import "ARTInternalLog.h"
#import "ARTGCD.h"

@implementation ARTPushChannelSubscriptions {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTPushChannelSubscriptionsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (void)save:(ARTPushChannelSubscription *)channelSubscription callback:(ARTCallback)callback {
    [_internal save:channelSubscription wrapperSDKAgents:nil callback:callback];
}

- (void)listChannels:(ARTPaginatedTextCallback)callback {
    [_internal listChannelsWithWrapperSDKAgents:nil completion:callback];
}

- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedPushChannelCallback)callback {
    [_internal list:params wrapperSDKAgents:nil callback:callback];
}

- (void)remove:(ARTPushChannelSubscription *)subscription callback:(ARTCallback)callback {
    [_internal remove:subscription wrapperSDKAgents:nil callback:callback];
}

- (void)removeWhere:(NSStringDictionary *)params callback:(ARTCallback)callback {
    [_internal removeWhere:params wrapperSDKAgents:nil callback:callback];
}

@end

@implementation ARTPushChannelSubscriptionsInternal {
    __weak ARTRestInternal *_rest; // weak because rest owns self
    ARTInternalLog *_logger;
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
}

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _rest = rest;
        _logger = logger;
        _queue = rest.queue;
        _userQueue = rest.userQueue;
    }
    return self;
}

- (void)save:(ARTPushChannelSubscription *)channelSubscription wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
#if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;
#else
    ARTLocalDevice *local = nil;
#endif
    
    art_dispatch_async(_queue, ^{
        NSMutableDictionary<NSString *, NSString *> *params = nil;
        if (self->_rest.options.pushFullWait) {
            params = @{
                @"fullWait": @"true"
            }.mutableCopy;
        }
        NSData *bodyData = [[self->_rest defaultEncoder] encodePushChannelSubscription:channelSubscription error:nil];
        NSError *error = nil;
        NSMutableURLRequest *request = [self->_rest buildRequest:@"POST"
                                                            path:@"/push/channelSubscriptions"
                                                         baseUrl:self->_rest.baseUrl
                                                          params:params
                                                            body:bodyData
                                                         headers:nil
                                                           error:&error];
        if (error) {
            if (callback) callback([ARTErrorInfo createFromNSError:error]);
            return;
        }
        
        [request setDeviceAuthentication:channelSubscription.deviceId localDevice:local];
        
        ARTLogDebug(self->_logger, @"save channel subscription with request %@", request);
        [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:wrapperSDKAgents completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            if (response.statusCode == 200 /*Ok*/ || response.statusCode == 201 /*Created*/) {
                ARTLogDebug(self->_logger, @"channel subscription saved successfully");
                callback(nil);
            }
            else if (error) {
                ARTLogError(self->_logger, @"%@: save channel subscription failed (%@)", NSStringFromClass(self.class), error.localizedDescription);
                callback([ARTErrorInfo createFromNSError:error]);
            }
            else {
                ARTLogError(self->_logger, @"%@: save channel subscription failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode);
                NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                callback([ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain art_shortString]]);
            }
        }];
    });
}

- (void)listChannelsWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                              completion:(ARTPaginatedTextCallback)callback {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult *, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }
    
    art_dispatch_async(_queue, ^{
        NSError *error = nil;
        NSMutableURLRequest *request = [self->_rest buildRequest:@"GET"
                                                            path:@"/push/channels"
                                                         baseUrl:nil
                                                          params:nil
                                                            body:nil
                                                         headers:nil
                                                           error:&error];
        if (error) {
            if (callback) callback(nil, [ARTErrorInfo createFromNSError:error]);
            return;
        }
        
        ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
            return [self->_rest.encoders[response.MIMEType] decode:data error:error];
        };
        [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor wrapperSDKAgents:wrapperSDKAgents logger:self->_logger callback:callback];
    });
}

- (void)list:(NSStringDictionary *)params wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTPaginatedPushChannelCallback)callback {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult *, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }
    
    art_dispatch_async(_queue, ^{
        NSError *error = nil;
        NSMutableURLRequest *request = [self->_rest buildRequest:@"GET"
                                                            path:@"/push/channelSubscriptions"
                                                         baseUrl:nil
                                                          params:params
                                                            body:nil
                                                         headers:nil
                                                           error:&error];
        if (error) {
            if (callback) callback(nil, [ARTErrorInfo createFromNSError:error]);
            return;
        }
    
        ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
            return [self->_rest.encoders[response.MIMEType] decodePushChannelSubscriptions:data error:error];
        };
        [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor wrapperSDKAgents:wrapperSDKAgents logger:self->_logger callback:callback];
    });
}

- (void)remove:(ARTPushChannelSubscription *)subscription wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    art_dispatch_async(_queue, ^{
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
        [self _removeWhere:where wrapperSDKAgents:wrapperSDKAgents callback:callback];
    });
}

- (void)removeWhere:(NSStringDictionary *)params wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    art_dispatch_async(_queue, ^{
        [self _removeWhere:params wrapperSDKAgents:wrapperSDKAgents callback:callback];
    });
}

- (void)_removeWhere:(NSStringDictionary *)params wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTCallback)callback {
    NSMutableDictionary<NSString *, NSString *> *queryParams = [params mutableCopy];
    if (_rest.options.pushFullWait) {
        queryParams[@"fullWait"] = @"true";
    }
    NSError *error = nil;
    NSMutableURLRequest *request = [_rest buildRequest:@"DELETE"
                                                  path:@"/push/channelSubscriptions"
                                               baseUrl:_rest.baseUrl
                                                params:queryParams
                                                  body:nil
                                               headers:nil
                                                 error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
#if TARGET_OS_IOS
    [request setDeviceAuthentication:[params objectForKey:@"deviceId"] localDevice:_rest.device_nosync];
#endif
    
    ARTLogDebug(_logger, @"remove channel subscription with request %@", request);
    [_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:wrapperSDKAgents completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*Ok*/ || response.statusCode == 204 /*not returning any content*/) {
            ARTLogDebug(self->_logger, @"%@: channel subscription removed successfully", NSStringFromClass(self.class));
            callback(nil);
        }
        else if (error) {
            ARTLogError(self->_logger, @"%@: remove channel subscription failed (%@)", NSStringFromClass(self.class), error.localizedDescription);
            callback([ARTErrorInfo createFromNSError:error]);
        }
        else {
            ARTLogError(self->_logger, @"%@: remove channel subscription failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode);
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback([ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain art_shortString]]);
        }
    }];
}

@end
