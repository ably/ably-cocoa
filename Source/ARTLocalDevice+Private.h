//
//  ARTLocalDevice+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTRest.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDeviceIdKey;
extern NSString *const ARTDeviceSecretKey;
extern NSString *const ARTDeviceIdentityTokenKey;
extern NSString *const ARTDeviceTokenKey;

@interface ARTLocalDevice ()

@property (weak, nonatomic) ARTRest *rest;

+ (ARTLocalDevice *_Nonnull)load:(ARTRest *)rest;
- (NSString *_Nullable)deviceToken;
- (void)setAndPersistDeviceToken:(nullable NSString *)deviceToken;
- (void)setAndPersistIdentityTokenDetails:(nullable ARTDeviceIdentityTokenDetails *)tokenDetails;

+ (NSString *)generateId;
+ (NSString *)generateSecret;

@end

NS_ASSUME_NONNULL_END
