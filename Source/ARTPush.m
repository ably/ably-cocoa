//
//  ARTPush.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPush+Private.h"
#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTEventEmitter.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#import "ARTPushActivationStateMachine+Private.h"
#endif
#import "ARTPushAdmin.h"
#import "ARTPushActivationEvent.h"
#import "ARTClientOptions+Private.h"
#import "ARTPushAdmin+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTDeviceStorage.h"
#import "ARTRealtime+Private.h"

@implementation ARTPush {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTPushInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (ARTPushAdmin *)admin {
    return [[ARTPushAdmin alloc] initWithInternal:_internal.admin queuedDealloc:_dealloc];
}

#if TARGET_OS_IOS

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest; {
    return [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken rest:rest];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime; {
    return [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken realtime:realtime];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest; {
    return [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error rest:rest];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime; {
    return [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error realtime:realtime];
}

- (void)activate {
    [_internal activate];
}

- (void)deactivate {
    [_internal deactivate];
}

#endif

@end

NSString *const ARTDeviceIdKey = @"ARTDeviceId";
NSString *const ARTDeviceSecretKey = @"ARTDeviceSecret";
NSString *const ARTDeviceIdentityTokenKey = @"ARTDeviceIdentityToken";
NSString *const ARTDeviceTokenKey = @"ARTDeviceToken";

@implementation ARTPushInternal {
    ARTRestInternal *_rest;
    ARTLog *_logger;
}

- (instancetype)init:(ARTRestInternal *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _admin = [[ARTPushAdminInternal alloc] initWithRest:rest];
    }
    return self;
}

- (dispatch_queue_t)queue {
    return _rest.queue;
}

#if TARGET_OS_IOS

// Store address of once_token to access it in debug function.
static dispatch_once_t *activationMachine_once_token;

- (ARTPushActivationStateMachine *)activationMachine {
    static dispatch_once_t once;
    activationMachine_once_token = &once;
    static id activationMachineInstance;
    dispatch_once(&once, ^{
        activationMachineInstance = [[ARTPushActivationStateMachine alloc] init:self->_rest];
    });
    return activationMachineInstance;
}

- (void)resetActivationStateMachineSingleton {
    if (activationMachine_once_token) *activationMachine_once_token = 0;
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData restInternal:(ARTRestInternal *)rest {
    // HEX string, i.e.: <12ce7dda 8032c423 8f8bd40f 3484e5bb f4698da5 8b7fdf8d 5c55e0a2 XXXXXXXX>
    // Normalizing token by removing symbols and spaces, i.e.: 12ce7dda8032c4238f8bd40f3484e5bbf4698da58b7fdf8d5c55e0a2XXXXXXXX
    NSString *deviceToken = [[[deviceTokenData description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];

    [rest.logger info:@"ARTPush: device token received %@", deviceToken];
    NSString *currentDeviceToken = [rest.storage objectForKey:ARTDeviceTokenKey];
    if ([currentDeviceToken isEqualToString:deviceToken]) {
        // Already stored.
        return;
    }

    [[rest device] setAndPersistDeviceToken:deviceToken];
    [rest.logger debug:@"ARTPush: device token stored"];
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime {
    [realtime internalAsync:^(ARTRealtimeInternal *realtime) {
        [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken restInternal:realtime.rest];
    }];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest {
    [rest internalAsync:^(ARTRestInternal *rest) {
        [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken restInternal:rest];
    }];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error restInternal:(ARTRestInternal *)rest {
    [rest.logger error:@"ARTPush: device token not received (%@)", [error localizedDescription]];
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime {
    [realtime internalAsync:^(ARTRealtimeInternal *realtime) {
        [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error restInternal:realtime.rest];
    }];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest {
    [rest internalAsync:^(ARTRestInternal *rest) {
        [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error restInternal:rest];
    }];
}

- (void)activate {
    if (!self.activationMachine.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // -[UIApplication delegate] is an UI API call
            self.activationMachine.delegate = UIApplication.sharedApplication.delegate;
            [self.activationMachine sendEvent:[ARTPushActivationEventCalledActivate new]];
        });
    }
    else {
        [self.activationMachine sendEvent:[ARTPushActivationEventCalledActivate new]];
    }
}

- (void)deactivate {
    if (!self.activationMachine.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // -[UIApplication delegate] is an UI API call
            self.activationMachine.delegate = UIApplication.sharedApplication.delegate;
            [self.activationMachine sendEvent:[ARTPushActivationEventCalledDeactivate new]];
        });
    }
    else {
        [self.activationMachine sendEvent:[ARTPushActivationEventCalledDeactivate new]];
    }
}

#endif

@end
