//
//  ARTConnectionDetails.h
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

@class ARTProtocolMessage;

@interface ARTConnectionDetails : NSObject

ART_ASSUME_NONNULL_BEGIN

@property (readonly, getter=getClientId, art_nullable) NSString *clientId;
@property (readonly, getter=getConnectionKey, art_nullable) NSString *connectionKey;
// In those, -1 means 'undefined'.
@property (readonly, nonatomic) NSInteger maxMessageSize;
@property (readonly, nonatomic) NSInteger maxFrameSize;
@property (readonly, nonatomic) NSInteger maxInboundRate;
@property (readonly, nonatomic) NSTimeInterval connectionStateTtl;
@property (readonly, strong, nonatomic, art_nullable) NSString *serverId;

- (instancetype)initWithClientId:(NSString *__art_nullable)clientId
                   connectionKey:(NSString *__art_nullable)connectionKey
                  maxMessageSize:(NSInteger)maxMessageSize
                    maxFrameSize:(NSInteger)maxFrameSize
                  maxInboundRate:(NSInteger)maxInboundRate
              connectionStateTtl:(NSTimeInterval)connectionStateTtl
                        serverId:(NSString *)serverId;

ART_ASSUME_NONNULL_END

@end
