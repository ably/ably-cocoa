@testable import AblyLiveObjects
import Foundation
import Testing

struct ObjectDiffHelpersTests {
    /// Tests for the `calculateCounterDiff` method, covering RTLC14 specification points
    struct CalculateCounterDiffTests {
        // @spec RTLC14b
        @Test
        func calculatesDifference() {
            let update = ObjectDiffHelpers.calculateCounterDiff(
                previousData: 10.0,
                newData: 15.0,
            )
            #expect(update.update?.amount == 5.0)
        }
    }

    /// Tests for the `calculateMapDiff` method, covering RTLM22 specification points
    struct CalculateMapDiffTests {
        // @spec RTLM22b1
        @Test
        func detectsRemovedKeys() {
            let previousData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
                "key2": TestFactories.internalMapEntry(data: ObjectData(string: "value2")),
            ]
            let newData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
            ]

            let update = ObjectDiffHelpers.calculateMapDiff(
                previousData: previousData,
                newData: newData,
            )

            #expect(update.update?.update["key2"] == .removed)
            #expect(update.update?.update["key1"] == nil) // key1 unchanged
        }

        // @spec RTLM22b2
        @Test
        func detectsAddedKeys() {
            let previousData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
            ]
            let newData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
                "key2": TestFactories.internalMapEntry(data: ObjectData(string: "value2")),
            ]

            let update = ObjectDiffHelpers.calculateMapDiff(
                previousData: previousData,
                newData: newData,
            )

            #expect(update.update?.update["key2"] == .updated)
            #expect(update.update?.update["key1"] == nil) // key1 unchanged
        }

        // @specOneOf(1/2) RTLM22b3
        @Test
        func detectsUpdatedKeys() {
            let previousData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "oldValue")),
            ]
            let newData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "newValue")),
            ]

            let update = ObjectDiffHelpers.calculateMapDiff(
                previousData: previousData,
                newData: newData,
            )

            #expect(update.update?.update["key1"] == .updated)
        }

        // @specOneOf(2/2) RTLM22b3
        @Test
        func ignoresUnchangedKeys() {
            let previousData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
            ]
            let newData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
            ]

            let update = ObjectDiffHelpers.calculateMapDiff(
                previousData: previousData,
                newData: newData,
            )

            #expect(update.update?.update.isEmpty == true)
        }

        // @specOneOf(1/3) RTLM22b - Ignores tombstoned entries in previousData
        @Test
        func ignoresTombstonedEntriesInPreviousData() {
            let previousData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(tombstonedAt: Date(), data: ObjectData(string: "value1")),
                "key2": TestFactories.internalMapEntry(data: ObjectData(string: "value2")),
            ]
            let newData: [String: InternalObjectsMapEntry] = [
                "key2": TestFactories.internalMapEntry(data: ObjectData(string: "value2")),
            ]

            let update = ObjectDiffHelpers.calculateMapDiff(
                previousData: previousData,
                newData: newData,
            )

            // key1 was tombstoned in previousData, so it's not considered "removed"
            #expect(update.update?.update["key1"] == nil)
            #expect(update.update?.update.isEmpty == true)
        }

        // @specOneOf(2/3) RTLM22b - Ignores tombstoned entries in newData
        @Test
        func ignoresTombstonedEntriesInNewData() {
            let previousData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
            ]
            let newData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(tombstonedAt: Date(), data: ObjectData(string: "value1")),
            ]

            let update = ObjectDiffHelpers.calculateMapDiff(
                previousData: previousData,
                newData: newData,
            )

            // key1 became tombstoned in newData, so it's considered "removed"
            #expect(update.update?.update["key1"] == .removed)
        }

        // @specOneOf(3/3) RTLM22b - Tombstoned to tombstoned is not a change
        @Test
        func ignoresTombstonedToTombstonedTransition() {
            let previousData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(tombstonedAt: Date(), data: ObjectData(string: "value1")),
            ]
            let newData: [String: InternalObjectsMapEntry] = [
                "key1": TestFactories.internalMapEntry(tombstonedAt: Date(), data: ObjectData(string: "value2")),
            ]

            let update = ObjectDiffHelpers.calculateMapDiff(
                previousData: previousData,
                newData: newData,
            )

            // Both tombstoned, so no change
            #expect(update.update?.update.isEmpty == true)
        }

        // Test combined changes
        @Test
        func detectsMultipleChanges() {
            let previousData: [String: InternalObjectsMapEntry] = [
                "removed": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
                "updated": TestFactories.internalMapEntry(data: ObjectData(string: "oldValue")),
                "unchanged": TestFactories.internalMapEntry(data: ObjectData(string: "sameValue")),
            ]
            let newData: [String: InternalObjectsMapEntry] = [
                "added": TestFactories.internalMapEntry(data: ObjectData(string: "value2")),
                "updated": TestFactories.internalMapEntry(data: ObjectData(string: "newValue")),
                "unchanged": TestFactories.internalMapEntry(data: ObjectData(string: "sameValue")),
            ]

            let update = ObjectDiffHelpers.calculateMapDiff(
                previousData: previousData,
                newData: newData,
            )

            #expect(update.update?.update["removed"] == .removed)
            #expect(update.update?.update["added"] == .updated)
            #expect(update.update?.update["updated"] == .updated)
            #expect(update.update?.update["unchanged"] == nil)
        }
    }
}
