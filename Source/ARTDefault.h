#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTDefault : NSObject

+ (NSString *)apiVersion;
+ (NSString *)libraryVersion;

+ (NSArray<NSString *> *)fallbackHosts;
+ (NSArray<NSString *> *)fallbackHostsWithEnvironment:(NSString *_Nullable)environment;
+ (NSString*)restHost;
+ (NSString*)realtimeHost;
+ (int)port;
+ (int)tlsPort;

/**
 Default in seconds of requested time to live for the token.
 */
+ (NSTimeInterval)ttl;

/**
 When the client is in the DISCONNECTED state, once this TTL has passed, the client should change the state to the SUSPENDED state signifying that the state is now lost i.e. channels need to be reattached manually.
 
 Note that this default is override by any connectionStateTtl specified in the ConnectionDetails of the CONNECTED ProtocolMessage.
 */
+ (NSTimeInterval)connectionStateTtl;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Timeout for the wait of acknowledgement for operations performed via a realtime connection, before the client library considers a request failed and triggers a failure condition. Operations include establishing a connection with Ably, or sending a `ARTProtocolMessageHeartbeat`, `ARTProtocolMessageConnect`, `ARTProtocolMessageAttach`, `ARTProtocolMessageDetach` or `ARTProtocolMessageClose` request. It is the equivalent of `-[ARTClientOptions httpRequestTimeout]` but for realtime operations, rather than REST. The default is 10 seconds.
 * END CANONICAL PROCESSED DOCSTRING
 */
+ (NSTimeInterval)realtimeRequestTimeout;

+ (NSString *)libraryAgent;

+ (NSString *)platformAgent;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The maximum size of messages that can be published in one go. For realtime publishes, the default can be overridden by the `maxMessageSize` in the `ARTConnectionDetails` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
+ (NSInteger)maxMessageSize;

@end

NS_ASSUME_NONNULL_END
