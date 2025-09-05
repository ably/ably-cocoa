#import <Foundation/Foundation.h>

@class ARTPushActivationStateMachine;
@class ARTPushActivationEvent;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushActivationState : NSObject <NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger;
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger;

@property (atomic, nullable) ARTPushActivationStateMachine *machine;

- (nullable ARTPushActivationState *)transition:(ARTPushActivationEvent *)event;

- (NSData *)archive;
+ (nullable ARTPushActivationState *)unarchive:(NSData *)data withLogger:(nullable ARTInternalLog *)logger;

@end

/// Persistent State
@interface ARTPushActivationPersistentState : ARTPushActivationState
@end

#pragma mark - States

@interface ARTPushActivationStateNotActivated : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForDeviceRegistration : ARTPushActivationState
@end

@interface ARTPushActivationStateWaitingForPushDeviceDetails : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForNewPushDeviceDetails : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForRegistrationSync : ARTPushActivationState

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger NS_UNAVAILABLE;

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger fromEvent:(ARTPushActivationEvent *)event;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger fromEvent:(ARTPushActivationEvent *)event;

@property (atomic) ARTPushActivationEvent *fromEvent;

@end

@interface ARTPushActivationStateAfterRegistrationSyncFailed : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForDeregistration : ARTPushActivationState
@end

// Deprecated states; kept around for persistence backwards-compatibility

@interface ARTPushActivationDeprecatedPersistentState : ARTPushActivationPersistentState

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine NS_UNAVAILABLE;
- (nullable ARTPushActivationPersistentState *)migrate;

@end

@interface ARTPushActivationStateAfterRegistrationUpdateFailed : ARTPushActivationDeprecatedPersistentState
@end

NS_ASSUME_NONNULL_END
