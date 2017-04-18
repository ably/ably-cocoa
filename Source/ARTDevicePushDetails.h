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

@interface ARTDevicePushDetails : NSObject

@property (nullable, nonatomic) NSString *transportType;
@property (nullable, nonatomic) NSString *state;
@property (nullable, nonatomic) ARTErrorInfo *errorReason;
@property (nonatomic) NSDictionary<NSString *, NSString *> *metadata;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
