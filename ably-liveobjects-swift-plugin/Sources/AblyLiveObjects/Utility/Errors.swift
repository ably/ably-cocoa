internal import _AblyPluginSupportPrivate
import Ably

/**
 Describes the errors that can be thrown by the LiveObjects SDK. Use ``toARTErrorInfo()`` to convert to an `ARTErrorInfo` that you can throw.
 */
@available(macOS 11, iOS 14, tvOS 14, *)
internal enum LiveObjectsError {
    // operationDescription should be a description of a method like "LiveCounter.value"; it will be interpolated into an error message
    case objectsOperationFailedInvalidChannelState(operationDescription: String, channelState: _AblyPluginSupportPrivate.RealtimeChannelState)
    case counterInitialValueInvalid(value: Double)
    case counterIncrementAmountInvalid(amount: Double)
    case other(Error)

    /// The ``ARTErrorInfo/code`` that should be returned for this error.
    internal var code: ARTErrorCode {
        switch self {
        case .objectsOperationFailedInvalidChannelState:
            .channelOperationFailedInvalidState
        case .counterInitialValueInvalid, .counterIncrementAmountInvalid:
            // RTO12f1, RTLC12e1
            .invalidParameterValue
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
             .other:
            400
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
        case let .other(error):
            "\(error)"
        }
    }

    internal func toARTErrorInfo() -> ARTErrorInfo {
        ARTErrorInfo.create(
            withCode: Int(code.rawValue),
            status: statusCode,
            message: localizedDescription,
            additionalUserInfo: [liveObjectsErrorUserInfoKey: self],
        )
    }
}

// MARK: - ConvertibleToLiveObjectsError Protocol

/// Protocol for types that can be converted to a `LiveObjectsError`.
///
/// We deliberately do not conform `ARTErrorInfo` (or its parent types `NSError` or `Error`) to this protocol, so that we do not accidentally end up flattening an `ARTErrorInfo` into the `.other` `LiveObjectsError` case; if we have an `ARTErrorInfo` then it should just be thrown directly.
///
/// If you need to convert a non-specific `NSError` or `Error` to a `LiveObjects` error, then do so explicitly using `LiveObjectsError.other`.
@available(macOS 11, iOS 14, tvOS 14, *)
internal protocol ConvertibleToLiveObjectsError {
    func toLiveObjectsError() -> LiveObjectsError
}

@available(macOS 11, iOS 14, tvOS 14, *)
internal extension ConvertibleToLiveObjectsError {
    /// Convenience method to convert directly to an `ARTErrorInfo`.
    func toARTErrorInfo() -> ARTErrorInfo {
        toLiveObjectsError().toARTErrorInfo()
    }
}

// MARK: - Conversion Extensions

@available(macOS 11, iOS 14, tvOS 14, *)
extension DecodingError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension WireValueDecodingError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension WireValue.ConversionError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension SyncCursor.Error: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension InboundWireObjectMessage.DecodingError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension StringOrData.DecodingError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONObjectOrArray.ConversionError: ConvertibleToLiveObjectsError {
    internal func toLiveObjectsError() -> LiveObjectsError {
        .other(self)
    }
}

// MARK: - ARTErrorInfo Extension

/// The `ARTErrorInfo.userInfo` key under which we store the underlying `LiveObjectsError`. Used by `testsOnly_underlyingLiveObjectsError`.
private let liveObjectsErrorUserInfoKey = "LiveObjectsError"

@available(macOS 11, iOS 14, tvOS 14, *)
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
