//
//  ARTLocalDevice.m
//  Ably
//
//  Created by Ricardo Pereira on 28/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTLocalDevice+Private.h"
#import "ARTDevicePushDetails.h"
#import "ARTPush.h"
#import "ARTRest+Private.h"
#import "ARTAuth+Private.h"
#import "ARTEncoder.h"
#import "ARTDeviceStorage.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTCrypto+Private.h"
#import <ULID/ULID.h>

NSString *const ARTDevicePlatform = @"ios";

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
NSString *const ARTDeviceFormFactor = @"phone";
#elif TARGET_OS_TV
NSString *const ARTDeviceFormFactor = @"tv";
#elif TARGET_OS_WATCH
NSString *const ARTDeviceFormFactor = @"watch";
#elif TARGET_OS_SIMULATOR
NSString *const ARTDeviceFormFactor = @"simulator";
#elif TARGET_OS_MAC
NSString *const ARTDeviceFormFactor = @"desktop";
#else
NSString *const ARTDeviceFormFactor = @"embedded";
#endif

NSString *const ARTDevicePushTransportType = @"apns";

@implementation ARTLocalDevice {
    __weak ARTLog *_logger;
}

- (instancetype)initWithRest:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = rest.logger;
    }
    return self;
}

+ (ARTLocalDevice *)load:(ARTRest *_Nonnull)rest {
    ARTLocalDevice *device = [[ARTLocalDevice alloc] initWithRest:rest];
    device.clientId = device.rest.auth.clientId_nosync;
    device.platform = ARTDevicePlatform;
    switch (UI_USER_INTERFACE_IDIOM()) {
        case UIUserInterfaceIdiomPad:
            device.formFactor = @"tablet";
        case UIUserInterfaceIdiomCarPlay:
            device.formFactor = @"car";
        default:
            device.formFactor = ARTDeviceFormFactor;
    }
    device.push.recipient[@"transportType"] = ARTDevicePushTransportType;

    NSString *deviceId = [rest.storage objectForKey:ARTDeviceIdKey];
    if (!deviceId) {
        deviceId = [self generateId];
        [rest.storage setObject:deviceId forKey:ARTDeviceIdKey];
    }
    device.id = deviceId;

    NSString *deviceSecret = [rest.storage secretForDevice:deviceId];
    if (!deviceSecret) {
        deviceSecret = [self generateSecret];
        [rest.storage setSecret:deviceSecret forDevice:deviceId];
    }
    device.secret = deviceSecret;

    device->_identityTokenDetails = [ARTDeviceIdentityTokenDetails unarchive:[rest.storage objectForKey:ARTDeviceIdentityTokenKey]];

    [device setDeviceToken:[rest.storage objectForKey:ARTDeviceTokenKey]];

    return device;
}

+ (NSString *)generateId {
    return [[ULID new] ulidString];
}

+ (NSString *)generateSecret {
    NSData *randomData = [ARTCrypto generateSecureRandomData:32];
    NSData *hash = [ARTCrypto generateHashSHA256:randomData];
    return [hash base64EncodedStringWithOptions:0];
}

- (NSString *)deviceToken {
    return self.push.recipient[@"deviceToken"];
}

- (void)setDeviceToken:(NSString *_Nonnull)token {
    self.push.recipient[@"deviceToken"] = token;
}

- (void)setAndPersistDeviceToken:(NSString *)deviceToken {
    [self.rest.storage setObject:deviceToken forKey:ARTDeviceTokenKey];
    [self setDeviceToken:deviceToken];
}

- (void)setAndPersistIdentityTokenDetails:(ARTDeviceIdentityTokenDetails *)tokenDetails {
    [self.rest.storage setObject:[tokenDetails archive] forKey:ARTDeviceIdentityTokenKey];
    _identityTokenDetails = tokenDetails;
}

@end
