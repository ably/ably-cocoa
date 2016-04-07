//
//  ARTPresence.h
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTPresenceMessage.h"
#import "ARTPaginatedResult.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTPresence : NSObject

- (void)history:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
