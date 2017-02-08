//
//  ARTDevicePushDetails.h
//  Ably
//
//  Created by Ricardo Pereira on 08/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDevicePushTransportType;

typedef NS_ENUM(NSUInteger, ARTDevicePushState) {
    ARTDevicePushStateInitialized,
    ARTDevicePushStateActive,
    ARTDevicePushStateFailing,
    ARTDevicePushStateFailed
};

@interface ARTDevicePushDetails : NSObject

@property (nonatomic, readonly) NSString *transportType;
@property (nonatomic) NSString *deviceToken;
@property (nonatomic, assign) ARTDevicePushState state;
@property (nullable, nonatomic) ARTErrorInfo *errorReason;

@end

NS_ASSUME_NONNULL_END
