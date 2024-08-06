#import <Foundation/Foundation.h>

/// :nodoc:
typedef NS_ENUM(NSUInteger, ARTState) {
    ARTStateOk NS_SWIFT_NAME(ok) = 0,
    ARTStateConnectionClosedByClient NS_SWIFT_NAME(connetionClosedByClient),
    ARTStateConnectionDisconnected NS_SWIFT_NAME(connectionDisconnected),
    ARTStateConnectionSuspended NS_SWIFT_NAME(connectionSuspended),
    ARTStateConnectionFailed NS_SWIFT_NAME(connectionFailed),
    ARTStateAccessRefused NS_SWIFT_NAME(accessRefused),
    ARTStateNeverConnected NS_SWIFT_NAME(neverConnected),
    ARTStateConnectionTimedOut NS_SWIFT_NAME(connectiontimedOut),
    ARTStateAttachTimedOut NS_SWIFT_NAME(attachTimedOut),
    ARTStateDetachTimedOut NS_SWIFT_NAME(detachTimedOut),
    ARTStateNotAttached NS_SWIFT_NAME(notAttached),
    ARTStateInvalidArgs NS_SWIFT_NAME(invalidArgs),
    ARTStateCryptoBadPadding NS_SWIFT_NAME(cryptoBadPadding),
    ARTStateNoClientId NS_SWIFT_NAME(noClientId),
    ARTStateMismatchedClientId NS_SWIFT_NAME(mismatchedClientId),
    ARTStateRequestTokenFailed NS_SWIFT_NAME(requestTokenFailed),
    ARTStateAuthorizationFailed NS_SWIFT_NAME(authorizationFailed),
    ARTStateAuthUrlIncompatibleContent NS_SWIFT_NAME(authUrlIncompatibleContent),
    ARTStateBadConnectionState NS_SWIFT_NAME(badConnectionState),
    ARTStateError NS_SWIFT_NAME(error) = 99999
} NS_SWIFT_NAME(AblyState); // `State` clashes with SwiftUI so using AblyState instead

/**
 The list of all public error codes returned under the error domain ARTAblyErrorDomain
 */
typedef CF_ENUM(NSUInteger, ARTErrorCode) {
    ARTErrorNoError NS_SWIFT_NAME(noError) = 10000,
    ARTErrorBadRequest NS_SWIFT_NAME(badRequest) = 40000,
    ARTErrorInvalidRequestBody NS_SWIFT_NAME(invalidRequestBody) = 40001,
    ARTErrorInvalidParameterName NS_SWIFT_NAME(invalidParameterName) = 40002,
    ARTErrorInvalidParameterValue NS_SWIFT_NAME(invalidParameterValue) = 40003,
    ARTErrorInvalidHeader NS_SWIFT_NAME(invalidHeader) = 40004,
    ARTErrorInvalidCredential NS_SWIFT_NAME(invalidCredential) = 40005,
    ARTErrorInvalidConnectionId NS_SWIFT_NAME(invalidConnectionId) = 40006,
    ARTErrorInvalidMessageId NS_SWIFT_NAME(invalidMessageId) = 40007,
    ARTErrorInvalidContentLength NS_SWIFT_NAME(invalidContentLength) = 40008,
    ARTErrorMaxMessageLengthExceeded NS_SWIFT_NAME(maxMessageLengthExceeded) = 40009,
    ARTErrorInvalidChannelName NS_SWIFT_NAME(invalidChannelName) = 40010,
    ARTErrorStaleRingState NS_SWIFT_NAME(staleRingState) = 40011,
    ARTErrorInvalidClientId NS_SWIFT_NAME(invalidClientId) = 40012,
    ARTErrorInvalidMessageDataOrEncoding NS_SWIFT_NAME(invalidMessageDataOrEncoding) = 40013,
    ARTErrorResourceDisposed NS_SWIFT_NAME(resourceDisposed) = 40014,
    ARTErrorInvalidDeviceId NS_SWIFT_NAME(invalidDeviceId) = 40015,
    ARTErrorInvalidMessageName NS_SWIFT_NAME(invalidMessageName) = 40016,
    ARTErrorUnsupportedProtocolVersion NS_SWIFT_NAME(unsupportedProtocolVersion) = 40017,
    ARTErrorUnableToDecodeMessage NS_SWIFT_NAME(unableToDecodeMessage) = 40018,
    ARTErrorBatchError NS_SWIFT_NAME(batchError) = 40020,
    ARTErrorInvalidPublishRequest NS_SWIFT_NAME(invalidPublishRequest) = 40030,
    ARTErrorInvalidClient NS_SWIFT_NAME(invalidClient) = 40031,
    ARTErrorReservedForTesting NS_SWIFT_NAME(reservedForTesting) = 40099,
    ARTErrorUnauthorized NS_SWIFT_NAME(unauthorized) = 40100,
    ARTErrorInvalidCredentials NS_SWIFT_NAME(invalidCredentials) = 40101,
    ARTErrorIncompatibleCredentials NS_SWIFT_NAME(incompatibleCredentials) = 40102,
    ARTErrorInvalidUseOfBasicAuthOverNonTlsTransport NS_SWIFT_NAME(invalidUseOfBasicAuthOverNonTlsTransport) = 40103,
    ARTErrorTimestampNotCurrent NS_SWIFT_NAME(timestampNotCurrent) = 40104,
    ARTErrorNonceValueReplayed NS_SWIFT_NAME(nonceValueReplayed) = 40105,
    ARTErrorUnableToObtainCredentials NS_SWIFT_NAME(unableToObtainCredentials) = 40106,
    ARTErrorAccountDisabled NS_SWIFT_NAME(accountDisabled) = 40110,
    ARTErrorAccountConnectionLimitsExceeded NS_SWIFT_NAME(accountConnectionLimitsExceeded) = 40111,
    ARTErrorAccountMessageLimitsExceeded NS_SWIFT_NAME(accountMessageLimitsExceeded) = 40112,
    ARTErrorAccountBlocked NS_SWIFT_NAME(accountBlocked) = 40113,
    ARTErrorAccountChannelLimitsExceeded NS_SWIFT_NAME(accountChannelLimitsExceeded) = 40114,
    ARTErrorApplicationDisabled NS_SWIFT_NAME(applicationDisabled) = 40120,
    ARTErrorKeyErrorUnspecified NS_SWIFT_NAME(keyErrorUnspecified) = 40130,
    ARTErrorKeyRevoked NS_SWIFT_NAME(keyRevoked) = 40131,
    ARTErrorKeyExpired NS_SWIFT_NAME(keyExpired) = 40132,
    ARTErrorKeyDisabled NS_SWIFT_NAME(keyDisabled) = 40133,
    ARTErrorTokenErrorUnspecified NS_SWIFT_NAME(tokenErrorUnspecified) = 40140,
    ARTErrorTokenRevoked NS_SWIFT_NAME(tokenRevoked) = 40141,
    ARTErrorTokenExpired NS_SWIFT_NAME(tokenExpired) = 40142,
    ARTErrorTokenUnrecognised NS_SWIFT_NAME(tokenUnrecognised) = 40143,
    ARTErrorInvalidJwtFormat NS_SWIFT_NAME(invalidJwtFormat) = 40144,
    ARTErrorInvalidTokenFormat NS_SWIFT_NAME(invalidTokenFormat) = 40145,
    ARTErrorConnectionLimitsExceeded NS_SWIFT_NAME(connectionLimitsExceeded) = 40150,
    ARTErrorOperationNotPermittedWithProvidedCapability NS_SWIFT_NAME(operationNotPermittedWithProvidedCapability) = 40160,
    ARTErrorOperationNotPermittedAsItRequiresAnIdentifiedClient NS_SWIFT_NAME(operationNotPermittedAsItRequiresAnIdentifiedClient) = 40161,
    ARTErrorErrorFromClientTokenCallback NS_SWIFT_NAME(errorFromClientTokenCallback) = 40170,
    ARTErrorNoMeansProvidedToRenewAuthToken NS_SWIFT_NAME(noMeansProvidedToRenewAuthToken) = 40171,
    ARTErrorForbidden NS_SWIFT_NAME(forbidden) = 40300,
    ARTErrorAccountDoesNotPermitTlsConnection NS_SWIFT_NAME(accountDoesNotPermitTlsConnection) = 40310,
    ARTErrorOperationRequiresTlsConnection NS_SWIFT_NAME(operationRequiresTlsConnection) = 40311,
    ARTErrorApplicationRequiresAuthentication NS_SWIFT_NAME(applicationRequiresAuthentication) = 40320,
    ARTErrorUnableToActivateAccountUnspecified NS_SWIFT_NAME(unableToActivateAccountUnspecified) = 40330,
    ARTErrorUnableToActivateAccountIncompatibleEnvironment NS_SWIFT_NAME(unableToActivateAccountIncompatibleEnvironment) = 40331,
    ARTErrorUnableToActivateAccountIncompatibleSite NS_SWIFT_NAME(unableToActivateAccountIncompatibleSite) = 40332,
    ARTErrorNotFound NS_SWIFT_NAME(notFound) = 40400,
    ARTErrorMethodNotAllowed NS_SWIFT_NAME(methodNotAllowed) = 40500,
    ARTErrorRateLimitExceededUnspecified NS_SWIFT_NAME(rateLimitExceededUnspecified) = 42910,
    ARTErrorMaxPerConnectionPublishRateLimitExceeded NS_SWIFT_NAME(maxPerConnectionPublishRateLimitExceeded) = 42911,
    ARTErrorRateLimitExceededFatal NS_SWIFT_NAME(rateLimitExceededFatal) = 42920,
    ARTErrorMaxPerConnectionPublishRateLimitExceededFatal NS_SWIFT_NAME(maxPerConnectionPublishRateLimitExceededFatal) = 42921,
    ARTErrorInternalError NS_SWIFT_NAME(internalError) = 50000,
    ARTErrorInternalChannelError NS_SWIFT_NAME(internalChannelError) = 50001,
    ARTErrorInternalConnectionError NS_SWIFT_NAME(internalConnectionError) = 50002,
    ARTErrorTimeoutError NS_SWIFT_NAME(timeoutError) = 50003,
    ARTErrorRequestFailedDueToOverloadedInstance NS_SWIFT_NAME(requestFailedDueToOverloadedInstance) = 50004,
    ARTErrorEdgeProxyServiceInternalError NS_SWIFT_NAME(edgeProxyServiceInternalError) = 50010,
    ARTErrorEdgeProxyServiceBadGateway NS_SWIFT_NAME(edgeProxyServiceBadGateway) = 50210,
    ARTErrorEdgeProxyServiceUnavailableAblyPlatform NS_SWIFT_NAME(edgeProxyServiceUnavailableAblyPlatform) = 50310,
    ARTErrorTrafficTemporarilyRedirectedToBackupService NS_SWIFT_NAME(trafficTemporarilyRedirectedToBackupService) = 50320,
    ARTErrorEdgeProxyServiceTimedOutWaitingAblyPlatform NS_SWIFT_NAME(edgeProxyServiceTimedOutWaitingAblyPlatform) = 50410,
    ARTErrorReactorOperationFailed NS_SWIFT_NAME(reactorOperationFailed) = 70000,
    ARTErrorReactorPostOperationFailed NS_SWIFT_NAME(reactorPostOperationFailed) = 70001,
    ARTErrorReactorPostOperationReturnedUnexpectedCode NS_SWIFT_NAME(reactorPostOperationReturnedUnexpectedCode) = 70002,
    ARTErrorReactorMaxNumberOfConcurrentRequestsExceeded NS_SWIFT_NAME(reactorMaxNumberOfConcurrentRequestsExceeded) = 70003,
    ARTErrorReactorInvalidOrUnacceptedMessageContents NS_SWIFT_NAME(reactorInvalidOrUnacceptedMessageContents) = 70004,
    ARTErrorExchangeErrorUnspecified NS_SWIFT_NAME(exchangeErrorUnspecified) = 71000,
    ARTErrorForcedReAttachmentDueToPermissionsChange NS_SWIFT_NAME(forcedReAttachmentDueToPermissionsChange) = 71001,
    ARTErrorExchangePublisherErrorUnspecified NS_SWIFT_NAME(exchangePublisherErrorUnspecified) = 71100,
    ARTErrorNoSuchPublisher NS_SWIFT_NAME(noSuchPublisher) = 71101,
    ARTErrorPublisherNotEnabledAsAnExchangePublisher NS_SWIFT_NAME(publisherNotEnabledAsAnExchangePublisher) = 71102,
    ARTErrorExchangeProductErrorUnspecified NS_SWIFT_NAME(exchangeProductErrorUnspecified) = 71200,
    ARTErrorNoSuchProduct NS_SWIFT_NAME(noSuchProduct) = 71201,
    ARTErrorProductDisabled NS_SWIFT_NAME(productDisabled) = 71202,
    ARTErrorNoSuchChannelInThisProduct NS_SWIFT_NAME(noSuchChannelInThisProduct) = 71203,
    ARTErrorForcedReAttachmentDueToRemapped NS_SWIFT_NAME(forcedReAttachmentDueToRemapped) = 71204,
    ARTErrorExchangeSubscriptionErrorUnspecified NS_SWIFT_NAME(exchangeSubscriptionErrorUnspecified) = 71300,
    ARTErrorSubscriptionDisabled NS_SWIFT_NAME(subscriptionDisabled) = 71301,
    ARTErrorRequesterHasNoSubscriptionToThisProduct NS_SWIFT_NAME(requesterHasNoSubscriptionToThisProduct) = 71302,
    ARTErrorChannelDoesNotMatchTheChannelFilter NS_SWIFT_NAME(channelDoesNotMatchTheChannelFilter) = 71303,
    ARTErrorConnectionFailed NS_SWIFT_NAME(connectionFailed) = 80000,
    ARTErrorConnectionFailedNoCompatibleTransport NS_SWIFT_NAME(connectionFailedNoCompatibleTransport) = 80001,
    ARTErrorConnectionSuspended NS_SWIFT_NAME(connectionSuspended) = 80002,
    ARTErrorDisconnected NS_SWIFT_NAME(disconnected) = 80003,
    ARTErrorAlreadyConnected NS_SWIFT_NAME(alreadyConnected) = 80004,
    ARTErrorInvalidConnectionIdRemoteNotFound NS_SWIFT_NAME(invalidConnectionIdRemoteNotFound) = 80005,
    ARTErrorUnableToRecoverConnectionMessagesExpired NS_SWIFT_NAME(unableToRecoverConnectionMessagesExpired) = 80006,
    ARTErrorUnableToRecoverConnectionMessageLimitExceeded NS_SWIFT_NAME(unableToRecoverConnectionMessageLimitExceeded) = 80007,
    ARTErrorUnableToRecoverConnectionExpired NS_SWIFT_NAME(unableToRecoverConnectionExpired) = 80008,
    ARTErrorConnectionNotEstablishedNoTransportHandle NS_SWIFT_NAME(connectionNotEstablishedNoTransportHandle) = 80009,
    ARTErrorInvalidTransportHandle NS_SWIFT_NAME(invalidTransportHandle) = 80010,
    ARTErrorUnableToRecoverConnectionIncompatibleAuthParams NS_SWIFT_NAME(unableToRecoverConnectionIncompatibleAuthParams) = 80011,
    ARTErrorUnableToRecoverConnectionInvalidConnectionSerial NS_SWIFT_NAME(unableToRecoverConnectionInvalidConnectionSerial) = 80012,
    ARTErrorProtocolError NS_SWIFT_NAME(protocolError) = 80013,
    ARTErrorConnectionTimedOut NS_SWIFT_NAME(connectionTimedOut) = 80014,
    ARTErrorIncompatibleConnectionParameters NS_SWIFT_NAME(incompatibleConnectionParameters) = 80015,
    ARTErrorOperationOnSupersededConnection NS_SWIFT_NAME(operationOnSupersededConnection) = 80016,
    ARTErrorConnectionClosed NS_SWIFT_NAME(connectionClosed) = 80017,
    ARTErrorInvalidConnectionIdInvalidFormat NS_SWIFT_NAME(invalidConnectionIdInvalidFormat) = 80018,
    ARTErrorAuthConfiguredProviderFailure NS_SWIFT_NAME(authConfiguredProviderFailure) = 80019,
    ARTErrorContinuityLossDueToMaxSubscribeMessageRateExceeded NS_SWIFT_NAME(continuityLossDueToMaxSubscribeMessageRateExceeded) = 80020,
    ARTErrorClientRestrictionNotSatisfied NS_SWIFT_NAME(clientRestrictionNotSatisfied) = 80030,
    ARTErrorChannelOperationFailed NS_SWIFT_NAME(channelOperationFailed) = 90000,
    ARTErrorChannelOperationFailedInvalidState NS_SWIFT_NAME(channelOperationFailedInvalidState) = 90001,
    ARTErrorChannelOperationFailedEpochExpired NS_SWIFT_NAME(channelOperationFailedEpochExpired) = 90002,
    ARTErrorUnableToRecoverChannelMessagesExpired NS_SWIFT_NAME(unableToRecoverChannelMessagesExpired) = 90003,
    ARTErrorUnableToRecoverChannelMessageLimitExceeded NS_SWIFT_NAME(unableToRecoverChannelMessageLimitExceeded) = 90004,
    ARTErrorUnableToRecoverChannelNoMatchingEpoch NS_SWIFT_NAME(unableToRecoverChannelNoMatchingEpoch) = 90005,
    ARTErrorUnableToRecoverChannelUnboundedRequest NS_SWIFT_NAME(unableToRecoverChannelUnboundedRequest) = 90006,
    ARTErrorChannelOperationFailedNoResponseFromServer NS_SWIFT_NAME(channelOperationFailedNoResponseFromServer) = 90007,
    ARTErrorMaxNumberOfChannelsPerConnectionExceeded NS_SWIFT_NAME(maxNumberOfChannelsPerConnectionExceeded) = 90010,
    ARTErrorUnableToEnterPresenceChannelNoClientid NS_SWIFT_NAME(unableToEnterPresenceChannelNoClientid) = 91000,
    ARTErrorUnableToEnterPresenceChannelInvalidState NS_SWIFT_NAME(unableToEnterPresenceChannelInvalidState) = 91001,
    ARTErrorUnableToLeavePresenceChannelThatIsNotEntered NS_SWIFT_NAME(unableToLeavePresenceChannelThatIsNotEntered) = 91002,
    ARTErrorUnableToEnterPresenceChannelMaxMemberLimitExceeded NS_SWIFT_NAME(unableToEnterPresenceChannelMaxMemberLimitExceeded) = 91003,
    ARTErrorUnableToAutomaticallyReEnterPresenceChannel NS_SWIFT_NAME(unableToAutomaticallyReEnterPresenceChannel) = 91004,
    ARTErrorPresenceStateIsOutOfSync NS_SWIFT_NAME(presenceStateIsOutOfSync) = 91005,
    ARTErrorMemberImplicitlyLeftPresenceChannel NS_SWIFT_NAME(memberImplicitlyLeftPresenceChannel) = 91100,
};


/**
 The list of all client error codes returned under the error domain ARTAblyErrorDomain
 */
typedef CF_ENUM(NSUInteger, ARTClientCodeError) {
    ARTClientCodeErrorInvalidType NS_SWIFT_NAME(invalidType),
    ARTClientCodeErrorTransport NS_SWIFT_NAME(transport),
} NS_SWIFT_NAME(ClientCodeError);

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
FOUNDATION_EXPORT NSString *const ARTErrorInfoRequestIdKey;

/// :nodoc:
FOUNDATION_EXPORT NSString *const ARTAblyErrorDomain;

/// :nodoc:
FOUNDATION_EXPORT NSString *const ARTFallbackIncompatibleOptionsException;

/// :nodoc:
FOUNDATION_EXPORT NSString *const ARTAblyMessageNoMeansToRenewToken;

/**
 * A generic Ably error object that contains an Ably-specific status code, and a generic status code. Errors returned from the Ably server are compatible with the `ARTErrorInfo` structure and should result in errors that inherit from `ARTErrorInfo`.
 *
 * @see For possible `NSError.code` see Ably [error codes](https://github.com/ably/ably-common/blob/main/protocol/errors.json).
 */
NS_SWIFT_NAME(ErrorInfo)
@interface ARTErrorInfo : NSError

/**
 * Additional message information, where available.
 */
@property (readonly) NSString *message;

/**
 * The reason why the error occured, where available.
 */
@property (nullable, readonly) NSString *reason;

/**
 * HTTP Status Code corresponding to this error, where applicable.
 */
@property (readonly) NSInteger statusCode;

/**
 * This is included for REST responses to provide a URL for additional help on the error code.
 */
@property (nullable, readonly) NSString *href;

/**
 * If a request fails, the request ID must be included in the `ARTErrorInfo` returned to the user.
 */
@property (nullable, readonly) NSString *requestId;

/**
 * Information pertaining to what caused the error where available.
 */
@property (nullable, readonly) ARTErrorInfo *cause;

/// :nodoc:
+ (ARTErrorInfo *)createWithCode:(NSInteger)code message:(NSString *)message;

/// :nodoc:
+ (ARTErrorInfo *)createWithCode:(NSInteger)code status:(NSInteger)status message:(NSString *)message;

/// :nodoc:
+ (ARTErrorInfo *)createFromNSError:(NSError *)error;

/// :nodoc:
+ (ARTErrorInfo *)createFromNSException:(NSException *)error;

/// :nodoc:
+ (ARTErrorInfo *)createWithCode:(NSInteger)code message:(NSString *)message requestId:(nullable NSString *)requestId;

/// :nodoc:
+ (ARTErrorInfo *)createWithCode:(NSInteger)code status:(NSInteger)status message:(NSString *)message requestId:(nullable NSString *)requestId;

/// :nodoc:
+ (ARTErrorInfo *)createFromNSException:(NSException *)error requestId:(nullable NSString *)requestId;

/// :nodoc:
+ (ARTErrorInfo *)createUnknownError;

/// :nodoc:
+ (ARTErrorInfo *)wrap:(ARTErrorInfo *)error prepend:(NSString *)prepend;

/// :nodoc:
- (NSString *)description;

@end

/**
 * :nodoc: TODO: docstring
 * An object representing a status of an operation.
 */
NS_SWIFT_NAME(Status)
@interface ARTStatus : NSObject

@property (nullable, readonly, nonatomic) ARTErrorInfo *errorInfo;
@property (nonatomic) ARTState state;

+ (ARTStatus *)state:(ARTState) state;
+ (ARTStatus *)state:(ARTState) state info:(nullable ARTErrorInfo *) info;

- (NSString *)description;

@end

/// :nodoc:
@interface ARTException : NSException
@end

/// :nodoc:
@interface NSError (ARTErrorInfo)

- (NSInteger)artStatusCode;

@end

NS_ASSUME_NONNULL_END
