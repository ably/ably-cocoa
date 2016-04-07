//
//  ARTRestPresence.h
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTPresence.h"
#import "ARTDataQuery.h"

@class ARTRestChannel;

ART_ASSUME_NONNULL_BEGIN

@interface ARTPresenceQuery : NSObject

@property (nonatomic, readwrite) NSUInteger limit;
@property (nonatomic, strong, readwrite) NSString *clientId;
@property (nonatomic, strong, readwrite) NSString *connectionId;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *__art_nullable)clientId connectionId:(NSString *__art_nullable)connectionId;
- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *__art_nullable)clientId connectionId:(NSString *__art_nullable)connectionId;

@end

@interface ARTRestPresence : ARTPresence

- (void)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback;
- (BOOL)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;
- (BOOL)get:(ARTPresenceQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;

- (BOOL)history:(art_nullable ARTDataQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;

@end

ART_ASSUME_NONNULL_END
