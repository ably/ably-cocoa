//
//  ARTConnectionDetails.m
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTConnectionDetails+Private.h"

@implementation ARTConnectionDetails

- (instancetype)initWithClientId:(NSString *__art_nullable)clientId
                   connectionKey:(NSString *__art_nullable)connectionKey
                  maxMessageSize:(NSInteger)maxMessageSize
                    maxFrameSize:(NSInteger)maxFrameSize
                  maxInboundRate:(NSInteger)maxInboundRate
              connectionStateTtl:(NSTimeInterval)connectionStateTtl
                        serverId:(NSString *)serverId {
    if (self == [super init]) {
        _clientId = clientId;
        _connectionKey = connectionKey;
        _maxMessageSize = maxMessageSize;
        _maxFrameSize = maxFrameSize;
        _maxInboundRate = maxInboundRate;
        _connectionStateTtl = connectionStateTtl;
        _serverId = serverId;
    }
    return self;
}

@end
