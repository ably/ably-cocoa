//
//  ARTDeviceDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"

NSString *const ARTDevicePlatform = @"ios";

NSString *ARTDeviceFormFactorToStr(ARTDeviceFormFactor formFactor) {
    switch (formFactor) {
        case ARTDeviceFormFactorMobile:
            return @"mobile"; //0
        case ARTDeviceFormFactorTablet:
            return @"tablet"; //1
        case ARTDeviceFormFactorDesktop:
            return @"desktop"; //2
        case ARTDeviceFormFactorEmbedded:
            return @"embedded"; //3
    }
}

@implementation ARTDeviceDetails

+ (instancetype)fromLocalDevice:(NSString *)deviceToken {
    return [[ARTDeviceDetails alloc] initWithToken:deviceToken];
}

- (instancetype)initWithToken:(NSString *)deviceToken {
    if (self = [super init]) {
        _id = [[NSUUID new] UUIDString];
        _formFactor = ARTDeviceFormFactorMobile;
        _push = [[ARTDevicePushDetails alloc] init];
        _push.deviceToken = deviceToken;
    }
    return self;
}

- (NSString *)platform {
    return ARTDevicePlatform;
}

@end
