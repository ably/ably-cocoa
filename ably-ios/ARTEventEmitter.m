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
#import "ARTRealtimeChannelSubscription.h"

@interface NSMutableArray (AsSet)

- (id)member:(id)object;
- (void)addObjectReplacing:(id)object;

@end

@implementation NSMutableArray (AsSet)

- (id)member:(id)object {
    for (id item in self) {
        if ([item isEqual:object]) {
            return item;
        }
    }
    return nil;
}

- (void)addObjectReplacing:(id)object {
    for (int i = 0; i < [self count]; i++) {
        id item = [self objectAtIndex:i];
        if ([item isEqual:object] || [object isEqual:item]) {
            [self replaceObjectAtIndex:i withObject:object];
            return;
        }
    }
    [self addObject:object];
}

- (void)artRemoveObject:(id)object {
    for (id item in self) {
        if ([item isEqual:object]) {
            [self removeObject:item];
            return;
        }
    }
}

@end

@interface ARTEventListener ()

- (instancetype)initWithBlock:(void (^)(id __art_nonnull))block;

@end

@implementation ARTEventListener {
    void (^_block)(id __art_nonnull);
}

- (instancetype)initWithBlock:(void (^)(id __art_nonnull))block {
    self = [self init];
    if (self) {
        _block = block;
    }
    return self;
}

- (void)call:(id)argument {
    _block(argument);
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
        _listeners = [[NSMutableDictionary alloc] init];
        _totalListeners = [[NSMutableArray alloc] init];
        _ignoring = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (ARTEventListener *)on:(id)event call:(void (^)(id __art_nonnull))cb {
    ARTEventListener *listener = [[ARTEventListener alloc] initWithBlock:cb];
    [self on:event callListener:listener];
    return listener;
}

- (void)on:(id)event callListener:(ARTEventListener *)listener {
    [self addOnEntry:[[ARTEventEmitterEntry alloc] initWithListener:listener once:false] event:event];
}

- (ARTEventListener *)once:(id)event call:(void (^)(id __art_nonnull))cb {
    ARTEventListener *listener = [[ARTEventListener alloc] initWithBlock:cb];
    [self once:event callListener:listener];
    return listener;
}

- (void)once:(id)event callListener:(ARTEventListener *)listener {
    [self addOnEntry:[[ARTEventEmitterEntry alloc] initWithListener:listener once:true] event:event];
}

- (void)addOnEntry:(ARTEventEmitterEntry *)entry event:(id)event {
    if ([self.totalListeners member:entry.listener] != nil) {
        // Already listening to everything! No need to add. Just check if it
        // is ignoring it, and un-ignore it if so.
        [self removeObject:entry.listener fromArrayWithKey:event inDictionary:self.ignoring];
        if (!entry.once) {
            // But 'once' listeners still need to be added. emit will check
            // listeners before totalListeners. If a listener has once=true
            // and also is in totalListeners, after dispatching the event to it,
            // the event will be added to its ignored set.
            return;
        }
    }
    
    [self addObject:entry toArrayWithKey:event inDictionary:self.listeners];
}

- (ARTEventListener *)onAll:(void (^)(id __art_nonnull))cb {
    ARTEventListener *listener = [[ARTEventListener alloc] initWithBlock:cb];
    [self onAllCallListener:listener];
    return listener;
}

- (void)onAllCallListener:(ARTEventListener *)listener {
    [self addOnAllEntry:[[ARTEventEmitterEntry alloc] initWithListener:listener once:false]];
}

- (ARTEventListener *)onceAll:(void (^)(id __art_nonnull))cb {
    ARTEventListener *listener = [[ARTEventListener alloc] initWithBlock:cb];
    [self onceAllCallListener:listener];
    return listener;
}

- (void)onceAllCallListener:(ARTEventListener *)listener {
    [self addOnAllEntry:[[ARTEventEmitterEntry alloc] initWithListener:listener once:true]];
}

- (void)addOnAllEntry:(ARTEventEmitterEntry *)entry {
    [self.totalListeners addObjectReplacing:entry];
    
    // Maybe cb was already listening to some events; remove it from their
    // entries in listeners if so.
    for (NSMutableArray *listenersToEvent in [self.listeners allValues]) {
        [listenersToEvent artRemoveObject:entry.listener];
    }
}

- (void)off:(id)event listener:(ARTEventListener *)listener {
    if ([self.totalListeners member:listener] != nil) {
        // It is listening to everything but now wants to ignore a particular
        // event. Just mark it in its ignoring entry; emit will check that.
        [self addObject:listener toArrayWithKey:event inDictionary:self.ignoring];
        return;
    }
    [self removeObject:listener fromArrayWithKey:event inDictionary:self.listeners];
}

- (void)offAll:(ARTEventListener *)listener {
    [self.totalListeners artRemoveObject:listener];
    for (id event in [self.ignoring keyEnumerator]) {
        [self removeObject:listener fromArrayWithKey:event inDictionary:self.ignoring];
    }
    for (id event in [self.listeners keyEnumerator]) {
        [self removeObject:listener fromArrayWithKey:event inDictionary:self.listeners];
    }
}

- (void)emit:(id)event with:(id)data {
    NSMutableArray *listenersForEvent = [self.listeners objectForKey:event];
    NSMutableArray *toCall = [[NSMutableArray alloc] init];
    NSMutableArray *toRemoveFromListenersForEvent = [[NSMutableArray alloc] init];
    NSMutableArray *toRemoveFromTotalListeners = [[NSMutableArray alloc] init];
    @try {
        for (ARTEventEmitterEntry *entry in listenersForEvent) {
            if (entry.once) {
                NSMutableArray *ign = [self.ignoring objectForKey:event];
                if (ign && [ign member:entry.listener]) {
                    // If you call 'onAll', then 'once(A)' and then 'off(A)',
                    // 'onAll' will add to totalListeners, 'once(A)' will add
                    // to listeners and 'off(A)' will add to ignoring. We've found
                    // here one of those cases; just keep going. (If 'on' or 'once'
                    // is called again, it will remove A from ignoring and replace this
                    // entry, so it's fine to leave it here.)
                    [toRemoveFromListenersForEvent addObjectReplacing:entry];
                    continue;
                }

                [toRemoveFromListenersForEvent addObjectReplacing:entry];
                if ([self.totalListeners member:entry]) {
                    // If you call 'onAll' and then 'once(A)', you end up here, and you need
                    // to ignore from now on A so that 'once' has effect.
                    [self addObject:entry.listener toArrayWithKey:event inDictionary:self.ignoring];
                }
            }
            
            [toCall addObjectReplacing:entry];
        }
        
        for (ARTEventEmitterEntry *entry in self.totalListeners) {
            NSMutableArray *ign = [self.ignoring objectForKey:event];
            if (ign && [ign member:entry.listener]) {
                continue;
            }
            
            if (entry.once) {
                [toRemoveFromTotalListeners addObjectReplacing:entry];
            }

            [toCall addObjectReplacing:entry];
        }
    }
    @finally {
        for (ARTEventEmitterEntry *entry in toRemoveFromListenersForEvent) {
            [listenersForEvent artRemoveObject:entry.listener];
        }
        for (ARTEventEmitterEntry *entry in toRemoveFromTotalListeners) {
            [self.totalListeners artRemoveObject:entry.listener];
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
    [array addObjectReplacing:obj];
}

- (void)removeObject:(id)obj fromArrayWithKey:(id)key inDictionary:(NSMutableDictionary *)dict {
    NSMutableArray *array = [dict objectForKey:key];
    if (array == nil) {
        return;
    }
    [array artRemoveObject:obj];
    if ([array count] == 0) {
        [dict removeObjectForKey:key];
    }
}

@end
