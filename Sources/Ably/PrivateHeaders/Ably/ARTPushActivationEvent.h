#import <Foundation/Foundation.h>

@class ARTErrorInfo;
@class ARTPushActivationState;
@class ARTDeviceIdentityTokenDetails;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushActivationEvent : NSObject <NSSecureCoding>

- (NSData *)archiveWithLogger:(nullable ARTInternalLog *)logger;
+ (nullable ARTPushActivationState *)unarchive:(NSData *)data withLogger:(nullable ARTInternalLog *)logger;

@end

/// Event with Error info
@interface ARTPushActivationErrorEvent : ARTPushActivationEvent

@property (nonatomic, readonly) ARTErrorInfo *error;

- (instancetype)initWithError:(ARTErrorInfo *)error;
+ (instancetype)newWithError:(ARTErrorInfo *)error;

@end

/// Event with Device Identity Token details
@interface ARTPushActivationDeviceIdentityEvent : ARTPushActivationEvent

@property (nonatomic, readonly, nullable) ARTDeviceIdentityTokenDetails *identityTokenDetails;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new;

- (instancetype)initWithIdentityTokenDetails:(nullable ARTDeviceIdentityTokenDetails *)identityTokenDetails;
+ (instancetype)newWithIdentityTokenDetails:(ARTDeviceIdentityTokenDetails *)identityTokenDetails;

@end

#pragma mark - Events

@interface ARTPushActivationEventCalledActivate : ARTPushActivationEvent
@end

@interface ARTPushActivationEventCalledDeactivate : ARTPushActivationEvent
@end

@interface ARTPushActivationEventGotPushDeviceDetails : ARTPushActivationEvent
@end

@interface ARTPushActivationEventGettingPushDeviceDetailsFailed : ARTPushActivationErrorEvent
@end

@interface ARTPushActivationEventGotDeviceRegistration : ARTPushActivationDeviceIdentityEvent
@end

@interface ARTPushActivationEventGettingDeviceRegistrationFailed : ARTPushActivationErrorEvent
@end

@interface ARTPushActivationEventRegistrationSynced : ARTPushActivationDeviceIdentityEvent
@end

@interface ARTPushActivationEventSyncRegistrationFailed : ARTPushActivationErrorEvent
@end

@interface ARTPushActivationEventDeregistered : ARTPushActivationEvent
@end

@interface ARTPushActivationEventDeregistrationFailed : ARTPushActivationErrorEvent
@end

NS_ASSUME_NONNULL_END
