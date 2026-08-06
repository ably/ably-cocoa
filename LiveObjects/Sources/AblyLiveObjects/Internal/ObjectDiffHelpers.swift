import Foundation

/// Helper methods for calculating diffs between LiveObject data values.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal enum ObjectDiffHelpers {
    /// Calculates the diff between two LiveCounter data values, per RTLC14.
    ///
    /// - Parameters:
    ///   - previousData: The previous `data` value (RTLC14a1).
    ///   - newData: The new `data` value (RTLC14a2).
    /// - Returns: Per RTLC14b.
    internal static func calculateCounterDiff(
        previousData: Double,
        newData: Double,
    ) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
        // RTLC14b specifies only the amount (newData - previousData) and does not cover the
        // zero-delta case. A zero delta means the value did not actually change (e.g. re-applying an
        // ObjectState whose count equals the current data); since an update communicates a change
        // (RTLO4b4a) we return the no-op update permitted by RTLO4b4b rather than a spurious
        // zero-amount update that would fire subscriber callbacks for no change. ably-java
        // (LiveCounterManager.calculateUpdateFromDataDiff) and ably-js do the same.
        if newData == previousData {
            return .noop
        }
        return .update(DefaultLiveCounterUpdate(amount: newData - previousData))
    }

    /// Calculates the diff between two LiveMap data values, per RTLM22.
    ///
    /// - Parameters:
    ///   - previousData: The previous `data` value (RTLM22a1).
    ///   - newData: The new `data` value (RTLM22a2).
    /// - Returns: Per RTLM22b.
    internal static func calculateMapDiff(
        previousData: [String: InternalObjectsMapEntry],
        newData: [String: InternalObjectsMapEntry],
    ) -> LiveObjectUpdate<DefaultLiveMapUpdate> {
        // RTLM22b
        let previousNonTombstonedKeys = Set(previousData.filter { !$0.value.tombstone }.keys)
        let newNonTombstonedKeys = Set(newData.filter { !$0.value.tombstone }.keys)

        var update: [String: LiveMapUpdateAction] = [:]

        // RTLM22b1
        for key in previousNonTombstonedKeys.subtracting(newNonTombstonedKeys) {
            update[key] = .removed
        }

        // RTLM22b2
        for key in newNonTombstonedKeys.subtracting(previousNonTombstonedKeys) {
            update[key] = .updated
        }

        // RTLM22b3
        for key in previousNonTombstonedKeys.intersection(newNonTombstonedKeys) {
            let previousEntry = previousData[key]!
            let newEntry = newData[key]!

            if previousEntry.data != newEntry.data {
                update[key] = .updated
            }
        }

        // RTLM22b specifies only the key diff and does not cover the empty-diff case. An empty diff
        // means nothing actually changed (e.g. re-applying an ObjectState that matches the current
        // data, or clearing an already-empty map); since an update communicates a change (RTLO4b4a)
        // we return the no-op update permitted by RTLO4b4b rather than a spurious empty update that
        // would fire subscriber callbacks for no change. ably-java
        // (LiveMapManager.calculateUpdateFromDataDiff) and ably-js do the same.
        if update.isEmpty {
            return .noop
        }

        return .update(DefaultLiveMapUpdate(update: update))
    }
}
