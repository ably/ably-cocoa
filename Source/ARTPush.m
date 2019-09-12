//
//  ARTPush.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPush.h"
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

NSString *const ARTDeviceIdKey = @"ARTDeviceId";
NSString *const ARTDeviceSecretKey = @"ARTDeviceSecret";
NSString *const ARTDeviceIdentityTokenKey = @"ARTDeviceIdentityToken";
NSString *const ARTDeviceTokenKey = @"ARTDeviceToken";

@implementation ARTPush {
    ARTRest *_rest;
    __weak ARTLog *_logger;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _admin = [[ARTPushAdmin alloc] initWithRest:rest];
    }
    return self;
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

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData rest:(ARTRest *)rest {
    NSLog(@"ARTPush: device token data received: %@", [deviceTokenData base64EncodedStringWithOptions:0]);

    NSUInteger dataLength = deviceTokenData.length;
    const unsigned char *dataBuffer = deviceTokenData.bytes;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }

    NSString *deviceToken = [hexString copy];

    NSLog(@"ARTPush: device token: %@", deviceToken);
    NSString *currentDeviceToken = [rest.storage objectForKey:ARTDeviceTokenKey];
    if ([currentDeviceToken isEqualToString:deviceToken]) {
        // Already stored.
        return;
    }

    [[rest device] setAndPersistDeviceToken:deviceToken];
    NSLog(@"ARTPush: device token stored");
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime {
    [ARTPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken rest:realtime.rest];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest {
    NSLog(@"ARTPush: device token not received (%@)", [error localizedDescription]);
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime {
    [ARTPush didFailToRegisterForRemoteNotificationsWithError:error rest:realtime.rest];
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
