//
//  ARTEventEmitter.m
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTEventEmitter+Private.h"

#import "ARTRealtime.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtimeChannel.h"
#import "ARTGCD.h"

@implementation NSMutableArray (AsSet)

- (void)artRemoveWhere:(BOOL (^)(id))cond {
    NSUInteger l = [self count];
    for (NSInteger i = 0; i < l; i++) {
        if (cond([self objectAtIndex:i])) {
            @synchronized(self) {
                [self removeObjectAtIndex:i];
            }
            i--;
            l--;
        }
    }
}

@end

#pragma mark - ARTEvent

@implementation ARTEvent {
    NSString *_value;
}

- (instancetype)initWithString:(NSString *)value {
    if (self = [super init]) {
        _value = value;
    }
    return self;
}

+ (instancetype)newWithString:(NSString *)value {
    return [[self alloc] initWithString:value];
}

- (NSString *)identification {
    return _value;
}

@end

#pragma mark - ARTEventListener

@interface ARTEventListener ()
@property (readonly) BOOL timerIsRunning;
@property (readonly) BOOL hasTimer;
@end

@implementation ARTEventListener {
    __weak NSNotificationCenter *_center;
    __weak ARTEventEmitter *_eventHandler;
    NSTimeInterval _timeoutDeadline;
    void (^_timeoutBlock)();
    dispatch_block_t _work;
}

- (instancetype)initWithId:(NSString *)eventId token:(id<NSObject>)token handler:(ARTEventEmitter *)eventHandler center:(NSNotificationCenter *)center {
    if (self = [super init]) {
        _eventId = eventId;
        _token = token;
        _center = center;
        _eventHandler = eventHandler;
        _timeoutDeadline = 0;
        _timeoutBlock = nil;
        _timerIsRunning = false;
    }
    return self;
}

- (void)dealloc {
    [self removeObserver];
}

- (void)removeObserver {
    [self stopTimer];
    [_center removeObserver:_token];
}

- (BOOL)handled {
    return _count++ > 0;
}

- (ARTEventListener *)setTimer:(NSTimeInterval)timeoutDeadline onTimeout:(void (^)())timeoutBlock {
    if (_timeoutBlock) {
        NSAssert(false, @"timer is already set");
    }
    _timeoutBlock = timeoutBlock;
    _timeoutDeadline = timeoutDeadline;
    return self;
}

- (void)timeout {
    [_eventHandler off:self];
    if (_timeoutBlock) {
        _timeoutBlock();
    }
}

- (BOOL)hasTimer {
    return _timeoutBlock != nil;
}

- (void)startTimer {
    if (_timerIsRunning) {
        NSAssert(false, @"timer is already running");
    }
    _timerIsRunning = true;
    __weak typeof(self) weakSelf = self;
    _work = artDispatchScheduled(_timeoutDeadline, [_eventHandler queue], ^{
        [weakSelf timeout];
    });
}

- (void)stopTimer {
    artDispatchCancel(nil);
    artDispatchCancel(_work);
    _timerIsRunning = false;
}

@end

#pragma mark - ARTEventEmitter

@implementation ARTEventEmitter

- (instancetype)init {
    return [self initWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _notificationCenter = [[NSNotificationCenter alloc] init];
        _queue = queue;
        [self resetListeners];
    }
    return self;
}

- (ARTEventListener *)on:(id<ARTEventIdentification>)event callback:(void (^)(id __art_nonnull))cb {
    NSString *eventId = [NSString stringWithFormat:@"%p-%@", self, [event identification]];
    __weak __block ARTEventListener *weakListener;
    id<NSObject> observerToken = [_notificationCenter addObserverForName:eventId object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (weakListener == nil) return;
        if ([weakListener hasTimer] && ![weakListener timerIsRunning]) return;
        [weakListener stopTimer];
        cb(note.object);
    }];
    ARTEventListener *eventToken = [[ARTEventListener alloc] initWithId:eventId token:observerToken handler:self center:_notificationCenter];
    weakListener = eventToken;
    [self addObject:eventToken toArrayWithKey:eventToken.eventId inDictionary:self.listeners];
    return eventToken;
}

- (ARTEventListener *)once:(id<ARTEventIdentification>)event callback:(void (^)(id __art_nonnull))cb {
    NSString *eventId = [NSString stringWithFormat:@"%p-%@", self, [event identification]];
    __weak __block ARTEventListener *weakListener;
    __weak typeof(self) weakSelf = self;
    id<NSObject> observerToken = [_notificationCenter addObserverForName:eventId object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (weakListener == nil) return;
        if ([weakListener hasTimer] && ![weakListener timerIsRunning]) return;
        if ([weakListener handled]) return;
        [weakListener removeObserver];
        [weakSelf removeObject:weakListener fromArrayWithKey:[weakListener eventId] inDictionary:[weakSelf listeners]];
        cb(note.object);
    }];
    ARTEventListener *eventToken = [[ARTEventListener alloc] initWithId:eventId token:observerToken handler:self center:_notificationCenter];
    weakListener = eventToken;
    [self addObject:eventToken toArrayWithKey:eventToken.eventId inDictionary:self.listeners];
    return eventToken;
}

- (ARTEventListener *)on:(void (^)(id __art_nonnull))cb {
    NSString *eventId = [NSString stringWithFormat:@"%p", self];
    __weak __block ARTEventListener *weakListener;
    id<NSObject> observerToken = [_notificationCenter addObserverForName:eventId object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (weakListener == nil) return;
        if ([weakListener hasTimer] && ![weakListener timerIsRunning]) return;
        [weakListener stopTimer];
        cb(note.object);
    }];
    ARTEventListener *eventToken = [[ARTEventListener alloc] initWithId:eventId token:observerToken handler:self center:_notificationCenter];
    weakListener = eventToken;
    [self.anyListeners addObject:eventToken];
    return eventToken;
}

- (ARTEventListener *)once:(void (^)(id __art_nonnull))cb {
    NSString *eventId = [NSString stringWithFormat:@"%p", self];
    __weak __block ARTEventListener *weakListener;
    __weak typeof(self) weakSelf = self;
    id<NSObject> observerToken = [_notificationCenter addObserverForName:eventId object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (weakListener == nil) return;
        if ([weakListener hasTimer] && ![weakListener timerIsRunning]) return;
        if ([weakListener handled]) return;
        [weakListener removeObserver];
        [[weakSelf anyListeners] removeObject:weakListener];
        cb(note.object);
    }];
    ARTEventListener *eventToken = [[ARTEventListener alloc] initWithId:eventId token:observerToken handler:self center:_notificationCenter];
    weakListener = eventToken;
    [self.anyListeners addObject:eventToken];
    return eventToken;
}

- (void)off:(id<ARTEventIdentification>)event listener:(ARTEventListener *)listener {
    NSString *eventId = [NSString stringWithFormat:@"%p-%@", self, [event identification]];
    if (![eventId isEqualToString:listener.eventId]) return;
    [listener removeObserver];
    @synchronized (_listeners) {
        [self.listeners[listener.eventId] removeObject:listener];
        if ([self.listeners[listener.eventId] firstObject] == nil) {
            [self.listeners removeObjectForKey:listener.eventId];
        }
    }
}

- (void)off:(ARTEventListener *)listener {
    [listener removeObserver];
    @synchronized (_listeners) {
        [self.listeners[listener.eventId] removeObject:listener];
    }
    @synchronized (_anyListeners) {
        [self.anyListeners removeObject:listener];
    }
}

- (void)off {
    [self resetListeners];
}

- (void)resetListeners {
    @synchronized (_listeners) {
        for (NSArray<ARTEventListener *> *items in [_listeners allValues]) {
            for (ARTEventListener *item in items) {
                [item removeObserver];
            }
        }
        [_listeners removeAllObjects];
    }
    _listeners = [[NSMutableDictionary alloc] init];

    @synchronized (_anyListeners) {
        for (ARTEventListener *item in _anyListeners) {
            [item removeObserver];
        }
        [_anyListeners removeAllObjects];
    }
    _anyListeners = [[NSMutableArray alloc] init];
}

- (void)emit:(id<ARTEventIdentification>)event with:(id)data {
    NSString *eventId;
    if (event) {
        eventId = [NSString stringWithFormat:@"%p-%@", self, [event identification]];
        [self.notificationCenter postNotificationName:eventId object:data];
        [self.notificationCenter postNotificationName:[NSString stringWithFormat:@"%p", self] object:data];
    }
    else {
        eventId = [NSString stringWithFormat:@"%p", self];
        [self.notificationCenter postNotificationName:eventId object:data];
    }
}

- (void)addObject:(id)obj toArrayWithKey:(id)key inDictionary:(NSMutableDictionary *)dict {
    @synchronized (dict) {
        NSMutableArray *array = [dict objectForKey:key];
        if (array == nil) {
            array = [[NSMutableArray alloc] init];
            [dict setObject:array forKey:key];
        }
        if ([array indexOfObject:obj] == NSNotFound) {
            [array addObject:obj];
        }
    }
}

- (void)removeObject:(id)obj fromArrayWithKey:(id)key inDictionary:(NSMutableDictionary *)dict {
    @synchronized (dict) {
        NSMutableArray *array = [dict objectForKey:key];
        if (array == nil) {
            return;
        }
        [array removeObject:obj];
        if ([array count] == 0) {
            [dict removeObjectForKey:key];
        }
    }
}

- (void)removeObject:(id)obj fromArrayWithKey:(id)key inDictionary:(NSMutableDictionary *)dict where:(BOOL(^)(id))cond {
    @synchronized (dict) {
        NSMutableArray *array = [dict objectForKey:key];
        if (array == nil) {
            return;
        }
        [array artRemoveWhere:cond];
        if ([array count] == 0) {
            [dict removeObjectForKey:key];
        }
    }
}

@end
