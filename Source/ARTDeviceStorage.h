#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTDeviceStorage <NSObject>
- (BOOL)getObject:(_Nullable id * _Nullable)ptr forKey:(NSString *)key error:(NSError **)error;
- (void)setObject:(nullable id)value forKey:(NSString *)key;
- (BOOL)getSecret:(NSString * _Nullable * _Nullable)ptr forDevice:(ARTDeviceId *)deviceId error:(NSError **)error;
- (void)setSecret:(nullable NSString *)value forDevice:(ARTDeviceId *)deviceId;
@end

NS_ASSUME_NONNULL_END
