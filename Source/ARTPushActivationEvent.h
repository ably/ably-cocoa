//
//  ARTPushActivationEvent.h
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARTPushActivationEvent : NSObject

@end

@interface ARTPushActivationCalledActivateEvent : ARTPushActivationEvent
@end

@interface ARTPushActivationCalledDeactivateEvent : ARTPushActivationEvent
@end

@interface ARTPushActivationGotPushDeviceDetailsEvent : ARTPushActivationEvent
@end

@interface ARTPushActivationGotUpdateTokenEvent : ARTPushActivationEvent
@end

@interface ARTPushActivationGettingUpdateTokenFailedEvent : ARTPushActivationEvent
@end

@interface ARTPushActivationRegistrationUpdatedEvent : ARTPushActivationEvent
@end

@interface ARTPushActivationUpdatingRegistrationFailedEvent : ARTPushActivationEvent
@end

@interface ARTPushActivationDeregisteredEvent : ARTPushActivationEvent
@end

@interface ARTPushActivationDeregistrationFailedEvent : ARTPushActivationEvent
@end
