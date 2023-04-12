#import "ARTNSMutableRequest+ARTPush.h"

#import "ARTInternalLog.h"
#import "ARTDeviceDetails.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTLocalDevice.h"

@implementation NSMutableURLRequest (ARTPush)

- (void)setDeviceAuthentication:(ARTDeviceId *)deviceId localDevice:(ARTLocalDevice *)localDevice {
    [self setDeviceAuthentication:deviceId localDevice:localDevice logger:nil];
}

- (void)setDeviceAuthentication:(ARTDeviceId *)deviceId localDevice:(ARTLocalDevice *)localDevice logger:(ARTInternalLog *)logger {
    if ([localDevice.id isEqualToString:deviceId]) {
        if (localDevice.identityTokenDetails.token) {
            ARTLogDebug(logger, @"adding device authentication using local device identity token");
            [self setValue:[localDevice.identityTokenDetails.token art_base64Encoded] forHTTPHeaderField:@"X-Ably-DeviceToken"];
        }
        else if (localDevice.secret) {
            ARTLogDebug(logger, @"adding device authentication using local device secret");
            [self setValue:localDevice.secret forHTTPHeaderField:@"X-Ably-DeviceSecret"];
        }
    }
}

- (void)setDeviceAuthentication:(ARTLocalDevice *)localDevice {
    [self setDeviceAuthentication:localDevice logger:nil];
}

- (void)setDeviceAuthentication:(ARTLocalDevice *)localDevice logger:(ARTInternalLog *)logger {
    [self setDeviceAuthentication:localDevice.id localDevice:localDevice logger:nil];
}

@end
