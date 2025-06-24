import Ably
internal import AblyPlugin

/// The class that provides the public API for interacting with LiveObjects, via the ``ARTRealtimeChannel/objects`` property.
internal class DefaultObjects: Objects {
    private weak var channel: ARTRealtimeChannel?
    private let logger: AblyPlugin.Logger
    private let pluginAPI: AblyPlugin.PluginAPIProtocol

    // These drive the testsOnly_* properties that expose the received ProtocolMessages to the test suite.
    private let receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation
    private let receivedObjectSyncProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectSyncProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation

    internal init(channel: ARTRealtimeChannel, logger: AblyPlugin.Logger, pluginAPI: AblyPlugin.PluginAPIProtocol) {
        self.channel = channel
        self.logger = logger
        self.pluginAPI = pluginAPI
        (receivedObjectProtocolMessages, receivedObjectProtocolMessagesContinuation) = AsyncStream.makeStream()
        (receivedObjectSyncProtocolMessages, receivedObjectSyncProtocolMessagesContinuation) = AsyncStream.makeStream()
    }

    // MARK: `Objects` protocol

    internal func getRoot() async throws(ARTErrorInfo) -> any LiveMap {
        notYetImplemented()
    }

    internal func createMap(entries _: any LiveMap) async throws(ARTErrorInfo) -> any LiveMap {
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

    internal func batch(callback _: (any BatchContext) -> Void) async throws {
        notYetImplemented()
    }

    internal func on(event _: ObjectsEvent, callback _: () -> Void) -> any OnObjectsEventResponse {
        notYetImplemented()
    }

    internal func offAll() {
        notYetImplemented()
    }

    // MARK: Handling channel events

    internal private(set) var testsOnly_onChannelAttachedHasObjects: Bool?
    internal func onChannelAttached(hasObjects: Bool) {
        testsOnly_onChannelAttachedHasObjects = hasObjects
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

    internal func handleObjectSyncProtocolMessage(objectMessages: [InboundObjectMessage], protocolMessageChannelSerial _: String) {
        receivedObjectSyncProtocolMessagesContinuation.yield(objectMessages)
    }

    // MARK: - Sending `OBJECT` ProtocolMessage

    // This is currently exposed so that we can try calling it from the tests in the early days of the SDK to check that we can send an OBJECT ProtocolMessage. We'll probably make it private later on.
    internal func testsOnly_sendObject(objectMessages: [OutboundObjectMessage]) async throws(InternalError) {
        guard let channel else {
            return
        }

        try await DefaultInternalPlugin.sendObject(
            objectMessages: objectMessages,
            channel: channel,
            pluginAPI: pluginAPI,
        )
    }
}
