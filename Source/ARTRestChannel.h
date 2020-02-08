//
//  ARTRestChannel.h
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTChannel.h>
#import <Ably/ARTLog.h>

@class ARTRest;
@class ARTRestPresence;
@class ARTPushChannel;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTRestChannelProtocol <ARTChannelProtocol>

- (BOOL)history:(nullable ARTDataQuery *)query callback:(void(^)(ARTPaginatedResult<ARTMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

@interface ARTRestChannel : NSObject <ARTRestChannelProtocol>

@property (readonly) ARTRestPresence *presence;
@property (readonly) ARTPushChannel *push;

@end

NS_ASSUME_NONNULL_END
