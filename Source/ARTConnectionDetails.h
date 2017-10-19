//
//  ARTConnectionDetails.h
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTProtocolMessage;

@interface ARTConnectionDetails : NSObject

NS_ASSUME_NONNULL_BEGIN

@property (readonly, getter=getClientId, nullable) NSString *clientId;
@property (readonly, getter=getConnectionKey, nullable) NSString *connectionKey;
// In those, -1 means 'undefined'.
@property (readonly, nonatomic) NSInteger maxMessageSize;
@property (readonly, nonatomic) NSInteger maxFrameSize;
@property (readonly, nonatomic) NSInteger maxInboundRate;
@property (readonly, nonatomic) NSTimeInterval connectionStateTtl;
@property (readonly, strong, nonatomic, nullable) NSString *serverId;

- (instancetype)initWithClientId:(NSString *_Nullable)clientId
                   connectionKey:(NSString *_Nullable)connectionKey
                  maxMessageSize:(NSInteger)maxMessageSize
                    maxFrameSize:(NSInteger)maxFrameSize
                  maxInboundRate:(NSInteger)maxInboundRate
              connectionStateTtl:(NSTimeInterval)connectionStateTtl
                        serverId:(NSString *)serverId;

NS_ASSUME_NONNULL_END

@end
