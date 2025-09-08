import Foundation

// swift-migration: original location ARTConnectionStateChangeParams.h, line 14 and ARTConnectionStateChangeParams.m, line 3
/**
 Provides parameters for a request to perform an operation that may cause an `ARTRealtimeInternal` instance to emit a connection state change.

 `ARTRealtimeInternal` will incorporate this data into the `ARTConnectionStateChange` object that it emits as a result of the connection state change.
 */
internal class ARTConnectionStateChangeParams: NSObject {
    
    // swift-migration: original location ARTConnectionStateChangeParams.h, line 19
    /**
     Information about the error that triggered this state change, if any.
     */
    internal let errorInfo: ARTErrorInfo?
    
    // swift-migration: original location ARTConnectionStateChangeParams.h, line 21
    internal let retryAttempt: ARTRetryAttempt?
    
    // swift-migration: original location ARTConnectionStateChangeParams.h, line 23
    internal var resumed: Bool = false
    
    // swift-migration: original location ARTConnectionStateChangeParams.h, line 28 and ARTConnectionStateChangeParams.m, line 5
    /**
     Creates an `ARTConnectionStateChangeParams` instance whose `errorInfo` is `nil`.
     */
    internal override init() {
        self.errorInfo = nil
        self.retryAttempt = nil
        super.init()
    }
    
    // swift-migration: original location ARTConnectionStateChangeParams.h, line 30 and ARTConnectionStateChangeParams.m, line 9
    internal init(errorInfo: ARTErrorInfo?) {
        self.errorInfo = errorInfo
        self.retryAttempt = nil
        super.init()
    }
    
    // swift-migration: original location ARTConnectionStateChangeParams.h, line 32 and ARTConnectionStateChangeParams.m, line 13
    internal init(errorInfo: ARTErrorInfo?, retryAttempt: ARTRetryAttempt?) {
        self.errorInfo = errorInfo
        self.retryAttempt = retryAttempt
        super.init()
    }
}