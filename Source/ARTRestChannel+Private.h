
//
//  ARTRestChannel+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTRestChannel.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;

@interface ARTRestChannelInternal : ARTChannel <ARTRestChannelProtocol>

@property (readonly) ARTRestPresence *presence;
@property (readonly) ARTPushChannel *push;

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRestInternal *)rest;

@property (nonatomic, weak) ARTRestInternal *rest;

@end

@interface ARTRestChannelInternal (Private)

@property (readonly, getter=getBasePath) NSString *basePath;

@end

@interface ARTRestChannel ()

- (instancetype)initWithInternal:(ARTRestChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end
