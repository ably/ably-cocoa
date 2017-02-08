//
//  ARTPush.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPush.h"
#import "ARTRest+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"

@interface ARTPush ()

@end

@implementation ARTPush {
    __weak ARTRest *_rest;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
    }
    return self;
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Normalizing token by removing symbols and spaces
    NSString *token = [[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];

    ARTDeviceDetails *localDeviceDetails = [ARTDeviceDetails fromLocalDevice:token];

    [self activate:localDeviceDetails callback:^(ARTDeviceDetails *deviceDetails, ARTErrorInfo *error) {

    }];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"ARTPush %p %s: %@", self, __FUNCTION__, error);
}

- (void)publish:(NSDictionary<NSString *,NSString *> *)params jsonObject:(ARTJsonObject *)jsonObject {

}

- (void)activate:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTDeviceDetails * _Nullable, ARTErrorInfo * _Nullable))callback {
    id<ARTEncoder> jsonEncoder = [[ARTJsonLikeEncoder alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [jsonEncoder encodeDeviceDetails:deviceDetails];
    [request setValue:[jsonEncoder mimeType] forHTTPHeaderField:@"Content-Type"];

    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {


    }];
}

- (void)deactivate:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceId * _Nullable, ARTErrorInfo * _Nullable))callback {

}

@end
