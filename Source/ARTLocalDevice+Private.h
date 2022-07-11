#import <Ably/ARTRest.h>

@protocol ARTDeviceStorage;
@class ARTPushActivationPersistentState;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDeviceIdKey;
extern NSString *const ARTDeviceSecretKey;
extern NSString *const ARTDeviceIdentityTokenKey;
extern NSString *const ARTAPNSDeviceTokenKey;
extern NSString *const ARTDeviceActivationErrorKey;

@interface ARTLocalDevice ()

@property (strong, nonatomic) id<ARTDeviceStorage> storage;

#if TARGET_OS_IOS
@property (nullable, nonatomic, readonly) ARTErrorInfo *activationError;
@property (nullable, nonatomic, readonly) ARTPushActivationPersistentState *activationState;
#endif

+ (ARTLocalDevice *)load:(NSString *)clientId storage:(id<ARTDeviceStorage>)storage;
- (nullable NSString *)apnsDeviceToken;
- (void)setAndPersistAPNSDeviceToken:(nullable NSString *)deviceToken;
- (void)setAndPersistIdentityTokenDetails:(nullable ARTDeviceIdentityTokenDetails *)tokenDetails;
- (BOOL)isRegistered;

+ (NSString *)generateId;
+ (NSString *)generateSecret;

@end

NS_ASSUME_NONNULL_END
