@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal enum LiveObjectUpdate<Update: Sendable>: Sendable {
    case noop // RTLO4b4
    case update(Update) // RTLO4b4a

    // MARK: - Convenience getters

    /// Returns `true` if and only if this `LiveObjectUpdate` has case `noop`.
    internal var isNoop: Bool {
        if case .noop = self {
            true
        } else {
            false
        }
    }

    /// If this `LiveObjectUpdate` has case `update`, returns the associated value. Else, returns `nil`.
    internal var update: Update? {
        if case let .update(update) = self {
            update
        } else {
            nil
        }
    }
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension LiveObjectUpdate: Equatable where Update: Equatable {}

// MARK: - Message/tombstone enrichment (P2)

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal extension LiveObjectUpdate where Update: LiveObjectUpdatePayload {
    /// The source public object message carried by an `update` payload (`nil` for `noop` or
    /// sync-originated updates). Spec: RTLO4b4d.
    var objectMessage: ObjectMessage? {
        update?.objectMessage
    }

    /// Whether this update tombstones the object. `false` for `noop`. Spec: RTLO4b4e.
    var tombstone: Bool {
        update?.tombstone ?? false
    }

    /// Returns a copy of this update whose `update` payload carries the given source public object
    /// message; `noop` updates are returned unchanged. Used to stamp the PAOM3 message onto an
    /// update at emission time (RTLO4b4d).
    func nosync_stampingObjectMessage(_ message: ObjectMessage?) -> Self {
        guard case var .update(payload) = self else {
            return self
        }
        payload.objectMessage = message
        return .update(payload)
    }
}
