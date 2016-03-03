//
//  ARTQueuedMessage.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

@class ARTProtocolMessage;

@interface ARTQueuedMessage : NSObject

@property (readonly, strong, nonatomic) ARTProtocolMessage *msg;
@property (readonly, strong, nonatomic) NSMutableArray *cbs;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg callback:(void (^)(ARTStatus *))cb;
- (BOOL)mergeFrom:(ARTProtocolMessage *)msg callback:(void (^)(ARTStatus *))cb;

- (void (^)(ARTStatus *))cb;

@end
