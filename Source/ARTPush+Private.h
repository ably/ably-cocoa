//
//  ARTPush+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTPush.h>
#import <Ably/ARTPushAdmin+Private.h>
#import "ARTQueuedDealloc.h"

@class ARTPushActivationStateMachine;
@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushInternal : NSObject <ARTPushProtocol>

@property (nonatomic, strong, readonly) ARTPushAdminInternal *admin;
@property (readonly) dispatch_queue_t queue;

- (instancetype)init:(ARTRestInternal *)rest;

#if TARGET_OS_IOS
- (void)getActivationMachine:(void (^)(ARTPushActivationStateMachine *_Nullable))block;

/// Direct access to _activationMachine var for whitebox testing.
@property (nullable, readonly) ARTPushActivationStateMachine *activationMachine;

/// Create the _activationMachine manually with a custom delegate for whitebox testing.
- (ARTPushActivationStateMachine *)createActivationStateMachine_nolock:(id)delegate;
#endif

@end

@interface ARTPush ()

@property (nonatomic, readonly) ARTPushInternal *internal;

- (instancetype)initWithInternal:(ARTPushInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
