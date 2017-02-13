//
//  ARTPushRecipient.m
//  Ably
//
//  Created by Ricardo Pereira on 13/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushRecipient.h"

#pragma mark ClientId
@implementation ARTPushRecipientClientId

- (NSDictionary<NSString *,NSString *> *)recipient {
    return @{ @"clientId": self.clientId };
}

@end

#pragma mark DeviceId
@implementation ARTPushRecipientDeviceId

- (NSDictionary<NSString *,NSString *> *)recipient {
    return @{ @"deviceId": self.deviceId };
}

@end

#pragma mark APNs
@implementation ARTPushRecipientAPNDevice

- (NSDictionary<NSString *,NSString *> *)recipient {
    return @{
        @"transportType": @"apns",
        @"deviceToken": self.deviceToken,
    };
}

@end

#pragma mark GCM
@implementation ARTPushRecipientGCMDevice

- (NSDictionary<NSString *,NSString *> *)recipient {
    return @{
        @"transportType": @"gcm",
        @"registrationToken": self.registrationToken,
    };
}

@end

#pragma mark FCM
@implementation ARTPushRecipientFCMDevice

- (NSDictionary<NSString *,NSString *> *)recipient {
    return @{
        @"transportType": @"fcm",
        @"registrationToken": self.registrationToken,
    };
}

@end

#pragma mark Web
@implementation ARTPushRecipientWebDevice

- (NSDictionary<NSString *,NSString *> *)recipient {
    return @{
        @"transportType": @"web",
        @"targetUrl": self.targetURL,
        @"encryptionKey": self.encryptionKey,
    };
}

@end
