//
//  ARTDeviceDetails.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTDevicePushDetails;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDevicePlatform;

typedef NS_ENUM(NSUInteger, ARTDeviceFormFactor) {
    ARTDeviceFormFactorMobile,
    ARTDeviceFormFactorTablet,
    ARTDeviceFormFactorDesktop,
    ARTDeviceFormFactorEmbedded
};

NSString *ARTDeviceFormFactorToStr(ARTDeviceFormFactor formFactor);

@interface ARTDeviceDetails : NSObject

@property (nonatomic, readonly) NSString *id;
@property (nullable, nonatomic) NSString *clientId;
@property (nonatomic, readonly) NSString *platform;
@property (nonatomic, readonly) ARTDeviceFormFactor formFactor;
@property (nullable, nonatomic) NSDictionary<NSString *, NSString *> *metadata;
@property (nonatomic, readonly) ARTDevicePushDetails *push;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithToken:(NSString *)deviceToken;
+ (instancetype)fromLocalDevice:(NSString *)deviceToken;

@end

NS_ASSUME_NONNULL_END
