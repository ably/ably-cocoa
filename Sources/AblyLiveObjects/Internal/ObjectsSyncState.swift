/// The type that the spec uses to represent the client's state of syncing its local Objects data with the server.
///
/// (TODO: This isn't actually in the spec yet, will specify in https://github.com/ably/ably-liveobjects-swift-plugin/issues/80; it's currently copied from https://github.com/ably/ably-js/blob/0c5baa9273ca87aec6ca594833d59c4c4d2dddbb/src/plugins/objects/objects.ts)
internal enum ObjectsSyncState {
    case initialized
    case syncing
    case synced

    internal var toEvent: ObjectsEvent? {
        switch self {
        case .initialized:
            nil
        case .syncing:
            .syncing
        case .synced:
            .synced
        }
    }
}
