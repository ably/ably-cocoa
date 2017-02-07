//
//  ARTDeviceDetails.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDevicePlatform;
extern NSString *const ARTDevicePushTransportType;

typedef NS_ENUM(NSUInteger, ARTDeviceFormFactor) {
    ARTDeviceFormFactorMobile,
    ARTDeviceFormFactorTablet,
    ARTDeviceFormFactorDesktop,
    ARTDeviceFormFactorEmbedded
};

NSString *ARTDeviceFormFactorToStr(ARTDeviceFormFactor formFactor);

@interface ARTDeviceDetails : NSObject

@end

NS_ASSUME_NONNULL_END
