//
//  ARTPush.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPush.h"
#import "ARTDeviceDetails.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTEventEmitter.h"

NSString *const ARTDeviceTokenKey = @"ARTDeviceToken";

typedef NS_ENUM(NSUInteger, ARTPushState) {
    ARTPushStateDeactivated,
    ARTPushStateActivated,
};

@interface ARTPush ()

@property (nonatomic, readonly) ARTPushState state;

@end

@implementation ARTPush {
    id<ARTHTTPAuthenticatedExecutor> _httpExecutor;
    __weak ARTLog *_logger;
    ARTEventEmitter<NSNull *, ARTDeviceToken *> *_deviceTokenEmitter;
}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor {
    if (self = [super init]) {
        _httpExecutor = httpExecutor;
        _logger = [httpExecutor logger];
        _device = [ARTDeviceDetails fromLocalDevice];
        _state = ARTPushStateDeactivated;
        _deviceTokenEmitter = [[ARTEventEmitter alloc] init];
    }
    return self;
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [_logger info:@"ARTPush: device token received and stored"];
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:ARTDeviceTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_deviceTokenEmitter emit:[NSNull null] with:deviceToken];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [_logger error:@"ARTPush: device token not received (%@)", [error localizedDescription]];
}

- (void)publish:(ARTPushRecipient *)recipient jsonObject:(ARTJsonObject *)jsonObject {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/publish"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_httpExecutor defaultEncoder] encode:@{
        @"recipient": recipient,
        @"push": jsonObject,
    }];
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
    [self activate:self.device registerCallback:nil];
}

- (void)activateWithRegisterCallback:(void (^)(ARTDeviceDetails *, ARTErrorInfo *, void (^)(ARTUpdateToken *, ARTErrorInfo *)))registerCallback {
    [self activate:self.device registerCallback:registerCallback];
}

- (void)activate:(ARTDeviceDetails *)deviceDetails registerCallback:(void (^)(ARTDeviceDetails *, ARTErrorInfo *, void (^)(ARTUpdateToken *, ARTErrorInfo *)))registerCallback {
    if (self.state == ARTPushStateActivated) {
        return;
    }

    NSData *deviceToken = [[NSUserDefaults standardUserDefaults] dataForKey:ARTDeviceTokenKey];
    if (!deviceToken) {
        // Waiting for device token
        [_deviceTokenEmitter once:^(ARTDeviceToken *deviceToken) {
            [self activate:deviceDetails registerCallback:registerCallback];
        }];
        return;
    }

    if (registerCallback) {
        registerCallback(deviceDetails, nil, ^(ARTUpdateToken *updateToken, ARTErrorInfo *error) {
            if (updateToken) {
                self.device.updateToken = updateToken;
            }
            if (error) {
                [_logger error:@"%@: device registration using a `registerCallback` failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            }
        });
        return;
    }

    if (self.device.updateToken) {
        [self updateDevice:deviceDetails];
    }
    else {
        [self newDevice:deviceDetails];
    }
}

- (void)deactivate {
    [self deactivate:self.device.id deregisterCallback:nil];
}

- (void)deactivateWithDeregisterCallback:(void (^)(ARTDeviceId *, ARTErrorInfo *, void (^)(ARTErrorInfo *)))deregisterCallback {
    [self deactivate:self.device.id deregisterCallback:deregisterCallback];
}

- (void)deactivate:(ARTDeviceId *)deviceId deregisterCallback:(void (^)(ARTDeviceId *, ARTErrorInfo *, void (^)(ARTErrorInfo *)))deregisterCallback {
    if (deregisterCallback) {
        deregisterCallback(deviceId, nil, ^(ARTErrorInfo *error) {
            if (error) {
                [_logger error:@"%@: device deregistration using a `deregisterCallback` failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            }
        });
        return;
    }

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"deviceId" value:deviceId],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [_logger debug:__FILE__ line:__LINE__ message:@"device deregistration with request %@", request];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            [_logger debug:__FILE__ line:__LINE__ message:@"successfully deactivate device"];
            self.device.updateToken = nil;
        }
        else if (error) {
            [_logger error:@"%@: device deregistration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
        }
        else {
            [_logger error:@"%@: device deregistration failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
        }
    }];
}

- (void)newDevice:(ARTDeviceDetails *)deviceDetails {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_httpExecutor defaultEncoder] encodeDeviceDetails:deviceDetails];
    [request setValue:[[_httpExecutor defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"device registration with request %@", request];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 201 /*Created*/) {
            ARTDeviceDetails *deviceDetails = [[_httpExecutor defaultEncoder] decodeDeviceDetails:data];
            self.device.updateToken = deviceDetails.updateToken;
        }
        else if (error) {
            [_logger error:@"%@: device registration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
        }
        else {
            [_logger error:@"%@: device registration failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
        }
    }];
}

- (void)updateDevice:(ARTDeviceDetails *)deviceDetails {

}

@end
