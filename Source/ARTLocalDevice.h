//
//  ARTLocalDevice.h
//  Ably
//
//  Created by Ricardo Pereira on 28/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTDeviceDetails.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTLocalDevice : ARTDeviceDetails

@property (nonatomic, readonly) ARTDeviceToken *registrationToken;

- (instancetype)init;
+ (ARTLocalDevice *)local;

- (void)resetId;
- (void)resetUpdateToken:(void (^)(ARTErrorInfo * _Nullable))callback;

@end

NS_ASSUME_NONNULL_END
