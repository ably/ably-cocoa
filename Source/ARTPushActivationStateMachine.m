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
#import "ARTLocalDevice.h"
#import "ARTDevicePushDetails.h"

#ifdef TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NSString *const ARTPushActivationCurrentStateKey = @"ARTPushActivationCurrentState";
NSString *const ARTPushActivationPendingEventsKey = @"ARTPushActivationPendingEvents";

@implementation ARTPushActivationStateMachine {
    ARTPushActivationState *_current;
    NSMutableArray<ARTPushActivationEvent *> *_pendingEvents;
    id<ARTHTTPAuthenticatedExecutor> _httpExecutor;

}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor {
    if (self = [super init]) {
        _httpExecutor = httpExecutor;
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
    // Arquiving
    if ([_current isKindOfClass:[ARTPushActivationPersistentState class]]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_current] forKey:ARTPushActivationCurrentStateKey];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_pendingEvents] forKey:ARTPushActivationPendingEventsKey];
}

- (void)deviceRegistration:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    ARTLocalDevice *local = [ARTLocalDevice local];

    if (![[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:@"ARTPushRegistererDelegate must be implemented on AppDelegate" format:@""];
    }

    id delegate = [UIApplication sharedApplication].delegate;

    // Custom register
    SEL customRegisterMethodSelector = @selector(ablyPushCustomRegister:deviceDetails:callback:);
    if ([delegate respondsToSelector:customRegisterMethodSelector]) {
        [delegate ablyPushCustomRegister:error deviceDetails:local callback:^(ARTUpdateToken *updateToken, ARTErrorInfo *error) {
            if (![delegate respondsToSelector:@selector(ablyPushActivateCallback:)]) {
                [NSException raise:@"ablyPushRegisterCallback: method is required" format:@""];
            }
            if (error) {
                // Failed
                [delegate ablyPushActivateCallback:error];
                [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:error]];
            }
            else if (updateToken) {
                // Success
                [delegate ablyPushActivateCallback:nil];
                [[NSUserDefaults standardUserDefaults] setObject:updateToken forKey:ARTDeviceUpdateTokenKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self sendEvent:[ARTPushActivationEventGotUpdateToken new]];
            }
            else {
                ARTErrorInfo *missingUpdateTokenError = [ARTErrorInfo createWithCode:0 message:@"UpdateToken is expected"];
                [delegate ablyPushActivateCallback:missingUpdateTokenError];
                [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:missingUpdateTokenError]];
            }
        }];
        return;
    }

    // Asynchronous HTTP request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_httpExecutor defaultEncoder] encodeDeviceDetails:local];
    [request setValue:[[_httpExecutor defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [[_httpExecutor logger] debug:__FILE__ line:__LINE__ message:@"device registration with request %@", request];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 201 /*Created*/) {
            ARTDeviceDetails *deviceDetails = [[_httpExecutor defaultEncoder] decodeDeviceDetails:data error:nil];
            [[NSUserDefaults standardUserDefaults] setObject:deviceDetails.updateToken forKey:ARTDeviceUpdateTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self sendEvent:[ARTPushActivationEventGotUpdateToken new]];
        }
        else if (error) {
            [[_httpExecutor logger] error:@"%@: device registration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:[ARTErrorInfo createWithNSError:error]]];
        }
        else {
            [[_httpExecutor logger] error:@"%@: device registration failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:[ARTErrorInfo createWithCode:response.statusCode message:@"Device registration failed"]]];
        }
    }];
    #endif
}

- (void)deviceUpdateRegistration:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    ARTLocalDevice *local = [ARTLocalDevice local];

    if (![[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:@"ARTPushRegistererDelegate must be implemented on AppDelegate" format:@""];
    }

    id delegate = [UIApplication sharedApplication].delegate;

    // Custom register
    SEL customRegisterMethodSelector = @selector(ablyPushCustomRegister:deviceDetails:callback:);
    if ([delegate respondsToSelector:customRegisterMethodSelector]) {
        [delegate ablyPushCustomRegister:error deviceDetails:local callback:^(ARTUpdateToken *updateToken, ARTErrorInfo *error) {
            if (![delegate respondsToSelector:@selector(ablyPushActivateCallback:)]) {
                [NSException raise:@"ablyPushRegisterCallback: method is required" format:@""];
            }
            if (error) {
                // Failed
                [delegate ablyPushActivateCallback:error];
                [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:error]];
            }
            else if (updateToken) {
                // Success
                [delegate ablyPushActivateCallback:nil];
                [[NSUserDefaults standardUserDefaults] setObject:updateToken forKey:ARTDeviceUpdateTokenKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                local.updateToken = updateToken;
                [self sendEvent:[ARTPushActivationEventRegistrationUpdated new]];
            }
            else {
                ARTErrorInfo *missingUpdateTokenError = [ARTErrorInfo createWithCode:0 message:@"UpdateToken is expected"];
                [delegate ablyPushActivateCallback:missingUpdateTokenError];
                [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:missingUpdateTokenError]];
            }
        }];
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:local.id]];
    NSData *tokenData = [local.updateToken dataUsingEncoding:NSUTF8StringEncoding];
    NSString *tokenBase64 = [tokenData base64EncodedStringWithOptions:0];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", tokenBase64] forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [[_httpExecutor defaultEncoder] encode:@{
        @"push": @{
            @"metadata": @{
                @"deviceToken": local.push.deviceToken,
            }
        }
    }];
    [request setValue:[[_httpExecutor defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [[_httpExecutor logger] debug:__FILE__ line:__LINE__ message:@"update device with request %@", request];
    [_httpExecutor executeRequest:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            ARTDeviceDetails *deviceDetails = [[_httpExecutor defaultEncoder] decodeDeviceDetails:data error:nil];
            [[NSUserDefaults standardUserDefaults] setObject:deviceDetails.updateToken forKey:ARTDeviceUpdateTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            local.updateToken = deviceDetails.updateToken;
            [self sendEvent:[ARTPushActivationEventRegistrationUpdated new]];
        }
        else if (error) {
            [[_httpExecutor logger] error:@"%@: update device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:[ARTErrorInfo createWithNSError:error]]];
        }
        else {
            [[_httpExecutor logger] error:@"%@: update device failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:[ARTErrorInfo createWithCode:response.statusCode message:@"Update device failed"]]];
        }
    }];
    #endif
}

- (void)deviceUnregistration:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    ARTLocalDevice *local = [ARTLocalDevice local];

    if (![[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:@"ARTPushRegistererDelegate must be implemented on AppDelegate" format:@""];
    }

    id delegate = [UIApplication sharedApplication].delegate;

    // Custom register
    SEL customDeregisterMethodSelector = @selector(ablyPushCustomDeregister:deviceId:callback:);
    if ([delegate respondsToSelector:customDeregisterMethodSelector]) {
        [delegate ablyPushCustomDeregister:error deviceId:local.id callback:^(ARTErrorInfo *error) {
            if (![delegate respondsToSelector:@selector(ablyPushDeactivateCallback:)]) {
                [NSException raise:@"ablyPushDeregisterCallback: method is required" format:@""];
            }
            if (error) {
                // Failed
                [delegate ablyPushDeactivateCallback:error];
                [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:error]];
            }
            else {
                // Success
                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:ARTDeviceUpdateTokenKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [delegate ablyPushDeactivateCallback:nil];
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

    [[_httpExecutor logger] debug:__FILE__ line:__LINE__ message:@"device deregistration with request %@", request];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            [[_httpExecutor logger] debug:__FILE__ line:__LINE__ message:@"successfully deactivate device"];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:ARTDeviceUpdateTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self sendEvent:[ARTPushActivationEventDeregistered new]];
        }
        else if (error) {
            [[_httpExecutor logger] error:@"%@: device deregistration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:[ARTErrorInfo createWithNSError:error]]];
        }
        else {
            [[_httpExecutor logger] error:@"%@: device deregistration failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:[ARTErrorInfo createWithCode:response.statusCode message:@"Device registration failed"]]];
        }
    }];
    #endif
}

- (void)callActivatedCallback:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        id delegate = [UIApplication sharedApplication].delegate;
        SEL activateCallbackMethodSelector = @selector(ablyPushActivateCallback:);
        if ([delegate respondsToSelector:activateCallbackMethodSelector]) {
            [delegate ablyPushActivateCallback:error];
        }
    }
    #endif
}

- (void)callDeactivatedCallback:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        id delegate = [UIApplication sharedApplication].delegate;
        SEL deactivateCallbackMethodSelector = @selector(ablyPushDeactivateCallback:);
        if ([delegate respondsToSelector:deactivateCallbackMethodSelector]) {
            [delegate ablyPushDeactivateCallback:error];
        }
    }
    #endif
}

- (void)callUpdateFailedCallback:(nullable ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        id delegate = [UIApplication sharedApplication].delegate;
        SEL updateFailedCallbackMethodSelector = @selector(ablyPushUpdateFailedCallback:);
        if ([delegate respondsToSelector:updateFailedCallbackMethodSelector]) {
            [delegate ablyPushUpdateFailedCallback:error];
        }
    }
    #endif
}

@end
