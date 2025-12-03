#import "ARTConnectionDetails+Private.h"

@implementation ARTConnectionDetails

- (instancetype)initWithClientId:(NSString *_Nullable)clientId
                   connectionKey:(NSString *_Nullable)connectionKey
                  maxMessageSize:(NSInteger)maxMessageSize
                    maxFrameSize:(NSInteger)maxFrameSize
                  maxInboundRate:(NSInteger)maxInboundRate
              connectionStateTtl:(NSTimeInterval)connectionStateTtl
                        serverId:(NSString *)serverId
                 maxIdleInterval:(NSTimeInterval)maxIdleInterval
            objectsGCGracePeriod:(nullable NSNumber *)objectsGCGracePeriod {
    if (self = [super init]) {
        _clientId = clientId;
        _connectionKey = connectionKey;
        _maxMessageSize = maxMessageSize;
        _maxFrameSize = maxFrameSize;
        _maxInboundRate = maxInboundRate;
        _connectionStateTtl = connectionStateTtl;
        _serverId = serverId;
        _maxIdleInterval = maxIdleInterval;
        _objectsGCGracePeriod = objectsGCGracePeriod;
    }
    return self;
}

- (void)setMaxIdleInterval:(NSTimeInterval)seconds {
    _maxIdleInterval = seconds;
}

@end
