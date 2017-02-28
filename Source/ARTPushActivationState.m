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
#import "ARTLocalDevice.h"
#import "ARTDevicePushDetails.h"
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

+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine {
    return [[ARTPushActivationState alloc] initWithMachine:machine];
}

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    NSAssert(false, @"-[%s:%d %s] should always be overriden.", __FILE__, __LINE__, __FUNCTION__);
    return nil;
}

- (void)logEventTransition:(ARTPushActivationEvent *)event file:(const char *)file line:(NSUInteger)line {
    NSLog(@"%@ state: transitioning to %@ event", NSStringFromClass(self.class), NSStringFromClass(event.class));
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

#pragma mark - Persistent State

@implementation ARTPushActivationPersistentState
@end

#pragma mark - Activation States

@implementation ARTPushActivationStateNotActivated

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self logEventTransition:event file:__FILE__ line:__LINE__];
        [self.machine callDeactivatedCallback:nil];
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        [self logEventTransition:event file:__FILE__ line:__LINE__];
        ARTLocalDevice *local = [ARTLocalDevice local];

        if (local.updateToken != nil) {
            // Already registered.
            return [ARTPushActivationStateWaitingForNewPushDeviceDetails newWithMachine:self.machine];
        }

        if (local.registrationToken == nil) {
            [self.machine sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
        }

        return [ARTPushActivationStateWaitingForPushDeviceDetails newWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateCalledActivate

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForUpdateToken

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForPushDeviceDetails

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        return [ARTPushActivationStateCalledActivate newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine callDeactivatedCallback:nil];
        return [ARTPushActivationStateNotActivated newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGotPushDeviceDetails class]]) {
        [self.machine deviceRegistration:nil];
        return [ARTPushActivationStateWaitingForUpdateToken newWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForNewPushDeviceDetails

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForRegistrationUpdate

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForDeregistration

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end

@implementation ARTPushActivationStateAfterRegistrationUpdateFailed

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    // TODO
    return nil;
}

@end
