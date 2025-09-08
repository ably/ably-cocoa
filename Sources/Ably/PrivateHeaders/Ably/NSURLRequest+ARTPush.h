#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

@class ARTLocalDevice;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface NSURLRequest (ARTPush)

- (NSURLRequest *)settingDeviceAuthentication:(ARTDeviceId *)deviceId localDevice:(ARTLocalDevice *)localDevice;
- (NSURLRequest *)settingDeviceAuthentication:(ARTDeviceId *)deviceId localDevice:(ARTLocalDevice *)localDevice logger:(nullable ARTInternalLog *)logger;
- (NSURLRequest *)settingDeviceAuthentication:(ARTLocalDevice *)localDevice;
- (NSURLRequest *)settingDeviceAuthentication:(ARTLocalDevice *)localDevice logger:(nullable ARTInternalLog *)logger;

@end

NS_ASSUME_NONNULL_END
