@testable import AblyLiveObjects
import Foundation
import Testing

struct SyncObjectsPoolTests {
    @Test
    func initCreatesEmptyPool() {
        let pool = SyncObjectsPool()

        #expect(pool.isEmpty)
    }

    // MARK: - accumulate: skip / reject

    // @specOneOf (1/2) RTO5f3
    @Test
    func accumulateSkipsMessageWithNoObjectState() {
        var pool = SyncObjectsPool()
        let message = TestFactories.inboundObjectMessage(object: nil)

        pool.accumulate([message], logger: TestLogger())

        #expect(pool.isEmpty)
    }

    // @specOneOf(2/2) RTO5f3
    @Test
    func accumulateSkipsUnsupportedObjectType() {
        var pool = SyncObjectsPool()
        // An ObjectState with neither map nor counter set.
        let message = TestFactories.inboundObjectMessage(
            object: TestFactories.objectState(objectId: "unknown:abc@1"),
        )

        pool.accumulate([message], logger: TestLogger())

        #expect(pool.isEmpty)
    }

    // MARK: - accumulate: store new (RTO5f1)

    // @specOneOf(1/2) RTO5f1
    @Test
    func accumulateStoresNewMapMessage() {
        var pool = SyncObjectsPool()
        let message = TestFactories.inboundObjectMessage(
            object: TestFactories.mapObjectState(objectId: "map:a@1"),
            serialTimestamp: Date(timeIntervalSince1970: 1_000_000),
        )

        pool.accumulate([message], logger: TestLogger())

        #expect(pool.count == 1)
        #expect(Array(pool) == [message])
    }

    // @specOneOf(2/2) RTO5f1
    @Test
    func accumulateStoresNewCounterMessage() {
        var pool = SyncObjectsPool()
        let message = TestFactories.inboundObjectMessage(
            object: TestFactories.counterObjectState(objectId: "counter:b@1", count: 42),
            serialTimestamp: Date(timeIntervalSince1970: 2_000_000),
        )

        pool.accumulate([message], logger: TestLogger())

        #expect(pool.count == 1)
        #expect(Array(pool) == [message])
    }

    // MARK: - accumulate: partial map merge (RTO5f2a)

    // @spec RTO5f2a1
    @Test
    func accumulateReplacesMapEntryWhenTombstoneTrue() {
        var pool = SyncObjectsPool()
        let logger = TestLogger()

        let (key1, entry1) = TestFactories.stringMapEntry(key: "key1", value: "value1")
        let firstMessage = TestFactories.inboundObjectMessage(
            object: TestFactories.mapObjectState(
                objectId: "map:a@1",
                entries: [key1: entry1],
            ),
        )
        pool.accumulate([firstMessage], logger: logger)

        // Second message with tombstone=true should replace entirely. (Note this is a somewhat contrived scenario because in reality a tombstoned map will have no entries — but then we wouldn't be able to test this spec point.)
        let (key2, entry2) = TestFactories.stringMapEntry(key: "key2", value: "value2")
        let tombstoneMessage = TestFactories.inboundObjectMessage(
            object: TestFactories.mapObjectState(
                objectId: "map:a@1",
                tombstone: true,
                entries: [key2: entry2],
            ),
        )
        pool.accumulate([tombstoneMessage], logger: logger)

        #expect(pool.count == 1)
        let entry = Array(pool).first
        #expect(entry?.object?.tombstone == true)
        // Only the replacement entries should be present.
        #expect(entry?.object?.map?.entries?["key2"] != nil)
        #expect(entry?.object?.map?.entries?["key1"] == nil)
    }

    // @spec RTO5f2a2
    @Test
    func accumulateMergesMapEntries() {
        var pool = SyncObjectsPool()
        let logger = TestLogger()

        var expectedEntries: [String: ObjectsMapEntry] = [:]
        for i in 1 ... 3 {
            let (key, entry) = TestFactories.stringMapEntry(key: "key\(i)", value: "value\(i)")
            expectedEntries[key] = entry
            let message = TestFactories.inboundObjectMessage(
                object: TestFactories.mapObjectState(
                    objectId: "map:a@1",
                    entries: [key: entry],
                ),
            )
            pool.accumulate([message], logger: logger)
        }

        #expect(pool.count == 1)
        let entry = Array(pool).first
        #expect(entry?.object?.map?.entries == expectedEntries)
    }

    // Note this is a gap in the spec (because the server should never send two different object types for a given object ID), and arguably not one worth specifying, and there's no _correct_ behaviour here — our handling is arbitrary — but we have a test just because the code still needs to do _something_ and we want code coverage for that branch.
    @Test
    func accumulateReplacesExistingNonMapEntryWhenMergingMap() {
        var pool = SyncObjectsPool()
        let logger = TestLogger()

        // Store a counter first.
        let counterMessage = TestFactories.inboundObjectMessage(
            object: TestFactories.counterObjectState(objectId: "counter:a@1", count: 10),
        )
        pool.accumulate([counterMessage], logger: logger)

        // Now accumulate a map message for the same objectId — the existing entry is not a map,
        // so the pool should replace it with the incoming map message.
        let (key, entry) = TestFactories.stringMapEntry(key: "key1", value: "value1")
        let mapMessage = TestFactories.inboundObjectMessage(
            object: TestFactories.mapObjectState(
                objectId: "counter:a@1",
                entries: [key: entry],
            ),
        )
        pool.accumulate([mapMessage], logger: logger)

        #expect(pool.count == 1)
        let result = Array(pool).first
        #expect(result?.object?.map?.entries?["key1"] != nil)
        #expect(result?.object?.counter == nil)
    }

    // MARK: - accumulate: partial counter (RTO5f2b)

    // @spec RTO5f2b
    @Test
    func accumulateSkipsPartialCounter() {
        var pool = SyncObjectsPool()
        let logger = TestLogger()

        let firstMessage = TestFactories.inboundObjectMessage(
            object: TestFactories.counterObjectState(objectId: "counter:a@1", count: 10),
        )
        pool.accumulate([firstMessage], logger: logger)

        // A second counter message for the same objectId should be skipped.
        let secondMessage = TestFactories.inboundObjectMessage(
            object: TestFactories.counterObjectState(objectId: "counter:a@1", count: 20),
        )
        pool.accumulate([secondMessage], logger: logger)

        #expect(pool.count == 1)
        // The original entry should be preserved.
        let entry = Array(pool).first
        #expect(entry?.object?.counter?.count == NSNumber(value: 10))
    }

    // MARK: - Iteration

    @Test
    func iterationYieldsAllEntries() {
        var pool = SyncObjectsPool()
        let messages = [
            TestFactories.inboundObjectMessage(object: TestFactories.mapObjectState(objectId: "map:a@1")),
            TestFactories.inboundObjectMessage(object: TestFactories.counterObjectState(objectId: "counter:b@2")),
            TestFactories.inboundObjectMessage(object: TestFactories.mapObjectState(objectId: "map:c@3")),
        ]

        pool.accumulate(messages, logger: TestLogger())

        let yielded = Array(pool).sorted { $0.object!.objectId < $1.object!.objectId }
        let expected = messages.sorted { $0.object!.objectId < $1.object!.objectId }
        #expect(yielded == expected)
    }
}
