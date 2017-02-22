//
//  ARTPushActivationEvent.m
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushActivationEvent.h"

@implementation ARTPushActivationEvent

- (id)copyWithZone:(NSZone *)zone {
    // Implement NSCopying by retaining the original instead of creating a new copy when the class and its contents are immutable.
    return self;
}

#pragma mark - NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    // Just to persist the class info, no properties
}

@end

@implementation ARTPushActivationCalledActivateEvent
@end

@implementation ARTPushActivationCalledDeactivateEvent
@end

@implementation ARTPushActivationGotPushDeviceDetailsEvent
@end

@implementation ARTPushActivationGotUpdateTokenEvent
@end

@implementation ARTPushActivationGettingUpdateTokenFailedEvent
@end

@implementation ARTPushActivationRegistrationUpdatedEvent
@end

@implementation ARTPushActivationUpdatingRegistrationFailedEvent
@end

@implementation ARTPushActivationDeregisteredEvent
@end

@implementation ARTPushActivationDeregistrationFailedEvent
@end
