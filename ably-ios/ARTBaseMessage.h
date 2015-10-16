//
//  ARTBaseMessage.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTPayload.h"

@interface ARTBaseMessage : NSObject<NSCopying>

/// A unique id for this message
@property (strong, nonatomic) NSString *id;

/// The timestamp for this message
@property (strong, nonatomic) NSDate *timestamp;

/// The id of the publisher of this message
@property (strong, nonatomic) NSString *clientId;

/// The connection id of the publisher of this message
@property (strong, nonatomic) NSString *connectionId;

/// Any transformation applied to the data for this message
@property (strong, nonatomic) NSString *encoding;

/// The message payload.
@property (strong, nonatomic) ARTPayload *payload;

- (instancetype)decode:(id<ARTPayloadEncoder>)encoder;
- (instancetype)encode:(id<ARTPayloadEncoder>)encoder;

- (id)content;
- (NSString *)description;

+ (NSArray *)messagesWithPayloads:(NSArray *)payloads;

@end
