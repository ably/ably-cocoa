internal import _AblyPluginSupportPrivate
import Ably

/**
 Describes the errors that can be thrown by the LiveObjects SDK. Use ``toARTErrorInfo()`` to convert to an `ARTErrorInfo` that you can throw.
 */
internal enum LiveObjectsError {
    // operationDescription should be a description of a method like "LiveCounter.value"; it will be interpolated into an error message
    case objectsOperationFailedInvalidChannelState(operationDescription: String, channelState: _AblyPluginSupportPrivate.RealtimeChannelState)
    case counterInitialValueInvalid(value: Double)
    case counterIncrementAmountInvalid(amount: Double)
    /// RTO20e1: The channel entered a non-`ATTACHED` state whilst a `publishAndApply` call was waiting for objects sync to complete.
    case publishAndApplyFailedChannelStateChanged(channelState: _AblyPluginSupportPrivate.RealtimeChannelState, reason: ARTErrorInfo?)
    /// RTO11h3d, RTO12h3d: A newly created object was not found in the pool after `publishAndApply`.
    case newlyCreatedObjectNotInPool(objectID: String)
    case other(Error)

    /// The ``ARTErrorInfo/code`` that should be returned for this error.
    internal var code: ARTErrorCode {
        switch self {
        case .objectsOperationFailedInvalidChannelState:
            .channelOperationFailedInvalidState
        case .counterInitialValueInvalid, .counterIncrementAmountInvalid:
            // RTO12f1, RTLC12e1
            .invalidParameterValue
        case .publishAndApplyFailedChannelStateChanged:
            // RTO20e1
            .unableToApplyObjectsOperationSyncDidNotComplete
        case .newlyCreatedObjectNotInPool:
            .internalError
        case .other:
            .badRequest
        }
    }

    /// The ``ARTErrorInfo/statusCode`` that should be returned for this error.
    internal var statusCode: Int {
        switch self {
        case .objectsOperationFailedInvalidChannelState,
             .counterInitialValueInvalid,
             .counterIncrementAmountInvalid,
             .publishAndApplyFailedChannelStateChanged,
             .other:
            400
        case .newlyCreatedObjectNotInPool:
            500
        }
    }

    /// The ``ARTErrorInfo/localizedDescription`` that should be returned for this error.
    internal var localizedDescription: String {
        switch self {
        case let .objectsOperationFailedInvalidChannelState(operationDescription: operationDescription, channelState: channelState):
            "\(operationDescription) operation failed (invalid channel state: \(channelState))"
        case let .counterInitialValueInvalid(value: value):
            "Invalid counter initial value (must be a finite number): \(value)"
        case let .counterIncrementAmountInvalid(amount: amount):
            "Invalid counter increment amount (must be a finite number): \(amount)"
        case let .publishAndApplyFailedChannelStateChanged(channelState: channelState, reason: _):
            // RTO20e1
            "operation could not be applied locally: channel entered \(channelState) state whilst waiting for objects sync to complete"
        case let .newlyCreatedObjectNotInPool(objectID: objectID):
            "Newly created object \(objectID) not found in pool after publishAndApply"
        case let .other(error):
            "\(error)"
        }
    }

    /// The ``ARTErrorInfo/cause`` that should be returned for this error.
    internal var cause: ARTErrorInfo? {
        switch self {
        case let .publishAndApplyFailedChannelStateChanged(channelState: _, reason: reason):
            // RTO20e1
            reason
        case .objectsOperationFailedInvalidChannelState,
             .counterInitialValueInvalid,
             .counterIncrementAmountInvalid,
             .newlyCreatedObjectNotInPool,
             .other:
            nil
        }
    }

    internal func toARTErrorInfo() -> ARTErrorInfo {
        var userInfo: [String: Any] = [liveObjectsErrorUserInfoKey: self]
        if let cause {
            // Note that here we're making use of an implementation detail of ably-cocoa (the fact that this user info key populates `ARTErrorInfo.cause`).
            userInfo[NSUnderlyingErrorKey] = cause
        }

        return ARTErrorInfo.create(
            withCode: Int(code.rawValue),
            status: statusCode,
            message: localizedDescription,
            additionalUserInfo: userInfo,
        )
    }
}

// MARK: - ConvertibleToLiveObjectsError Protocol

/// Protocol for types that can be converted to a `LiveObjectsError`.
///
/// We deliberately do not conform `ARTErrorInfo` (or its parent types `NSError` or `Error`) to this protocol, so that we do not accidentally end up flattening an `ARTErrorInfo` into the `.other` `LiveObjectsError` case; if we have an `ARTErrorInfo` then it should just be thrown directly.
///
/// If you need to convert a non-specific `NSError` or `Error` to a `LiveObjects` error, then do so explicitly using `LiveObjectsError.other`.
internal protocol ConvertibleToLiveObjectsError {
    func toLiveObjectsError() -> LiveObjectsError
}

internal extension ConvertibleToLiveObjectsError {
    /// Convenience method to convert directly to an `ARTErrorInfo`.
    func toARTErrorInfo() -> ARTErrorInfo {
        toLiveObjectsError().toARTErrorInfo()
    }
}

// MARK: - Conversion Extensions

extension DecodingError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

extension WireValueDecodingError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

extension WireValue.ConversionError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

extension SyncCursor.Error: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

extension InboundWireObjectMessage.DecodingError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

extension StringOrData.DecodingError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

extension JSONObjectOrArray.ConversionError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

// MARK: - ARTErrorInfo Extension

/// The `ARTErrorInfo.userInfo` key under which we store the underlying `LiveObjectsError`. Used by `testsOnly_underlyingLiveObjectsError`.
private let liveObjectsErrorUserInfoKey = "LiveObjectsError"

internal extension ARTErrorInfo {
    /// Retrieves the underlying `LiveObjectsError` from this `ARTErrorInfo` if it was generated from a `LiveObjectsError`.
    ///
    /// - Returns: The underlying `LiveObjectsError` if this error was generated from one, `nil` otherwise.
    var testsOnly_underlyingLiveObjectsError: LiveObjectsError? {
        guard let userInfoEntry = userInfo[liveObjectsErrorUserInfoKey] else {
            return nil
        }

        guard let liveObjectsError = userInfoEntry as? LiveObjectsError else {
            preconditionFailure("Expected a LiveObjectsError, got \(userInfoEntry)")
        }

        return liveObjectsError
    }
}
