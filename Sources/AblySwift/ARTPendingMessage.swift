import Foundation

// swift-migration: original location ARTPendingMessage.h, line 7 and ARTPendingMessage.m, line 3
/// :nodoc:
internal class ARTPendingMessage: ARTQueuedMessage {
    
    // swift-migration: original location ARTPendingMessage.h, line 11 and ARTPendingMessage.m, line 5
    internal init(protocolMessage msg: ARTProtocolMessage, ackCallback: ARTStatusCallback?) {
        super.init(protocolMessage: msg, sentCallback: nil, ackCallback: ackCallback)
    }
}