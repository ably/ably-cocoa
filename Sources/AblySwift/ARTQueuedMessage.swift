import Foundation

/// :nodoc:
// swift-migration: original location ARTQueuedMessage.h, line 9 and ARTQueuedMessage.m, line 6
internal class ARTQueuedMessage: NSObject {
    
    // swift-migration: original location ARTQueuedMessage.h, line 11
    internal let msg: ARTProtocolMessage
    
    // swift-migration: original location ARTQueuedMessage.h, line 12
    internal let sentCallbacks: NSMutableArray
    
    // swift-migration: original location ARTQueuedMessage.h, line 13
    internal let ackCallbacks: NSMutableArray
    
    // swift-migration: original location ARTQueuedMessage.m, line 8
    internal init(protocolMessage msg: ARTProtocolMessage, sentCallback: ARTCallback?, ackCallback: ARTStatusCallback?) {
        self.msg = msg
        self.sentCallbacks = NSMutableArray()
        if let sentCallback = sentCallback {
            self.sentCallbacks.add(sentCallback)
        }
        self.ackCallbacks = NSMutableArray()
        if let ackCallback = ackCallback {
            self.ackCallbacks.add(ackCallback)
        }
        super.init()
    }
    
    // swift-migration: original location ARTQueuedMessage.m, line 24
    public override var description: String {
        return msg.description
    }
    
    // swift-migration: original location ARTQueuedMessage.m, line 28
    internal func merge(from msg: ARTProtocolMessage, maxSize: Int, sentCallback: ARTCallback?, ackCallback: ARTStatusCallback?) -> Bool {
        if self.msg.merge(from: msg, maxSize: maxSize) {
            if let sentCallback = sentCallback {
                self.sentCallbacks.add(sentCallback)
            }
            if let ackCallback = ackCallback {
                self.ackCallbacks.add(ackCallback)
            }
            return true
        }
        return false
    }
    
    // swift-migration: original location ARTQueuedMessage.m, line 41
    internal func sentCallback() -> ARTCallback {
        return { error in
            for cb in self.sentCallbacks {
                if let callback = cb as? ARTCallback {
                    callback(error)
                }
            }
        }
    }
    
    // swift-migration: original location ARTQueuedMessage.m, line 49
    internal func ackCallback() -> ARTStatusCallback {
        return { status in
            for cb in self.ackCallbacks {
                if let callback = cb as? ARTStatusCallback {
                    callback(status)
                }
            }
        }
    }
}