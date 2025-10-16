#import "ARTRealtimeAnnotations+Private.h"
#import "ARTRealtime+Private.h"
#import "ARTChannel+Private.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTStatus.h"
#import "ARTDataQuery+Private.h"
#import "ARTConnection+Private.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTInternalLog.h"
#import "ARTEventEmitter+Private.h"
#import "ARTDataEncoder.h"
#import "ARTAnnotation+Private.h"
#import "ARTOutboundAnnotation.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTEventEmitter+Private.h"
#import "ARTClientOptions.h"
#import "ARTRealtimeChannelOptions.h"
#import "ARTRestAnnotations+Private.h"

@implementation ARTRealtimeAnnotations {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTRealtimeAnnotationsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [_internal getForMessage:message query:query callback:callback];
}

- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [_internal getForMessageSerial:messageSerial query:query callback:callback];
}

- (void)publishForMessage:(ARTMessage *)message annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [_internal publishForMessage:message annotation:annotation callback:callback];
}

- (void)publishForMessageSerial:(NSString *)messageSerial annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [_internal publishForMessageSerial:messageSerial annotation:annotation callback:callback];
}

- (void)deleteForMessage:(ARTMessage *)message annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [_internal deleteForMessage:message annotation:annotation callback:callback];
}

- (void)deleteForMessageSerial:(NSString *)messageSerial annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [_internal deleteForMessageSerial:messageSerial annotation:annotation callback:callback];
}

- (ARTEventListener *)subscribe:(ARTAnnotationCallback)callback {
    return [_internal subscribe:callback];
}

- (ARTEventListener *)subscribe:(NSString *)type callback:(ARTAnnotationCallback)callback {
    return [_internal subscribe:type callback:callback];
}

- (void)unsubscribe {
    [_internal unsubscribe];
}

- (void)unsubscribe:(ARTEventListener *)listener {
    [_internal unsubscribe:listener];
}

- (void)unsubscribe:(NSString *)type listener:(ARTEventListener *)listener {
    [_internal unsubscribe:type listener:listener];
}

@end

#pragma mark - ARTRealtimeAnnotationsInternal

@interface ARTRealtimeAnnotationsInternal ()

@property (nonnull, nonatomic, readonly) ARTInternalLog *logger;

@end

@implementation ARTRealtimeAnnotationsInternal {
    __weak ARTRealtimeChannelInternal *_channel; // weak because channel owns self
    __weak ARTRealtimeInternal *_realtime;
    dispatch_queue_t _userQueue;
    ARTEventEmitter<ARTEvent *, ARTAnnotation *> *_eventEmitter;
    ARTDataEncoder *_dataEncoder;
}

- (instancetype)initWithChannel:(ARTRealtimeChannelInternal *)channel logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _channel = channel;
        _realtime = channel.realtime;
        _userQueue = _realtime.rest.userQueue;
        _queue = _realtime.rest.queue;
        _logger = logger;
        _eventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_queue];
        _dataEncoder = _channel.dataEncoder;
    }
    return self;
}

- (void)publishAnnotation:(ARTOutboundAnnotation *)outboundAnnotation
            messageSerial:(NSString *)messageSerial
                   action:(ARTAnnotationAction)action
                 callback:(ARTCallback)callback {
    if (callback) {
        ARTCallback userCallback = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    // RSAN1a1: Message object must contain a populated serial field
    if (messageSerial == nil) {
        if (callback) {
            callback([ARTErrorInfo createWithCode:ARTErrorBadRequest message:@"Message serial cannot be nil."]);
        }
        return;
    }
    
    // Convert ARTOutboundAnnotation to ARTAnnotation for internal processing
    ARTAnnotation *annotation = [[ARTAnnotation alloc] initWithId:nil
                                                           action:action // RSAN1c1
                                                         clientId:outboundAnnotation.clientId
                                                             name:outboundAnnotation.name
                                                            count:outboundAnnotation.count
                                                             data:outboundAnnotation.data
                                                         encoding:nil
                                                        timestamp:nil
                                                           serial:nil
                                                    messageSerial:messageSerial // RSAN1c2
                                                             type:outboundAnnotation.type
                                                           extras:outboundAnnotation.extras];
dispatch_sync(_queue, ^{
    if (!self.realtime.connection.isActive_nosync) { // RTAN1b
        if (callback) {
            callback(self.realtime.connection.error_nosync);
        }
        return;
    }
    
    NSError *error = nil;
    ARTAnnotation *annotationToPublish = _dataEncoder ? [annotation encodeDataWithEncoder:_dataEncoder error:&error] : annotation; // RSAN1c3
    if (error) {
        if (callback) {
            callback([ARTErrorInfo createFromNSError:error]);
        }
        return;
    }
    
    // Validate annotation size against connection's maxMessageSize
    NSInteger annotationSize = [annotationToPublish annotationSize];
    NSInteger maxSize = self.realtime.connection.maxMessageSize;
    
    if (annotationSize > maxSize) {
        if (callback) {
            callback([ARTErrorInfo createWithCode:ARTErrorMaxMessageLengthExceeded
                                       message:[NSString stringWithFormat:@"Annotation size of %ld bytes exceeds maxMessageSize of %ld bytes", (long)annotationSize, (long)maxSize]]);
        }
        return;
    }
    
    // RTAN1c
    ARTProtocolMessage *pm = [[ARTProtocolMessage alloc] init];
    pm.action = ARTProtocolMessageAnnotation;
    pm.channel = _channel.name;
    pm.annotations = @[annotationToPublish];
    
    switch (_channel.state_nosync) { // RTAN1b
        case ARTRealtimeChannelSuspended:
        case ARTRealtimeChannelFailed: {
            if (callback) {
                callback([ARTErrorInfo createWithCode:ARTErrorChannelOperationFailedInvalidState message:[NSString stringWithFormat:@"channel operation failed (invalid channel state: %@)", ARTRealtimeChannelStateToStr(self->_channel.state_nosync)]]);
            }
            break;
        }
        case ARTRealtimeChannelInitialized:
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelDetached:
        case ARTRealtimeChannelAttaching:
        case ARTRealtimeChannelAttached: {
            [self.realtime send:pm sentCallback:nil ackCallback:^(ARTStatus *status) {
                if (callback) {
                    callback(status.errorInfo);
                }
            }];
            break;
        }
    }
});
}

- (ARTEventListener *)_subscribe:(NSString *_Nullable)type onAttach:(ARTCallback)onAttach callback:(ARTAnnotationCallback)cb {
    if (cb) {
        ARTAnnotationCallback userCallback = cb;
        cb = ^(ARTAnnotation *_Nullable m) {
            dispatch_async(self->_userQueue, ^{
                userCallback(m);
            });
        };
    }

    __block ARTEventListener *listener = nil;
    
dispatch_sync(_queue, ^{
    ARTRealtimeChannelOptions *options = self->_channel.getOptions_nosync;
    BOOL attachOnSubscribe = options != nil ? options.attachOnSubscribe : true;
    if (self->_channel.state_nosync == ARTRealtimeChannelFailed) {
        if (onAttach && attachOnSubscribe) { // RTL7h
            onAttach([ARTErrorInfo createWithCode:ARTErrorChannelOperationFailedInvalidState message:@"attempted to subscribe while channel is in Failed state."]);
        }
        ARTLogWarn(self.logger, @"R:%p C:%p (%@) anotation subscribe to '%@' action(s) has been ignored (attempted to subscribe while channel is in FAILED state)", self->_realtime, self->_channel, self->_channel.name, type);
        return;
    }
    if (attachOnSubscribe) {
        NSString *warningTemplate = @"R:%p C:%p (%@) You are trying to add an annotation listener, but you haven't requested the annotation_subscribe channel mode in ChannelOptions, so this won't do anything (we only deliver annotations to clients who have explicitly requested them).";
        if (self->_channel.shouldAttach) { // RTP6c
            [self->_channel _attach:onAttach];
            [self->_channel.internalEventEmitter once:^(ARTChannelStateChange *stateChange) {
                if (stateChange.current == ARTRealtimeChannelAttached && !self->_channel.isAnnotationSubscribeGranted) { // RTAN4e
                    ARTLogWarn(self.logger, warningTemplate, self->_realtime, self->_channel, self->_channel.name);
                }
            }];
        } else if (self->_channel.state_nosync == ARTRealtimeChannelAttached && !self->_channel.isAnnotationSubscribeGranted) {
            ARTLogWarn(self.logger, warningTemplate, self->_realtime, self->_channel, self->_channel.name);
        }
    }
    listener = type == nil ? [_eventEmitter on:cb] : [_eventEmitter on:[ARTEvent newWithAnnotationType:type] callback:cb];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) annotation subscribe to '%@' action(s)", self->_realtime, self->_channel, self->_channel.name, type == nil ? @"all" : type);
});
    return listener;
}

- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [self getForMessageSerial:message.serial query:query callback:callback];
}

- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [_channel.restChannel.annotations getForMessageSerial:messageSerial query:query callback:callback];
}

- (void)publishForMessage:(ARTMessage *)message annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [self publishAnnotation:annotation messageSerial:message.serial action:ARTAnnotationCreate callback:callback];
}

- (void)publishForMessageSerial:(NSString *)messageSerial annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [self publishAnnotation:annotation messageSerial:messageSerial action:ARTAnnotationCreate callback:callback];
}

- (void)deleteForMessage:(ARTMessage *)message annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [self publishAnnotation:annotation messageSerial:message.serial action:ARTAnnotationDelete callback:callback];
}

- (void)deleteForMessageSerial:(NSString *)messageSerial annotation:(ARTOutboundAnnotation *)annotation callback:(ARTCallback)callback {
    [self publishAnnotation:annotation messageSerial:messageSerial action:ARTAnnotationDelete callback:callback];
}

- (ARTEventListener *)subscribe:(ARTAnnotationCallback)cb {
    return [self _subscribe:nil onAttach:nil callback:cb];
}

- (ARTEventListener *)subscribe:(NSString *)type callback:(ARTAnnotationCallback)callback {
    return [self _subscribe:type onAttach:nil callback:callback];
}

// RTP7

- (void)unsubscribe {
dispatch_sync(_queue, ^{
    [self _unsubscribe];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) annotations unsubscribe to all types", self->_realtime, self->_channel, self->_channel.name);
});
}

- (void)_unsubscribe {
    [_eventEmitter off];
}

- (void)unsubscribe:(ARTEventListener *)listener {
dispatch_sync(_queue, ^{
    [_eventEmitter off:listener];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) annotations unsubscribe to all types", self->_realtime, self->_channel, self->_channel.name);
});
}

- (void)unsubscribe:(NSString *)type listener:(ARTEventListener *)listener {
dispatch_sync(_queue, ^{
    [_eventEmitter off:[ARTEvent newWithAnnotationType:type] listener:listener];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) annotations unsubscribe to type '%@'", self->_realtime, self->_channel, self->_channel.name, type);
});
}

- (void)onMessage:(ARTProtocolMessage *)message {
    for (ARTAnnotation *a in message.annotations) {
        ARTAnnotation *annotation = a;
        if (annotation.data && _dataEncoder) {
            NSError *decodeError = nil;
            annotation = [a decodeDataWithEncoder:_dataEncoder error:&decodeError];
            if (decodeError != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason] prepend:@"Failed to decode data: "];
                ARTLogError(self.logger, @"RT:%p C:%p (%@) %@", _realtime, _channel, _channel.name, errorInfo.message);
            }
        }
        [_eventEmitter emit:[ARTEvent newWithAnnotationType:annotation.type] with:annotation];
    }
}

@end
