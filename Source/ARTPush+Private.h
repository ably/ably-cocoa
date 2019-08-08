//
//  ARTPush+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTPush.h>
#import "ARTQueuedDealloc.h"

@class ARTPushActivationStateMachine;
@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushInternal : NSObject <ARTPushProtocol>

@property (nonatomic, strong, readonly) ARTPushAdmin *admin;

- (instancetype)init:(ARTRestInternal *)rest;

- (ARTPushActivationStateMachine *)activationMachine;

@end

@interface ARTPush ()

- (instancetype)initWithInternal:(ARTPushInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
