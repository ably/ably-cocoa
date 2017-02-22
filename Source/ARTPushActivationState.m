//
//  ARTPushActivationState.m
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushActivationState.h"
#import "ARTPushActivationStateMachine.h"
#import "ARTPushActivationEvent.h"
#import "ARTLog.h"

@interface ARTPushActivationState ()

@property (atomic, readonly) ARTPushActivationStateMachine *machine;

@end

@implementation ARTPushActivationState

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine {
    if (self = [super init]) {
        _machine = machine;
    }
    return self;
}

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    NSAssert(false, @"-[%s:%d %s] should always be overriden.", __FILE__, __LINE__, __FUNCTION__);
    return nil;
}

- (void)logEventTransition:(ARTPushActivationEvent *)event file:(const char *)file line:(NSUInteger)line {
    [[self.machine logger] debug:__FILE__ line:__LINE__ message:@"%@ state: transitioning to %@ event", NSStringFromClass(self.class), NSStringFromClass(event.class)];
}

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


#pragma mark - Activation States

@implementation ARTPushActivationNotActivatedState

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    if ([event isKindOfClass:[ARTPushActivationCalledDeactivateEvent class]]) {
        [self logEventTransition:event file:__FILE__ line:__LINE__];
        // TODO
    }
    else if ([event isKindOfClass:[ARTPushActivationCalledActivateEvent class]]) {
        [self logEventTransition:event file:__FILE__ line:__LINE__];
        // TODO
    }
    return nil;
}

@end

@implementation ARTPushActivationCalledActivateState

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationWaitingForUpdateTokenState

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationWaitingForPushDeviceDetailsState

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationWaitingForNewPushDeviceDetailsState

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationWaitingForRegistrationUpdateState

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationWaitingForDeregistrationState

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationAfterRegistrationUpdateFailedState

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end
