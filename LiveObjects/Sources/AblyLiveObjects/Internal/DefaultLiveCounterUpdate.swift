@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal struct DefaultLiveCounterUpdate: LiveCounterUpdate, Equatable {
    internal var amount: Double
    /// The source public object message (op-bearing only), or `nil` for sync-originated updates (RTO4b2a).
    internal var objectMessage: ObjectMessage?
    /// Whether this update tombstones the counter (RTLO4b4e).
    internal var tombstone: Bool

    internal init(amount: Double, objectMessage: ObjectMessage? = nil, tombstone: Bool = false) {
        self.amount = amount
        self.objectMessage = objectMessage
        self.tombstone = tombstone
    }
}
