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

#ifdef TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NSString *const ARTPushActivationCurrentStateKey = @"ARTPushActivationCurrentState";
NSString *const ARTPushActivationPendingEventsKey = @"ARTPushActivationPendingEvents";

@implementation ARTPushActivationStateMachine {
    ARTPushActivationState *_current;
    NSMutableArray<ARTPushActivationEvent *> *_pendingEvents;
}

- (instancetype)init {
    if (self = [super init]) {
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

- (void)deviceRegistration:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor error:(ARTErrorInfo *)error {
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
            if (![delegate respondsToSelector:@selector(ablyPushRegisterCallback:)]) {
                [NSException raise:@"ablyPushRegisterCallback: method is required" format:@""];
            }
            if (error) {
                // Failed
                [delegate ablyPushRegisterCallback:error];
                [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:error]];
            }
            else if (updateToken) {
                // Success
                [delegate ablyPushRegisterCallback:nil];
                [[NSUserDefaults standardUserDefaults] setObject:updateToken forKey:ARTDeviceUpdateTokenKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self sendEvent:[ARTPushActivationEventGotUpdateToken new]];
            }
            else {
                ARTErrorInfo *missingUpdateTokenError = [ARTErrorInfo createWithCode:0 message:@"UpdateToken is expected"];
                [delegate ablyPushRegisterCallback:missingUpdateTokenError];
                [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:missingUpdateTokenError]];
            }
        }];
        return;
    }

    // Asynchronous HTTP request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[httpExecutor defaultEncoder] encodeDeviceDetails:local];
    [request setValue:[[httpExecutor defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [[httpExecutor logger] debug:__FILE__ line:__LINE__ message:@"device registration with request %@", request];
    [httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 201 /*Created*/) {
            ARTDeviceDetails *deviceDetails = [[httpExecutor defaultEncoder] decodeDeviceDetails:data error:nil];
            [[NSUserDefaults standardUserDefaults] setObject:deviceDetails.updateToken forKey:ARTDeviceUpdateTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self sendEvent:[ARTPushActivationEventGotUpdateToken new]];
        }
        else if (error) {
            [[httpExecutor logger] error:@"%@: device registration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:[ARTErrorInfo createWithNSError:error]]];
        }
        else {
            [[httpExecutor logger] error:@"%@: device registration failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            [self sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:[ARTErrorInfo createWithCode:response.statusCode message:@"Device registration failed"]]];
        }
    }];
    #endif
}

- (void)deviceUnregistration:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor error:(ARTErrorInfo *)error {
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
            if (![delegate respondsToSelector:@selector(ablyPushDeregisterCallback:)]) {
                [NSException raise:@"ablyPushDeregisterCallback: method is required" format:@""];
            }
            if (error) {
                // Failed
                [delegate ablyPushRegisterCallback:error];
                [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:error]];
            }
            else {
                // Success
                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:ARTDeviceUpdateTokenKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [delegate ablyPushDeregisterCallback:nil];
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

    [[httpExecutor logger] debug:__FILE__ line:__LINE__ message:@"device deregistration with request %@", request];
    [httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            [[httpExecutor logger] debug:__FILE__ line:__LINE__ message:@"successfully deactivate device"];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:ARTDeviceUpdateTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else if (error) {
            [[httpExecutor logger] error:@"%@: device deregistration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
        }
        else {
            [[httpExecutor logger] error:@"%@: device deregistration failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
        }
    }];
    #endif
}

- (void)callDeactivatedCallback:(ARTErrorInfo *)error {
    #ifdef TARGET_OS_IOS
    if ([[UIApplication sharedApplication].delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        id delegate = [UIApplication sharedApplication].delegate;
        SEL deregisterCallbackMethodSelector = @selector(ablyPushDeregisterCallback:);
        if ([delegate respondsToSelector:deregisterCallbackMethodSelector]) {
            [delegate ablyPushDeregisterCallback:error];
        }
    }
    #endif
}

@end
