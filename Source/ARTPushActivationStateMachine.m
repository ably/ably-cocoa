//
//  ARTPushActivationStateMachine.m
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushActivationStateMachine.h"
#import "ARTPush.h"
#import "ARTPushActivationEvent.h"
#import "ARTPushActivationState.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTTypes.h"
#import "ARTLocalDevice+Private.h"
#import "ARTDevicePushDetails.h"

#ifdef TARGET_OS_IOS
#import <UIKit/UIKit.h>

NSString *const ARTPushActivationCurrentStateKey = @"ARTPushActivationCurrentState";
NSString *const ARTPushActivationPendingEventsKey = @"ARTPushActivationPendingEvents";

@implementation ARTPushActivationStateMachine {
    ARTPushActivationState *_current;
    NSMutableArray<ARTPushActivationEvent *> *_pendingEvents;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        // Unarquiving
        NSData *stateData = [[NSUserDefaults standardUserDefaults] objectForKey:ARTPushActivationCurrentStateKey];
        _current = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
        if (!_current) {
            _current = [ARTPushActivationStateNotActivated newWithMachine:self];
        }
        NSData *pendingEventsData = [[NSUserDefaults standardUserDefaults] objectForKey:ARTPushActivationPendingEventsKey];
        _pendingEvents = [NSKeyedUnarchiver unarchiveObjectWithData:pendingEventsData];
        if (!_pendingEvents) {
            _pendingEvents = [NSMutableArray array];
        }
    }
    return self;
}

- (void)sendEvent:(ARTPushActivationEvent *)event {
    [self handleEvent:event];
}

- (void)handleEvent:(nonnull ARTPushActivationEvent *)event {
    ARTPushActivationState *maybeNext = [_current transition:event];

    if (maybeNext == nil) {
        [_pendingEvents addObject:event];
        return;
    }

    _current = maybeNext;

    while (true) {
        ARTPushActivationEvent *pending = [_pendingEvents peek];
        if (pending == nil) {
            break;
        }
        maybeNext = [_current transition:pending];
        if (maybeNext == nil) {
            break;
        }
        [_pendingEvents dequeue];

        _current = maybeNext;
    }

    [self persist];
}

- (void)persist {
    // Archiving
    if ([_current isKindOfClass:[ARTPushActivationPersistentState class]]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_current] forKey:ARTPushActivationCurrentStateKey];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_pendingEvents] forKey:ARTPushActivationPendingEventsKey];
}

- (void)deviceRegistration:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;

    if (![[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:@"ARTPushRegistererDelegate must be implemented on AppDelegate" format:@""];
    }

    id delegate = [UIApplication sharedApplication].delegate;

    // Custom register
    SEL customRegisterMethodSelector = @selector(ablyPushCustomRegister:deviceDetails:callback:);
    if ([delegate respondsToSelector:customRegisterMethodSelector]) {
        [delegate ablyPushCustomRegister:error deviceDetails:local callback:^(ARTUpdateToken *updateToken, ARTErrorInfo *error) {
            if (error) {
                // Failed
                [delegate didActivateAblyPush:error];
                [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:error]];
            }
            else if (updateToken) {
                // Success
                [local setAndPersistUpdateToken:updateToken];
                [delegate didActivateAblyPush:nil];
                [self sendEvent:[ARTPushActivationEventGotUpdateToken new]];
            }
            else {
                ARTErrorInfo *missingUpdateTokenError = [ARTErrorInfo createWithCode:0 message:@"UpdateToken is expected"];
                [delegate didActivateAblyPush:missingUpdateTokenError];
                [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:missingUpdateTokenError]];
            }
        }];
        return;
    }

    // Asynchronous HTTP request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_rest defaultEncoder] encodeDeviceDetails:local error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"device registration with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[_rest logger] error:@"%@: device registration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
            return;
        }
        ARTDeviceDetails *deviceDetails = [[_rest defaultEncoder] decodeDeviceDetails:data error:nil];
        [local setAndPersistUpdateToken:deviceDetails.updateToken];
        [self sendEvent:[ARTPushActivationEventGotUpdateToken new]];
    }];
    #endif
}

- (void)deviceUpdateRegistration:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;

    if (![[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:@"ARTPushRegistererDelegate must be implemented on AppDelegate" format:@""];
    }

    id delegate = [UIApplication sharedApplication].delegate;

    // Custom register
    SEL customRegisterMethodSelector = @selector(ablyPushCustomRegister:deviceDetails:callback:);
    if ([delegate respondsToSelector:customRegisterMethodSelector]) {
        [delegate ablyPushCustomRegister:error deviceDetails:local callback:^(ARTUpdateToken *updateToken, ARTErrorInfo *error) {
            if (error) {
                // Failed
                [delegate didActivateAblyPush:error];
                [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:error]];
            }
            else if (updateToken) {
                // Success
                [local setAndPersistUpdateToken:updateToken];
                [delegate didActivateAblyPush:nil];
                [self sendEvent:[ARTPushActivationEventRegistrationUpdated new]];
            }
            else {
                ARTErrorInfo *missingUpdateTokenError = [ARTErrorInfo createWithCode:0 message:@"UpdateToken is expected"];
                [delegate didActivateAblyPush:missingUpdateTokenError];
                [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:missingUpdateTokenError]];
            }
        }];
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:local.id]];
    NSData *tokenData = [local.updateToken dataUsingEncoding:NSUTF8StringEncoding];
    NSString *tokenBase64 = [tokenData base64EncodedStringWithOptions:0];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", tokenBase64] forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = @"PATCH";
    request.HTTPBody = [[_rest defaultEncoder] encode:@{
        @"push": @{
            @"recipient": local.push.recipient
        }
    } error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"update device with request %@", request];
    [_rest executeRequest:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[_rest logger] error:@"%@: update device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
            return;
        }
        ARTDeviceDetails *deviceDetails = [[_rest defaultEncoder] decodeDeviceDetails:data error:nil];
        [local setAndPersistUpdateToken:deviceDetails.updateToken];
        [self sendEvent:[ARTPushActivationEventRegistrationUpdated new]];
    }];
    #endif
}

- (void)deviceUnregistration:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;

    id delegate = [UIApplication sharedApplication].delegate;

    // Custom register
    SEL customDeregisterMethodSelector = @selector(ablyPushCustomDeregister:deviceId:callback:);
    if ([delegate respondsToSelector:customDeregisterMethodSelector]) {
        [delegate ablyPushCustomDeregister:error deviceId:local.id callback:^(ARTErrorInfo *error) {
            if (error) {
                // Failed
                [delegate didDeactivateAblyPush:error];
                [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:error]];
            }
            else {
                // Success
                [delegate didDeactivateAblyPush:nil];
            }
        }];
        return;
    }

    // Asynchronous HTTP request
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"deviceId" value:local.id],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"device deregistration with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[_rest logger] error:@"%@: device deregistration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
        }

        [[_rest logger] debug:__FILE__ line:__LINE__ message:@"successfully deactivate device"];
        [self sendEvent:[ARTPushActivationEventDeregistered new]];
    }];
    #endif
}

- (void)callActivatedCallback:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        id delegate = [UIApplication sharedApplication].delegate;
        SEL activateCallbackMethodSelector = @selector(didActivateAblyPush:);
        if ([delegate respondsToSelector:activateCallbackMethodSelector]) {
            [delegate didActivateAblyPush:error];
        }
    }
    #endif
}

- (void)callDeactivatedCallback:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        id delegate = [UIApplication sharedApplication].delegate;
        SEL deactivateCallbackMethodSelector = @selector(didDeactivateAblyPush:);
        if ([delegate respondsToSelector:deactivateCallbackMethodSelector]) {
            [delegate didDeactivateAblyPush:error];
        }
    }
    #endif
}

- (void)callUpdateFailedCallback:(nullable ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        id delegate = [UIApplication sharedApplication].delegate;
        SEL updateFailedCallbackMethodSelector = @selector(didAblyPushRegistrationFail:);
        if ([delegate respondsToSelector:updateFailedCallbackMethodSelector]) {
            [delegate didAblyPushRegistrationFail:error];
        }
    }
    #endif
}

@end

#endif
