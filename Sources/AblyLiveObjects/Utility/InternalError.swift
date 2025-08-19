internal import _AblyPluginSupportPrivate
import Ably

/// An error thrown by the internals of the LiveObjects SDK.
///
/// Copied from ably-chat-swift; will decide what to do about it.
internal enum InternalError: Error {
    case errorInfo(ARTErrorInfo)
    case other(Other)

    internal enum Other {
        // In ably-chat-swift we have different cases here for different types of errors thrown within the codebase, but we didn't figure out what to actually _do_ with these different types of errors (see implementation of toARTErrorInfo which squashes everything down to the same error), so let's not bother with that for now
        case generic(Error)
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

internal extension Error {
    func toInternalError() -> InternalError {
        .other(.generic(self))
    }
}

internal extension ARTErrorInfo {
    func toInternalError() -> InternalError {
        .errorInfo(self)
    }
}

internal extension _AblyPluginSupportPrivate.PublicErrorInfo {
    func toInternalError() -> InternalError {
        ARTErrorInfo.castPluginPublicErrorInfo(self).toInternalError()
    }
}
