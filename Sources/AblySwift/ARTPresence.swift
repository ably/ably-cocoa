import Foundation

// swift-migration: original location ARTPresence.h, line 10 and ARTPresence.m, line 3
/// :nodoc:
public class ARTPresence: NSObject {

    // swift-migration: original location ARTPresence+Private.h, line 12
    internal var channel: ARTChannel {
        return getChannel()
    }

    // swift-migration: original location ARTPresence+Private.h, line 12
    private func getChannel() -> ARTChannel {
        fatalError("ARTPresence getChannel not yet implemented - should be overridden by subclasses")
    }

    // swift-migration: original location ARTPresence+Private.h, line 14
    internal init(channel: ARTChannel) {
        super.init()
        fatalError("ARTPresence init not yet implemented - should be overridden by subclasses")
    }

    // swift-migration: original location ARTPresence.h, line 12 and ARTPresence.m, line 5
    public func history(_ callback: @escaping ARTPaginatedPresenceCallback) {
        assertionFailure("-[\(type(of: self)) \(#function)] should always be overriden.")
    }

}