// Test-only accessors for `ObjectsPool` (and its `Entry`), moved out of the shipped sources so
// that production code carries no test plumbing. Consumed by AblyLiveObjectsTests via
// `@testable import AblyLiveObjectsTesting`. See README.md for the dumb-accessor review rule.

@testable import AblyLiveObjects
import Foundation

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension ObjectsPool.Entry {
    /// Test-only accessor for isTombstone that handles locking internally.
    var testsOnly_isTombstone: Bool {
        switch self {
        case let .counter(counter):
            counter.testsOnly_isTombstone
        case let .map(map):
            map.testsOnly_isTombstone
        }
    }

    /// Test-only accessor for tombstonedAt that handles locking internally.
    var testsOnly_tombstonedAt: Date? {
        switch self {
        case let .counter(counter):
            counter.testsOnly_tombstonedAt
        case let .map(map):
            map.testsOnly_tombstonedAt
        }
    }
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension ObjectsPool {
    // MARK: - Test-only initializers

    init(
        logger: Logger,
        internalQueue: DispatchQueue,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock,
        testsOnly_otherEntries otherEntries: [String: Entry]? = nil,
    ) {
        self.init(
            logger: logger,
            internalQueue: internalQueue,
            userCallbackQueue: userCallbackQueue,
            clock: clock,
            otherEntries: otherEntries,
        )
    }

    // MARK: - Test-only setters

    /// Test-only setter that inserts or replaces an entry for the given object ID.
    mutating func testsOnly_setEntry(_ entry: Entry, forObjectID objectID: String) {
        entries[objectID] = entry
    }
}
