//
//  ARTPushActivationState.h
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTPushActivationStateMachine;
@class ARTPushActivationEvent;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushActivationState : NSObject <NSCoding>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine;
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine;

- (nullable ARTPushActivationState *)transition:(ARTPushActivationEvent *)event;

@end

@interface ARTPushActivationPersistentState : ARTPushActivationState
@end

#pragma mark - States

@interface ARTPushActivationStateNotActivated : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateCalledActivate : ARTPushActivationState
@end

@interface ARTPushActivationStateWaitingForUpdateToken : ARTPushActivationState
@end

@interface ARTPushActivationStateWaitingForPushDeviceDetails : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForNewPushDeviceDetails : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForRegistrationUpdate : ARTPushActivationState
@end

@interface ARTPushActivationStateWaitingForDeregistration : ARTPushActivationState
@end

@interface ARTPushActivationStateAfterRegistrationUpdateFailed : ARTPushActivationPersistentState
@end

NS_ASSUME_NONNULL_END
