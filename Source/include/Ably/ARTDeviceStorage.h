#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

// Instances of ARTDeviceStorage should expect to have their methods called
// from any thread.
/// :nodoc:
@protocol ARTDeviceStorage <NSObject>
- (nullable id)objectForKey:(NSString *)key;
- (void)setObject:(nullable id)value forKey:(NSString *)key;
- (nullable NSString *)secretForDevice:(ARTDeviceId *)deviceId;
- (void)setSecret:(nullable NSString *)value forDevice:(ARTDeviceId *)deviceId;
@end

NS_ASSUME_NONNULL_END
