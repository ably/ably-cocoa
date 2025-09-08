import Foundation

// swift-migration: original location ARTChannelStateChangeParams.h, line 15 and ARTChannelStateChangeParams.m, line 3
/// Provides parameters for a request to perform an operation that may cause an `ARTRealtimeChannelInternal` instance to emit a connection state change.
///
/// `ARTRealtimeChannelInternal` will incorporate some of this data into the `ARTChannelStateChange` object that it emits as a result of the connection state change.
internal class ARTChannelStateChangeParams: NSObject {
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 20
    /// A state that some operations will use when failing pending presence operations.
    internal let state: ARTState
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 25
    /// Information about the error that triggered this state change, if any.
    internal let errorInfo: ARTErrorInfo?
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 30
    /// Whether the `ARTRealtimeChannelInternal` instance should update its `errorReason` property.
    internal let storeErrorInfo: Bool
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 32
    internal let retryAttempt: ARTRetryAttempt?
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 37
    /// The `resumed` value of the `ARTProtocolMessage` that triggered this state change.
    internal var resumed: Bool = false
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 44 and ARTChannelStateChangeParams.m, line 5
    /// Creates an `ARTChannelStateChangeParams` instance whose `errorInfo` is `nil`, and whose `storeErrorInfo` is `NO`.
    internal init(state: ARTState) {
        self.state = state
        self.errorInfo = nil
        self.storeErrorInfo = false
        self.retryAttempt = nil
        super.init()
    }
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 49 and ARTChannelStateChangeParams.m, line 9
    /// Creates an `ARTChannelStateChangeParams` instance with the given `errorInfo`, whose `storeErrorInfo` is `YES`.
    internal init(state: ARTState, errorInfo: ARTErrorInfo?) {
        self.state = state
        self.errorInfo = errorInfo
        self.storeErrorInfo = true
        self.retryAttempt = nil
        super.init()
    }
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 52 and ARTChannelStateChangeParams.m, line 13
    internal init(state: ARTState, errorInfo: ARTErrorInfo?, storeErrorInfo: Bool) {
        self.state = state
        self.errorInfo = errorInfo
        self.storeErrorInfo = storeErrorInfo
        self.retryAttempt = nil
        super.init()
    }
    
    // swift-migration: original location ARTChannelStateChangeParams.h, line 56 and ARTChannelStateChangeParams.m, line 17
    internal init(state: ARTState, errorInfo: ARTErrorInfo?, storeErrorInfo: Bool, retryAttempt: ARTRetryAttempt?) {
        self.state = state
        self.errorInfo = errorInfo
        self.storeErrorInfo = storeErrorInfo
        self.retryAttempt = retryAttempt
        super.init()
    }
}