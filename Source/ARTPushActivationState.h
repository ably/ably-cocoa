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

- (nullable ARTPushActivationState *)transition:(ARTPushActivationEvent *)event;

@end

@interface ARTPushActivationNotActivatedState : ARTPushActivationState
@end

@interface ARTPushActivationCalledActivateState : ARTPushActivationState
@end

@interface ARTPushActivationWaitingForUpdateTokenState : ARTPushActivationState
@end

@interface ARTPushActivationWaitingForPushDeviceDetailsState : ARTPushActivationState
@end

@interface ARTPushActivationWaitingForNewPushDeviceDetailsState : ARTPushActivationState
@end

@interface ARTPushActivationWaitingForRegistrationUpdateState : ARTPushActivationState
@end

@interface ARTPushActivationWaitingForDeregistrationState : ARTPushActivationState
@end

@interface ARTPushActivationAfterRegistrationUpdateFailedState : ARTPushActivationState
@end

NS_ASSUME_NONNULL_END
