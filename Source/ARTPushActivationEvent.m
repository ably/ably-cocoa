//
//  ARTPushActivationEvent.m
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushActivationEvent.h"
#import "ARTTypes.h"

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

#pragma mark - Event with Error info

@implementation ARTPushActivationErrorEvent

- (instancetype)initWithError:(ARTErrorInfo *)error {
    if (self = [super init]) {
        _error = error;
    }
    return self;
}

+ (instancetype)newWithError:(ARTErrorInfo *)error {
    return [[self alloc] initWithError:error];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _error = [aDecoder decodeObjectForKey:@"error"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.error forKey:@"error"];
}

@end

#pragma mark - Activation Events

@implementation ARTPushActivationEventCalledActivate
@end

@implementation ARTPushActivationEventCalledDeactivate
@end

@implementation ARTPushActivationEventGotPushDeviceDetails
@end

@implementation ARTPushActivationEventGotUpdateToken
@end

@implementation ARTPushActivationEventGettingUpdateTokenFailed
@end

@implementation ARTPushActivationEventRegistrationUpdated
@end

@implementation ARTPushActivationEventUpdatingRegistrationFailed
@end

@implementation ARTPushActivationEventDeregistered
@end

@implementation ARTPushActivationEventDeregistrationFailed
@end
