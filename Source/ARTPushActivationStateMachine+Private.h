//
//  ARTPushActivationStateMachine+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 26/01/2018.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Ably/ARTPushActivationStateMachine.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTPushActivationCurrentStateKey;
extern NSString *const ARTPushActivationPendingEventsKey;

@interface ARTPushActivationStateMachine ()

@property (weak, nonatomic) id delegate;
@property (nonatomic, copy, nullable) void (^transitions)(ARTPushActivationEvent *event, ARTPushActivationState *from, ARTPushActivationState *to);
@property (readonly, nonatomic) ARTPushActivationEvent *lastEvent;
@property (readonly, nonatomic) ARTPushActivationEvent *lastEvent_nosync;
@property (readonly, nonatomic) ARTPushActivationState *current;
@property (readonly, nonatomic) ARTPushActivationState *current_nosync;

@property (readonly, nonatomic) NSMutableArray<ARTPushActivationEvent *> *pendingEvents;

#if TARGET_OS_IOS
/// Register to receive remote notifications via Apple Push Notification service.
- (void)registerForRemoteNotifications;
#endif

@end

NS_ASSUME_NONNULL_END
