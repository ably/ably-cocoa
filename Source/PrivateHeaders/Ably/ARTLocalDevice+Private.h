#import <Ably/ARTRest.h>

@class ARTInternalLog;
@protocol ARTDeviceStorage;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDeviceIdKey;
extern NSString *const ARTDeviceSecretKey;
extern NSString *const ARTDeviceIdentityTokenKey;
extern NSString *const ARTAPNSDeviceTokenKey;

extern NSString *const ARTAPNSDeviceDefaultTokenType;
extern NSString *const ARTAPNSDeviceLocationTokenType;

NSString* ARTAPNSDeviceTokenKeyOfType(NSString * _Nullable tokenType);

@interface ARTLocalDevice ()

@property (nonatomic) id<ARTDeviceStorage> storage;

+ (ARTLocalDevice *)load:(NSString *)clientId storage:(id<ARTDeviceStorage>)storage logger:(nullable ARTInternalLog *)logger;
- (nullable NSString *)apnsDeviceToken;
- (void)setAndPersistAPNSDeviceToken:(nullable NSString *)deviceToken tokenType:(NSString *)tokenType;
- (void)setAndPersistAPNSDeviceToken:(nullable NSString *)deviceToken;
- (void)setAndPersistIdentityTokenDetails:(nullable ARTDeviceIdentityTokenDetails *)tokenDetails;
- (BOOL)isRegistered;

+ (NSString *)generateId;
+ (NSString *)generateSecret;

+ (NSString *)apnsDeviceTokenOfType:(nullable NSString *)tokenType fromStorage:(id<ARTDeviceStorage>)storage;

@end

NS_ASSUME_NONNULL_END
