@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal struct DefaultLiveMapUpdate: LiveMapUpdate, Equatable {
    internal var update: [String: LiveMapUpdateAction]
    /// The source public object message (op-bearing only), or `nil` for sync-originated updates (RTO4b2a).
    internal var objectMessage: ObjectMessage?
    /// Whether this update tombstones the map (RTLO4b4e).
    internal var tombstone: Bool

    internal init(update: [String: LiveMapUpdateAction], objectMessage: ObjectMessage? = nil, tombstone: Bool = false) {
        self.update = update
        self.objectMessage = objectMessage
        self.tombstone = tombstone
    }
}
