#import "NSURLRequest+ARTPush.h"

#import "ARTInternalLog.h"
#import "ARTDeviceDetails.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTLocalDevice.h"

@implementation NSURLRequest (ARTPush)

- (NSURLRequest *)settingDeviceAuthentication:(ARTDeviceId *)deviceId localDevice:(ARTLocalDevice *)localDevice {
    return [self settingDeviceAuthentication:deviceId localDevice:localDevice logger:nil];
}

- (NSURLRequest *)settingDeviceAuthentication:(ARTDeviceId *)deviceId localDevice:(ARTLocalDevice *)localDevice logger:(ARTInternalLog *)logger {
    NSMutableURLRequest *mutableRequest = [self mutableCopy];
    
    if ([localDevice.id isEqualToString:deviceId]) {
        if (localDevice.identityTokenDetails.token) {
            ARTLogDebug(logger, @"adding device authentication using local device identity token");
            [mutableRequest setValue:[localDevice.identityTokenDetails.token art_base64Encoded] forHTTPHeaderField:@"X-Ably-DeviceToken"];
        }
        else if (localDevice.secret) {
            ARTLogDebug(logger, @"adding device authentication using local device secret");
            [mutableRequest setValue:localDevice.secret forHTTPHeaderField:@"X-Ably-DeviceSecret"];
        }
    }
    
    return [mutableRequest copy];
}

- (NSURLRequest *)settingDeviceAuthentication:(ARTLocalDevice *)localDevice {
    return [self settingDeviceAuthentication:localDevice logger:nil];
}

- (NSURLRequest *)settingDeviceAuthentication:(ARTLocalDevice *)localDevice logger:(ARTInternalLog *)logger {
    return [self settingDeviceAuthentication:localDevice.id localDevice:localDevice logger:logger];
}

@end
