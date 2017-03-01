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

#pragma mark - Persistent State with Auth credentials

@implementation ARTPushActivationAuthState

- (instancetype)initWithKey:(NSString *)key machine:(ARTPushActivationStateMachine *)machine clientId:(NSString *)clientId {
    if (self = [super initWithMachine:machine]) {
        _key = key;
        _clientId = clientId;
    }
    return self;
}

+ (instancetype)newWithKey:(NSString *)key machine:(ARTPushActivationStateMachine *)machine clientId:(NSString *)clientId {
    return [[self alloc] initWithKey:key clientId:clientId];
}

- (instancetype)initWithToken:(NSString *)token machine:(ARTPushActivationStateMachine *)machine clientId:(NSString *)clientId {
    if (self = [super initWithMachine:machine]) {
        _token = token;
        _clientId = clientId;
    }
    return self;
}

+ (instancetype)newWithToken:(NSString *)token machine:(ARTPushActivationStateMachine *)machine clientId:(NSString *)clientId {
    return [[self alloc] initWithToken:token clientId:clientId];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _key = [aDecoder decodeObjectForKey:@"key"];
        _token = [aDecoder decodeObjectForKey:@"token"];
        _clientId = [aDecoder decodeObjectForKey:@"clientId"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.token forKey:@"token"];
    [aCoder encodeObject:self.clientId forKey:@"clientId"];
}

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
        ARTPushActivationEventCalledActivate *activateEvent = (ARTPushActivationEventCalledActivate *)event;
        ARTLocalDevice *local = [ARTLocalDevice local];

        if (local.updateToken != nil) {
            // Already registered.
            if (activateEvent.key) {
                return [ARTPushActivationStateWaitingForNewPushDeviceDetails newWithKey:activateEvent.key machine:self.machine clientId:activateEvent.clientId];
            }
            if (activateEvent.token) {
                return [ARTPushActivationStateWaitingForNewPushDeviceDetails newWithToken:activateEvent.token machine:self.machine clientId:activateEvent.clientId];
            }
            return nil;
        }

        if (local.registrationToken != nil) {
            [self.machine sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
        }

        if (activateEvent.key) {
            return [ARTPushActivationStateWaitingForPushDeviceDetails newWithKey:activateEvent.key machine:self.machine clientId:activateEvent.clientId];
        }
        if (activateEvent.token) {
            return [ARTPushActivationStateWaitingForPushDeviceDetails newWithToken:activateEvent.token machine:self.machine clientId:activateEvent.clientId];
        }
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
        id<ARTHTTPAuthenticatedExecutor> httpExecutor;
        if (self.key) {
            httpExecutor = [ARTRest createWithKey:self.key];
        }
        else if (self.token) {
            httpExecutor = [ARTRest createWithToken:self.token];
        }
        else {
            [NSException raise:@"ARTPushActivationStateWaitingForPushDeviceDetails: must have a key or token for authentication" format:@""];
        }
        [self.machine deviceRegistration:httpExecutor error:nil];
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
