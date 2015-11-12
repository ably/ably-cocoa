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

ART_ASSUME_NONNULL_BEGIN

@interface ARTRestChannel : ARTChannel

@property (nonatomic, weak) ARTRest *rest;
@property (readonly, getter=getLogger) ARTLog *logger;

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRest *)rest;

@end

ART_ASSUME_NONNULL_END
