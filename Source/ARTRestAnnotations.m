#import "ARTRestAnnotations+Private.h"
#import "ARTRest+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTChannel+Private.h"
#import "ARTBaseMessage+Private.h"
#import "ARTInternalLog.h"

#import "ARTChannel.h"
#import "ARTDataQuery.h"

@implementation ARTAnnotationsQuery

- (instancetype)initWithLimit:(NSUInteger)limit {
    self = [super init];
    if (self) {
        _limit = limit;
    }
    return self;
}

- (NSMutableArray *)asQueryItems {
    NSMutableArray *items = [NSMutableArray array];

    [items addObject:[NSURLQueryItem queryItemWithName:@"limit" value:[NSString stringWithFormat:@"%lu", (unsigned long)self.limit]]];

    return items;
}

@end

@implementation ARTRestAnnotations {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTRestAnnotationsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
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

- (void)publish:(ARTAnnotation *)annotation messageSerial:(NSString *)messageSerial callback:(ARTAnnotationErrorCallback)callback {
    [_internal publish:annotation messageSerial:messageSerial callback:callback];
}

- (void)unpublish:(ARTAnnotation *)annotation messageSerial:(NSString *)messageSerial callback:(ARTAnnotationErrorCallback)callback {
    [_internal unpublish:annotation messageSerial:messageSerial callback:callback];
}

@end

NS_ASSUME_NONNULL_BEGIN

@interface ARTRestAnnotationsInternal ()

@property (nonatomic, readonly) ARTInternalLog *logger;

@end

NS_ASSUME_NONNULL_END

@implementation ARTRestAnnotationsInternal {
    __weak ARTRestChannelInternal *_channel; // weak because channel owns self
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
}

- (instancetype)initWithChannel:(ARTRestChannelInternal *)channel logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _channel = channel;
        _userQueue = channel.rest.userQueue;
        _queue = channel.rest.queue;
        _logger = logger;
    }
    return self;
}

- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    [self getForMessageSerial:message.serial query:query callback:callback];
}

- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback {
    // TODO: implement
}

- (void)publish:(ARTAnnotation *)annotation messageSerial:(NSString *)messageSerial callback:(ARTAnnotationErrorCallback)callback {
    // TODO: implement
}

- (void)unpublish:(ARTAnnotation *)annotation messageSerial:(NSString *)messageSerial callback:(ARTAnnotationErrorCallback)callback {
    // TODO: implement
}

@end
