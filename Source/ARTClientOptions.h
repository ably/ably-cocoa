#import <Foundation/Foundation.h>

#import <Ably/ARTAuthOptions.h>
#import <Ably/ARTLog.h>

@class ARTPlugin;
@class ARTStringifiable;
@protocol ARTPushRegistererDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Passes additional client-specific properties to the REST `-[ARTRestClient initWithOptions:]` or the Realtime `-[ARTRealtimeClient initWithOptions:]`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTClientOptions : ARTAuthOptions

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables a non-default Ably host to be specified. For development environments only. The default value is `rest.ably.io`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, strong, nonatomic) NSString *restHost;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables a non-default Ably host to be specified for realtime connections. For development environments only. The default value is `realtime.ably.io`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, strong, nonatomic) NSString *realtimeHost;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables a non-default Ably port to be specified. For development environments only. The default value is 80.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, assign) NSInteger port;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables a non-default Ably TLS port to be specified. For development environments only. The default value is 443.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, assign) NSInteger tlsPort;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables a [custom environment](https://ably.com/docs/platform-customization) to be used with the Ably service.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, strong, nonatomic) NSString *environment;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When `false`, the client will use an insecure connection. The default is `true`, meaning a TLS connection will be used to connect to Ably.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, assign) BOOL tls;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Controls the log output of the library. This is an object to handle each line of log output.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, readwrite) ARTLog *logHandler;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Controls the verbosity of the logs output from the library. Levels include `ARTLogLevelVerbose`, `ARTLogLevelDebug`, `ARTLogLevelInfo`, `ARTLogLevelWarn` and `ARTLogLevelError`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, assign) ARTLogLevel logLevel;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * If `false`, this disables the default behavior whereby the library queues messages on a connection in the disconnected or connecting states. The default behavior enables applications to submit messages immediately upon instantiating the library without having to wait for the connection to be established. Applications may use this option to disable queueing if they wish to have application-level control over the queueing. The default is `true`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL queueMessages;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * If `false`, prevents messages originating from this connection being echoed back on the same connection. The default is `true`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL echoMessages;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When `true`, the more efficient MsgPack binary encoding is used. When `false`, JSON text encoding is used. The default is `true`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL useBinaryProtocol;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When `true`, the client connects to Ably as soon as it is instantiated. You can set this to `false` and explicitly connect to Ably using the `-[ARTConnection connect]` method. The default is `true`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL autoConnect;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables a connection to inherit the state of a previous connection that may have existed under a different instance of the Realtime library. This might typically be used by clients of the browser library to ensure connection state can be preserved when the user refreshes the page. A recovery key string can be explicitly provided, or alternatively if a callback function is provided, the client library will automatically persist the recovery key between page reloads and call the callback when the connection is recoverable. The callback is then responsible for confirming whether the connection should be recovered or not. See [connection state recovery](https://ably.com/docs/realtime/connection/#connection-state-recovery) for further information.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, readwrite, copy, nonatomic) NSString *recover;

@property (readwrite, assign, nonatomic) BOOL pushFullWait;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. Note that a `clientId` may also be implicit in a token used to instantiate the library. An error will be raised if a `clientId` specified here conflicts with the `clientId` implicit in the token.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * The id of the client represented by this instance.
 * The clientId is relevant to presence operations, where the clientId is the principal identifier of the client in presence update messages. The clientId is also relevant to authentication; a token issued for a specific client may be used to authenticate the bearer of that token to the service.
 * END LEGACY DOCSTRING
 */
@property (readwrite, strong, nonatomic, nullable) NSString *clientId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When a `ARTTokenParams` object is provided, it overrides the client library defaults when issuing new Ably Tokens or Ably `ARTTokenRequest`s.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, strong, nonatomic, nullable) ARTTokenParams *defaultTokenParams;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * If the connection is still in the `ARTRealtimeDisconnected` state after this delay, the client library will attempt to reconnect automatically. The default is 15 seconds.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSTimeInterval disconnectedRetryTimeout;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When the connection enters the `ARTRealtimeSuspended` state, after this delay, if the state is still `ARTRealtimeSuspended`, the client library attempts to reconnect automatically. The default is 30 seconds.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSTimeInterval suspendedRetryTimeout;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When a channel becomes `ARTRealtimeChannelSuspended` following a server initiated `ARTRealtimeChannelDetached`, after this delay, if the channel is still `ARTRealtimeChannelSuspended` and the connection is `ARTRealtimeConnected`, the client library will attempt to re-attach the channel automatically. The default is 15 seconds.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSTimeInterval channelRetryTimeout;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Timeout for opening a connection to Ably to initiate an HTTP request. The default is 4 seconds.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpOpenTimeout;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Timeout for a client performing a complete HTTP request to Ably, including the connection phase. The default is 10 seconds.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpRequestTimeout;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The maximum time before HTTP requests are retried against the default endpoint. The default is 600 seconds.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * The period in seconds before HTTP requests are retried against the default endpoint. (After a failed request to the default endpoint, followed by a successful request to a fallback endpoint)
 * END LEGACY DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSTimeInterval fallbackRetryTimeout;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The maximum number of fallback hosts to use as a fallback when an HTTP request to the primary host is unreachable or indicates that it is unserviceable. The default value is 3.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSUInteger httpMaxRetryCount;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The maximum elapsed time in which fallback host retries for HTTP requests will be attempted. The default is 15 seconds.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * Max elapsed time in which fallback host retries for HTTP requests will be attempted i.e. if the first default host attempt takes 5s, and then the subsequent fallback retry attempt takes 7s, no further fallback host attempts will be made as the total elapsed time of 12s exceeds the default 10s limit.
 * END LEGACY DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpMaxRetryDuration;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An array of fallback hosts to be used in the case of an error necessitating the use of an alternative host. If you have been provided a set of custom fallback hosts by Ably, please specify them here.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * Optionally allows one or more fallback hosts to be used instead of the default fallback hosts.
 * END LEGACY DOCSTRING
 */
@property (nullable, nonatomic, copy) NSArray<NSString *> *fallbackHosts;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * DEPRECATED: this property is deprecated and will be removed in a future version. Enables default fallback hosts to be used.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (assign, nonatomic) BOOL fallbackHostsUseDefault DEPRECATED_MSG_ATTRIBUTE("Future library releases will ignore any supplied value.");

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * DEPRECATED: this property is deprecated and will be removed in a future version. Defaults to a string value for an Ably error reporting DSN (Data Source Name), which is typically a URL in the format `https://[KEY]:[SECRET]@errors.ably.io/[ID]`. When set to `nil` exception reporting is disabled.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, strong, nonatomic, nullable) NSString *logExceptionReportingUrl;

/**
 The queue to which all calls to user-provided callbacks will be dispatched
 asynchronously. It will be used as target queue for an internal, serial queue.

 It defaults to the main queue.
 */
@property (readwrite, strong, nonatomic) dispatch_queue_t dispatchQueue;

/**
 The queue to which all internal concurrent operations will be dispatched.
 It must be a serial queue. It shouldn't be the same queue as dispatchQueue.

 It defaults to a newly created serial queue.
 */
@property (readwrite, strong, nonatomic) dispatch_queue_t internalDispatchQueue;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When `true`, enables idempotent publishing by assigning a unique message ID client-side, allowing the Ably servers to discard automatic publish retries following a failure such as a network fault. The default is `true`.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * True when idempotent publishing is enabled for all messages published via REST.
 * When this feature is enabled, the client library will add a unique ID to every published message (without an ID) ensuring any failed published attempts (due to failures such as HTTP requests failing mid-flight) that are automatically retried will not result in duplicate messages being published to the Ably platform.
 * Note: This is a beta unsupported feature!
 * END LEGACY DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL idempotentRestPublishing;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When `true`, every REST request to Ably should include a random string in the `request_id` query string parameter. The random string should be a url-safe base64-encoding sequence of at least 9 bytes, obtained from a source of randomness. This request ID must remain the same if a request is retried to a fallback host. Any log messages associated with the request should include the request ID. If the request fails, the request ID must be included in the `ARTErrorInfo` returned to the user. The default is `false`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL addRequestIds;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A set of key-value pairs that can be used to pass in arbitrary connection parameters, such as [`heartbeatInterval`](https://ably.com/docs/realtime/connection#heartbeats) or [`remainPresentFor`](https://ably.com/docs/realtime/presence#unstable-connections).
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * Additional parameters to be sent in the querystring when initiating a realtime connection. Keys are Strings, values are Stringifiable (a value that can be coerced to a string in order to be sent as a querystring parameter. Supported values should be at least strings, numbers, and booleans, with booleans stringified as true and false. If this is unidiomatic to the language, the implementer may consider this as equivalent to String).
 * Note:  If a key in transportParams is one the library sends by default (for example, v or heartbeats), the value in transportParams takes precedence.
 * END LEGACY DOCSTRING
 */
@property (nonatomic, copy, nullable) NSDictionary<NSString *, ARTStringifiable *> *transportParams;

/**
 The object that processes Push activation/deactivation-related actions.
 */
@property (nullable, weak, nonatomic) id<ARTPushRegistererDelegate, NSObject> pushRegistererDelegate;

- (BOOL)isBasicAuth;
- (NSURL *)restUrl;
- (NSURL *)realtimeUrl;

/**
 Method for adding additional agent to the resulting agent header.
 
 This should only be used by Ably-authored SDKs.
 If you need to use this then you have to add the agent to the agents.json file:
 https://github.com/ably/ably-common/blob/main/protocol/agents.json
 
 Agent versions are optional, if you don't want to specify it pass `nil`.
*/
- (void)addAgent:(NSString *)agentName version:(NSString * _Nullable)version;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A set of additional entries for the Ably agent header. Each entry can be a key string or set of key-value pairs.
 * Consists of `+[ARTDefault libraryAgent]`, `+[ARTDefault platformAgent]` and items added with `-[ARTClientOptions addAgent:version:]` function.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * All agents added with `addAgent:version:` method plus `[ARTDefault libraryAgent]` and `[ARTDefault platformAgent]`.
 * END LEGACY DOCSTRING
 */
- (NSString *)agents;

@end

NS_ASSUME_NONNULL_END
