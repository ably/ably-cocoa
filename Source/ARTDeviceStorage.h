#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTDeviceStorage <NSObject>
- (BOOL)getObject:(_Nullable id * _Nullable)ptr forKey:(NSString *)key error:(NSError **)error;
- (BOOL)setObject:(nullable id)value forKey:(NSString *)key error:(NSError **)error;
- (BOOL)getSecret:(NSString * _Nullable * _Nullable)ptr forDevice:(ARTDeviceId *)deviceId error:(NSError **)error;
- (BOOL)setSecret:(nullable NSString *)value forDevice:(ARTDeviceId *)deviceId error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
