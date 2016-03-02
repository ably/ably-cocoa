//
//  ARTRestPresence.h
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTPresence.h"

@class ARTRestChannel;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRestPresence : ARTPresence

- (instancetype)initWithChannel:(ARTRestChannel *)channel;

@end

ART_ASSUME_NONNULL_END
