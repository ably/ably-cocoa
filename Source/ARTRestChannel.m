#import "ARTRestChannel+Private.h"

#import "ARTRest+Private.h"
#import "ARTRestPresence+Private.h"
#import "ARTChannel+Private.h"
#import "ARTChannelOptions.h"
#import "ARTMessage.h"
#import "ARTMessageOperation.h"
#import "ARTMessageOperation+Private.h"
#import "ARTBaseMessage+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTAuth+Private.h"
#import "ARTTokenDetails.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSString+ARTUtil.h"
#import "ARTPushChannel+Private.h"
#import "ARTCrypto+Private.h"
#import "ARTClientOptions.h"
#import "ARTNSError+ARTUtils.h"
#import "ARTInternalLog.h"
#import "ARTRestAnnotations.h"
#import "ARTRestAnnotations+Private.h"
#import "ARTConstants.h"
#import "ARTGCD.h"

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

- (ARTRestAnnotations *)annotations {
    return [[ARTRestAnnotations alloc] initWithInternal:_internal.annotations queuedDealloc:_dealloc];
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

- (void)updateMessage:(ARTMessage *)message operation:(nullable ARTMessageOperation *)operation params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params callback:(nullable ARTCallback)callback {
    [_internal updateMessage:message operation:operation params:params wrapperSDKAgents:nil callback:callback];
}

- (void)deleteMessage:(ARTMessage *)message operation:(nullable ARTMessageOperation *)operation params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params callback:(nullable ARTCallback)callback {
    [_internal deleteMessage:message operation:operation params:params wrapperSDKAgents:nil callback:callback];
}

- (void)getMessageWithSerial:(NSString *)serial callback:(ARTMessageErrorCallback)callback {
    [_internal getMessageWithSerial:serial wrapperSDKAgents:nil callback:callback];
}

- (void)getMessageVersionsWithSerial:(NSString *)serial callback:(ARTPaginatedMessagesCallback)callback {
    [_internal getMessageVersionsWithSerial:serial wrapperSDKAgents:nil callback:callback];
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

@implementation ARTRestChannelInternal {
@private
    dispatch_queue_t _userQueue;
    ARTRestPresenceInternal *_presence;
    ARTRestAnnotationsInternal *_annotations;
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
        _annotations = [[ARTRestAnnotationsInternal alloc] initWithChannel:self logger:self.logger];
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

- (ARTRestAnnotationsInternal *)annotations {
    return _annotations;
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
            art_dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    if (query.limit > 1000) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorLimit
                                        userInfo:@{NSLocalizedDescriptionKey:@"Limit supports up to 1000 results only"}];
        }
        return NO;
    }
    if ([query.start compare:query.end] == NSOrderedDescending) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorTimestampRange
                                        userInfo:@{NSLocalizedDescriptionKey:@"Start must be equal to or less than end"}];
        }
        return NO;
    }

    NSError *error = nil;
    NSMutableURLRequest *request = [self->_rest buildRequest:@"GET"
                                                        path:[self->_basePath stringByAppendingPathComponent:@"messages"]
                                                     baseUrl:nil
                                                      params:query.asQueryParams
                                                        body:nil
                                                     headers:nil
                                                       error:&error];
    if (error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        return NO;
    }

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
    
art_dispatch_sync(_queue, ^{
    [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor wrapperSDKAgents:wrapperSDKAgents logger:self.logger callback:callback];
});
    return YES;
}

- (void)status:(ARTChannelDetailsCallback)callback {
    if (callback) {
        ARTChannelDetailsCallback userCallback = callback;
        callback = ^(ARTChannelDetails *details, ARTErrorInfo *_Nullable error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(details, error);
            });
        };
    }
    art_dispatch_async(_queue, ^{
        NSError *error = nil;
        NSMutableURLRequest *request = [self->_rest buildRequest:@"GET"
                                                            path:self->_basePath
                                                         baseUrl:nil
                                                          params:nil
                                                            body:nil
                                                         headers:nil
                                                           error:&error];
        if (error) {
            if (callback) callback(nil, [ARTErrorInfo createFromNSError:error]);
            return;
        }
        
        ARTLogDebug(self.logger, @"RS:%p C:%p (%@) channel details request %@", self->_rest, self, self.name, request);
        
        [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:nil completion:^(NSHTTPURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable error) {
            
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
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    art_dispatch_async(_queue, ^{
        NSArray<ARTMessage *> *messages = nil;
        BOOL dataIsArray = NO;
        
        if ([data isKindOfClass:ARTMessage.class]) {
            messages = @[data];
        }
        else if ([data isKindOfClass:[NSArray<ARTMessage *> class]]) {
            messages = data;
            dataIsArray = YES;
        }
        else {
            if (callback) callback([ARTErrorInfo createWithCode:ARTStateInvalidArgs message:@"Unknown data type for publishing messages. Expected ARTMessage or [ARTMessage]."]);
            return;
        }
        
        NSString *baseId = nil;
        if (self.rest.options.idempotentRestPublishing) {
            BOOL messagesHaveEmptyId = [messages artFilter:^BOOL(ARTMessage *m) { return !m.isIdEmpty; }].count <= 0;
            if (messagesHaveEmptyId) {
                NSData *baseIdData = [ARTCrypto generateSecureRandomData:ARTIdempotentLibraryGeneratedIdLength];
                baseId = [baseIdData base64EncodedStringWithOptions:0];
            }
        }
        
        NSInteger serial = 0;
        for (ARTMessage *message in messages) {
            if (message.clientId && self.rest.auth.clientId_nosync && ![message.clientId isEqualToString:self.rest.auth.clientId_nosync]) {
                if (callback) callback([ARTErrorInfo createWithCode:ARTStateMismatchedClientId message:@"attempted to publish message with an invalid clientId"]);
                return;
            }
            if (baseId) {
                message.id = [NSString stringWithFormat:@"%@:%ld", baseId, (long)serial];
            }
            serial += 1;
        }
        
        NSArray<NSDictionary *> *jsonMessages = [self.rest.defaultEncoder messagesToArray:messages];
        
        // unwrap single item array back to the object, because many tests rely on that
        id bodyData = jsonMessages.count > 1 || dataIsArray ? jsonMessages : jsonMessages.firstObject;
        
        NSError *error = nil;
        NSMutableURLRequest *request = [self->_rest buildRequest:@"POST"
                                                            path:[self->_basePath stringByAppendingPathComponent:@"messages"]
                                                         baseUrl:nil
                                                          params:nil
                                                            body:bodyData
                                                         headers:nil
                                                           error:&error];
        if (error) {
            if (callback) callback([ARTErrorInfo createFromNSError:error]);
            return;
        }

        ARTLogDebug(self.logger, @"RS:%p C:%p (%@) post message(s):\n%@", self->_rest, self, self.name, jsonMessages);
        
        [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:nil completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
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

- (void)_updateMessage:(ARTMessage *)message
              isDelete:(BOOL)isDelete
             operation:(nullable ARTMessageOperation *)operation
                params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
      wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
              callback:(nullable ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *__nullable error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    art_dispatch_async(_queue, ^{
        // RSL12/RSL13 - message must have serial
        if (!message.serial || message.serial.length == 0) {
            if (callback) {
                callback([ARTErrorInfo createWithCode:ARTErrorInvalidParameterValue message:[NSString stringWithFormat:@"This message lacks a serial and cannot be %@. Make sure you have enabled \"Message annotations, updates, and deletes\" in channel settings on your dashboard.", isDelete ? @"deleted" : @"updated"]]);
            }
            return;
        }
        
        // RSL12b/RSL13b - Build request body according to spec
        NSMutableDictionary *requestBody = [NSMutableDictionary dictionary];
        
        // RSL12b1/RSL13b1 - serial
        requestBody[@"serial"] = message.serial;
        
        // RSL12b2/RSL13b2 - operation
        if (operation) {
            NSMutableDictionary *operationDict = [NSMutableDictionary dictionary];
            [operation writeToDictionary:operationDict];
            if (operationDict.count > 0) {
                requestBody[@"operation"] = operationDict;
            }
        }
        
        // RSL12b3/RSL13b3 - name
        if (message.name) {
            requestBody[@"name"] = message.name;
        }
        
        // RSL12b4, RSL12b5 / RSL13b4, RSL13b5 - data and encoding (encode per RSL4)
        if (message.data) {
            NSError *encodeError = nil;
            ARTMessage *encodedMessage = [message encodeWithEncoder:self.dataEncoder error:&encodeError];
            if (encodeError) {
                if (callback) callback([ARTErrorInfo createFromNSError:encodeError]);
                return;
            }
            
            requestBody[@"data"] = encodedMessage.data;
            if (encodedMessage.encoding && encodedMessage.encoding.length > 0) {
                requestBody[@"encoding"] = encodedMessage.encoding;
            }
        }
        
        // RSL12b6/RSL13b6 - extras
        if (message.extras) {
            requestBody[@"extras"] = message.extras;
        }
        
        // RSL12b - PATCH to /channels/{channelName}/messages/{serial}
        // RSL13b - POST to /channels/{channelName}/messages/{serial}/delete
        NSString *messagePath;
        NSString *httpMethod;
        
        if (isDelete) {
            // RSL13b - POST to /channels/{channelName}/messages/{serial}/delete
            messagePath = [NSString stringWithFormat:@"%@/messages/%@/delete", self->_basePath, [message.serial encodePathSegment]];
            httpMethod = @"POST";
        } else {
            // RSL12b - PATCH to /channels/{channelName}/messages/{serial}
            messagePath = [NSString stringWithFormat:@"%@/messages/%@", self->_basePath, [message.serial encodePathSegment]];
            httpMethod = @"PATCH";
        }
        
        // RSL12a/RSL13a - params in querystring
        NSStringDictionary *queryParams = [params artMap:^id(NSString *key, ARTStringifiable *value) {
            return value.stringValue;
        }];
        
        NSError *error = nil;
        NSMutableURLRequest *request = [self->_rest buildRequest:httpMethod
                                                            path:messagePath
                                                         baseUrl:nil
                                                          params:queryParams
                                                            body:requestBody
                                                         headers:nil
                                                           error:&error];
        if (error) {
            if (callback) callback([ARTErrorInfo createFromNSError:error]);
            return;
        }
        
        NSString *logOperation = isDelete ? @"delete" : @"update";
        ARTLogDebug(self.logger, @"RS:%p C:%p (%@) %@ message:\n%@", self->_rest, self, self.name, logOperation, requestBody);
        
        [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:wrapperSDKAgents completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
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

// RSL12
- (void)updateMessage:(ARTMessage *)message
            operation:(nullable ARTMessageOperation *)operation
               params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
     wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
             callback:(nullable ARTCallback)callback {
    [self _updateMessage:message isDelete:NO operation:operation params:params wrapperSDKAgents:wrapperSDKAgents callback:callback];
}

// RSL13
- (void)deleteMessage:(ARTMessage *)message
            operation:(nullable ARTMessageOperation *)operation
               params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
     wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
             callback:(nullable ARTCallback)callback {
    [self _updateMessage:message isDelete:YES operation:operation params:params wrapperSDKAgents:wrapperSDKAgents callback:callback];
}

// RSL11
- (void)getMessageWithSerial:(NSString *)serial
            wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                    callback:(ARTMessageErrorCallback)callback {
    if (callback) {
        ARTMessageErrorCallback userCallback = callback;
        callback = ^(ARTMessage *_Nullable message, ARTErrorInfo *_Nullable error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(message, error);
            });
        };
    }
    
    art_dispatch_async(_queue, ^{
        NSString *messagePath = [NSString stringWithFormat:@"%@/messages/%@", self->_basePath, [serial encodePathSegment]];
        
        NSError *error = nil;
        NSMutableURLRequest *request = [self->_rest buildRequest:@"GET"
                                                            path:messagePath
                                                         baseUrl:nil
                                                          params:nil
                                                            body:nil
                                                         headers:nil
                                                           error:&error];
        if (error) {
            if (callback) callback(nil, [ARTErrorInfo createFromNSError:error]);
            return;
        }

        ARTLogDebug(self.logger, @"RS:%p C:%p (%@) get message with serial %@", self->_rest, self, self.name, serial);
        
        [self->_rest executeAblyRequest:request withAuthOption:ARTAuthenticationOn wrapperSDKAgents:wrapperSDKAgents completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                ARTErrorInfo *errorInfo;
                if (self->_rest.options.addRequestIds) {
                    errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error] prepend:[NSString stringWithFormat:@"Request '%@' failed with ", request.URL]];
                } else {
                    errorInfo = [ARTErrorInfo createFromNSError:error];
                }
                if (callback) {
                    callback(nil, errorInfo);
                }
                return;
            }
            
            if (response.statusCode == 200) {
                NSError *decodeError = nil;
                id<ARTEncoder> decoder = self->_rest.encoders[response.MIMEType];
                if (!decoder) {
                    if (callback) {
                        callback(nil, [ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:[NSString stringWithFormat:@"Decoder for MIMEType '%@' wasn't found.", response.MIMEType]]);
                    }
                    return;
                }
                
                ARTMessage *message = [decoder decodeMessage:data error:&decodeError];
                if (decodeError) {
                    if (callback) {
                        callback(nil, [ARTErrorInfo createFromNSError:decodeError]);
                    }
                    return;
                }
                
                // Decode the message data if needed
                ARTMessage *decodedMessage = [message decodeWithEncoder:self.dataEncoder error:&decodeError];
                if (decodeError) {
                    if (callback) {
                        callback(nil, [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:decodeError] prepend:@"Failed to decode message data: "]);
                    }
                    return;
                }
                
                if (callback) {
                    callback(decodedMessage, nil);
                }
            } else {
                if (callback) {
                    callback(nil, [ARTErrorInfo createWithCode:response.statusCode message:[NSString stringWithFormat:@"Failed to get message: HTTP %ld", (long)response.statusCode]]);
                }
            }
        }];
    });
}

// RSL14
- (void)getMessageVersionsWithSerial:(NSString *)serial
                    wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                            callback:(ARTPaginatedMessagesCallback)callback {
    if (callback) {
        ARTPaginatedMessagesCallback userCallback = callback;
        callback = ^(ARTPaginatedResult<ARTMessage *> *_Nullable result, ARTErrorInfo *_Nullable error) {
            art_dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }
    
    art_dispatch_async(_queue, ^{
        NSString *path = [NSString stringWithFormat:@"%@/messages/%@/versions", self->_basePath, [serial encodePathSegment]];
        
        NSError *error = nil;
        NSMutableURLRequest *request = [self->_rest buildRequest:@"GET"
                                                            path:path
                                                         baseUrl:nil
                                                          params:nil
                                                            body:nil
                                                         headers:nil
                                                           error:&error];
        if (error) {
            if (callback) callback(nil, [ARTErrorInfo createFromNSError:error]);
            return;
        }
        
        ARTLogDebug(self.logger, @"RS:%p C:%p (%@) get message versions for serial %@", self->_rest, self, self.name, serial);
        
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
        
        [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor wrapperSDKAgents:wrapperSDKAgents logger:self.logger callback:callback];
    });
}

@end
