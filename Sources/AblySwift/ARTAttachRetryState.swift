import Foundation

// swift-migration: original location ARTAttachRetryState.h, line 14
/// Maintains the state that an `ARTRealtimeChannel` instance needs in order to determine the duration to wait before retrying an attach. Wraps a sequence of `ARTRetrySequence` objects.
public class AttachRetryState: NSObject {
    
    // swift-migration: original location ARTAttachRetryState.m, line 10
    internal let logger: InternalLog
    // swift-migration: original location ARTAttachRetryState.m, line 11
    internal let logMessagePrefix: String
    // swift-migration: original location ARTAttachRetryState.m, line 12
    internal let retryDelayCalculator: RetryDelayCalculator
    // swift-migration: original location ARTAttachRetryState.m, line 13
    internal var retrySequence: RetrySequence?
    
    // swift-migration: original location ARTAttachRetryState.h, line 16
    public init(
        retryDelayCalculator: RetryDelayCalculator,
        logger: InternalLog,
        logMessagePrefix: String
    ) {
        self.retryDelayCalculator = retryDelayCalculator
        self.logger = logger
        self.logMessagePrefix = logMessagePrefix
        super.init()
    }
    
    // swift-migration: original location ARTAttachRetryState.m, line 33
    /// Calls `addRetryAttempt` on the current retry sequence.
    public func addRetryAttempt() -> ARTRetryAttempt {
        if retrySequence == nil {
            retrySequence = RetrySequence(delayCalculator: retryDelayCalculator)
            ARTLogDebug(logger, "Created attach retry sequence \(retrySequence!)")
        }
        
        let retryAttempt = retrySequence!.addRetryAttempt()
        ARTLogDebug(logger, "Adding attach retry attempt to \(retrySequence!.id) gave \(retryAttempt)")
        
        return retryAttempt
    }
    
    // swift-migration: original location ARTAttachRetryState.m, line 45
    /// Resets the retry sequence when the channel leaves the sequence of `SUSPENDED` <-> `ATTACHING` state changes.
    public func channelWillTransition(to state: ARTRealtimeChannelState) {
        // The client library specification doesn't specify when to reset the retry count (see https://github.com/ably/specification/issues/127); have taken the logic from ably-js: https://github.com/ably/ably-js/blob/404c4128316cc5f735e3bf95a25e654e3fedd166/src/common/lib/client/realtimechannel.ts#L804-L806 (see discussion https://github.com/ably/ably-js/pull/1008/files#r925898316)
        if state != .attaching && state != .suspended {
            retrySequence = nil
        }
    }
}
