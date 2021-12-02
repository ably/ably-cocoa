#import <Ably/ARTRest+Private.h>

@protocol ARTDeviceStorage;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDeviceIdKey;
extern NSString *const ARTDeviceSecretKey;
extern NSString *const ARTDeviceIdentityTokenKey;
extern NSString *const ARTAPNSDeviceTokenKey;

@interface ARTLocalDevice ()

@property (class, nullable, readonly, nonatomic) ARTLocalDevice *shared;
@property (class, nullable, readonly, nonatomic) ARTLocalDevice *shared_nosync;

@property (strong, nonatomic) id<ARTDeviceStorage> storage;

- (nullable NSString *)apnsDeviceToken;
- (void)setAndPersistAPNSDeviceToken:(nullable NSString *)deviceToken;
- (void)setAndPersistIdentityTokenDetails:(nullable ARTDeviceIdentityTokenDetails *)tokenDetails;
- (BOOL)isRegistered;

+ (NSString *)generateId;
+ (NSString *)generateSecret;

+ (ARTLocalDevice *)createDeviceWithClientId:(NSString *)clientId apnsToken:(NSString *)apnsToken logger:(ARTLog *)logger;
+ (ARTLocalDevice *)renewDeviceWithClientId:(NSString *)clientId logger:(ARTLog *)logger;
+ (void)resetSharedDevice;

@end

NS_ASSUME_NONNULL_END
