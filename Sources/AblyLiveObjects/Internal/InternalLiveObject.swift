/// Provides RTLO spec point functionality common to all LiveObjects.
///
/// This exists in addition to ``LiveObjectMutableState`` to enable polymorphism.
internal protocol InternalLiveObject<Update> {
    associatedtype Update: Sendable

    var liveObjectMutableState: LiveObjectMutableState<Update> { get set }
}
