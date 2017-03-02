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
#import "ARTPushActivationStateMachine.h"
#import "ARTPushActivationEvent.h"
#import "ARTClientOptions+Private.h"

NSString *const ARTDeviceIdKey = @"ARTDeviceId";
NSString *const ARTDeviceUpdateTokenKey = @"ARTDeviceUpdateToken";
NSString *const ARTDeviceTokenKey = @"ARTDeviceToken";

@implementation ARTPush {
    id<ARTHTTPAuthenticatedExecutor> _httpExecutor;
    __weak ARTLog *_logger;
}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor {
    if (self = [super init]) {
        _httpExecutor = httpExecutor;
        _logger = [httpExecutor logger];
    }
    return self;
}

- (ARTPushActivationStateMachine *)activationMachine {
    static dispatch_once_t once;
    static id activationMachineInstance;
    dispatch_once(&once, ^{
        activationMachineInstance = [[ARTPushActivationStateMachine alloc] init:_httpExecutor];
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

- (void)publish:(ARTPushRecipient *)recipient jsonObject:(ARTJsonObject *)jsonObject {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/publish"]];
    request.HTTPMethod = @"POST";
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setObject:recipient forKey:@"recipient"];
    [body addEntriesFromDictionary:jsonObject];
    request.HTTPBody = [[_httpExecutor defaultEncoder] encode:body];
    [request setValue:[[_httpExecutor defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"push notification to a single device %@", request];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            return;
        }
        if (error) {
            [_logger error:@"%@: push notification to a single device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
        }
        else {
            [_logger error:@"%@: push notification to a single device failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
        }
    }];
}

- (void)activate {
    [[self activationMachine] sendEvent:[ARTPushActivationEventCalledActivate new]];
}

- (void)deactivate {
    [[self activationMachine] sendEvent:[ARTPushActivationEventCalledDeactivate new]];
}

@end
