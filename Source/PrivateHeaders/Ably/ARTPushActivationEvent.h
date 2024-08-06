#import <Foundation/Foundation.h>

@class ARTErrorInfo;
@class ARTPushActivationState;
@class ARTDeviceIdentityTokenDetails;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PushActivationEvent)
@interface ARTPushActivationEvent : NSObject <NSSecureCoding>

- (NSData *)archiveWithLogger:(nullable ARTInternalLog *)logger;
+ (nullable ARTPushActivationState *)unarchive:(NSData *)data withLogger:(nullable ARTInternalLog *)logger;

@end

/// Event with Error info
NS_SWIFT_NAME(PushActivationErrorEvent)
@interface ARTPushActivationErrorEvent : ARTPushActivationEvent

@property (nonatomic, readonly) ARTErrorInfo *error;

- (instancetype)initWithError:(ARTErrorInfo *)error;
+ (instancetype)newWithError:(ARTErrorInfo *)error;

@end

/// Event with Device Identity Token details
NS_SWIFT_NAME(PushActivationDeviceIdentityEvent)
@interface ARTPushActivationDeviceIdentityEvent : ARTPushActivationEvent

@property (nonatomic, readonly, nullable) ARTDeviceIdentityTokenDetails *identityTokenDetails;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new;

- (instancetype)initWithIdentityTokenDetails:(nullable ARTDeviceIdentityTokenDetails *)identityTokenDetails;
+ (instancetype)newWithIdentityTokenDetails:(ARTDeviceIdentityTokenDetails *)identityTokenDetails;

@end

#pragma mark - Events

NS_SWIFT_NAME(PushActivationEventCalledActivate)
@interface ARTPushActivationEventCalledActivate : ARTPushActivationEvent
@end

NS_SWIFT_NAME(PushActivationEventCalledDeactivate)
@interface ARTPushActivationEventCalledDeactivate : ARTPushActivationEvent
@end

NS_SWIFT_NAME(PushActivationEventGotPushDeviceDetails)
@interface ARTPushActivationEventGotPushDeviceDetails : ARTPushActivationEvent
@end

NS_SWIFT_NAME(PushActivationEventGettingPushDeviceDetailsFailed)
@interface ARTPushActivationEventGettingPushDeviceDetailsFailed : ARTPushActivationErrorEvent
@end

NS_SWIFT_NAME(PushActivationEventGotDeviceRegistration)
@interface ARTPushActivationEventGotDeviceRegistration : ARTPushActivationDeviceIdentityEvent
@end

NS_SWIFT_NAME(PushActivationEventGettingDeviceRegistrationFailed)
@interface ARTPushActivationEventGettingDeviceRegistrationFailed : ARTPushActivationErrorEvent
@end

NS_SWIFT_NAME(PushActivationEventRegistrationSynced)
@interface ARTPushActivationEventRegistrationSynced : ARTPushActivationDeviceIdentityEvent
@end

NS_SWIFT_NAME(PushActivationEventSyncRegistrationFailed)
@interface ARTPushActivationEventSyncRegistrationFailed : ARTPushActivationErrorEvent
@end

NS_SWIFT_NAME(PushActivationEventDeregistered)
@interface ARTPushActivationEventDeregistered : ARTPushActivationEvent
@end

NS_SWIFT_NAME(PushActivationEventDeregistrationFailed)
@interface ARTPushActivationEventDeregistrationFailed : ARTPushActivationErrorEvent
@end

NS_ASSUME_NONNULL_END
