import Ably
internal import AblyPlugin

/// The class that provides the public API for interacting with LiveObjects, via the ``ARTRealtimeChannel/objects`` property.
internal class DefaultLiveObjects: Objects {
    private weak var channel: ARTRealtimeChannel?
    private let logger: AblyPlugin.Logger
    private let pluginAPI: AblyPlugin.PluginAPIProtocol

    internal init(channel: ARTRealtimeChannel, logger: AblyPlugin.Logger, pluginAPI: AblyPlugin.PluginAPIProtocol) {
        self.channel = channel
        self.logger = logger
        self.pluginAPI = pluginAPI
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

    internal func onChannelAttached(hasObjects _: Bool) {
        notYetImplemented()
    }

    internal func handleObjectProtocolMessage(objectMessages _: [ObjectMessage]) {
        notYetImplemented()
    }

    internal func handleObjectSyncProtocolMessage(objectMessages _: [ObjectMessage], protocolMessageChannelSerial _: String) {
        notYetImplemented()
    }
}
