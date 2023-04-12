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
    [_internal save:channelSubscription callback:callback];
}

- (void)listChannels:(ARTPaginatedTextCallback)callback {
    [_internal listChannels:callback];
}

- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedPushChannelCallback)callback {
    [_internal list:params callback:callback];
}

- (void)remove:(ARTPushChannelSubscription *)subscription callback:(ARTCallback)callback {
    [_internal remove:subscription callback:callback];
}

- (void)removeWhere:(NSStringDictionary *)params callback:(ARTCallback)callback {
    [_internal removeWhere:params callback:callback];
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

- (void)save:(ARTPushChannelSubscription *)channelSubscription callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
#if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;
#else
    ARTLocalDevice *local = nil;
#endif
    
    dispatch_async(_queue, ^{
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
        if (self->_rest.options.pushFullWait) {
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"fullWait" value:@"true"]];
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
        request.HTTPMethod = @"POST";
        request.HTTPBody = [[self->_rest defaultEncoder] encodePushChannelSubscription:channelSubscription error:nil];
        [request setValue:[[self->_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];
        [request setDeviceAuthentication:channelSubscription.deviceId localDevice:local];
        
        ARTLogDebug(self->_logger, @"save channel subscription with request %@", request);
        [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
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

- (void)listChannels:(ARTPaginatedTextCallback)callback {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult *, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }
    
    dispatch_async(_queue, ^{
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channels"] resolvingAgainstBaseURL:NO];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
        request.HTTPMethod = @"GET";
        
        ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
            return [self->_rest.encoders[response.MIMEType] decode:data error:error];
        };
        [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor logger:self->_logger callback:callback];
    });
}

- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedPushChannelCallback)callback {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult *, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }
    
    dispatch_async(_queue, ^{
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
        components.queryItems = [params art_asURLQueryItems];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
        request.HTTPMethod = @"GET";
        
        ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
            return [self->_rest.encoders[response.MIMEType] decodePushChannelSubscriptions:data error:error];
        };
        [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor logger:self->_logger callback:callback];
    });
}

- (void)remove:(ARTPushChannelSubscription *)subscription callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    dispatch_async(_queue, ^{
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
    });
}

- (void)removeWhere:(NSStringDictionary *)params callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    dispatch_async(_queue, ^{
        [self _removeWhere:params callback:callback];
    });
}

- (void)_removeWhere:(NSStringDictionary *)params callback:(ARTCallback)callback {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params art_asURLQueryItems];
    if (_rest.options.pushFullWait) {
        components.queryItems = [components.queryItems arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"fullWait" value:@"true"]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";
#if TARGET_OS_IOS
    [request setDeviceAuthentication:[params objectForKey:@"deviceId"] localDevice:_rest.device_nosync];
#endif
    
    ARTLogDebug(_logger, @"remove channel subscription with request %@", request);
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
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
