@import Foundation;

@class ARTProtocolMessage;
@class ARTErrorInfo;
@protocol ARTErrorChecker;

/**
 The type of the Realtime system’s response to a resume request, as described by RTN15c.
 */
typedef NS_ENUM(NSUInteger, ARTResumeRequestResponseType) {
    /**
     RTN15c6: "This indicates that the resume attempt was valid. The client library should move all channels that were in the `ATTACHING`, `ATTACHED`, or `SUSPENDED` states to the `ATTACHING` state, and initiate an `RTL4c` attach sequence for each. The connection should also process any messages queued per `RTL6c2` (there is no need to wait for the attaches to finish before processing queued messages)."
     */
    ARTResumeRequestResponseTypeValid,

    /**
     RTN15c7: "In this case, the resume was invalid, and the error indicates the cause. The `error` should be set as the `reason` in the `CONNECTED` event, and as the `Connection#errorReason`. The internal `msgSerial` counter should be reset so that the first message published to Ably will contain a `msgSerial` of `0`. The rest of the process is the same as for `RTN16c6`: The client library should move all channels that were in the `ATTACHING`, `ATTACHED`, or `SUSPENDED` states to the `ATTACHING` state, and initiate an `RTL4c` attach sequence for each. The connection should also process any messages queued per `RTL6c2`."
     */
    ARTResumeRequestResponseTypeInvalid,

    /**
     RTN15c5: "The transport will be closed by the server. The spec described in RTN15h must be followed for a connection being resumed with a token error"
     */
    ARTResumeRequestResponseTypeTokenError,

    /**
     RTN15c4: "Any other `ERROR` `ProtocolMessage` indicating a fatal error in the connection. The server will close the transport immediately after. The client should transition to the `FAILED` state triggering all attached channels to transition to the `FAILED` state as well. Additionally the `Connection#errorReason` will be set should be set with the error received from Ably"
     */
    ARTResumeRequestResponseTypeFatalError,

    /**
     The response from the Realtime system was not one of the expected responses.
     */
    ARTResumeRequestResponseTypeUnknown,
} NS_SWIFT_NAME(ResumeRequestResponse.ResponseType);

NS_ASSUME_NONNULL_BEGIN

/**
 The Realtime system’s response to a resume request, as described by RTN15c.
 */
NS_SWIFT_NAME(ResumeRequestResponse)
@interface ARTResumeRequestResponse: NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates an `ARTResumeRequestResponse` describing the resume request response that the Realtime system has communicated through the use of a protocol message.

 @param currentConnectionID The ID of the connection that we are trying to resume. `nil` in case of a new connection.
 @param protocolMessage The first protocol message received on a transport which is trying to resume a connection with ID `currentConnectionID`.
 @param errorChecker An error checker which will be used to check whether an error is a token error.
 */
- (instancetype)initWithCurrentConnectionID:(nullable NSString *)currentConnectionID
                            protocolMessage:(ARTProtocolMessage *)protocolMessage
                               errorChecker:(id<ARTErrorChecker>)errorChecker NS_DESIGNATED_INITIALIZER;

/**
 The type of the response. This indicates how a client is meant to act upon receiving this response.
 */
@property (nonatomic, readonly) ARTResumeRequestResponseType type;

/**
 The error that the Realtime system included in its response.

 Non-nil if and only if `type` is `ARTResumeRequestResponseTypeInvalid`, `ARTResumeRequestResponseTypeTokenError`, or `ARTResumeRequestResponseTypeFatalError`.
 */
@property (nullable, nonatomic, readonly, strong) ARTErrorInfo *error;

@end

NS_ASSUME_NONNULL_END
