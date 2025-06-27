import Ably
internal import AblyPlugin

/// The class that provides the public API for interacting with LiveObjects, via the ``ARTRealtimeChannel/objects`` property.
internal final class DefaultRealtimeObjects: RealtimeObjects {
    // Used for synchronizing access to all of this instance's mutable state. This is a temporary solution just to allow us to implement `Sendable`, and we'll revisit it in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3.
    private let mutex = NSLock()

    private let channel: WeakRef<ARTRealtimeChannel>
    private let logger: AblyPlugin.Logger
    private let pluginAPI: AblyPlugin.PluginAPIProtocol

    // These drive the testsOnly_* properties that expose the received ProtocolMessages to the test suite.
    private let receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation
    private let receivedObjectSyncProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectSyncProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation

    internal init(channel: ARTRealtimeChannel, logger: AblyPlugin.Logger, pluginAPI: AblyPlugin.PluginAPIProtocol) {
        self.channel = .init(referenced: channel)
        self.logger = logger
        self.pluginAPI = pluginAPI
        (receivedObjectProtocolMessages, receivedObjectProtocolMessagesContinuation) = AsyncStream.makeStream()
        (receivedObjectSyncProtocolMessages, receivedObjectSyncProtocolMessagesContinuation) = AsyncStream.makeStream()
    }

    // MARK: `RealtimeObjects` protocol

    internal func getRoot() async throws(ARTErrorInfo) -> any LiveMap {
        notYetImplemented()
    }

    internal func createMap(entries _: [String: LiveMapValue]) async throws(ARTErrorInfo) -> any LiveMap {
        notYetImplemented()
    }

    internal func createMap() async throws(ARTErrorInfo) -> any LiveMap {
        notYetImplemented()
    }

    internal func createCounter(count _: Int) async throws(ARTErrorInfo) -> any LiveCounter {
        notYetImplemented()
    }

    internal func createCounter() async throws(ARTErrorInfo) -> any LiveCounter {
        notYetImplemented()
    }

    internal func batch(callback _: sending (sending any BatchContext) -> Void) async throws {
        notYetImplemented()
    }

    internal func on(event _: ObjectsEvent, callback _: () -> Void) -> any OnObjectsEventResponse {
        notYetImplemented()
    }

    internal func offAll() {
        notYetImplemented()
    }

    // MARK: Handling channel events

    private nonisolated(unsafe) var onChannelAttachedHasObjects: Bool?
    internal var testsOnly_onChannelAttachedHasObjects: Bool? {
        mutex.withLock {
            onChannelAttachedHasObjects
        }
    }

    internal func onChannelAttached(hasObjects: Bool) {
        mutex.withLock {
            onChannelAttachedHasObjects = hasObjects
        }
    }

    internal var testsOnly_receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]> {
        receivedObjectProtocolMessages
    }

    internal func handleObjectProtocolMessage(objectMessages: [InboundObjectMessage]) {
        receivedObjectProtocolMessagesContinuation.yield(objectMessages)
    }

    internal var testsOnly_receivedObjectSyncProtocolMessages: AsyncStream<[InboundObjectMessage]> {
        receivedObjectSyncProtocolMessages
    }

    internal func handleObjectSyncProtocolMessage(objectMessages: [InboundObjectMessage], protocolMessageChannelSerial _: String?) {
        receivedObjectSyncProtocolMessagesContinuation.yield(objectMessages)
    }

    // MARK: - Sending `OBJECT` ProtocolMessage

    // This is currently exposed so that we can try calling it from the tests in the early days of the SDK to check that we can send an OBJECT ProtocolMessage. We'll probably make it private later on.
    internal func testsOnly_sendObject(objectMessages: [OutboundObjectMessage]) async throws(InternalError) {
        guard let channel = channel.referenced else {
            return
        }

        try await DefaultInternalPlugin.sendObject(
            objectMessages: objectMessages,
            channel: channel,
            pluginAPI: pluginAPI,
        )
    }
}
