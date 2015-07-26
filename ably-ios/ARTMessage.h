//
//  ARTMessage.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTPayload.h"


@class ARTStatus;
@interface ARTMessage : NSObject

@property (readwrite, strong, nonatomic) NSString *id;
@property (readwrite, strong, nonatomic) NSString *name;
@property (readwrite, strong, nonatomic) NSString *clientId;
@property (readwrite, strong, nonatomic) NSString *connectionId;
@property (readwrite, strong, nonatomic) ARTPayload *payload;
@property (readwrite, strong, nonatomic) NSDate *timestamp;
@property (readwrite, strong, nonatomic) ARTStatus * status;

- (instancetype)init;
- (ARTMessage *)messageWithPayload:(ARTPayload *)payload;

- (ARTMessage *)decode:(id<ARTPayloadEncoder>)encoder;
- (ARTMessage *)encode:(id<ARTPayloadEncoder>)encoder;
- (id) content;

+ (ARTMessage *) messageWithPayload:(id) payload name:(NSString *) name;
+ (NSArray *) messagesWithPayloads:(NSArray *) payloads;
@end