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
#import "ARTLocalDevice+Private.h"
#import "ARTDevicePushDetails.h"
#import "ARTLog.h"
#import "ARTRest+Private.h"
#import "ARTHttp.h"

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
    NSAssert(false, @"-[%s:%d %s] should always be overriden; class %@ doesn't.", __FILE__, __LINE__, __FUNCTION__, NSStringFromClass(self.class));
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
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine callDeactivatedCallback:nil];
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        ARTLocalDevice *local = [ARTLocalDevice load:self.machine.rest];

        if (local.updateToken != nil) {
            // Already registered.
            return [[ARTPushActivationStateWaitingForNewPushDeviceDetails alloc] initWithMachine:self.machine];
        }

        if ([local deviceToken] != nil) {
            [self.machine sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
        }

        return [[ARTPushActivationStateWaitingForPushDeviceDetails alloc] initWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForUpdateToken

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGotUpdateToken class]]) {
        [ARTLocalDevice load:self.machine.rest].updateToken = [[NSUserDefaults standardUserDefaults] stringForKey:ARTDeviceUpdateTokenKey];
        [self.machine callActivatedCallback:nil];
        return [[ARTPushActivationStateWaitingForNewPushDeviceDetails alloc] initWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGettingUpdateTokenFailed class]]) {
        [self.machine callActivatedCallback:[(ARTPushActivationEventGettingUpdateTokenFailed *)event error]];
        return [[ARTPushActivationStateNotActivated alloc] initWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForPushDeviceDetails

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine callDeactivatedCallback:nil];
        return [[ARTPushActivationStateNotActivated alloc] initWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGotPushDeviceDetails class]]) {
        [self.machine deviceRegistration:nil];
        return [[ARTPushActivationStateWaitingForUpdateToken alloc] initWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForNewPushDeviceDetails

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        [self.machine callActivatedCallback:nil];
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine deviceUnregistration:nil];
        return [[ARTPushActivationStateWaitingForDeregistration alloc] initWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGotPushDeviceDetails class]]) {
        [self.machine deviceUpdateRegistration:nil];
        return [[ARTPushActivationStateWaitingForRegistrationUpdate alloc] initWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForRegistrationUpdate

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        [self.machine callActivatedCallback:nil];
        return [[ARTPushActivationStateWaitingForNewPushDeviceDetails alloc] initWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventRegistrationUpdated class]]) {
        return [[ARTPushActivationStateWaitingForNewPushDeviceDetails alloc] initWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventUpdatingRegistrationFailed class]]) {
        [self.machine callUpdateFailedCallback:[(ARTPushActivationEventUpdatingRegistrationFailed *)event error]];
        return [[ARTPushActivationStateAfterRegistrationUpdateFailed alloc] initWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateAfterRegistrationUpdateFailed

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]] ||
        [event isKindOfClass:[ARTPushActivationEventGotPushDeviceDetails class]]) {
        [self.machine deviceRegistration:nil];
        return [[ARTPushActivationStateWaitingForUpdateToken alloc] initWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine callDeactivatedCallback:nil];
        return [[ARTPushActivationStateNotActivated alloc] initWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForDeregistration

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        return [[ARTPushActivationStateWaitingForDeregistration alloc] initWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventDeregistered class]]) {
        ARTLocalDevice *local = [ARTLocalDevice load:self.machine.rest];
        local.updateToken = nil;
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:ARTDeviceUpdateTokenKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.machine callDeactivatedCallback:nil];
        return [[ARTPushActivationStateNotActivated alloc] initWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventDeregistrationFailed class]]) {
        [self.machine callDeactivatedCallback:[(ARTPushActivationEventDeregistrationFailed *)event error]];
        return [[ARTPushActivationStateWaitingForDeregistration alloc] initWithMachine:self.machine];
    }
    return nil;

}

@end
