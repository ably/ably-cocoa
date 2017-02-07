//
//  ARTDeviceDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTDeviceDetails.h"

NSString *const ARTDevicePlatform = @"ios";
NSString *const ARTDevicePushTransportType = @"apns";

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

@end
