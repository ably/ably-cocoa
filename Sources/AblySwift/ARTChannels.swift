import Foundation

// swift-migration: original location ARTChannels.h, line 11 and ARTChannels.m, line 15
internal class ARTChannels<ChannelType>: NSObject where ChannelType: ARTChannel {
    private weak var delegate: ARTChannelsDelegate? // weak because delegates outlive their counterpart
    private let queue: DispatchQueue
    
    // swift-migration: original location ARTChannels+Private.h, line 16 and ARTChannels.m, line 20
    internal let channels: NSMutableDictionary
    
    // swift-migration: original location ARTChannels+Private.h, line 18
    internal let prefix: String?
    
    // swift-migration: original location ARTChannels+Private.h, line 27 and ARTChannels.m, line 17
    internal init(delegate: ARTChannelsDelegate, dispatchQueue: DispatchQueue, prefix: String?) {
        self.queue = dispatchQueue
        self.channels = NSMutableDictionary()
        self.delegate = delegate
        self.prefix = prefix
        super.init()
    }
    
    // swift-migration: original location ARTChannels.h, line 50 and ARTChannels.m, line 27
    internal func copyIntoIterator(withMapper mapper: @escaping (ChannelType) -> Any) -> NSFastEnumeration {
        var ret: NSFastEnumeration!
        queue.sync {
            let channelsArray = NSMutableArray()
            let enumerator = getNosyncIterable as! NSEnumerator
            while let nextObj = enumerator.nextObject() {
                channelsArray.add(mapper(nextObj as! ChannelType))
            }
            ret = channelsArray.objectEnumerator()
        }
        return ret
    }
    
    // swift-migration: original location ARTChannels+Private.h, line 17 and ARTChannels.m, line 39
    internal var getNosyncIterable: NSFastEnumeration {
        return channels.objectEnumerator()
    }
    
    // swift-migration: original location ARTChannels.h, line 20 and ARTChannels.m, line 43
    internal func exists(_ name: String) -> Bool {
        var ret: Bool = false
        queue.sync {
            ret = _exists(name)
        }
        return ret
    }
    
    // swift-migration: original location ARTChannels+Private.h, line 22 and ARTChannels.m, line 51
    internal func _exists(_ name: String) -> Bool {
        return channels[addPrefix(name)] != nil
    }
    
    // swift-migration: original location ARTChannels.h, line 29 and ARTChannels.m, line 55
    internal func get(_ name: String) -> ChannelType {
        return getChannel(addPrefix(name), options: nil) as! ChannelType
    }
    
    // swift-migration: original location ARTChannels.h, line 39 and ARTChannels.m, line 59
    internal func get(_ name: String, options: ARTChannelOptions) -> ChannelType {
        return getChannel(addPrefix(name), options: options) as! ChannelType
    }
    
    // swift-migration: original location ARTChannels.h, line 47 and ARTChannels.m, line 63
    internal func release(_ name: String) {
        queue.sync {
            _release(name)
        }
    }
    
    // swift-migration: original location ARTChannels+Private.h, line 25 and ARTChannels.m, line 69
    internal func _release(_ name: String) {
        channels.removeObject(forKey: addPrefix(name))
    }
    
    // swift-migration: original location ARTChannels.m, line 73
    internal func getChannel(_ name: String, options: ARTChannelOptions?) -> ARTChannel {
        var channel: ARTChannel!
        queue.sync {
            channel = _getChannel(name, options: options, addPrefix: true)
        }
        return channel
    }
    
    // swift-migration: original location ARTChannels+Private.h, line 24 and ARTChannels.m, line 81
    internal func _getChannel(_ name: String, options: ARTChannelOptions?, addPrefix: Bool) -> ARTChannel {
        var channelName = name
        if addPrefix {
            channelName = self.addPrefix(name)
        }
        var channel = _get(channelName)
        if channel == nil {
            channel = delegate?.makeChannel(channelName, options: options)
            if let channel = channel {
                channels.setObject(channel, forKey: channelName as NSString)
            }
        } else if let options = options {
            channel?.setOptions_nosync(options)
        }
        return channel!
    }
    
    // swift-migration: original location ARTChannels+Private.h, line 23 and ARTChannels.m, line 95
    internal func _get(_ name: String) -> ARTChannel? {
        return channels[name] as? ARTChannel
    }
    
    // swift-migration: original location ARTChannels+Private.h, line 20 and ARTChannels.m, line 99
    internal func addPrefix(_ name: String) -> String {
        if let prefix = self.prefix {
            if !name.hasPrefix(prefix) {
                return "\(prefix)-\(name)"
            }
        }
        return name
    }
}