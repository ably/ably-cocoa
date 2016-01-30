//
//  ARTEventEmitter+Private.h
//  ably
//
//  Created by Toni Cárdenas on 29/1/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#include "ARTEventEmitter.h"
#include "CompatibilityMacros.h"

ART_ASSUME_NONNULL_BEGIN

@interface __GENERIC(ARTEventEmitterEntry, ItemType) : NSObject

@property (readwrite, strong, nonatomic) __GENERIC(ARTEventListener, ItemType) *listener;
@property (readwrite, nonatomic) BOOL once;

- (instancetype)initWithListener:(__GENERIC(ARTEventListener, ItemType) *)listener once:(BOOL)once;
// ARTEventEmitterEntry are compared only using their listener.
- (BOOL)isEqual:(id)object;

@end

@interface __GENERIC(ARTEventEmitter, EventType, ItemType) ()

// The reason we use arrays as sets is that blocks are not hashable.

@property (readwrite, nonatomic) __GENERIC(NSMutableDictionary, EventType, __GENERIC(NSMutableArray, __GENERIC(ARTEventEmitterEntry, ItemType) *) *) *listeners;
// totalListeners listen to all events, except those in exceptions.
@property (readwrite, nonatomic) __GENERIC(NSMutableArray, __GENERIC(ARTEventEmitterEntry, ItemType) *) *totalListeners;
@property (readwrite, nonatomic) __GENERIC(NSMutableDictionary, EventType, __GENERIC(NSMutableArray, __GENERIC(ARTEventListener, ItemType) *) *) *ignoring;

@end

ART_ASSUME_NONNULL_END
