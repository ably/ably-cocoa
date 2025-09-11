import Foundation

// MARK: - ARTRealtimeChannels

// swift-migration: original location ARTRealtimeChannels.h, line 21 and ARTRealtimeChannels.m, line 10
/// :nodoc:
public class ARTRealtimeChannels: NSObject, ARTRealtimeChannelsProtocol {
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 36 and ARTRealtimeChannels.m, line 17
    internal let `internal`: ARTRealtimeChannelsInternal
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 37 and ARTRealtimeChannels.m, line 18
    internal let realtimeInternal: ARTRealtimeInternal
    
    // swift-migration: original location ARTRealtimeChannels.m, line 11
    private let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 39 and ARTRealtimeChannels.m, line 14
    internal init(internal: ARTRealtimeChannelsInternal, realtimeInternal: ARTRealtimeInternal, queuedDealloc: ARTQueuedDealloc) {
        self.`internal` = `internal`
        self.realtimeInternal = realtimeInternal
        self._dealloc = queuedDealloc
        super.init()
    }
    
    // swift-migration: original location ARTRealtimeChannels.h, line 13 and ARTRealtimeChannels.m, line 24
    public func exists(_ name: String) -> Bool {
        return `internal`.exists(name)
    }
    
    // swift-migration: original location ARTRealtimeChannels.h, line 23 and ARTRealtimeChannels.m, line 28
    public func get(_ name: String) -> ARTRealtimeChannel {
        return ARTRealtimeChannel(internal: `internal`.get(name), realtimeInternal: realtimeInternal, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRealtimeChannels.h, line 24 and ARTRealtimeChannels.m, line 32
    public func get(_ name: String, options: ARTRealtimeChannelOptions) -> ARTRealtimeChannel {
        return ARTRealtimeChannel(internal: `internal`.get(name, options: options), realtimeInternal: realtimeInternal, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRealtimeChannels.h, line 14 and ARTRealtimeChannels.m, line 36
    public func release(_ name: String, callback: ARTCallback?) {
        `internal`.release(name, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannels.h, line 15 and ARTRealtimeChannels.m, line 40
    public func release(_ name: String) {
        `internal`.release(name)
    }
    
    // swift-migration: original location ARTRealtimeChannels.h, line 31 and ARTRealtimeChannels.m, line 44
    /// Iterates through the existing channels.
    ///
    /// - Returns: Each iteration returns an `ARTRealtimeChannel` object.
    public func iterate() -> any NSFastEnumeration {
        return `internal`.copyIntoIteratorWithMapper { [weak self] internalChannel in
            guard let self = self else {
                fatalError("ARTRealtimeChannels deallocated during iteration")
            }
            return ARTRealtimeChannel(internal: internalChannel, realtimeInternal: self.realtimeInternal, queuedDealloc: self._dealloc)
        }
    }
}

// MARK: - ARTRealtimeChannelsInternal

// swift-migration: original location ARTRealtimeChannels+Private.h, line 14 and ARTRealtimeChannels.m, line 62
internal class ARTRealtimeChannelsInternal: NSObject, ARTChannelsDelegate {
    // swift-migration: original location ARTRealtimeChannels.m, line 63
    // swift-migration: Lawrence changed to implicitly unwrapped optional for breaking initialization cycle
    private var _channels: ARTChannels<ARTRealtimeChannelInternal>!
    // swift-migration: original location ARTRealtimeChannels.m, line 64
    private let _userQueue: DispatchQueue
    
    // swift-migration: original location ARTRealtimeChannels.m, line 54
    internal let logger: ARTInternalLog
    // swift-migration: original location ARTRealtimeChannels.m, line 55
    internal weak var realtime: ARTRealtimeInternal? // weak because realtime owns self
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 26
    internal var queue: DispatchQueue
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 20 and ARTRealtimeChannels.m, line 67
    internal init(realtime: ARTRealtimeInternal, logger: ARTInternalLog) {
        self.realtime = realtime
        self._userQueue = realtime.rest.userQueue
        self.queue = realtime.rest.queue
        self.logger = logger
        super.init()
        self._channels = ARTChannels(delegate: self, dispatchQueue: self.queue, prefix: realtime.options.testOptions.channelNamePrefix)
    }
    
    // swift-migration: original location ARTRealtimeChannels.m, line 78
    internal func makeChannel(_ channel: String, options: ARTChannelOptions?) -> ARTChannel {
        return ARTRealtimeChannelInternal(realtime: realtime!, name: channel, options: options, logger: logger)
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 18 and ARTRealtimeChannels.m, line 82
    internal func copyIntoIteratorWithMapper(_ mapper: @escaping (ARTRealtimeChannelInternal) -> ARTRealtimeChannel) -> any NSFastEnumeration {
        return _channels.copyIntoIterator(withMapper: mapper)
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 16 and ARTRealtimeChannels.m, line 86
    internal func get(_ name: String) -> ARTRealtimeChannelInternal {
        return _channels.get(name)
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 17 and ARTRealtimeChannels.m, line 90
    internal func get(_ name: String, options: ARTChannelOptions) -> ARTRealtimeChannelInternal {
        return _channels.get(name, options: options)
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 28 and ARTRealtimeChannels.m, line 94
    internal func exists(_ name: String) -> Bool {
        return _channels.exists(name)
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 29 and ARTRealtimeChannels.m, line 98
    internal func release(_ name: String, callback: ARTCallback?) {
        let name = _channels.addPrefix(name)
        
        var cb = callback
        if let originalCallback = callback {
            let userCallback = originalCallback
            cb = { error in
                self._userQueue.async {
                    userCallback(error)
                }
            }
        }
        
        queue.sync {
            if !self._channels._exists(name) {
                if let cb = cb {
                    cb(nil)
                }
                return
            }
            
            let channel = self._channels._get(name) as! ARTRealtimeChannelInternal
            channel._detach { errorInfo in
                channel.off_nosync()
                channel._unsubscribe()
                channel.presence._unsubscribe()
                
                // Only release if the stored channel now is the same as whne.
                // Otherwise, subsequent calls to this release method race, and
                // a new channel, created between the first call releases the stored
                // one and the second call's detach callback is called, can be
                // released unwillingly.
                if self._channels._exists(name) && self._channels._get(name) as! ARTRealtimeChannelInternal === channel {
                    self._channels._release(name)
                }
                
                if let cb = cb {
                    cb(errorInfo)
                }
            }
        }
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 30 and ARTRealtimeChannels.m, line 136
    internal func release(_ name: String) {
        release(name, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 23 and ARTRealtimeChannels.m, line 140
    internal var collection: NSMutableDictionary {
        return _channels.channels
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 22 and ARTRealtimeChannels.m, line 144
    internal var nosyncIterable: any NSFastEnumeration {
        return _channels.nosyncIterable
    }
    
    // swift-migration: original location ARTRealtimeChannels+Private.h, line 24 and ARTRealtimeChannels.m, line 148
    internal func _getChannel(_ name: String, options: ARTChannelOptions?, addPrefix: Bool) -> ARTRealtimeChannelInternal {
        return _channels._getChannel(name, options: options, addPrefix: addPrefix) as! ARTRealtimeChannelInternal
    }
}
