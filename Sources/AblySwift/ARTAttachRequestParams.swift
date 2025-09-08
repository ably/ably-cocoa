import Foundation

// swift-migration: original location ARTAttachRequestParams.h, line 12
/// Provides parameters for a request to perform an operation that may ultimately call `ARTChannelRealtimeInternal`'s `internalAttach:callback:` method.
public class ARTAttachRequestParams: NSObject {
    
    // swift-migration: original location ARTAttachRequestParams.h, line 17
    /// Information about the error that triggered this attach request, if any.
    public let reason: ARTErrorInfo?
    
    // swift-migration: original location ARTAttachRequestParams.h, line 22
    /// The value to set for the `ATTACH` `ProtocolMessage`'s `channelSerial` property.
    public let channelSerial: String?
    
    // swift-migration: original location ARTAttachRequestParams.h, line 24
    public let retryAttempt: ARTRetryAttempt?
    
    // swift-migration: original location ARTAttachRequestParams.h, line 31
    /// Creates an `ARTAttachRequestParams` instance with the given `reason`, whose `channelSerial` is `nil`.
    public convenience init(reason: ARTErrorInfo?) {
        self.init(reason: reason, channelSerial: nil)
    }
    
    // swift-migration: original location ARTAttachRequestParams.h, line 36
    /// Creates an `ARTAttachRequest` instance with the given `reason` and `channelSerial`, whose `retryAttempt` is `nil`.
    public convenience init(reason: ARTErrorInfo?, channelSerial: String?) {
        self.init(reason: reason, channelSerial: channelSerial, retryAttempt: nil)
    }
    
    // swift-migration: original location ARTAttachRequestParams.h, line 38
    public init(reason: ARTErrorInfo?, channelSerial: String?, retryAttempt: ARTRetryAttempt?) {
        self.reason = reason
        self.channelSerial = channelSerial
        self.retryAttempt = retryAttempt
        super.init()
    }
}