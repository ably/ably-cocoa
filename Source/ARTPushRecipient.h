//
//  ARTPushRecipient.h
//  Ably
//
//  Created by Ricardo Pereira on 13/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushRecipient<NSObject>
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *recipient;
@end

// ClientId
@interface ARTPushRecipientClientId : NSObject<ARTPushRecipient>
@property (nonatomic) NSString *clientId;
@end

// DeviceId
@interface ARTPushRecipientDeviceId : NSObject<ARTPushRecipient>
@property (nonatomic) NSString *deviceId;
@end

// APNs
@interface ARTPushRecipientAPNDevice : NSObject<ARTPushRecipient>
@property (nonatomic) NSString *deviceToken;
@end

// GCM
@interface ARTPushRecipientGCMDevice : NSObject<ARTPushRecipient>
@property (nonatomic) NSString *registrationToken;
@end

// FCM
@interface ARTPushRecipientFCMDevice : ARTPushRecipientGCMDevice
@end

// Web
@interface ARTPushRecipientWebDevice : NSObject<ARTPushRecipient>
@property (nonatomic) NSString *targetURL;
@property (nonatomic) NSString *encryptionKey;
@end

NS_ASSUME_NONNULL_END
