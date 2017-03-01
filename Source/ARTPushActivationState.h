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

@protocol ARTHTTPAuthenticatedExecutor;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushActivationState : NSObject <NSCoding>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine;
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine;

- (nullable ARTPushActivationState *)transition:(ARTPushActivationEvent *)event;

@end

/// Persistent State
@interface ARTPushActivationPersistentState : ARTPushActivationState
@end

/// Persistent State with Auth credentials
@interface ARTPushActivationAuthState : ARTPushActivationPersistentState

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSString *clientId;

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine NS_UNAVAILABLE;

- (instancetype)initWithKey:(NSString *)key machine:(ARTPushActivationStateMachine *)machine clientId:(nullable NSString *)clientId;
+ (instancetype)newWithKey:(NSString *)key machine:(ARTPushActivationStateMachine *)machine clientId:(nullable NSString *)clientId;
- (instancetype)initWithToken:(NSString *)token machine:(ARTPushActivationStateMachine *)machine clientId:(nullable NSString *)clientId;
+ (instancetype)newWithToken:(NSString *)token machine:(ARTPushActivationStateMachine *)machine clientId:(nullable NSString *)clientId;

@end

#pragma mark - States

@interface ARTPushActivationStateNotActivated : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateCalledActivate : ARTPushActivationState
@end

@interface ARTPushActivationStateWaitingForUpdateToken : ARTPushActivationState
@end

@interface ARTPushActivationStateWaitingForPushDeviceDetails : ARTPushActivationAuthState
@end

@interface ARTPushActivationStateWaitingForNewPushDeviceDetails : ARTPushActivationAuthState
@end

@interface ARTPushActivationStateWaitingForRegistrationUpdate : ARTPushActivationState
@end

@interface ARTPushActivationStateWaitingForDeregistration : ARTPushActivationState
@end

@interface ARTPushActivationStateAfterRegistrationUpdateFailed : ARTPushActivationPersistentState
@end

NS_ASSUME_NONNULL_END
