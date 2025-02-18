#import "ARTRestChannel+Private.h"

#import "ARTRest+Private.h"
#import "ARTRestPresence+Private.h"
#import "ARTChannel+Private.h"
#import "ARTChannel+Subclass.h"
#import "ARTChannelOptions.h"
#import "ARTMessage.h"
#import "ARTBaseMessage+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTAuth+Private.h"
#import "ARTTokenDetails.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTPushChannel+Private.h"
#import "ARTCrypto+Private.h"
#import "ARTClientOptions.h"
#import "ARTNSError+ARTUtils.h"
#import "ARTInternalLog.h"

@implementation ARTRestChannel {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTRestChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (ARTRestPresence*) presence {
    return [[ARTRestPresence alloc] initWithInternal:_internal.presence queuedDealloc:_dealloc];
}

- (ARTPushChannel *)push {
    return [[ARTPushChannel alloc] initWithInternal:_internal.push queuedDealloc:_dealloc];
}

- (NSString *)name {
    return _internal.name;
}

- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedMessagesCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr {
    return [_internal history:query wrapperSDKAgents:nil callback:callback error:errorPtr];
}

- (void)status:(ARTChannelDetailsCallback)callback {
    [_internal status:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data {
    [_internal publish:name data:data];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data callback:(nullable ARTCallback)callback {
    [_internal publish:name data:data callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId {
    [_internal publish:name data:data clientId:clientId];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId callback:(nullable ARTCallback)callback {
    [_internal publish:name data:data clientId:clientId callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras {
    [_internal publish:name data:data extras:extras];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable ARTCallback)callback {
    [_internal publish:name data:data extras:extras callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras {
    [_internal publish:name data:data clientId:clientId extras:extras];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable ARTCallback)callback {
    [_internal publish:name data:data clientId:clientId extras:extras callback:callback];
}

- (void)publish:(NSArray<ARTMessage *> *)messages {
    [_internal publish:messages];
}

- (void)publish:(NSArray<ARTMessage *> *)messages callback:(nullable ARTCallback)callback {
    [_internal publish:messages callback:callback];
}

- (void)history:(ARTPaginatedMessagesCallback)callback {
    [_internal historyWithWrapperSDKAgents:nil completion:callback];
}

- (ARTChannelOptions *)options {
    return [_internal options];
}

- (void)setOptions:(ARTChannelOptions *_Nullable)options {
    [_internal setOptions:options];
}

@end

static const NSUInteger kIdempotentLibraryGeneratedIdLength = 9; //bytes

@implementation ARTRestChannelInternal {
@private
    dispatch_queue_t _userQueue;
    ARTRestPresenceInternal *_presence;
    ARTPushChannelInternal *_pushChannel;
@public
    NSString *_basePath;
}

@dynamic options;

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger {
    if (self = [super initWithName:name andOptions:options rest:rest logger:logger]) {
        _rest = rest;
        _queue = rest.queue;
        _userQueue = rest.userQueue;
        _basePath = [NSString stringWithFormat:@"/channels/%@", [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]]; // Using URLHostAllowedCharacterSet, because it doesn't include '/', which can be used in channel names across other platforms.
        ARTLogDebug(self.logger, @"RS:%p instantiating under '%@'", self, name);
    }
    return self;
}

- (NSString *)getBasePath {
    return _basePath;
}

- (ARTRestPresenceInternal *)presence {
    if (!_presence) {
        _presence = [[ARTRestPresenceInternal alloc] initWithChannel:self logger:self.logger];
    }
    return _presence;
}

- (ARTPushChannelInternal *)push {
    if (!_pushChannel) {
        _pushChannel = [[ARTPushChannelInternal alloc] init:self.rest withChannel:self logger:self.logger];
    }
    return _pushChannel;
}

- (void)historyWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents completion:(ARTPaginatedMessagesCallback)callback {
    [self history:[[ARTDataQuery alloc] init] wrapperSDKAgents:wrapperSDKAgents callback:callback error:nil];
}

- (BOOL)history:(ARTDataQuery *)query wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTPaginatedMessagesCallback)callback error:(NSError * __autoreleasing *)errorPtr {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult<ARTMessage *> *result, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult<ARTMessage *> *result, ARTErrorInfo *error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    __block BOOL ret;
dispatch_sync(_queue, ^{
    if (query.limit > 1000) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorLimit
                                        userInfo:@{NSLocalizedDescriptionKey:@"Limit supports up to 1000 results only"}];
        }
        ret = NO;
        return;
    }
    if ([query.start compare:query.end] == NSOrderedDescending) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorTimestampRange
                                        userInfo:@{NSLocalizedDescriptionKey:@"Start must be equal to or less than end"}];
        }
        ret = NO;
        return;
    }

    NSURLComponents *componentsUrl = [NSURLComponents componentsWithString:[self->_basePath stringByAppendingPathComponent:@"messages"]];
    NSError *error = nil;
    componentsUrl.queryItems = [query asQueryItems:&error];
    if (error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        ret = NO;
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:componentsUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^NSArray<ARTMessage *> *(NSHTTPURLResponse *response, NSData *data, NSError **errorPtr) {
        id<ARTEncoder> encoder = [self->_rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodeMessages:data error:errorPtr] artMap:^(ARTMessage *message) {
            NSError *decodeError = nil;
            message = [message decodeWithEncoder:self.dataEncoder error:&decodeError];
            if (decodeError != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason] prepend:@"Failed to decode data: "];
                ARTLogError(self.logger, @"RS:%p C:%p (%@) %@", self->_rest, self, self.name, errorInfo.message);
            }
            return message;
        }];
    };

    ARTLogDebug(self.logger, @"RS:%p C:%p (%@) stats request %@", self->_rest, self, self.name, request);
    [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor wrapperSDKAgents:wrapperSDKAgents logger:self.logger callback:callback];
    ret = YES;
});
    return ret;
}

- (void)status:(ARTChannelDetailsCallback)callback {
    if (callback) {
        ARTChannelDetailsCallback userCallback = callback;
        callback = ^(ARTChannelDetails *details, ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(details, error);
            });
        };
    }
    dispatch_async(_queue, ^{
        NSURL *url = [NSURL URLWithString:self->_basePath];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        ARTLogDebug(self.logger, @"RS:%p C:%p (%@) channel details request %@", self->_rest, self, self.name, request);
        
        [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:nil completion:^(NSHTTPURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable error) {
            
            if (response.statusCode == 200 /*OK*/) {
                NSError *decodeError = nil;
                id<ARTEncoder> decoder = self->_rest.encoders[response.MIMEType];
                if (decoder == nil) {
                    NSString* errorMessage = [NSString stringWithFormat:@"Decoder for MIMEType '%@' wasn't found.", response.MIMEType];
                    ARTLogDebug(self.logger, @"%@: %@", NSStringFromClass(self.class), errorMessage);
                    if (callback) {
                        callback(nil, [ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:errorMessage]);
                    }
                }
                else {
                    ARTChannelDetails *channelDetails = [decoder decodeChannelDetails:data error:&decodeError];
                    if (decodeError) {
                        ARTLogDebug(self.logger, @"%@: decode channel details failed (%@)", NSStringFromClass(self.class), error.localizedDescription);
                        if (callback) {
                            callback(nil, [ARTErrorInfo createFromNSError:decodeError]);
                        }
                    }
                    else {
                        ARTLogDebug(self.logger, @"%@: successfully got channel details %@", NSStringFromClass(self.class), channelDetails.channelId);
                        if (callback) {
                            callback(channelDetails, nil);
                        }
                    }
                }
            }
            else {
                ARTLogDebug(self.logger, @"%@: get channel details failed (%@)", NSStringFromClass(self.class), error.localizedDescription);
                ARTErrorInfo *errorInfo = nil;
                if (error) {
                    if (self->_rest.options.addRequestIds) {
                        errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error] prepend:[NSString stringWithFormat:@"Request '%@' failed with ", request.URL]];
                    } else {
                        errorInfo = [ARTErrorInfo createFromNSError:error];
                    }
                }
                if (callback) {
                    callback(nil, errorInfo);
                }
            }
        }];
    });
}

- (void)internalPostMessages:(id)data callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *__nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    dispatch_async(_queue, ^{
        NSData *encodedMessage = nil;
        
        if ([data isKindOfClass:[ARTMessage class]]) {
            ARTMessage *message = (ARTMessage *)data;
            
            NSString *baseId = nil;
            if (self.rest.options.idempotentRestPublishing && message.isIdEmpty) {
                NSData *baseIdData = [ARTCrypto generateSecureRandomData:kIdempotentLibraryGeneratedIdLength];
                baseId = [baseIdData base64EncodedStringWithOptions:0];
                message.id = [NSString stringWithFormat:@"%@:0", baseId];
            }
            
            if (message.clientId && self.rest.auth.clientId_nosync && ![message.clientId isEqualToString:self.rest.auth.clientId_nosync]) {
                callback([ARTErrorInfo createWithCode:ARTStateMismatchedClientId message:@"attempted to publish message with an invalid clientId"]);
                return;
            }
            
            NSError *encodeError = nil;
            encodedMessage = [self.rest.defaultEncoder encodeMessage:message error:&encodeError];
            if (encodeError) {
                callback([ARTErrorInfo createFromNSError:encodeError]);
                return;
            }
        }
        else if ([data isKindOfClass:[NSArray class]]) {
            NSArray<ARTMessage *> *messages = (NSArray *)data;
            
            NSString *baseId = nil;
            if (self.rest.options.idempotentRestPublishing) {
                BOOL messagesHaveEmptyId = [messages artFilter:^BOOL(ARTMessage *m) { return !m.isIdEmpty; }].count <= 0;
                if (messagesHaveEmptyId) {
                    NSData *baseIdData = [ARTCrypto generateSecureRandomData:kIdempotentLibraryGeneratedIdLength];
                    baseId = [baseIdData base64EncodedStringWithOptions:0];
                }
            }
            
            NSInteger serial = 0;
            for (ARTMessage *message in messages) {
                if (message.clientId && self.rest.auth.clientId_nosync && ![message.clientId isEqualToString:self.rest.auth.clientId_nosync]) {
                    callback([ARTErrorInfo createWithCode:ARTStateMismatchedClientId message:@"attempted to publish message with an invalid clientId"]);
                    return;
                }
                if (baseId) {
                    message.id = [NSString stringWithFormat:@"%@:%ld", baseId, (long)serial];
                }
                serial += 1;
            }
            
            NSError *encodeError = nil;
            encodedMessage = [self.rest.defaultEncoder encodeMessages:data error:&encodeError];
            if (encodeError) {
                callback([ARTErrorInfo createFromNSError:encodeError]);
                return;
            }
        }
        
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:[self->_basePath stringByAppendingPathComponent:@"messages"]] resolvingAgainstBaseURL:YES];
        NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray new];
        
        if (queryItems.count > 0) {
            components.queryItems = queryItems;
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
        request.HTTPMethod = @"POST";
        request.HTTPBody = encodedMessage;
        
        if (self.rest.defaultEncoding) {
            [request setValue:self.rest.defaultEncoding forHTTPHeaderField:@"Content-Type"];
        }
        
        ARTLogDebug(self.logger, @"RS:%p C:%p (%@) post message %@", self->_rest, self, self.name, [[NSString alloc] initWithData:encodedMessage ?: [NSData data] encoding:NSUTF8StringEncoding]);
        
        [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:nil completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            if (callback) {
                ARTErrorInfo *errorInfo;
                if (self->_rest.options.addRequestIds) {
                    errorInfo = error ? [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error] prepend:[NSString stringWithFormat:@"Request '%@' failed with ", request.URL]] : nil;
                } else {
                    errorInfo = error ? [ARTErrorInfo createFromNSError:error] : nil;
                }
                
                callback(errorInfo);
            }
        }];
    });
}

@end
