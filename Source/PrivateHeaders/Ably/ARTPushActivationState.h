#import <Foundation/Foundation.h>

@class ARTPushActivationStateMachine;
@class ARTPushActivationEvent;
@class ARTInternalLog;

@protocol ARTHTTPAuthenticatedExecutor;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PushActivationState)
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
NS_SWIFT_NAME(PushActivationPersistantState)
@interface ARTPushActivationPersistentState : ARTPushActivationState
@end

#pragma mark - States

NS_SWIFT_NAME(PushActivationStateNotActivated)
@interface ARTPushActivationStateNotActivated : ARTPushActivationPersistentState
@end

NS_SWIFT_NAME(PushActivationStateWaitingForDeviceRegistration)
@interface ARTPushActivationStateWaitingForDeviceRegistration : ARTPushActivationState
@end

NS_SWIFT_NAME(PushActivationStateWaitingForPushDeviceDetails)
@interface ARTPushActivationStateWaitingForPushDeviceDetails : ARTPushActivationPersistentState
@end

NS_SWIFT_NAME(PushActivationStateWaitingForNewPushDeviceDetails)
@interface ARTPushActivationStateWaitingForNewPushDeviceDetails : ARTPushActivationPersistentState
@end

NS_SWIFT_NAME(PushActivationStateWaitingForRegistrationSync)
@interface ARTPushActivationStateWaitingForRegistrationSync : ARTPushActivationState

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger NS_UNAVAILABLE;

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger fromEvent:(ARTPushActivationEvent *)event;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine logger:(ARTInternalLog *)logger fromEvent:(ARTPushActivationEvent *)event;

@property (atomic) ARTPushActivationEvent *fromEvent;

@end

NS_SWIFT_NAME(PushActivationStateAfterRegistrationSyncFailed)
@interface ARTPushActivationStateAfterRegistrationSyncFailed : ARTPushActivationPersistentState
@end

NS_SWIFT_NAME(PushActivationStateWaitingForDeregistration)
@interface ARTPushActivationStateWaitingForDeregistration : ARTPushActivationState
@end

// Deprecated states; kept around for persistence backwards-compatibility

NS_SWIFT_NAME(PushActivationDeprecatedPersistentState)
@interface ARTPushActivationDeprecatedPersistentState : ARTPushActivationPersistentState

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine NS_UNAVAILABLE;
- (nullable ARTPushActivationPersistentState *)migrate;

@end

NS_SWIFT_NAME(PushActivationStateAfterRegistrationUpdateFailed)
@interface ARTPushActivationStateAfterRegistrationUpdateFailed : ARTPushActivationDeprecatedPersistentState
@end

NS_ASSUME_NONNULL_END
