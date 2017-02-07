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
@class ARTPushChannel;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRestChannel : ARTChannel

@property (readonly) ARTRestPresence *presence;
@property (readonly) ARTPushChannel *push;

- (BOOL)history:(art_nullable ARTDataQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;

@end

ART_ASSUME_NONNULL_END
