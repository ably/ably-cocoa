#import <Ably/ARTRest.h>

@protocol ARTDeviceStorage;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDeviceIdKey;
extern NSString *const ARTDeviceSecretKey;
extern NSString *const ARTDeviceIdentityTokenKey;
extern NSString *const ARTDeviceTokenKey;

@interface ARTLocalDevice ()

@property (class, nullable, strong, nonatomic) ARTLocalDevice *shared_nosync;

@property (strong, nonatomic) id<ARTDeviceStorage> storage;

+ (ARTLocalDevice *)load:(NSString *)clientId storage:(id<ARTDeviceStorage>)storage;
- (nullable NSString *)deviceToken;
- (void)setAndPersistDeviceToken:(nullable NSString *)deviceToken;
- (void)setAndPersistIdentityTokenDetails:(nullable ARTDeviceIdentityTokenDetails *)tokenDetails;
- (BOOL)isRegistered;

+ (NSString *)generateId;
+ (NSString *)generateSecret;

@end

NS_ASSUME_NONNULL_END
