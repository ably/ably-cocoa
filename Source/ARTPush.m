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

NSString *const ARTDeviceTokenKey = @"DeviceToken";

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
    id<ARTEncoder> _jsonEncoder;
    ARTEventEmitter<NSNull *, ARTDeviceToken *> *_deviceTokenEmitter;
}

- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor {
    if (self = [super init]) {
        _httpExecutor = httpExecutor;
        _logger = [httpExecutor logger];
        _device = [ARTDeviceDetails fromLocalDevice];
        _state = ARTPushStateDeactivated;
        _deviceTokenEmitter = [[ARTEventEmitter alloc] init];
        _jsonEncoder = [[ARTJsonLikeEncoder alloc] init];
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

- (void)publish:(id<ARTPushRecipient>)recipient jsonObject:(ARTJsonObject *)jsonObject {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/publish"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [_jsonEncoder encodePushRecipient:recipient withJsonObject:jsonObject];
    [request setValue:[_jsonEncoder mimeType] forHTTPHeaderField:@"Content-Type"];

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

- (void)deactivate:(ARTDeviceId *)deviceId {
    [self deactivate:deviceId deregisterCallback:nil];
}

- (void)deactivate:(ARTDeviceId *)deviceId deregisterCallback:(void (^)(ARTDeviceId * _Nullable, ARTErrorInfo * _Nullable))deregisterCallback {
    // TODO
}

- (void)newDevice:(ARTDeviceDetails *)deviceDetails {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [_jsonEncoder encodeDeviceDetails:deviceDetails];
    [request setValue:[_jsonEncoder mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"device registration with request %@", request];
    [_httpExecutor executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 201 /*Created*/) {
            ARTDeviceDetails *deviceDetails = [_jsonEncoder decodeDeviceDetails:data];
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
