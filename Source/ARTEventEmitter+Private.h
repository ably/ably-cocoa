//
//  ARTEventEmitter+Private.h
//  ably
//
//  Created by Toni Cárdenas on 29/1/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#include "ARTEventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTEventEmitter<EventType, ItemType> ()

@property (nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (nonatomic, readonly) dispatch_queue_t queue;

@property (readonly, atomic) NSMutableDictionary<NSString *, NSMutableArray<ARTEventListener *> *> *listeners;
@property (readonly, atomic) NSMutableArray<ARTEventListener *> *anyListeners;

@end

NS_ASSUME_NONNULL_END

