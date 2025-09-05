#import "ARTRealtimeAnnotations+Private.h"
#import "ARTRealtime+Private.h"
#import "ARTChannel+Private.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTStatus.h"
#import "ARTDataQuery+Private.h"
#import "ARTConnection+Private.h"
#import "NSArray+ARTFunctional.h"
#import "ARTInternalLog.h"
#import "ARTEventEmitter+Private.h"
#import "ARTDataEncoder.h"
#import "ARTAnnotation+Private.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTEventEmitter+Private.h"
#import "ARTClientOptions.h"
#import "ARTRealtimeChannelOptions.h"

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
        if (self->_channel.shouldAttach && attachOnSubscribe) { // RTP6c
            [self->_channel _attach:onAttach];
        }
        listener = type == nil ? [_eventEmitter on:cb] : [_eventEmitter on:[ARTEvent newWithAnnotationType:type] callback:cb];
        ARTLogVerbose(self.logger, @"R:%p C:%p (%@) annotation subscribe to '%@' action(s)", self->_realtime, self->_channel, self->_channel.name, type == nil ? @"all" : type);
    });
    return listener;
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
            annotation = [a decodeWithEncoder:_dataEncoder error:&decodeError];
            if (decodeError != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason] prepend:@"Failed to decode data: "];
                ARTLogError(self.logger, @"RT:%p C:%p (%@) %@", _realtime, _channel, _channel.name, errorInfo.message);
            }
        }
        [_eventEmitter emit:[ARTEvent newWithAnnotationType:annotation.type] with:annotation];
    }
}

@end
