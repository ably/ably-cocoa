//
//  ARTPresenceMessage.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTPayload.h>

@class ARTStatus;
typedef NS_ENUM(NSUInteger, ARTPresenceMessageAction) {
    ArtPresenceMessageAbsent,
    ArtPresenceMessagePresent,
    ARTPresenceMessageEnter,
    ARTPresenceMessageLeave,
    ARTPresenceMessageUpdate,
    ARTPresenceMessageLast
};

@interface ARTPresenceMessage : NSObject

@property (readwrite, strong, nonatomic) NSString *id;
@property (readwrite, strong, nonatomic) NSString *clientId;
@property (readwrite, strong, nonatomic) NSString *encoding;
@property (readwrite, strong, nonatomic) ARTStatus * status;
@property (readwrite, strong, nonatomic) ARTPayload *payload;
@property (readwrite, strong, nonatomic) NSDate *timestamp;

@property (readwrite, assign, nonatomic) ARTPresenceMessageAction action;
@property (readwrite, strong, nonatomic) NSString *connectionId;

- (ARTPresenceMessage *)messageWithPayload:(ARTPayload *)payload;

- (ARTPresenceMessage *)decode:(id<ARTPayloadEncoder>)encoder;
- (ARTPresenceMessage *)encode:(id<ARTPayloadEncoder>)encoder;
- (id) content;

@end
