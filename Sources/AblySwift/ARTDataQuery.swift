import Foundation

// swift-migration: original location ARTDataQuery.h, line 17 and ARTDataQuery.m, line 4
/**
 This object is used for providing parameters into methods with paginated results.
 */
public class ARTDataQuery: NSObject {
    
    // swift-migration: original location ARTDataQuery.h, line 22
    /**
     * The time from which the data items are retrieved.
     */
    public var start: Date?
    
    // swift-migration: original location ARTDataQuery.h, line 27
    /**
     * The time until the data items are retrieved.
     */
    public var end: Date?
    
    // swift-migration: original location ARTDataQuery.h, line 32
    /**
     * An upper limit on the number of the data items returned. The default is 100, and the maximum is 1000.
     */
    public var limit: UInt16
    
    // swift-migration: original location ARTDataQuery.h, line 37
    /**
     * The order for which the data is returned in. Valid values are `ARTQueryDirectionBackwards` which orders items from most recent to oldest, or `ARTQueryDirectionForwards` which orders items from oldest to most recent. The default is `ARTQueryDirectionBackwards`.
     */
    public var direction: ARTQueryDirection
    
    // swift-migration: original location ARTDataQuery.m, line 6
    public override init() {
        self.limit = 100
        self.direction = .backwards
        super.init()
    }
    
    // swift-migration: original location ARTDataQuery+Private.h, line 8 and ARTDataQuery.m, line 25
    // swift-migration: Changed from inout Error? parameter to throws pattern per PRD requirements
    internal func asQueryItems() throws -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let start = start {
            items.append(URLQueryItem(name: "start", value: "\(dateToMilliseconds(start))"))
        }
        if let end = end {
            items.append(URLQueryItem(name: "end", value: "\(dateToMilliseconds(end))"))
        }
        
        items.append(URLQueryItem(name: "limit", value: "\(limit)"))
        items.append(URLQueryItem(name: "direction", value: queryDirectionToString(direction)))
        
        return items
    }
}

// swift-migration: original location ARTDataQuery.m, line 15
private func queryDirectionToString(_ direction: ARTQueryDirection) -> String {
    switch direction {
    case .forwards:
        return "forwards"
    case .backwards:
        return "backwards"
    }
}

// swift-migration: original location ARTDataQuery.h, line 44 and ARTDataQuery.m, line 43
/**
 This object is used for providing parameters into `ARTRealtimePresence`'s methods with paginated results.
 */
public class ARTRealtimeHistoryQuery: ARTDataQuery {
    
    // swift-migration: original location ARTDataQuery.h, line 49
    /**
     * When `true`, ensures message history is up until the point of the channel being attached. See [continuous history](https://ably.com/docs/realtime/history#continuous-history) for more info. Requires the `direction` to be `ARTQueryDirectionBackwards`. If the channel is not attached, or if `direction` is set to `ARTQueryDirectionForwards`, this option results in an error.
     */
    public var untilAttach: Bool = false
    
    // swift-migration: original location ARTDataQuery+Private.h, line 14
    internal var realtimeChannel: ARTRealtimeChannelInternal?
    
    // swift-migration: original location ARTDataQuery.m, line 45
    // swift-migration: Changed from inout Error? parameter to throws pattern per PRD requirements
    internal override func asQueryItems() throws -> [URLQueryItem] {
        let items = try super.asQueryItems()
        var mutableItems = items
        
        if untilAttach {
            assert(realtimeChannel != nil, "ARTRealtimeHistoryQuery used from outside ARTRealtimeChannel.history")
            if realtimeChannel?.state_nosync != .attached {
                throw NSError(domain: ARTAblyErrorDomain, code: Int(ARTRealtimeHistoryErrorNotAttached), userInfo: [NSLocalizedDescriptionKey: "ARTRealtimeHistoryQuery: untilAttach used in channel that isn't attached"])
            }
            mutableItems.append(URLQueryItem(name: "fromSerial", value: realtimeChannel?.attachSerial))
        }
        
        return mutableItems
    }
}

// Add missing error constants to placeholders if they don't exist
private let ARTRealtimeHistoryErrorNotAttached = ARTRealtimeHistoryError.notAttached.rawValue