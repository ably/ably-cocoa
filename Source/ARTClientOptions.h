#import <Foundation/Foundation.h>

#import <Ably/ARTAuthOptions.h>
#import <Ably/ARTLog.h>

@class ARTPlugin;
@class ARTStringifiable;
@protocol ARTPushRegistererDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Passes additional client-specific properties to the REST [`constructor()`]{@link RestClient#constructor} or the Realtime [`constructor()`]{@link RealtimeClient#constructor}.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTClientOptions is used in the ``ARTRealtime`` object constructor’s argument.
 * END LEGACY DOCSTRING
 */
@interface ARTClientOptions : ARTAuthOptions

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables a non-default Ably host to be specified. For development environments only. The default value is `rest.ably.io`.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, strong, nonatomic) NSString *restHost;

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables a non-default Ably host to be specified for realtime connections. For development environments only. The default value is `realtime.ably.io`.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, strong, nonatomic) NSString *realtimeHost;

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables a non-default Ably port to be specified. For development environments only. The default value is 80.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, assign) NSInteger port;

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables a non-default Ably TLS port to be specified. For development environments only. The default value is 443.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, assign) NSInteger tlsPort;

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables a [custom environment](https://ably.com/docs/platform-customization) to be used with the Ably service.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, strong, nonatomic) NSString *environment;

/**
 * BEGIN CANONICAL DOCSTRING
 * When `false`, the client will use an insecure connection. The default is `true`, meaning a TLS connection will be used to connect to Ably.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, assign) BOOL tls;

/**
 * BEGIN CANONICAL DOCSTRING
 * Controls the log output of the library. This is a function to handle each line of log output.
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, strong, readwrite) ARTLog *logHandler;

/**
 * BEGIN CANONICAL DOCSTRING
 * Controls the log output of the library. This is a number controlling the verbosity of the output. Valid values are: 0 (no logs), 1 (errors only), 2 (errors plus connection and channel state changes), 3 (abbreviated debug output), and 4 (full debug output).
 * END CANONICAL DOCSTRING
 */
@property (nonatomic, assign) ARTLogLevel logLevel;

/**
 * BEGIN CANONICAL DOCSTRING
 * If `false`, this disables the default behavior whereby the library queues messages on a connection in the disconnected or connecting states. The default behavior enables applications to submit messages immediately upon instantiating the library without having to wait for the connection to be established. Applications may use this option to disable queueing if they wish to have application-level control over the queueing. The default is `true`.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL queueMessages;

/**
 * BEGIN CANONICAL DOCSTRING
 * If `false`, prevents messages originating from this connection being echoed back on the same connection. The default is `true`.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL echoMessages;

/**
 * BEGIN CANONICAL DOCSTRING
 * When `true`, the more efficient MsgPack binary encoding is used. When `false`, JSON text encoding is used. The default is `true`.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL useBinaryProtocol;

/**
 * BEGIN CANONICAL DOCSTRING
 * When `true`, the client connects to Ably as soon as it is instantiated. You can set this to `false` and explicitly connect to Ably using the [`connect()`]{@link Connection#connect} method. The default is `true`.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL autoConnect;

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables a connection to inherit the state of a previous connection that may have existed under a different instance of the Realtime library. This might typically be used by clients of the browser library to ensure connection state can be preserved when the user refreshes the page. A recovery key string can be explicitly provided, or alternatively if a callback function is provided, the client library will automatically persist the recovery key between page reloads and call the callback when the connection is recoverable. The callback is then responsible for confirming whether the connection should be recovered or not. See [connection state recovery](https://ably.com/docs/realtime/connection/#connection-state-recovery) for further information.
 * END CANONICAL DOCSTRING
 */
@property (nullable, readwrite, copy, nonatomic) NSString *recover;
@property (readwrite, assign, nonatomic) BOOL pushFullWait;

/**
 * BEGIN CANONICAL DOCSTRING
 * A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. Note that a `clientId` may also be implicit in a token used to instantiate the library. An error will be raised if a `clientId` specified here conflicts with the `clientId` implicit in the token.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * The id of the client represented by this instance.
 * The clientId is relevant to presence operations, where the clientId is the principal identifier of the client in presence update messages. The clientId is also relevant to authentication; a token issued for a specific client may be used to authenticate the bearer of that token to the service.
 * END LEGACY DOCSTRING
 */
@property (readwrite, strong, nonatomic, nullable) NSString *clientId;

/**
 * BEGIN CANONICAL DOCSTRING
 * When a [`TokenParams`]{@link TokenParams} object is provided, it overrides the client library defaults when issuing new Ably Tokens or Ably [`TokenRequest`s]{@link TokenRequest}.
 * END CANONICAL DOCSTRING
 */
@property (readwrite, strong, nonatomic, nullable) ARTTokenParams *defaultTokenParams;

/**
 * BEGIN CANONICAL DOCSTRING
 * If the connection is still in the [`DISCONNECTED`]{@link ConnectionState#disconnected} state after this delay, the client library will attempt to reconnect automatically. The default is 15 seconds.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Represents the timeout (in seconds) to retry connection when it's disconnected.
 * When the connection is in the DISCONNECTED state, how frequently the client library attempts to reconnect automatically.
 * END LEGACY DOCSTRING
 */
@property (readwrite, assign, nonatomic) NSTimeInterval disconnectedRetryTimeout;

/**
 Represents the timeout (in seconds) to retry connection when it's suspended.
 When the connection is in the SUSPENDED state, how frequently the client library attempts to reconnect automatically.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval suspendedRetryTimeout;

/**
 Represents the timeout (in seconds) to re-attach the channel automatically.
 When a channel becomes SUSPENDED following a server initiated DETACHED, after this delay in milliseconds, if the channel is still SUSPENDED and the connection is CONNECTED, the client library will attempt to re-attach.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval channelRetryTimeout;

/**
 Timeout for opening the connection, available in the client library if supported by the transport.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpOpenTimeout;

/**
 Timeout for any single HTTP request and response.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpRequestTimeout;

/**
 The period in seconds before HTTP requests are retried against the default endpoint.
 (After a failed request to the default endpoint, followed by a successful request to a fallback endpoint)
 */
@property (readwrite, assign, nonatomic) NSTimeInterval fallbackRetryTimeout;

/**
 Max number of fallback host retries for HTTP requests that fail due to network issues or server problems.
 */
@property (readwrite, assign, nonatomic) NSUInteger httpMaxRetryCount;

/**
 Max elapsed time in which fallback host retries for HTTP requests will be attempted i.e. if the first default host attempt takes 5s, and then the subsequent fallback retry attempt takes 7s, no further fallback host attempts will be made as the total elapsed time of 12s exceeds the default 10s limit.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpMaxRetryDuration;

/**
 * BEGIN CANONICAL DOCSTRING
 * An array of fallback hosts to be used in the case of an error necessitating the use of an alternative host. If you have been provided a set of custom fallback hosts by Ably, please specify them here.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Optionally allows one or more fallback hosts to be used instead of the default fallback hosts.
 * END LEGACY DOCSTRING
 */
@property (nullable, nonatomic, copy) NSArray<NSString *> *fallbackHosts;

/**
 * BEGIN CANONICAL DOCSTRING
 * DEPRECATED: this property is deprecated and will be removed in a future version. Enables default fallback hosts to be used.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Optionally allows the default fallback hosts `[a-e].ably-realtime.com` to be used when `environment` is not production or a custom realtime or REST host endpoint is being used. It is never valid to configure `fallbackHost` and set `fallbackHostsUseDefault` to `true`.
 * END LEGACY DOCSTRING
 */
@property (assign, nonatomic) BOOL fallbackHostsUseDefault DEPRECATED_MSG_ATTRIBUTE("Future library releases will ignore any supplied value.");

/**
 * BEGIN CANONICAL DOCSTRING
 * DEPRECATED: this property is deprecated and will be removed in a future version. Defaults to a string value for an Ably error reporting DSN (Data Source Name), which is typically a URL in the format `https://[KEY]:[SECRET]@errors.ably.io/[ID]`. When set to `null`, `false` or an empty string (depending on what is idiomatic for the platform), exception reporting is disabled.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Report uncaught exceptions to Ably, together with the last lines of the logger. This helps Ably fix bugs. Set to nil to disable.
 * END LEGACY DOCSTRING
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
 True when idempotent publishing is enabled for all messages published via REST.

 When this feature is enabled, the client library will add a unique ID to every published message (without an ID) ensuring any failed published attempts (due to failures such as HTTP requests failing mid-flight) that are automatically retried will not result in duplicate messages being published to the Ably platform.

 Note: This is a beta unsupported feature!
 */
@property (readwrite, assign, nonatomic) BOOL idempotentRestPublishing;

/**
 * BEGIN CANONICAL DOCSTRING
 * When `true`, every REST request to Ably should include a random string in the `request_id` query string parameter. The random string should be a url-safe base64-encoding sequence of at least 9 bytes, obtained from a source of randomness. This request ID must remain the same if a request is retried to a fallback host. Any log messages associated with the request should include the request ID. If the request fails, the request ID must be included in the [`ErrorInfo`]{@link ErrorInfo} returned to the user. The default is `false`.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * If enabled, every REST request to Ably includes a `request_id` query string parameter. This request ID remain the same if a request is retried to a fallback host.
 * END LEGACY DOCSTRING
 */
@property (readwrite, assign, nonatomic) BOOL addRequestIds;

/**
 * BEGIN CANONICAL DOCSTRING
 * Can be used to pass in arbitrary connection parameters, such as [`heartbeatInterval`](https://ably.com/docs/realtime/connection#heartbeats) or [`remainPresentFor`](https://ably.com/docs/realtime/presence#unstable-connections).
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
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
 All agents added with `addAgent:version:` method plus `[ARTDefault libraryAgent]` and `[ARTDefault platformAgent]`.
 */

- (NSString *)agents;

@end

NS_ASSUME_NONNULL_END
