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

    NSString *deviceId = [[NSUserDefaults standardUserDefaults] stringForKey:ARTDeviceIdKey];
    if (!deviceId) {
        deviceId = [[ULID new] ulidString];
        [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:ARTDeviceIdKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    device.id = deviceId;
    device.updateToken = [[NSUserDefaults standardUserDefaults] stringForKey:ARTDeviceUpdateTokenKey];

    [device setDeviceToken:[[NSUserDefaults standardUserDefaults] stringForKey:ARTDeviceTokenKey]];

    return device;
}

- (void)resetId {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:ARTDeviceIdKey];
    [self setAndPersistUpdateToken:nil];
    NSString *deviceId = [[ULID new] ulidString];
    [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:ARTDeviceIdKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.id = deviceId;
}

- (void)resetUpdateToken:(void (^)(ARTErrorInfo *error))callback {
    if (self.id == nil || self.updateToken == nil) {
        if (callback) callback(nil);
        return;
    }

    NSString *path = @"/push/deviceDetails";
    path = [path stringByAppendingPathComponent:self.id];
    path = [path stringByAppendingPathComponent:@"resetUpdateToken"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    request.HTTPMethod = @"POST";

    [_logger debug:__FILE__ line:__LINE__ message:@"RS:%p resetUpdateToken", _rest];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (!error && data) {
            ARTDeviceDetails *updated = [self.rest.encoders[response.allHeaderFields[@"Content-Type"]] decodeDeviceDetails:data error:&error];
            if (!error) {
                [self setAndPersistUpdateToken:updated.updateToken];
            }
        }
        if (callback) {
            ARTErrorInfo *errorInfo = error ? [ARTErrorInfo createFromNSError:error] : nil;
            callback(errorInfo);
        }
    }];
}

- (NSString *)deviceToken {
    return self.push.recipient[@"deviceToken"];
}

- (void)setDeviceToken:(NSString *_Nonnull)token {
    self.push.recipient[@"deviceToken"] = token;
}

- (void)setAndPersistDeviceToken:(NSString *)token {
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:ARTDeviceTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setDeviceToken:token];
}

- (void)setAndPersistUpdateToken:(NSString *)token {
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:ARTDeviceUpdateTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.updateToken = token;
}

@end
