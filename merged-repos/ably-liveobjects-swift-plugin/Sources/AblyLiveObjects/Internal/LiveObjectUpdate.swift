@available(macOS 10.15, iOS 13, tvOS 13, *)
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

@available(macOS 10.15, iOS 13, tvOS 13, *)
extension LiveObjectUpdate: Equatable where Update: Equatable {}
