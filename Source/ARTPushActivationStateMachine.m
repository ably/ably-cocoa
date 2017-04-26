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
#import "ARTLocalDeviceStorage.h"

#ifdef TARGET_OS_IOS
#import <UIKit/UIKit.h>

NSString *const ARTPushException = @"ARTPushException";

NSString *const ARTPushActivationCurrentStateKey = @"ARTPushActivationCurrentState";
NSString *const ARTPushActivationPendingEventsKey = @"ARTPushActivationPendingEvents";

@implementation ARTPushActivationStateMachine {
    NSMutableArray<ARTPushActivationEvent *> *_pendingEvents;
    id<ARTDeviceStorage> _storage;
}

- (instancetype)init:(ARTRest *)rest {
    return [self init:rest storage:[ARTLocalDeviceStorage new]];
}

- (instancetype)init:(ARTRest *)rest storage:(id<ARTDeviceStorage>)storage {
    if (self = [super init]) {
        _rest = rest;
        _storage = storage;
        // Unarquiving
        NSData *stateData = [_storage readKey:ARTPushActivationCurrentStateKey];
        _current = [ARTPushActivationState unarchive:stateData];
        if (!_current) {
            _current = [ARTPushActivationStateNotActivated newWithMachine:self];
        }
        else {
            _current.machine = self;
        }
        NSData *pendingEventsData = [_storage readKey:ARTPushActivationPendingEventsKey];
        _pendingEvents = [NSKeyedUnarchiver unarchiveObjectWithData:pendingEventsData];
        if (!_pendingEvents) {
            _pendingEvents = [NSMutableArray array];
        }
    }
    return self;
}

- (id)delegate {
    if (!_delegate) {
        _delegate = [UIApplication sharedApplication].delegate;
    }
    return _delegate;
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
        [_storage writeKey:ARTPushActivationCurrentStateKey withValue:[_current archive]];
    }
    [_storage writeKey:ARTPushActivationPendingEventsKey withValue:[NSKeyedArchiver archivedDataWithRootObject:_pendingEvents]];
}

- (void)deviceRegistration:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;

    if (![[self delegate] conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:ARTPushException format:@"ARTPushRegistererDelegate must be implemented"];
    }

    // Custom register
    SEL customRegisterMethodSelector = @selector(ablyPushCustomRegister:deviceDetails:callback:);
    if ([[self delegate] respondsToSelector:customRegisterMethodSelector]) {
        [[self delegate] ablyPushCustomRegister:error deviceDetails:local callback:^(ARTUpdateToken *updateToken, ARTErrorInfo *error) {
            if (error) {
                // Failed
                [[self delegate] didActivateAblyPush:error];
                [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:error]];
            }
            else if (updateToken) {
                // Success
                [local setAndPersistUpdateToken:updateToken];
                [[self delegate] didActivateAblyPush:nil];
                [self sendEvent:[ARTPushActivationEventGotUpdateToken new]];
            }
            else {
                ARTErrorInfo *missingUpdateTokenError = [ARTErrorInfo createWithCode:0 message:@"UpdateToken is expected"];
                [[self delegate] didActivateAblyPush:missingUpdateTokenError];
                [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:missingUpdateTokenError]];
            }
        }];
        return;
    }

    // Asynchronous HTTP request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_rest defaultEncoder] encodeDeviceDetails:local];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"device registration with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[_rest logger] error:@"%@: device registration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:[ARTErrorInfo createWithNSError:error]]];
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

    if (![[self delegate] conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:ARTPushException format:@"ARTPushRegistererDelegate must be implemented"];
    }

    // Custom register
    SEL customRegisterMethodSelector = @selector(ablyPushCustomRegister:deviceDetails:callback:);
    if ([[self delegate] respondsToSelector:customRegisterMethodSelector]) {
        [[self delegate] ablyPushCustomRegister:error deviceDetails:local callback:^(ARTUpdateToken *updateToken, ARTErrorInfo *error) {
            if (error) {
                // Failed
                [[self delegate] didActivateAblyPush:error];
                [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:error]];
            }
            else if (updateToken) {
                // Success
                [local setAndPersistUpdateToken:updateToken];
                [[self delegate] didActivateAblyPush:nil];
                [self sendEvent:[ARTPushActivationEventRegistrationUpdated new]];
            }
            else {
                ARTErrorInfo *missingUpdateTokenError = [ARTErrorInfo createWithCode:0 message:@"UpdateToken is expected"];
                [[self delegate] didActivateAblyPush:missingUpdateTokenError];
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
    }];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"update device with request %@", request];
    [_rest executeRequest:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[_rest logger] error:@"%@: update device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:[ARTErrorInfo createWithNSError:error]]];
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

    // Custom register
    SEL customDeregisterMethodSelector = @selector(ablyPushCustomDeregister:deviceId:callback:);
    if ([[self delegate] respondsToSelector:customDeregisterMethodSelector]) {
        [[self delegate] ablyPushCustomDeregister:error deviceId:local.id callback:^(ARTErrorInfo *error) {
            if (error) {
                [[self delegate] didDeactivateAblyPush:error];
                [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:error]];
                return;
            }
            [[self delegate] didDeactivateAblyPush:nil];
            [self sendEvent:[ARTPushActivationEventDeregistered new]];
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
            [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:[ARTErrorInfo createWithNSError:error]]];
            return;
        }
        [[_rest logger] debug:__FILE__ line:__LINE__ message:@"successfully deactivate device"];
        [self sendEvent:[ARTPushActivationEventDeregistered new]];
    }];
    #endif
}

- (void)callActivatedCallback:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[self delegate] conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        SEL activateCallbackMethodSelector = @selector(didActivateAblyPush:);
        if ([[self delegate] respondsToSelector:activateCallbackMethodSelector]) {
            [[self delegate] didActivateAblyPush:error];
        }
    }
    #endif
}

- (void)callDeactivatedCallback:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[self delegate] conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        SEL deactivateCallbackMethodSelector = @selector(didDeactivateAblyPush:);
        if ([[self delegate] respondsToSelector:deactivateCallbackMethodSelector]) {
            [[self delegate] didDeactivateAblyPush:error];
        }
    }
    #endif
}

- (void)callUpdateFailedCallback:(nullable ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[self delegate] conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        SEL updateFailedCallbackMethodSelector = @selector(didAblyPushRegistrationFail:);
        if ([[self delegate] respondsToSelector:updateFailedCallbackMethodSelector]) {
            [[self delegate] didAblyPushRegistrationFail:error];
        }
    }
    #endif
}

@end

#endif
