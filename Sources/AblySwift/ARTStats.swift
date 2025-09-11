import Foundation

// swift-migration: original location ARTStats.h, line 11
public enum ARTStatsGranularity: UInt, Sendable {
    case minute = 0
    case hour = 1
    case day = 2
    case month = 3
}

// swift-migration: original location ARTStats.h, line 33
public class ARTStatsQuery: ARTDataQuery {
    
    // swift-migration: original location ARTStats.h, line 38 and ARTStats.m, line 8
    public var unit: ARTStatsGranularity
    
    // swift-migration: original location ARTStats.m, line 6
    public override init() {
        self.unit = .minute
        super.init()
    }
    
    // swift-migration: original location ARTStats.m, line 28
    // swift-migration: Changed from inout Error? parameter to throws pattern per PRD requirements
    internal override func asQueryItems() throws -> [URLQueryItem] {
        let items = try super.asQueryItems()
        var mutableItems = items
        mutableItems.append(URLQueryItem(name: "unit", value: statsUnitToString(self.unit)))
        return mutableItems
    }
}

// swift-migration: original location ARTStats.m, line 14
private func statsUnitToString(_ unit: ARTStatsGranularity) -> String {
    switch unit {
    case .month:
        return "month"
    case .day:
        return "day"
    case .hour:
        return "hour"
    case .minute:
        return "minute"
    }
}

// swift-migration: original location ARTStats.h, line 45
public class ARTStatsMessageCount: NSObject {
    
    // swift-migration: original location ARTStats.h, line 50
    public let count: UInt
    
    // swift-migration: original location ARTStats.h, line 55
    public let data: UInt
    
    // swift-migration: original location ARTStats.h, line 61 and ARTStats.m, line 41
    public init(count: UInt, data: UInt) {
        self.count = count
        self.data = data
        super.init()
    }
    
    // swift-migration: original location ARTStats.h, line 65 and ARTStats.m, line 50
    public static var empty: ARTStatsMessageCount {
        return ARTStatsMessageCount(count: 0, data: 0)
    }
}

// swift-migration: original location ARTStats.h, line 72
public class ARTStatsMessageTypes: NSObject {
    
    // swift-migration: original location ARTStats.h, line 77
    public let all: ARTStatsMessageCount
    
    // swift-migration: original location ARTStats.h, line 82
    public let messages: ARTStatsMessageCount
    
    // swift-migration: original location ARTStats.h, line 87
    public let presence: ARTStatsMessageCount
    
    // swift-migration: original location ARTStats.h, line 93 and ARTStats.m, line 58
    public init(all: ARTStatsMessageCount?, messages: ARTStatsMessageCount?, presence: ARTStatsMessageCount?) {
        self.all = all ?? ARTStatsMessageCount.empty
        self.messages = messages ?? ARTStatsMessageCount.empty
        self.presence = presence ?? ARTStatsMessageCount.empty
        super.init()
    }
    
    // swift-migration: original location ARTStats.h, line 98 and ARTStats.m, line 68
    public static var empty: ARTStatsMessageTypes {
        return ARTStatsMessageTypes(all: ARTStatsMessageCount.empty, messages: ARTStatsMessageCount.empty, presence: ARTStatsMessageCount.empty)
    }
}

// swift-migration: original location ARTStats.h, line 105
public class ARTStatsMessageTraffic: NSObject {
    
    // swift-migration: original location ARTStats.h, line 110
    public let all: ARTStatsMessageTypes
    
    // swift-migration: original location ARTStats.h, line 115
    public let realtime: ARTStatsMessageTypes
    
    // swift-migration: original location ARTStats.h, line 120
    public let rest: ARTStatsMessageTypes
    
    // swift-migration: original location ARTStats.h, line 125
    public let webhook: ARTStatsMessageTypes
    
    // swift-migration: original location ARTStats.h, line 131 and ARTStats.m, line 76
    public init(all: ARTStatsMessageTypes?, realtime: ARTStatsMessageTypes?, rest: ARTStatsMessageTypes?, webhook: ARTStatsMessageTypes?) {
        self.all = all ?? ARTStatsMessageTypes.empty
        self.realtime = realtime ?? ARTStatsMessageTypes.empty
        self.rest = rest ?? ARTStatsMessageTypes.empty
        self.webhook = webhook ?? ARTStatsMessageTypes.empty
        super.init()
    }
    
    // swift-migration: original location ARTStats.h, line 137 and ARTStats.m, line 87
    public static var empty: ARTStatsMessageTraffic {
        return ARTStatsMessageTraffic(all: ARTStatsMessageTypes.empty, realtime: ARTStatsMessageTypes.empty, rest: ARTStatsMessageTypes.empty, webhook: ARTStatsMessageTypes.empty)
    }
}

// swift-migration: original location ARTStats.h, line 144
public class ARTStatsResourceCount: NSObject {
    
    // swift-migration: original location ARTStats.h, line 149
    public let opened: UInt
    
    // swift-migration: original location ARTStats.h, line 154
    public let peak: UInt
    
    // swift-migration: original location ARTStats.h, line 159
    public let mean: UInt
    
    // swift-migration: original location ARTStats.h, line 164
    public let min: UInt
    
    // swift-migration: original location ARTStats.h, line 169
    public let refused: UInt
    
    // swift-migration: original location ARTStats.h, line 175 and ARTStats.m, line 95
    public init(opened: UInt, peak: UInt, mean: UInt, min: UInt, refused: UInt) {
        self.opened = opened
        self.peak = peak
        self.mean = mean
        self.min = min
        self.refused = refused
        super.init()
    }
    
    // swift-migration: original location ARTStats.h, line 182 and ARTStats.m, line 107
    public static var empty: ARTStatsResourceCount {
        return ARTStatsResourceCount(opened: 0, peak: 0, mean: 0, min: 0, refused: 0)
    }
}

// swift-migration: original location ARTStats.h, line 189
public class ARTStatsConnectionTypes: NSObject {
    
    // swift-migration: original location ARTStats.h, line 194
    public let all: ARTStatsResourceCount
    
    // swift-migration: original location ARTStats.h, line 199
    public let plain: ARTStatsResourceCount
    
    // swift-migration: original location ARTStats.h, line 204
    public let tls: ARTStatsResourceCount
    
    // swift-migration: original location ARTStats.h, line 210 and ARTStats.m, line 115
    public init(all: ARTStatsResourceCount?, plain: ARTStatsResourceCount?, tls: ARTStatsResourceCount?) {
        self.all = all ?? ARTStatsResourceCount.empty
        self.plain = plain ?? ARTStatsResourceCount.empty
        self.tls = tls ?? ARTStatsResourceCount.empty
        super.init()
    }
    
    // swift-migration: original location ARTStats.h, line 215 and ARTStats.m, line 125
    public static var empty: ARTStatsConnectionTypes {
        return ARTStatsConnectionTypes(all: ARTStatsResourceCount.empty, plain: ARTStatsResourceCount.empty, tls: ARTStatsResourceCount.empty)
    }
}

// swift-migration: original location ARTStats.h, line 222
public class ARTStatsRequestCount: NSObject {
    
    // swift-migration: original location ARTStats.h, line 227
    public let succeeded: UInt
    
    // swift-migration: original location ARTStats.h, line 232
    public let failed: UInt
    
    // swift-migration: original location ARTStats.h, line 237
    public let refused: UInt
    
    // swift-migration: original location ARTStats.h, line 243 and ARTStats.m, line 133
    public init(succeeded: UInt, failed: UInt, refused: UInt) {
        self.succeeded = succeeded
        self.failed = failed
        self.refused = refused
        super.init()
    }
    
    // swift-migration: original location ARTStats.h, line 248 and ARTStats.m, line 143
    public static var empty: ARTStatsRequestCount {
        return ARTStatsRequestCount(succeeded: 0, failed: 0, refused: 0)
    }
}

// swift-migration: original location ARTStats.h, line 255
public class ARTStatsPushCount: NSObject {
    
    // swift-migration: original location ARTStats.h, line 260
    public let succeeded: UInt
    
    // swift-migration: original location ARTStats.h, line 265
    public let invalid: UInt
    
    // swift-migration: original location ARTStats.h, line 270
    public let attempted: UInt
    
    // swift-migration: original location ARTStats.h, line 275
    public let failed: UInt
    
    // swift-migration: original location ARTStats.h, line 280
    public let messages: UInt
    
    // swift-migration: original location ARTStats.h, line 285
    public let direct: UInt
    
    // swift-migration: original location ARTStats.h, line 291 and ARTStats.m, line 151
    public init(succeeded: UInt, invalid: UInt, attempted: UInt, failed: UInt, messages: UInt, direct: UInt) {
        self.succeeded = succeeded
        self.invalid = invalid
        self.attempted = attempted
        self.failed = failed
        self.messages = messages
        self.direct = direct
        super.init()
    }
    
    // swift-migration: original location ARTStats.h, line 299 and ARTStats.m, line 169
    public static var empty: ARTStatsPushCount {
        return ARTStatsPushCount(succeeded: 0, invalid: 0, attempted: 0, failed: 0, messages: 0, direct: 0)
    }
}

// swift-migration: original location ARTStats.h, line 306
public class ARTStats: NSObject {
    
    // swift-migration: original location ARTStats.h, line 320
    public let all: ARTStatsMessageTypes
    
    // swift-migration: original location ARTStats.h, line 325
    public let inbound: ARTStatsMessageTraffic
    
    // swift-migration: original location ARTStats.h, line 330
    public let outbound: ARTStatsMessageTraffic
    
    // swift-migration: original location ARTStats.h, line 335
    public let persisted: ARTStatsMessageTypes
    
    // swift-migration: original location ARTStats.h, line 340
    public let connections: ARTStatsConnectionTypes
    
    // swift-migration: original location ARTStats.h, line 345
    public let channels: ARTStatsResourceCount
    
    // swift-migration: original location ARTStats.h, line 350
    public let apiRequests: ARTStatsRequestCount
    
    // swift-migration: original location ARTStats.h, line 355
    public let tokenRequests: ARTStatsRequestCount
    
    // swift-migration: original location ARTStats.h, line 360
    public let pushes: ARTStatsPushCount
    
    // swift-migration: original location ARTStats.h, line 363
    public let inProgress: String
    
    // swift-migration: original location ARTStats.h, line 366
    public let count: UInt
    
    // swift-migration: original location ARTStats.h, line 371
    public let intervalId: String
    
    // swift-migration: original location ARTStats.h, line 377 and ARTStats.m, line 177
    public init(all: ARTStatsMessageTypes, inbound: ARTStatsMessageTraffic, outbound: ARTStatsMessageTraffic, persisted: ARTStatsMessageTypes, connections: ARTStatsConnectionTypes, channels: ARTStatsResourceCount, apiRequests: ARTStatsRequestCount, tokenRequests: ARTStatsRequestCount, pushes: ARTStatsPushCount, inProgress: String, count: UInt, intervalId: String) {
        self.all = all
        self.inbound = inbound
        self.outbound = outbound
        self.persisted = persisted
        self.connections = connections
        self.channels = channels
        self.apiRequests = apiRequests
        self.tokenRequests = tokenRequests
        self.pushes = pushes
        self.inProgress = inProgress
        self.count = count
        self.intervalId = intervalId
        super.init()
    }
    
    // swift-migration: original location ARTStats.m, line 207
    private static var intervalFormatStrings: [String] {
        return ["yyyy-MM-dd:HH:mm", "yyyy-MM-dd:HH", "yyyy-MM-dd", "yyyy-MM"]
    }
    
    // swift-migration: original location ARTStats.h, line 309 and ARTStats.m, line 215
    public static func dateFromIntervalId(_ intervalId: String) -> Date {
        for format in intervalFormatStrings {
            if format.count == intervalId.count {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.timeZone = TimeZone(identifier: "UTC")
                if let date = formatter.date(from: intervalId) {
                    return date
                }
            }
        }
        fatalError("invalid intervalId")
    }
    
    // swift-migration: original location ARTStats.h, line 312 and ARTStats.m, line 227
    public static func granularityFromIntervalId(_ intervalId: String) -> ARTStatsGranularity {
        let formats = intervalFormatStrings
        for (i, format) in formats.enumerated() {
            if format.count == intervalId.count {
                return ARTStatsGranularity(rawValue: UInt(i))!
            }
        }
        fatalError("invalid intervalId")
    }
    
    // swift-migration: original location ARTStats.h, line 315 and ARTStats.m, line 237
    public static func toIntervalId(_ time: Date, granularity: ARTStatsGranularity) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = intervalFormatStrings[Int(granularity.rawValue)]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: time)
    }
    
    // swift-migration: original location ARTStats.h, line 393 and ARTStats.m, line 248
    public func intervalTime() -> Date {
        return ARTStats.dateFromIntervalId(self.intervalId)
    }
    
    // swift-migration: original location ARTStats.h, line 398 and ARTStats.m, line 244
    public func intervalGranularity() -> ARTStatsGranularity {
        return ARTStats.granularityFromIntervalId(self.intervalId)
    }
    
    // swift-migration: original location ARTStats.h, line 401 and ARTStats.m, line 252
    public func dateFromInProgress() -> Date {
        for format in ARTStats.intervalFormatStrings {
            if format.count == self.inProgress.count {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.timeZone = TimeZone(identifier: "UTC")
                if let date = formatter.date(from: self.inProgress) {
                    return date
                }
            }
        }
        fatalError("invalid inProgress")
    }
}