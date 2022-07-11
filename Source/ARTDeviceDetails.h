#import <Foundation/Foundation.h>
#import <Ably/ARTPush.h>

@class ARTDevicePushDetails;

NS_ASSUME_NONNULL_BEGIN

@interface ARTDeviceDetails : NSObject

@property (strong, nonatomic) ARTDeviceId *id;
@property (strong, nullable, nonatomic) NSString *clientId;
@property (strong, nonatomic) NSString *platform;
@property (strong, nonatomic) NSString *formFactor;
@property (strong, nonatomic) NSDictionary<NSString *, NSString *> *metadata;
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *> *pushRecipient;

- (instancetype)init;
- (instancetype)initWithId:(ARTDeviceId *)deviceId;

@end

NS_ASSUME_NONNULL_END
