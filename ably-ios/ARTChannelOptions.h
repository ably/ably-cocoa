//
//  ARTChannelOptions.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTCipherParams;

NS_ASSUME_NONNULL_BEGIN

@interface ARTChannelOptions : NSObject

@property (nonatomic, assign) BOOL isEncrypted;
@property (nonatomic, strong, nullable) ARTCipherParams *cipherParams;

+ (instancetype)unencrypted;

- (instancetype)initEncrypted:(ARTCipherParams *)cipherParams;

@end

NS_ASSUME_NONNULL_END
