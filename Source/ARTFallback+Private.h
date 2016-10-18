//
//  ARTFallback+Private.h
//  Ably
//
//  Created by Ricardo Pereira on 13/10/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#include "ARTFallback.h"
#include "CompatibilityMacros.h"

ART_ASSUME_NONNULL_BEGIN

extern int (^ARTFallback_getRandomHostIndex)(int count);

@interface ARTFallback ()

@property (readwrite, strong, nonatomic) __GENERIC(NSMutableArray, NSString *) *hosts;

@end

ART_ASSUME_NONNULL_END
