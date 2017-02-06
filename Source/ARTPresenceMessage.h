//
//  ARTPresenceMessage.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTBaseMessage.h"

/// Presence action type
typedef NS_ENUM(NSUInteger, ARTPresenceAction) {
    ARTPresenceAbsent,
    ARTPresencePresent,
    ARTPresenceEnter,
    ARTPresenceLeave,
    ARTPresenceUpdate
};

NSString *__art_nonnull ARTPresenceActionToStr(ARTPresenceAction action);

/// List of members present on a channel
@interface ARTPresenceMessage : ARTBaseMessage

@property (readwrite, assign, nonatomic) ARTPresenceAction action;

- (NSString *)memberKey;

- (BOOL)isEqualToPresenceMessage:(ARTPresenceMessage *)presence;

@end
