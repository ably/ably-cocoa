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
#ifdef TARGET_OS_IOS
#import "ARTPushActivationStateMachine.h"
#endif
#import "ARTPushActivationEvent.h"
#import "ARTClientOptions+Private.h"
#import "ARTPushAdmin+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTRealtime+Private.h"

NSString *const ARTDeviceIdKey = @"ARTDeviceId";
NSString *const ARTDeviceUpdateTokenKey = @"ARTDeviceUpdateToken";
NSString *const ARTDeviceTokenKey = @"ARTDeviceToken";

@implementation ARTPush {
    ARTRest *_rest;
    __weak ARTLog *_logger;
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _admin = [[ARTPushAdmin alloc] init:rest];
        _queue = rest.queue;
        _userQueue = rest.userQueue;
    }
    return self;
}

- (void)publish:(ARTPushRecipient *)recipient notification:(ARTJsonObject *)notification callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/publish"]];
    request.HTTPMethod = @"POST";
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setObject:recipient forKey:@"recipient"];
    [body addEntriesFromDictionary:notification];
    request.HTTPBody = [[_rest defaultEncoder] encode:body error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"push notification to a single device %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [_logger error:@"%@: push notification to a single device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            if (callback) callback([ARTErrorInfo createFromNSError:error]);
            return;
        }
        if (callback) callback(nil);
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

#ifdef TARGET_OS_IOS

- (ARTPushActivationStateMachine *)activationMachine {
    static dispatch_once_t once;
    static id activationMachineInstance;
    dispatch_once(&once, ^{
        activationMachineInstance = [[ARTPushActivationStateMachine alloc] init:_rest];
    });
    return activationMachineInstance;
}


+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData rest:(ARTRest *)rest {
    // HEX string, i.e.: <12ce7dda 8032c423 8f8bd40f 3484e5bb f4698da5 8b7fdf8d 5c55e0a2 XXXXXXXX>
    // Normalizing token by removing symbols and spaces, i.e.: 12ce7dda8032c4238f8bd40f3484e5bbf4698da58b7fdf8d5c55e0a2XXXXXXXX
    NSString *deviceToken = [[[deviceTokenData description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSLog(@"ARTPush: device token received %@", deviceToken);
    NSString *currentDeviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:ARTDeviceTokenKey];
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
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime {
    [ARTPush didFailToRegisterForRemoteNotificationsWithError:error rest:realtime.rest];
}

- (void)activate {
    [[self activationMachine] sendEvent:[ARTPushActivationEventCalledActivate new]];
}

- (void)deactivate {
    [[self activationMachine] sendEvent:[ARTPushActivationEventCalledDeactivate new]];
}

#endif

@end
