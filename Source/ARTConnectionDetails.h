#import <Foundation/Foundation.h>

@class ARTProtocolMessage;

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains any constraints a client should adhere to and provides additional metadata about a [`Connection`]{@link Connection}, such as if a request to [`publish()`]{@link RealtimeClient#publish} a message that exceeds the maximum message size should be rejected immediately without communicating with Ably.
 * END CANONICAL DOCSTRING
 */
@interface ARTConnectionDetails : NSObject

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains the client ID assigned to the token. If `clientId` is `null` or omitted, then the client is prohibited from assuming a `clientId` in any operations, however if `clientId` is a wildcard string `*`, then the client is permitted to assume any `clientId`. Any other string value for `clientId` implies that the `clientId` is both enforced and assumed for all operations from this client.
 * END CANONICAL DOCSTRING
 */
@property (readonly, getter=getClientId, nullable) NSString *clientId;

/**
 * BEGIN CANONICAL DOCSTRING
 * The connection secret key string that is used to resume a connection and its state.
 * END CANONICAL DOCSTRING
 */
@property (readonly, getter=getConnectionKey, nullable) NSString *connectionKey;

/**
 * BEGIN CANONICAL DOCSTRING
 * Overrides the default `maxMessageSize`.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * -1 means 'undefined'.
 * END LEGACY DOCSTRING
 */
@property (readonly, nonatomic) NSInteger maxMessageSize;

/**
 * BEGIN CANONICAL DOCSTRING
 * Overrides the default `maxFrameSize`.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * -1 means 'undefined'.
 * END LEGACY DOCSTRING
 */
@property (readonly, nonatomic) NSInteger maxFrameSize;

/**
 * BEGIN CANONICAL DOCSTRING
 * The maximum allowable number of requests per second from a client or Ably. In the case of a realtime connection, this restriction applies to the number of messages sent, whereas in the case of REST, it is the total number of REST requests per second.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Represents the maximum allowable number of requests per second from a client or Ably. In the case of a realtime connection, this restriction applies to the number of ProtocolMessage objects sent, whereas in the case of REST, it is the total number of REST requests per second.
 * END LEGACY DOCSTRING
 */
@property (readonly, nonatomic) NSInteger maxInboundRate;

/**
 * BEGIN CANONICAL DOCSTRING
 * The duration that Ably will persist the connection state for when a Realtime client is abruptly disconnected.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Represents the duration that Ably will persist the connection state when a Realtime client is abruptly disconnected.
 * END LEGACY DOCSTRING
 */
@property (readonly, nonatomic) NSTimeInterval connectionStateTtl;

/**
 * BEGIN CANONICAL DOCSTRING
 * A unique identifier for the front-end server that the client has connected to. This server ID is only used for the purposes of debugging.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Represents a unique identifier for the front-end server that the client has connected to. This server ID is only used for the purposes of debugging.
 * END LEGACY DOCSTRING
 */
@property (readonly, strong, nonatomic, nullable) NSString *serverId;

/**
 Represents the maximum length of time in seconds that the server will allow no activity to occur in the server -> client direction. After such a period of inactivity, the server will send a HEARTBEAT or transport-level ping to the client. If the value is 0, the server will allow arbitrarily-long levels of inactivity.
 */
@property (readonly, nonatomic) NSTimeInterval maxIdleInterval;

- (instancetype)initWithClientId:(NSString *_Nullable)clientId
                   connectionKey:(NSString *_Nullable)connectionKey
                  maxMessageSize:(NSInteger)maxMessageSize
                    maxFrameSize:(NSInteger)maxFrameSize
                  maxInboundRate:(NSInteger)maxInboundRate
              connectionStateTtl:(NSTimeInterval)connectionStateTtl
                        serverId:(NSString *)serverId
                 maxIdleInterval:(NSTimeInterval)maxIdleInterval;

NS_ASSUME_NONNULL_END

@end
