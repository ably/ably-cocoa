//
//  ARTLocalDevice+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#ifndef ARTLocalDevice_Private_h
#define ARTLocalDevice_Private_h

#import "ARTRest.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDeviceIdKey;
extern NSString *const ARTDeviceUpdateTokenKey;
extern NSString *const ARTDeviceTokenKey;

@interface ARTLocalDevice : ARTDeviceDetails

+ (ARTLocalDevice *_Nonnull)load:(ARTRest *)rest;
- (void)setAndPersistDeviceToken:(NSString *_Nullable)token;
- (void)setAndPersistUpdateToken:(NSString *_Nullable)token;

@end

NS_ASSUME_NONNULL_END

#endif /* ARTLocalDevice_Private_h */
