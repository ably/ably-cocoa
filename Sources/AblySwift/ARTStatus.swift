import Foundation

// swift-migration: original location ARTStatus.m, line 8
let ARTAblyErrorDomain = "io.ably.cocoa"

// swift-migration: original location ARTStatus.m, line 10
let ARTErrorInfoStatusCodeKey = "ARTErrorInfoStatusCode"
// swift-migration: original location ARTStatus.m, line 11
let ARTErrorInfoOriginalDomainKey = "ARTErrorInfoOriginalDomain"
// swift-migration: original location ARTStatus.m, line 12
let ARTErrorInfoRequestIdKey = "ARTErrorInfoRequestId"

// swift-migration: original location ARTStatus.m, line 14
let ARTFallbackIncompatibleOptionsException = "ARTFallbackIncompatibleOptionsException"

// swift-migration: original location ARTStatus.m, line 16
let ARTAblyMessageNoMeansToRenewToken = "no means to renew the token is provided (either an API key, authCallback or authUrl)"

// swift-migration: original location ARTStatus.m, line 18
func getStatusFromCode(_ code: Int) -> Int {
    return code / 100
}

// swift-migration: original location ARTStatus.h, line 4 and ARTStatus.m, line 22
public enum ARTState: UInt, Sendable {
    case ok = 0
    case connectionClosedByClient
    case connectionDisconnected
    case connectionSuspended
    case connectionFailed
    case accessRefused
    case neverConnected
    case connectionTimedOut
    case attachTimedOut
    case detachTimedOut
    case notAttached
    case invalidArgs
    case cryptoBadPadding
    case noClientId
    case mismatchedClientId
    case requestTokenFailed
    case authorizationFailed
    case authUrlIncompatibleContent
    case badConnectionState
    case error = 99999
}

// swift-migration: original location ARTStatus.h, line 31
public enum ARTErrorCode: UInt, Sendable {
    case noError = 10000
    case badRequest = 40000
    case invalidRequestBody = 40001
    case invalidParameterName = 40002
    case invalidParameterValue = 40003
    case invalidHeader = 40004
    case invalidCredential = 40005
    case invalidConnectionId = 40006
    case invalidMessageId = 40007
    case invalidContentLength = 40008
    case maxMessageLengthExceeded = 40009
    case invalidChannelName = 40010
    case staleRingState = 40011
    case invalidClientId = 40012
    case invalidMessageDataOrEncoding = 40013
    case resourceDisposed = 40014
    case invalidDeviceId = 40015
    case invalidMessageName = 40016
    case unsupportedProtocolVersion = 40017
    case unableToDecodeMessage = 40018
    case batchError = 40020
    case invalidPublishRequest = 40030
    case invalidClient = 40031
    case reservedForTesting = 40099
    case unauthorized = 40100
    case invalidCredentials = 40101
    case incompatibleCredentials = 40102
    case invalidUseOfBasicAuthOverNonTlsTransport = 40103
    case timestampNotCurrent = 40104
    case nonceValueReplayed = 40105
    case unableToObtainCredentials = 40106
    case accountDisabled = 40110
    case accountConnectionLimitsExceeded = 40111
    case accountMessageLimitsExceeded = 40112
    case accountBlocked = 40113
    case accountChannelLimitsExceeded = 40114
    case applicationDisabled = 40120
    case keyErrorUnspecified = 40130
    case keyRevoked = 40131
    case keyExpired = 40132
    case keyDisabled = 40133
    case tokenErrorUnspecified = 40140
    case tokenRevoked = 40141
    case tokenExpired = 40142
    case tokenUnrecognised = 40143
    case invalidJwtFormat = 40144
    case invalidTokenFormat = 40145
    case connectionLimitsExceeded = 40150
    case operationNotPermittedWithProvidedCapability = 40160
    case operationNotPermittedAsItRequiresAnIdentifiedClient = 40161
    case errorFromClientTokenCallback = 40170
    case noMeansProvidedToRenewAuthToken = 40171
    case forbidden = 40300
    case accountDoesNotPermitTlsConnection = 40310
    case operationRequiresTlsConnection = 40311
    case applicationRequiresAuthentication = 40320
    case unableToActivateAccountUnspecified = 40330
    case unableToActivateAccountIncompatibleEnvironment = 40331
    case unableToActivateAccountIncompatibleSite = 40332
    case notFound = 40400
    case methodNotAllowed = 40500
    case rateLimitExceededUnspecified = 42910
    case maxPerConnectionPublishRateLimitExceeded = 42911
    case rateLimitExceededFatal = 42920
    case maxPerConnectionPublishRateLimitExceededFatal = 42921
    case internalError = 50000
    case internalChannelError = 50001
    case internalConnectionError = 50002
    case timeoutError = 50003
    case requestFailedDueToOverloadedInstance = 50004
    case edgeProxyServiceInternalError = 50010
    case edgeProxyServiceBadGateway = 50210
    case edgeProxyServiceUnavailableAblyPlatform = 50310
    case trafficTemporarilyRedirectedToBackupService = 50320
    case edgeProxyServiceTimedOutWaitingAblyPlatform = 50410
    case reactorOperationFailed = 70000
    case reactorPostOperationFailed = 70001
    case reactorPostOperationReturnedUnexpectedCode = 70002
    case reactorMaxNumberOfConcurrentRequestsExceeded = 70003
    case reactorInvalidOrUnacceptedMessageContents = 70004
    case exchangeErrorUnspecified = 71000
    case forcedReAttachmentDueToPermissionsChange = 71001
    case exchangePublisherErrorUnspecified = 71100
    case noSuchPublisher = 71101
    case publisherNotEnabledAsAnExchangePublisher = 71102
    case exchangeProductErrorUnspecified = 71200
    case noSuchProduct = 71201
    case productDisabled = 71202
    case noSuchChannelInThisProduct = 71203
    case forcedReAttachmentDueToRemapped = 71204
    case exchangeSubscriptionErrorUnspecified = 71300
    case subscriptionDisabled = 71301
    case requesterHasNoSubscriptionToThisProduct = 71302
    case channelDoesNotMatchTheChannelFilter = 71303
    case connectionFailed = 80000
    case connectionFailedNoCompatibleTransport = 80001
    case connectionSuspended = 80002
    case disconnected = 80003
    case alreadyConnected = 80004
    case invalidConnectionIdRemoteNotFound = 80005
    case unableToRecoverConnectionMessagesExpired = 80006
    case unableToRecoverConnectionMessageLimitExceeded = 80007
    case unableToRecoverConnectionExpired = 80008
    case connectionNotEstablishedNoTransportHandle = 80009
    case invalidTransportHandle = 80010
    case unableToRecoverConnectionIncompatibleAuthParams = 80011
    case unableToRecoverConnectionInvalidConnectionSerial = 80012
    case protocolError = 80013
    case connectionTimedOut = 80014
    case incompatibleConnectionParameters = 80015
    case operationOnSupersededConnection = 80016
    case connectionClosed = 80017
    case invalidConnectionIdInvalidFormat = 80018
    case authConfiguredProviderFailure = 80019
    case continuityLossDueToMaxSubscribeMessageRateExceeded = 80020
    case clientRestrictionNotSatisfied = 80030
    case channelOperationFailed = 90000
    case channelOperationFailedInvalidState = 90001
    case channelOperationFailedEpochExpired = 90002
    case unableToRecoverChannelMessagesExpired = 90003
    case unableToRecoverChannelMessageLimitExceeded = 90004
    case unableToRecoverChannelNoMatchingEpoch = 90005
    case unableToRecoverChannelUnboundedRequest = 90006
    case channelOperationFailedNoResponseFromServer = 90007
    case maxNumberOfChannelsPerConnectionExceeded = 90010
    case unableToEnterPresenceChannelNoClientid = 91000
    case unableToEnterPresenceChannelInvalidState = 91001
    case unableToLeavePresenceChannelThatIsNotEntered = 91002
    case unableToEnterPresenceChannelMaxMemberLimitExceeded = 91003
    case unableToAutomaticallyReEnterPresenceChannel = 91004
    case presenceStateIsOutOfSync = 91005
    case memberImplicitlyLeftPresenceChannel = 91100
}

// MARK: - Backward Compatibility for ARTErrorCode
// swift-migration: Adding compatibility cases that may be used by other files
extension ARTErrorCode {
    static let ARTErrorUnableToDecodeMessage = ARTErrorCode.unableToDecodeMessage
    static let ARTErrorInvalidMessageDataOrEncoding = ARTErrorCode.invalidMessageDataOrEncoding
    static let ARTErrorMaxMessageLengthExceeded = ARTErrorCode.maxMessageLengthExceeded
    static let ARTErrorDisconnected = ARTErrorCode.disconnected
    static let ARTErrorConnectionSuspended = ARTErrorCode.connectionSuspended
    static let ARTErrorConnectionFailed = ARTErrorCode.connectionFailed
    static let ARTErrorConnectionClosed = ARTErrorCode.connectionClosed
    static let ARTErrorInvalidTransportHandle = ARTErrorCode.invalidTransportHandle
    
    // Helper to convert to Int for compatibility
    var intValue: Int {
        return Int(self.rawValue)
    }
}

// swift-migration: original location ARTStatus.h, line 169
public enum ARTClientCodeError: UInt {
    case invalidType
    case transport
}

// swift-migration: original location ARTStatus.h, line 193 and ARTStatus.m, line 22
public class ARTErrorInfo: NSError, @unchecked Sendable {
    
    // MARK: - Convenience Initializers
    // swift-migration: Adding convenience initializers for backward compatibility
    public convenience init(code: Int, message: String) {
        self.init(domain: ARTAblyErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    // swift-migration: original location ARTStatus.h, line 198 and ARTStatus.m, line 102
    public var message: String {
        let description = userInfo[NSLocalizedDescriptionKey] as? String
        if let description = description, !description.isEmpty {
            return description
        }
        return reason ?? ""
    }
    
    // swift-migration: original location ARTStatus.h, line 203 and ARTStatus.m, line 110
    public var reason: String? {
        if let reason = userInfo[NSLocalizedFailureReasonErrorKey] as? String, !reason.isEmpty {
            return reason
        }
        if let reason = userInfo["NSDebugDescription"] as? String, !reason.isEmpty {
            return reason
        }
        if let reason = userInfo[ARTErrorInfoOriginalDomainKey] as? String, !reason.isEmpty {
            return reason
        }
        return nil
    }
    
    // swift-migration: original location ARTStatus.h, line 208 and ARTStatus.m, line 129
    public var statusCode: Int {
        return artStatusCode
    }
    
    // swift-migration: original location ARTStatus.h, line 213 and ARTStatus.m, line 141
    public var href: String? {
        if statusCode == 0 {
            return nil
        }
        return "https://help.ably.io/error/\(statusCode)"
    }
    
    // swift-migration: original location ARTStatus.h, line 218 and ARTStatus.m, line 149
    public var requestId: String? {
        return userInfo[ARTErrorInfoRequestIdKey] as? String
    }
    
    // swift-migration: original location ARTStatus.h, line 223 and ARTStatus.m, line 121
    public var cause: ARTErrorInfo? {
        guard let underlyingError = userInfo[NSUnderlyingErrorKey] as? Error else {
            return nil
        }
        return ARTErrorInfo.createFromError(underlyingError)
    }
    
    // swift-migration: original location ARTStatus.h, line 226 and ARTStatus.m, line 32
    public class func createWithCode(_ code: Int, message: String) -> ARTErrorInfo {
        return createWithCode(code, status: getStatusFromCode(code), message: message, requestId: nil)
    }
    
    // swift-migration: original location ARTStatus.h, line 229 and ARTStatus.m, line 36
    public class func createWithCode(_ code: Int, message: String, additionalUserInfo: [String: Any]?) -> ARTErrorInfo {
        return createWithCode(code, status: getStatusFromCode(code), message: message, requestId: nil, additionalUserInfo: additionalUserInfo)
    }
    
    // swift-migration: original location ARTStatus.h, line 232 and ARTStatus.m, line 62
    public class func createWithCode(_ code: Int, status: Int, message: String) -> ARTErrorInfo {
        return createWithCode(code, status: status, message: message, requestId: nil)
    }
    
    // swift-migration: original location ARTStatus.h, line 235 and ARTStatus.m, line 40
    public class func createWithCode(_ code: Int, status: Int, message: String, additionalUserInfo: [String: Any]?) -> ARTErrorInfo {
        return createWithCode(code, status: status, message: message, requestId: nil, additionalUserInfo: additionalUserInfo)
    }
    
    // swift-migration: original location ARTStatus.h, line 244 and ARTStatus.m, line 24
    public class func createWithCode(_ code: Int, message: String, requestId: String?) -> ARTErrorInfo {
        return createWithCode(code, status: getStatusFromCode(code), message: message, requestId: requestId)
    }
    
    // swift-migration: original location ARTStatus.h, line 247 and ARTStatus.m, line 28
    public class func createWithCode(_ code: Int, message: String, requestId: String?, additionalUserInfo: [String: Any]?) -> ARTErrorInfo {
        return createWithCode(code, status: getStatusFromCode(code), message: message, requestId: requestId, additionalUserInfo: additionalUserInfo)
    }
    
    // swift-migration: original location ARTStatus.h, line 250 and ARTStatus.m, line 44
    public class func createWithCode(_ code: Int, status: Int, message: String, requestId: String?) -> ARTErrorInfo {
        return createWithCode(code, status: status, message: message, requestId: requestId, additionalUserInfo: nil)
    }
    
    // swift-migration: original location ARTStatus.h, line 253 and ARTStatus.m, line 48
    public class func createWithCode(_ code: Int, status: Int, message: String, requestId: String?, additionalUserInfo: [String: Any]?) -> ARTErrorInfo {
        var userInfo: [String: Any] = [:]
        userInfo[ARTErrorInfoStatusCodeKey] = status
        userInfo[NSLocalizedDescriptionKey] = message
        userInfo[ARTErrorInfoRequestIdKey] = requestId
        
        // Add any additional userInfo values
        if let additionalUserInfo = additionalUserInfo {
            for (key, value) in additionalUserInfo {
                userInfo[key] = value
            }
        }
        
        return ARTErrorInfo(domain: ARTAblyErrorDomain, code: code, userInfo: userInfo)
    }
    
    // swift-migration: original location ARTStatus.h, line 238 and ARTStatus.m, line 66
    // swift-migration: Updated to work with Swift.Error instead of NSError per user instruction
    public class func createFromError(_ error: Error) -> ARTErrorInfo {
        if let artError = error as? ARTErrorInfo {
            return artError
        }
        
        let nsError = error as NSError
        var userInfo = nsError.userInfo
        userInfo[ARTErrorInfoOriginalDomainKey] = nsError.domain
        // swift-migration: Extract requestId from NSError's userInfo if available
        if let requestId = nsError.userInfo[ARTErrorInfoRequestIdKey] as? String {
            userInfo[ARTErrorInfoRequestIdKey] = requestId
        }
        
        return ARTErrorInfo(domain: ARTAblyErrorDomain, code: nsError.code, userInfo: userInfo)
    }
    
    // swift-migration: original location ARTStatus.h, line 241 and ARTStatus.m, line 78
    // swift-migration: Skipped per user instruction - NSException methods not migrated
    
    // swift-migration: original location ARTStatus.h, line 256 and ARTStatus.m, line 86
    // swift-migration: Skipped per user instruction - NSException methods not migrated
    
    // swift-migration: original location ARTStatus.h, line 259 and ARTStatus.m, line 90
    public class func createUnknownError() -> ARTErrorInfo {
        return createWithCode(0, message: "Unknown error", requestId: nil)
    }
    
    // swift-migration: original location ARTStatus.h, line 262 and ARTStatus.m, line 94
    public class func wrap(_ error: ARTErrorInfo, prepend: String) -> ARTErrorInfo {
        return createWithCode(error.code, status: error.statusCode, message: prepend + error.message, requestId: error.requestId)
    }
    
    // swift-migration: original location ARTStatus.h, line 265 and ARTStatus.m, line 133
    public override var description: String {
        if let reason = reason {
            return "Error \(code) - \(message.isEmpty ? "<Empty Message>" : message) (reason: \(reason))"
        } else {
            return "Error \(code) - \(message.isEmpty ? "<Empty Message>" : message)"
        }
    }
    
    // MARK: - Backward Compatibility Methods
    // swift-migration: Adding compatibility methods for existing codebase
    
    // Compatibility for createFromNSError (old name)
    public class func createFromNSError(_ error: Error) -> ARTErrorInfo {
        return createFromError(error)
    }
    
    // Compatibility for create(withCode:message:)
    public class func create(withCode code: Int, message: String) -> ARTErrorInfo {
        return createWithCode(code, message: message)
    }
    
    // Compatibility for create(withCode:status:message:)
    public class func create(withCode code: Int, status: Int, message: String) -> ARTErrorInfo {
        return createWithCode(code, status: status, message: message)
    }
    
    // Compatibility for UInt-based codes
    public class func create(withCode code: UInt, message: String) -> ARTErrorInfo {
        return createWithCode(Int(code), message: message)
    }
    
    public class func create(withCode code: UInt, status: Int, message: String) -> ARTErrorInfo {
        return createWithCode(Int(code), status: status, message: message)
    }
}

// swift-migration: original location ARTStatus.h, line 273 and ARTStatus.m, line 157
public class ARTStatus {
    
    // swift-migration: original location ARTStatus.h, line 275 and ARTStatus.m, line 187
    public private(set) var errorInfo: ARTErrorInfo?
    // swift-migration: original location ARTStatus.h, line 276
    public var state: ARTState
    
    // swift-migration: original location ARTStatus.m, line 159
    public init() {
        self.state = ARTState.ok
        self.errorInfo = nil
    }
    
    // MARK: - Convenience Initializers
    // swift-migration: Adding convenience initializers for backward compatibility
    public convenience init(state: ARTState) {
        self.init()
        self.state = state
    }
    
    public convenience init(state: ARTState, errorInfo: ARTErrorInfo?) {
        self.init()
        self.state = state
        self.setErrorInfo(errorInfo)
    }
    
    // swift-migration: original location ARTStatus.h, line 278 and ARTStatus.m, line 168
    public class func state(_ state: ARTState) -> ARTStatus {
        let status = ARTStatus()
        status.state = state
        return status
    }
    
    // swift-migration: original location ARTStatus.h, line 279 and ARTStatus.m, line 174
    public class func state(_ state: ARTState, info: ARTErrorInfo?) -> ARTStatus {
        let status = ARTStatus.state(state)
        status.setErrorInfo(info)
        return status
    }
    
    // swift-migration: original location ARTStatus.h, line 281 and ARTStatus.m, line 180
    public var description: String {
        return "ARTStatus: \(state.rawValue), Error info: \(errorInfo?.description ?? "nil")"
    }
    
    // MARK: Private
    
    // swift-migration: original location ARTStatus.m, line 187
    internal func setErrorInfo(_ errorInfo: ARTErrorInfo?) {
        self.errorInfo = errorInfo
    }
}

// swift-migration: original location ARTStatus.h, line 286 and ARTStatus.m, line 201
public class ARTException: NSException {
}

// swift-migration: original location ARTStatus.h, line 290 and ARTStatus.m, line 193
extension NSError {
    // swift-migration: original location ARTStatus.h, line 292 and ARTStatus.m, line 195
    public var artStatusCode: Int {
        return (userInfo[ARTErrorInfoStatusCodeKey] as? NSNumber)?.intValue ?? 0
    }
}