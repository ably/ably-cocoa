//
//  ARTRestChannel.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTChannel.h"
#import "ARTLog.h"

@class ARTRest;
@class ARTRestPresence;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRestChannel : ARTChannel

@property (nonatomic, weak) ARTRest *rest;

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRest *)rest;

- (ARTRestPresence *)presence;

@end

ART_ASSUME_NONNULL_END
