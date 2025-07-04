import Ably

/**
 Describes the errors that can be thrown by the LiveObjects SDK. Use ``toARTErrorInfo()`` to convert to an `ARTErrorInfo` that you can throw.
 */
internal enum LiveObjectsError {
    // operationDescription should be a description of a method like "LiveCounter.value"; it will be interpolated into an error message
    case objectsOperationFailedInvalidChannelState(operationDescription: String, channelState: ARTRealtimeChannelState)

    /// The ``ARTErrorInfo/code`` that should be returned for this error.
    internal var code: ARTErrorCode {
        switch self {
        case .objectsOperationFailedInvalidChannelState:
            .channelOperationFailedInvalidState
        }
    }

    /// The ``ARTErrorInfo/statusCode`` that should be returned for this error.
    internal var statusCode: Int {
        switch self {
        case .objectsOperationFailedInvalidChannelState:
            400
        }
    }

    /// The ``ARTErrorInfo/localizedDescription`` that should be returned for this error.
    internal var localizedDescription: String {
        switch self {
        case let .objectsOperationFailedInvalidChannelState(operationDescription: operationDescription, channelState: channelState):
            "\(operationDescription) operation failed (invalid channel state: \(channelState))"
        }
    }

    internal func toARTErrorInfo() -> ARTErrorInfo {
        ARTErrorInfo.create(
            withCode: Int(code.rawValue),
            status: statusCode,
            message: localizedDescription,
        )
    }
}
