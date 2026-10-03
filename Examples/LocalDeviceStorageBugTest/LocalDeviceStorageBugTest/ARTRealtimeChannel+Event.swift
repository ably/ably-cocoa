import Ably

extension ARTRealtimeChannel {
    /// Publishes an ``Event`` to this channel, using the event's ``Event/name``
    /// as the Ably message name and its JSON-encoded representation as the data.
    func publish(_ event: Event) {
        publish(event.name, data: event.toAblyData())
    }
}
