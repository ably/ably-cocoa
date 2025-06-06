import Ably

/// An error thrown by the internals of the LiveObjects SDK.
///
/// Copied from ably-chat-swift; will decide what to do about it.
internal enum InternalError: Error {
    case errorInfo(ARTErrorInfo)
    case other(Other)

    internal enum Other {
        case jsonValueDecodingError(JSONValueDecodingError)
    }

    /// Returns the error that this should be converted to when exposed via the SDK's public API.
    internal func toARTErrorInfo() -> ARTErrorInfo {
        switch self {
        case let .errorInfo(errorInfo):
            errorInfo
        case let .other(other):
            // For now we just treat all errors that are not backed by an ARTErrorInfo as non-recoverable user errors
            .create(withCode: Int(ARTErrorCode.badRequest.rawValue), message: "\(other)")
        }
    }
}

internal extension ARTErrorInfo {
    func toInternalError() -> InternalError {
        .errorInfo(self)
    }
}

internal extension JSONValueDecodingError {
    func toInternalError() -> InternalError {
        .other(.jsonValueDecodingError(self))
    }
}
