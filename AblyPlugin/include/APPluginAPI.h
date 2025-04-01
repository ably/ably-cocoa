@import Foundation;

@class ARTRealtimeChannel;
@class ARTProtocolMessage;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ProtocolMessageListener)
typedef void (^APProtocolMessageListener)(ARTProtocolMessage *);

NS_SWIFT_NAME(PluginAPI)

/// This class provides a stable API for Ably-authored plugins to access certain private functionality of ably-cocoa.
@interface APPluginAPI: NSObject

+ (void)setPluginDataValue:(id)value
                    forKey:(NSString *)key
                   channel:(ARTRealtimeChannel *)channel;

+ (nullable id)pluginDataValueForKey:(NSString *)key
                             channel:(ARTRealtimeChannel *)channel;

// Listener will be called each time a protocol message is received
+ (void)addPluginProtocolMessageListener:(APProtocolMessageListener)listener
                                 channel:(ARTRealtimeChannel *)channel;

+ (void)sendProtocolMessage:(ARTProtocolMessage *)protocolMessage
                    channel:(ARTRealtimeChannel *)channel;

@end

NS_ASSUME_NONNULL_END
