import Ably

public extension ARTRealtimeChannel {
    /// The ``RealtimeObject`` for this channel — the entry point into the LiveObjects API.
    ///
    /// From here, ``RealtimeObject/get()`` returns a ``LiveMapPathObject`` rooted at the channel's
    /// root map, from which the rest of the object graph is navigated.
    ///
    /// > Note: It is a programmer error to access this property without first providing the
    /// > `LiveObjects` plugin in the client options.
    ///
    /// Spec: `RTL27`.
    var object: any RealtimeObject {
        DefaultRealtimeObject.shared
    }
}
