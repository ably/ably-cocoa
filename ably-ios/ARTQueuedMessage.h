//
//  ARTQueuedMessage.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ably.h"

@class ARTProtocolMessage;

@interface ARTQueuedMessage : NSObject

@property (readonly, strong, nonatomic) ARTProtocolMessage *msg;
@property (readonly, strong, nonatomic) NSMutableArray *cbs;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb;
- (BOOL)mergeFrom:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb;

- (ARTStatusCallback)cb;

@end
