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

@class ARTChannel;
@class __GENERIC(ARTPaginatedResult, ItemType);
@class ARTDataQuery;

ART_ASSUME_NONNULL_BEGIN

@interface ARTPresenceQuery : NSObject

@property (nonatomic, readwrite) NSUInteger limit;
@property (nonatomic, strong, readwrite) NSString *clientId;
@property (nonatomic, strong, readwrite) NSString *connectionId;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *__art_nullable)clientId connectionId:(NSString *__art_nullable)connectionId;
- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *__art_nullable)clientId connectionId:(NSString *__art_nullable)connectionId;

@end

/**
 A class that provides access to presence operations and state for the associated Channel.
 */
@interface ARTPresence : NSObject

/**
 Get the presence state for one channel
 */
- (void)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback;
- (void)get:(ARTPresenceQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback;

/**
 Obtain recent presence history for one channel
 */
- (void)history:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback;
- (BOOL)history:(art_nullable ARTDataQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;

@end

ART_ASSUME_NONNULL_END
