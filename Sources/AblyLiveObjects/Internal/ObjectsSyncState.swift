/// The type that the spec uses to represent the client's state of syncing its local Objects data with the server.
///
/// (TODO: This isn't actually in the spec yet, will specify in https://github.com/ably/ably-liveobjects-swift-plugin/issues/80; it's currently copied from https://github.com/ably/ably-js/blob/e280bff11a4a7627362c5185e764b7ebd0490570/src/plugins/objects/objects.ts)
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
