import Foundation

// swift-migration: original location ARTConnectRetryState.h, line 14 and ARTConnectRetryState.m, line 19
/**
 Maintains the state that an `ARTRealtime` instance needs in order to determine the duration to wait before retrying a connection. Wraps a sequence of `ARTRetrySequence` objects.
 */
internal class ConnectRetryState: NSObject {
    
    // swift-migration: original location ARTConnectRetryState.m, line 10
    internal let logger: InternalLog
    
    // swift-migration: original location ARTConnectRetryState.m, line 11
    internal let logMessagePrefix: String
    
    // swift-migration: original location ARTConnectRetryState.m, line 12
    internal let retryDelayCalculator: RetryDelayCalculator
    
    // swift-migration: original location ARTConnectRetryState.m, line 13
    internal var retrySequence: ARTRetrySequence?
    
    // swift-migration: original location ARTConnectRetryState.h, line 16 and ARTConnectRetryState.m, line 21
    internal init(retryDelayCalculator: RetryDelayCalculator, logger: InternalLog, logMessagePrefix: String) {
        self.retryDelayCalculator = retryDelayCalculator
        self.logger = logger
        self.logMessagePrefix = logMessagePrefix
        super.init()
    }
    
    // swift-migration: original location ARTConnectRetryState.h, line 24 and ARTConnectRetryState.m, line 33
    /**
     Calls `addRetryAttempt` on the current retry sequence.
     */
    internal func addRetryAttempt() -> ARTRetryAttempt {
        if retrySequence == nil {
            retrySequence = ARTRetrySequence(delayCalculator: retryDelayCalculator)
            ARTLogDebug(logger, "\(logMessagePrefix)Created connect retry sequence \(retrySequence!)")
        }
        
        let retryAttempt = retrySequence!.addRetryAttempt()
        ARTLogDebug(logger, "\(logMessagePrefix)Adding connect retry attempt to \(retrySequence!.id) gave \(retryAttempt)")
        
        return retryAttempt
    }
    
    // swift-migration: original location ARTConnectRetryState.h, line 29 and ARTConnectRetryState.m, line 45
    /**
     Resets the retry sequence when the channel leaves the sequence of `DISCONNECTED` <-> `CONNECTING` state changes.
     */
    internal func connectionWillTransition(to state: ARTRealtimeConnectionState) {
        // The client library specification doesn't specify when to reset the retry count (see https://github.com/ably/specification/issues/127); have copied the analogous logic in ARTAttachRetryState.
        if state != .connecting && state != .disconnected {
            retrySequence = nil
        }
    }
}
