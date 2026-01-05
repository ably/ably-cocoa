#import "ARTChannel+Private.h"
#import "ARTChannelOptions+Private.h"
#import "ARTDataEncoder.h"
#import "ARTMessage.h"
#import "ARTMessage+Private.h"
#import "ARTMessageOperation.h"
#import "ARTMessageVersion+Private.h"
#import "ARTChannelOptions.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTBaseMessage+Private.h"
#import "ARTDataQuery.h"
#import "ARTRest+Private.h"
#import "ARTDefault.h"
#import "ARTClientOptions+Private.h"
#import "ARTInternalLog.h"
#import "ARTGCD.h"

@implementation ARTChannel {
    dispatch_queue_t _queue;
    ARTChannelOptions *_options;
}

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options rest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _name = name;
        _logger = logger;
        _queue = rest.queue;
        _options = options;
        _options.frozen = YES;
        NSError *error = nil;
        _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:_options.cipher logger:_logger error:&error];
        if (error != nil) {
            ARTLogWarn(_logger, @"creating ARTDataEncoder: %@", error);
            _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:nil logger:_logger error:nil];
        }
    }
    return self;
}

- (ARTChannelOptions *)options {
    __block ARTChannelOptions *ret;
    art_dispatch_sync(_queue, ^{
        ret = [self options_nosync];
    });
    return ret;
}

- (ARTChannelOptions *)options_nosync {
    return _options;
}

- (void)setOptions:(ARTChannelOptions *)options {
    art_dispatch_sync(_queue, ^{
        [self setOptions_nosync:options];
    });
}

- (void)setOptions_nosync:(ARTChannelOptions *)options {
    _options = options;
    [self recreateDataEncoderWith:options.cipher];
}

- (void)recreateDataEncoderWith:(ARTCipherParams*)cipher {
    NSError *error = nil;
    _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:cipher logger:self.logger error:&error];
    
    if (error != nil) {
        ARTLogWarn(_logger, @"creating ARTDataEncoder: %@", error);
        _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:nil logger:self.logger error:nil];
    }
}

- (void)publish:(NSString *)name data:(id)data {
    [self publish:name data:data callback:nil];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data callback:(nullable ARTCallback)callback {
    [self publish:name data:data extras:nil callback:callback];
}

- (void)publish:(NSString *)name data:(id)data extras:(id<ARTJsonCompatible>)extras {
    [self publish:name data:data extras:extras callback:nil];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(id<ARTJsonCompatible>)extras callback:(nullable ARTCallback)callback {
    [self publish:name message:[[ARTMessage alloc] initWithName:name data:data] extras:extras callback:callback];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId {
    [self publish:name data:data clientId:clientId callback:nil];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId extras:(id<ARTJsonCompatible>)extras {
    [self publish:name data:data clientId:clientId extras:extras callback:nil];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId callback:(ARTCallback)callback {
    [self publish:name data:data clientId:(NSString *)clientId extras:nil callback:callback];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId extras:(id<ARTJsonCompatible>)extras callback:(ARTCallback)callback {
    [self publish:name message:[[ARTMessage alloc] initWithName:name data:data clientId:clientId] extras:extras callback:callback];
}

- (void)publish:(NSString *)name message:(ARTMessage *)message extras:(id<ARTJsonCompatible>)extras callback:(ARTCallback)callback {
    NSError *error = nil;
    message.extras = extras;
    ARTMessage *messagesWithDataEncoded = [self encodeMessageIfNeeded:message error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
    
    // Checked after encoding, so that the client can receive callback with encoding errors
    if ([self exceedMaxSize:@[message]]) {
        ARTErrorInfo *sizeError = [ARTErrorInfo createWithCode:ARTErrorMaxMessageLengthExceeded
                                                       message:@"Maximum message length exceeded."];
        if (callback) {
            callback(sizeError);
        }
        return;
    }
    
    [self internalPostMessages:messagesWithDataEncoded callback:callback];
}

- (void)publish:(NSArray<ARTMessage *> *)messages {
    [self publish:messages callback:nil];
}

- (void)publish:(NSArray<ARTMessage *> *)messages callback:(nullable ARTCallback)callback {
    NSError *error = nil;

    NSMutableArray<ARTMessage *> *messagesWithDataEncoded = [NSMutableArray new];
    for (ARTMessage *message in messages) {
        [messagesWithDataEncoded addObject:[self encodeMessageIfNeeded:message error:&error]];
    }
    
    if (error) {
        if (callback) {
            callback([ARTErrorInfo createFromNSError:error]);
        }
        return;
    }
    
    // Checked after encoding, so that the client can receive callback with encoding errors
    if ([self exceedMaxSize:messages]) {
        ARTErrorInfo *sizeError = [ARTErrorInfo createWithCode:ARTErrorMaxMessageLengthExceeded
                                                       message:@"Maximum message length exceeded."];
        if (callback) {
            callback(sizeError);
        }
        return;
    }
    
    [self internalPostMessages:messagesWithDataEncoded callback:callback];
}

/// Sends a mutation request to edit the given user-supplied message (i.e. one passed to one of updateMessage or deleteMessage), per RSL15.
- (void)editMessage:(ARTMessage *)message
             action:(ARTMessageAction)action
          operation:(nullable ARTMessageOperation *)operation
             params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
   wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
           callback:(nullable ARTEditResultCallback)callback {
    // RSL4: Encode message's data
    NSError *error;
    ARTMessage *messageWithDataEncoded = [self encodeMessageIfNeeded:message error:&error];
    if (error) {
        if (callback) callback(nil, [ARTErrorInfo createFromNSError:error]);
        return;
    }

    ARTMessage *wireMessage = [messageWithDataEncoded copy];

    // RSL15b1
    wireMessage.action = action;
    wireMessage.actionIsInternallySet = YES;

    // RSL15b7
    if (operation) {
        wireMessage.version = [[ARTMessageVersion alloc] initWithOperation:operation];
    }

    [self internalSendEditRequestForMessage:wireMessage params:params wrapperSDKAgents:wrapperSDKAgents callback:callback];
}

- (void)updateMessage:(ARTMessage *)message
            operation:(nullable ARTMessageOperation *)operation
               params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
     wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
             callback:(nullable ARTCallback)callback {
    // RSL15b1, RTL32b1
    [self editMessage:message action:ARTMessageActionUpdate operation:operation params:params wrapperSDKAgents:wrapperSDKAgents callback:^(ARTUpdateDeleteResult *result, ARTErrorInfo *error) {
        if (callback) {
            callback(error);
        }
    }];
}

- (void)deleteMessage:(ARTMessage *)message
            operation:(nullable ARTMessageOperation *)operation
               params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
     wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
             callback:(nullable ARTCallback)callback {
    // RSL15b1, RTL32b1
    [self editMessage:message action:ARTMessageActionDelete operation:operation params:params wrapperSDKAgents:wrapperSDKAgents callback:^(ARTUpdateDeleteResult *result, ARTErrorInfo *error) {
        if (callback) {
            callback(error);
        }
    }];
}

- (void)getMessageWithSerial:(NSString *)serial
            wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                    callback:(ARTMessageErrorCallback)callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)getMessageVersionsWithSerial:(NSString *)serial
                    wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                            callback:(ARTPaginatedMessagesCallback)callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (BOOL)exceedMaxSize:(NSArray<ARTBaseMessage *> *)messages {
    NSInteger size = 0;
    for (ARTMessage *message in messages) {
        size += [message messageSize];
    }
    return size > [ARTDefault maxMessageSize];
}

- (ARTMessage *)encodeMessageIfNeeded:(ARTMessage *)message error:(NSError **)error {
    if (!self.dataEncoder) {
        return message;
    }
    NSError *e = nil;
    message = [message encodeWithEncoder:self.dataEncoder error:&e];
    if (e) {
        ARTLogError(self.logger, @"ARTChannel: error encoding data: %@", e);
    }
    if (error) {
        *error = e;
    }
    return message;
}

- (void)historyWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents completion:(ARTPaginatedMessagesCallback)callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)internalPostMessages:(id)data callback:(ARTCallback)callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)internalSendEditRequestForMessage:(ARTMessage *)message
                                   params:(nullable NSDictionary<NSString *, ARTStringifiable *> *)params
                         wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                                 callback:(nullable ARTEditResultCallback)callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
