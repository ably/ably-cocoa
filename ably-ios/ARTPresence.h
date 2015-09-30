//
//  ARTPresence.h
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTMessage.h>
#import <ably/ARTDataQuery.h>
#import <ably/ARTPaginatedResult.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARTPresenceAction) {
    ARTPresenceAbsent,
    ARTPresencePresent,
    ARTPresenceEnter,
    ARTPresenceLeave,
    ARTPresenceUpdate,
    ARTPresenceLast
};

@interface ARTPresenceMessage : ARTMessage

@property (nonatomic, assign) ARTPresenceAction action;

@end

@interface ARTPresence : NSObject

- (void)get:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *__nullable result, NSError *__nullable error))callback;

- (void)history:(nullable ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *__nullable result, NSError *__nullable error))callback;

@end

NS_ASSUME_NONNULL_END
