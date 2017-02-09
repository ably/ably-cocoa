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
    __weak ARTRest *_rest;
    __weak ARTLog *_logger;
    id<ARTEncoder> _jsonEncoder;
    ARTEventEmitter<NSNull *, ARTDeviceToken *> *_deviceTokenEmitter;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = rest.logger;
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
    [_deviceTokenEmitter emit:[NSNull null] with:(ARTDeviceToken *)deviceToken];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [_logger error:@"ARTPush: device token not received (%@)", [error localizedDescription]];
}

- (void)publish:(NSDictionary<NSString *,NSString *> *)params jsonObject:(ARTJsonObject *)jsonObject {

}

- (void)activate {
    [self activate:self.device registerCallback:nil];
}

- (void)activate:(ARTDeviceDetails *)deviceDetails {
    [self activate:deviceDetails registerCallback:nil];
}

- (void)activate:(ARTDeviceDetails *)deviceDetails registerCallback:(ARTUpdateToken* (^)(ARTDeviceDetails * _Nullable, ARTErrorInfo * _Nullable))registerCallback {
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
        self.device.updateToken = registerCallback(deviceDetails, nil);
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

}

- (void)newDevice:(ARTDeviceDetails *)deviceDetails {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [_jsonEncoder encodeDeviceDetails:deviceDetails];
    [request setValue:[_jsonEncoder mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"ARTPush: device registration with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 201 /*Created*/) {
            ARTDeviceDetails *deviceDetails = [_jsonEncoder decodeDeviceDetails:data];
            self.device.updateToken = deviceDetails.updateToken;
        }
        else if (error) {
            [_logger error:@"ARTPush: device registration failed (%@)", error.localizedDescription];
        }
        else {
            [_logger error:@"ARTPush: device registration failed with unknown error"];
        }
    }];
}

- (void)updateDevice:(ARTDeviceDetails *)deviceDetails {

}

@end
