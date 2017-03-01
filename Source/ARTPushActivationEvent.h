//
//  ARTPushActivationEvent.h
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushActivationEvent : NSObject <NSCoding>

@end

/// Event with Error info
@interface ARTPushActivationErrorEvent : ARTPushActivationEvent

@property (nonatomic, readonly) ARTErrorInfo *error;

- (instancetype)initWithError:(ARTErrorInfo *)error;
+ (instancetype)newWithError:(ARTErrorInfo *)error;

@end

/// Event with Auth credentials
@interface ARTPushActivationAuthEvent : ARTPushActivationEvent

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSString *clientId;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithKey:(NSString *)key clientId:(nullable NSString *)clientId;
+ (instancetype)newWithKey:(NSString *)key clientId:(nullable NSString *)clientId;
- (instancetype)initWithToken:(NSString *)token clientId:(nullable NSString *)clientId;
+ (instancetype)newWithToken:(NSString *)token clientId:(nullable NSString *)clientId;

@end

#pragma mark - Events

@interface ARTPushActivationEventCalledActivate : ARTPushActivationAuthEvent
@end

@interface ARTPushActivationEventCalledDeactivate : ARTPushActivationAuthEvent
@end

@interface ARTPushActivationEventGotPushDeviceDetails : ARTPushActivationEvent
@end

@interface ARTPushActivationEventGotUpdateToken : ARTPushActivationEvent
@end

@interface ARTPushActivationEventGettingUpdateTokenFailed : ARTPushActivationErrorEvent
@end

@interface ARTPushActivationEventRegistrationUpdated : ARTPushActivationEvent
@end

@interface ARTPushActivationEventUpdatingRegistrationFailed : ARTPushActivationErrorEvent
@end

@interface ARTPushActivationEventDeregistered : ARTPushActivationEvent
@end

@interface ARTPushActivationEventDeregistrationFailed : ARTPushActivationErrorEvent
@end

NS_ASSUME_NONNULL_END
