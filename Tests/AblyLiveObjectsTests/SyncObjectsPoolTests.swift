@testable import AblyLiveObjects
import Foundation
import Testing

struct SyncObjectsPoolTests {
    @Test
    func initCreatesEmptyPool() {
        let pool = SyncObjectsPool()

        #expect(pool.isEmpty)
    }

    @Test
    func initWithEntriesCreatesPoolWithThoseEntries() {
        let entries: [SyncObjectsPool.Entry] = [
            .init(state: TestFactories.mapObjectState(objectId: "map:a@1"), objectMessageSerialTimestamp: nil),
            .init(state: TestFactories.counterObjectState(objectId: "counter:b@2"), objectMessageSerialTimestamp: nil),
        ]

        let pool = SyncObjectsPool(entries: entries)

        #expect(pool.count == 2)
    }

    @Test
    func appendAccumulatesEntries() {
        var pool = SyncObjectsPool()

        pool.append(contentsOf: [
            .init(state: TestFactories.mapObjectState(objectId: "map:a@1"), objectMessageSerialTimestamp: nil),
        ])
        #expect(pool.count == 1)

        pool.append(contentsOf: [
            .init(state: TestFactories.counterObjectState(objectId: "counter:b@2"), objectMessageSerialTimestamp: nil),
            .init(state: TestFactories.mapObjectState(objectId: "map:c@3"), objectMessageSerialTimestamp: nil),
        ])
        #expect(pool.count == 3)
    }

    @Test
    func iterationYieldsAllEntries() {
        let objectIds = ["map:a@1", "counter:b@2", "map:c@3"]
        let entries: [SyncObjectsPool.Entry] = objectIds.map { objectId in
            .init(state: TestFactories.mapObjectState(objectId: objectId), objectMessageSerialTimestamp: nil)
        }
        let pool = SyncObjectsPool(entries: entries)

        let iteratedObjectIds = pool.map(\.state.objectId)

        #expect(iteratedObjectIds == objectIds)
    }

    @Test
    func entryPreservesObjectMessageSerialTimestamp() {
        let timestamp = Date(timeIntervalSince1970: 1_000_000)
        let entry = SyncObjectsPool.Entry(
            state: TestFactories.mapObjectState(),
            objectMessageSerialTimestamp: timestamp,
        )

        #expect(entry.objectMessageSerialTimestamp == timestamp)
    }

    @Test
    func entryAllowsNilObjectMessageSerialTimestamp() {
        let entry = SyncObjectsPool.Entry(
            state: TestFactories.mapObjectState(),
            objectMessageSerialTimestamp: nil,
        )

        #expect(entry.objectMessageSerialTimestamp == nil)
    }
}
