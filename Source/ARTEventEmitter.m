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

@implementation NSMutableArray (AsSet)

- (void)artRemoveWhere:(BOOL (^)(id))cond {
    NSUInteger l = [self count];
    for (NSInteger i = 0; i < l; i++) {
        if (cond([self objectAtIndex:i])) {
            [self removeObjectAtIndex:i];
            i--;
            l--;
        }
    }
}

@end

@interface ARTEventListener ()

- (instancetype)initWithBlock:(void (^)(id __art_nonnull))block;
- (void)setTimerWithDeadline:(NSTimeInterval)deadline onTimeout:(void (^)())onTimeout;
- (void)off;

@end

@implementation ARTEventListener {
    void (^_block)(id __art_nonnull);
    CFRunLoopTimerRef _timer;
}

- (instancetype)initWithBlock:(void (^)(id __art_nonnull))block {
    self = [self init];
    if (self) {
        _block = block;
    }
    return self;
}

- (void)call:(id)argument {
    [self cancelTimer];
    _block(argument);
}

- (void)setTimerWithDeadline:(NSTimeInterval)deadline onTimeout:(void (^)())onTimeout {
    [self cancelTimer];
    CFAbsoluteTime timeoutDate = CFAbsoluteTimeGetCurrent() + deadline;

    CFRunLoopRef rl = CFRunLoopGetCurrent();
    _timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, timeoutDate, 0, 0, 0, onTimeout);
    CFRunLoopAddTimer(rl, _timer, kCFRunLoopDefaultMode);
}

- (void)cancelTimer {
    if (_timer) {
        CFRunLoopTimerInvalidate(_timer);
        CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), _timer, kCFRunLoopDefaultMode);
        CFRelease(_timer);
        _timer = nil;
    }
}

- (void)off {
    [self cancelTimer];
}

@end

@implementation ARTEventEmitterEntry

-(instancetype)initWithListener:(ARTEventListener *)listener once:(BOOL)once {
    self = [self init];
    if (self) {
        _listener = listener;
        _once = once;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        return self == object || self.listener == ((ARTEventEmitterEntry *)object).listener;
    }
    return self.listener == object;
}

@end

@implementation ARTEventEmitter
- (instancetype)init {
    self = [super init];
    if (self) {
        [self resetListeners];
    }
    return self;
}

- (ARTEventListener *)on:(id)event callback:(void (^)(id __art_nonnull))cb {
    ARTEventListener *listener = [[ARTEventListener alloc] initWithBlock:cb];
    [self addOnEntry:[[ARTEventEmitterEntry alloc] initWithListener:listener once:false] event:event];
    return listener;
}

- (ARTEventListener *)once:(id)event callback:(void (^)(id __art_nonnull))cb {
    ARTEventListener *listener = [[ARTEventListener alloc] initWithBlock:cb];
    [self addOnEntry:[[ARTEventEmitterEntry alloc] initWithListener:listener once:true] event:event];
    return listener;
}

- (void)addOnEntry:(ARTEventEmitterEntry *)entry event:(id)event {
    [self addObject:entry toArrayWithKey:event inDictionary:self.listeners];
}

- (ARTEventListener *)on:(void (^)(id __art_nonnull))cb {
    ARTEventListener *listener = [[ARTEventListener alloc] initWithBlock:cb];
    [self addOnAllEntry:[[ARTEventEmitterEntry alloc] initWithListener:listener once:false]];
    return listener;
}

- (ARTEventListener *)once:(void (^)(id __art_nonnull))cb {
    ARTEventListener *listener = [[ARTEventListener alloc] initWithBlock:cb];
    [self addOnAllEntry:[[ARTEventEmitterEntry alloc] initWithListener:listener once:true]];
    return listener;
}

- (void)addOnAllEntry:(ARTEventEmitterEntry *)entry {
    [self.anyListeners addObject:entry];
}

- (void)off:(id)event listener:(ARTEventListener *)listener {
    [listener off];
    [self removeObject:listener fromArrayWithKey:event inDictionary:self.listeners where:^BOOL(id entry) {
        return ((ARTEventEmitterEntry *)entry).listener == listener;
    }];
}

- (void)off:(ARTEventListener *)listener {
    [listener off];
    BOOL (^cond)(id) = ^BOOL(id entry) {
        return ((ARTEventEmitterEntry *)entry).listener == listener;
    };
    [self.anyListeners artRemoveWhere:cond];
    for (id event in [self.listeners allKeys]) {
        [self removeObject:listener fromArrayWithKey:event inDictionary:self.listeners where:cond];
    }
}

- (void)off {
    [self resetListeners];
}

- (void)resetListeners {
    for (NSArray *entries in [_listeners allValues]) {
        for (ARTEventEmitterEntry *entry in entries) {
            [entry.listener off];
        }
    }
    for (ARTEventEmitterEntry *entry in _anyListeners) {
        [entry.listener off];
    }
    _listeners = [[NSMutableDictionary alloc] init];
    _anyListeners = [[NSMutableArray alloc] init];
}

- (void)emit:(id)event with:(id)data {
    NSMutableArray *toCall = [[NSMutableArray alloc] init];
    NSMutableArray *toRemoveFromListeners = [[NSMutableArray alloc] init];
    NSMutableArray *toRemoveFromTotalListeners = [[NSMutableArray alloc] init];
    @try {
        for (ARTEventEmitterEntry *entry in [self.listeners objectForKey:event]) {
            if (entry.once) {
                [toRemoveFromListeners addObject:entry];
            }
            
            [toCall addObject:entry];
        }
        
        for (ARTEventEmitterEntry *entry in self.anyListeners) {
            if (entry.once) {
                [toRemoveFromTotalListeners addObject:entry];
            }
            [toCall addObject:entry];
        }
    }
    @finally {
        for (ARTEventEmitterEntry *entry in toRemoveFromListeners) {
            [self removeObject:entry fromArrayWithKey:event inDictionary:self.listeners];
            [entry.listener off];
        }
        for (ARTEventEmitterEntry *entry in toRemoveFromTotalListeners) {
            [self.anyListeners removeObject:entry];
            [entry.listener off];
        }
        for (ARTEventEmitterEntry *entry in toCall) {
            [entry.listener call:data];
        }
    }
}

- (void)addObject:(id)obj toArrayWithKey:(id)key inDictionary:(NSMutableDictionary *)dict {
    NSMutableArray *array = [dict objectForKey:key];
    if (array == nil) {
        array = [[NSMutableArray alloc] init];
        [dict setObject:array forKey:key];
    }
    [array addObject:obj];
}

- (void)removeObject:(id)obj fromArrayWithKey:(id)key inDictionary:(NSMutableDictionary *)dict {
    NSMutableArray *array = [dict objectForKey:key];
    if (array == nil) {
        return;
    }
    [array removeObject:obj];
    if ([array count] == 0) {
        [dict removeObjectForKey:key];
    }
}

- (void)removeObject:(id)obj fromArrayWithKey:(id)key inDictionary:(NSMutableDictionary *)dict where:(BOOL(^)(id))cond {
    NSMutableArray *array = [dict objectForKey:key];
    if (array == nil) {
        return;
    }
    [array artRemoveWhere:cond];
    if ([array count] == 0) {
        [dict removeObjectForKey:key];
    }
}

- (ARTEventListener *)timed:(ARTEventListener *)listener deadline:(NSTimeInterval)deadline onTimeout:(void (^)())onTimeout {
    __weak ARTEventEmitter *s = self;
    __weak ARTEventListener *weakListener = listener;
    [listener setTimerWithDeadline:deadline onTimeout:^void() {
        [s off:weakListener];
        if (onTimeout) onTimeout();
    }];
    return listener;
}

@end
