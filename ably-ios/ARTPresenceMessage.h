//
//  ARTPresenceMessage.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTPayload.h"

typedef NS_ENUM(NSUInteger, ARTPresenceMessageAction) {
    ARTPresenceMessageEnter,
    ARTPresenceMessageLeave,
    ARTPresenceMessageUpdate
};

@interface ARTPresenceMessage : NSObject

@property (readwrite, strong, nonatomic) NSString *id;
@property (readwrite, strong, nonatomic) NSString *clientId;
@property (readwrite, strong, nonatomic) ARTPayload *payload;
@property (readwrite, strong, nonatomic) NSDate *timestamp;
@property (readwrite, assign, nonatomic) ARTPresenceMessageAction action;
@property (readwrite, strong, nonatomic) NSString *memberId;

- (ARTPresenceMessage *)messageWithPayload:(ARTPayload *)payload;

- (ARTPresenceMessage *)decode:(id<ARTPayloadEncoder>)encoder;
- (ARTPresenceMessage *)encode:(id<ARTPayloadEncoder>)encoder;

@end
