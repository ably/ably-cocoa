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

NSString *const ARTDeviceIdKey = @"ARTDeviceId";
NSString *const ARTDeviceUpdateTokenKey = @"ARTDeviceUpdateToken";
NSString *const ARTDeviceTokenKey = @"ARTDeviceToken";

@implementation ARTPush {
    ARTRest *_rest;
    __weak ARTLog *_logger;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [httpExecutor logger];
        _admin = [[ARTPushAdmin alloc] init:httpExecutor];
    }
    return self;
}

- (void)publish:(ARTPushRecipient *)recipient notification:(ARTJsonObject *)notification callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/publish"]];
    request.HTTPMethod = @"POST";
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setObject:recipient forKey:@"recipient"];
    [body addEntriesFromDictionary:notification];
    request.HTTPBody = [[_rest defaultEncoder] encode:body];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"push notification to a single device %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [_logger error:@"%@: push notification to a single device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            if (callback) callback([ARTErrorInfo createWithNSError:error]);
            return;
        }
        if (callback) callback(nil);
    }];
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


+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest {
    NSLog(@"ARTPush: device token received %@", deviceToken);
    NSData *currentDeviceToken = [[NSUserDefaults standardUserDefaults] dataForKey:ARTDeviceTokenKey];
    if ([currentDeviceToken isEqualToData:deviceToken]) {
        // Already stored.
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:ARTDeviceTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"ARTPush: device token stored");
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest {
    NSLog(@"ARTPush: device token not received (%@)", [error localizedDescription]);
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGettingUpdateTokenFailed newWithError:[ARTErrorInfo createWithNSError:error]]];
}

- (void)activate {
    [[self activationMachine] sendEvent:[ARTPushActivationEventCalledActivate new]];
}

- (void)deactivate {
    [[self activationMachine] sendEvent:[ARTPushActivationEventCalledDeactivate new]];
}

#endif

@end
