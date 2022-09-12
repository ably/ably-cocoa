#import <Foundation/Foundation.h>

@class ARTProtocolMessage;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains any constraints a client should adhere to and provides additional metadata about a `ARTConnection`, such as if a request to `-[ARTChannel publish:]` a message that exceeds the maximum message size should be rejected immediately without communicating with Ably.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTConnectionDetails : NSObject

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the client ID assigned to the token. If `clientId` is `nil` or omitted, then the client is prohibited from assuming a `clientId` in any operations, however if `clientId` is a wildcard string `*`, then the client is permitted to assume any `clientId`. Any other string value for `clientId` implies that the `clientId` is both enforced and assumed for all operations from this client.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, getter=getClientId, nullable) NSString *clientId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The connection secret key string that is used to resume a connection and its state.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, getter=getConnectionKey, nullable) NSString *connectionKey;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The maximum message size is an attribute of an Ably account and enforced by Ably servers. `maxMessageSize` indicates the maximum message size allowed by the Ably account this connection is using. Overrides the default value of `-[ARTDefault maxMessageSize]`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) NSInteger maxMessageSize;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Overrides the default `maxFrameSize`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) NSInteger maxFrameSize;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The maximum allowable number of requests per second from a client or Ably. In the case of a realtime connection, this restriction applies to the number of messages sent, whereas in the case of REST, it is the total number of REST requests per second.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) NSInteger maxInboundRate;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The duration that Ably will persist the connection state for when a Realtime client is abruptly disconnected.
 * @see `+[ARTDefault connectionStateTtl]`
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) NSTimeInterval connectionStateTtl;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A unique identifier for the front-end server that the client has connected to. This server ID is only used for the purposes of debugging.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic, nullable) NSString *serverId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The maximum length of time in milliseconds that the server will allow no activity to occur in the server to client direction. After such a period of inactivity, the server will send a `ARTProtocolMessageHeartbeat` or transport-level ping to the client. If the value is `0`, the server will allow arbitrarily-long levels of inactivity.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, nonatomic) NSTimeInterval maxIdleInterval;

/// :nodoc:
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
