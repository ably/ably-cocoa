import Foundation

// swift-migration: original location ARTRestChannels.h, line 8
/// :nodoc:
public protocol ARTRestChannelsProtocol {
    
    // swift-migration: original location ARTRestChannels.h, line 13
    // We copy this from the parent class and replace ChannelType by ARTRestChannel * because
    // Swift ignores Objective-C generics and thinks this is returning an id, failing to compile.
    // Thus, we can't make ARTRestChannels inherit from ARTChannels; we have to compose them instead.
    func exists(_ name: String) -> Bool
    
    // swift-migration: original location ARTRestChannels.h, line 14
    func release(_ name: String)
    
    // swift-migration: original location ARTRestChannels.h, line 22
    func get(_ name: String) -> ARTRestChannel
    
    // swift-migration: original location ARTRestChannels.h, line 23
    func get(_ name: String, options: ARTChannelOptions) -> ARTRestChannel
    
    // swift-migration: original location ARTRestChannels.h, line 30
    /**
     * Iterates through the existing channels.
     *
     * @return Each iteration returns an `ARTRestChannel` object.
     */
    func iterate() -> any NSFastEnumeration
}

// swift-migration: original location ARTRestChannels.m, lines 9-44
public class ARTRestChannels: NSObject, ARTRestChannelsProtocol, @unchecked Sendable {
    internal let _internal: ARTRestChannelsInternal
    private let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTRestChannels+Private.h, line 26 and ARTRestChannels.m, line 13
    internal init(internal internalInstance: ARTRestChannelsInternal, queuedDealloc: ARTQueuedDealloc) {
        _internal = internalInstance
        _dealloc = queuedDealloc
        super.init()
    }
    
    // swift-migration: original location ARTRestChannels+Private.h, line 26
    internal var `internal`: ARTRestChannelsInternal {
        return _internal
    }
    
    // swift-migration: original location ARTRestChannels.h, line 13 and ARTRestChannels.m, line 22
    public func exists(_ name: String) -> Bool {
        return _internal.exists(name)
    }
    
    // swift-migration: original location ARTRestChannels.h, line 22 and ARTRestChannels.m, line 26
    public func get(_ name: String) -> ARTRestChannel {
        return ARTRestChannel(internal: _internal.get(name), queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRestChannels.h, line 23 and ARTRestChannels.m, line 30
    public func get(_ name: String, options: ARTChannelOptions) -> ARTRestChannel {
        return ARTRestChannel(internal: _internal.get(name, options: options), queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRestChannels.h, line 14 and ARTRestChannels.m, line 34
    public func release(_ name: String) {
        _internal.release(name)
    }
    
    // swift-migration: original location ARTRestChannels.h, line 30 and ARTRestChannels.m, line 38
    public func iterate() -> any NSFastEnumeration {
        return _internal.copyIntoIterator { internalChannel in
            ARTRestChannel(internal: internalChannel, queuedDealloc: self._dealloc)
        }
    }
}

// swift-migration: original location ARTRestChannels.m, lines 60-101
internal class ARTRestChannelsInternal: NSObject, ARTChannelsDelegate {
    private var _channels: ARTChannels<ARTRestChannelInternal>!
    
    // swift-migration: original location ARTRestChannels.m, line 50
    weak var rest: ARTRestInternal? // weak because rest owns self
    // swift-migration: original location ARTRestChannels.m, line 51
    let logger: InternalLog
    
    // swift-migration: original location ARTRestChannels+Private.h, line 16 and ARTRestChannels.m, line 64
    internal init(rest: ARTRestInternal, logger: InternalLog) {
        self.rest = rest
        self.logger = logger
        // swift-migration: Initialize with placeholder delegate 
        super.init()
        self._channels = ARTChannels<ARTRestChannelInternal>(delegate: self, dispatchQueue: rest.queue, prefix: rest.options.testOptions.channelNamePrefix)
    }
    
    // swift-migration: original location ARTRestChannels.m, line 73
    func makeChannel(_ name: String, options: ARTChannelOptions?) -> ARTChannel {
        // swift-migration: Original Objective-C passes nil directly to initializer when options is nil
        // Using utility function to preserve nil-passing behavior despite missing _Nullable annotation
        return ARTRestChannelInternal(name: name, withOptions: ARTChannelOptions(), andRest: rest!, logger: logger)
    }
    
    // swift-migration: original location ARTRestChannels+Private.h, line 14 and ARTRestChannels.m, line 77
    internal func copyIntoIterator<T>(withMapper mapper: @escaping (ARTRestChannelInternal) -> T) -> any NSFastEnumeration {
        return _channels.copyIntoIterator(withMapper: mapper)
    }
    
    // swift-migration: original location ARTRestChannels+Private.h, line 12 and ARTRestChannels.m, line 81
    internal func get(_ name: String) -> ARTRestChannelInternal {
        return _channels.get(name)
    }
    
    // swift-migration: original location ARTRestChannels+Private.h, line 13 and ARTRestChannels.m, line 85
    internal func get(_ name: String, options: ARTChannelOptions) -> ARTRestChannelInternal {
        return _channels.get(name, options: options)
    }
    
    // swift-migration: original location ARTRestChannels+Private.h, line 19 and ARTRestChannels.m, line 89
    internal func exists(_ name: String) -> Bool {
        return _channels.exists(name)
    }
    
    // swift-migration: original location ARTRestChannels+Private.h, line 20 and ARTRestChannels.m, line 93
    internal func release(_ name: String) {
        _channels.release(name)
    }
    
    // swift-migration: original location ARTRestChannels+Private.h, line 17 and ARTRestChannels.m, line 97
    internal func _getChannel(_ name: String, options: ARTChannelOptions?, addPrefix: Bool) -> ARTRestChannelInternal {
        return _channels._getChannel(name, options: options, addPrefix: addPrefix) as! ARTRestChannelInternal
    }
}
