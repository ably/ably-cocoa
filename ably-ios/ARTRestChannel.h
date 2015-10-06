//
//  ARTRestChannel.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTChannel.h"

@class ARTRest;
@class ARTChannelOptions;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRestChannel : ARTChannel

@property (nonatomic, strong, readonly) ARTPresence *presence;
@property (nonatomic, strong) NSString *basePath;

//- (instancetype)initWithRest:(ARTRest *)rest name:(NSString *)name options:(art_nullable ARTChannelOptions *)options;

@end

ART_ASSUME_NONNULL_END
