//
//  ARTPushActivationEvent.h
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTErrorInfo;

@interface ARTPushActivationEvent : NSObject <NSCoding>

@end

@interface ARTPushActivationErrorEvent : ARTPushActivationEvent

@property (nonatomic, readonly) ARTErrorInfo *error;

- (instancetype)initWithError:(ARTErrorInfo *)error;
+ (instancetype)newWithError:(ARTErrorInfo *)error;

@end

#pragma mark - Events

@interface ARTPushActivationEventCalledActivate : ARTPushActivationEvent
@end

@interface ARTPushActivationEventCalledDeactivate : ARTPushActivationEvent
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
