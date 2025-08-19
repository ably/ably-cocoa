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

    /// The ``ARTErrorInfo/code`` that should be returned for this error.
    internal var code: ARTErrorCode {
        switch self {
        case .objectsOperationFailedInvalidChannelState:
            .channelOperationFailedInvalidState
        case .counterInitialValueInvalid, .counterIncrementAmountInvalid:
            // RTO12f1, RTLC12e1
            .invalidParameterValue
        }
    }

    /// The ``ARTErrorInfo/statusCode`` that should be returned for this error.
    internal var statusCode: Int {
        switch self {
        case .objectsOperationFailedInvalidChannelState,
             .counterInitialValueInvalid,
             .counterIncrementAmountInvalid:
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
