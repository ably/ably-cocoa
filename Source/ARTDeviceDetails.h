//
//  ARTDeviceDetails.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTPush.h"

@class ARTDevicePushDetails;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDevicePlatform;
extern NSString *const ARTDeviceFormFactor;

@interface ARTDeviceDetails : NSObject

@property (nonatomic, readonly) ARTDeviceId *id;
@property (nullable, nonatomic) NSString *clientId;
@property (nonatomic, readonly) NSString *platform;
@property (nonatomic, readonly) NSString *formFactor;
@property (nullable, nonatomic) NSDictionary<NSString *, NSString *> *metadata;
@property (nonatomic, readonly) ARTDevicePushDetails *push;
@property (nullable, nonatomic) ARTUpdateToken *updateToken;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithId:(ARTDeviceId *)deviceId;

@end

NS_ASSUME_NONNULL_END
