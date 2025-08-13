internal import AblyPlugin

// We explicitly import the NSObject class, else it seems to get transitively imported from  `internal import AblyPlugin`, leading to the error "Class cannot be declared public because its superclass is internal".
import ObjectiveC.NSObject

/// The default implementation of `AblyPlugin`'s `LiveObjectsInternalPluginProtocol`. Implements the interface that ably-cocoa uses to access the functionality provided by the LiveObjects plugin.
@objc
internal final class DefaultInternalPlugin: NSObject, AblyPlugin.LiveObjectsInternalPluginProtocol {
    private let pluginAPI: AblyPlugin.PluginAPIProtocol

    internal init(pluginAPI: AblyPlugin.PluginAPIProtocol) {
        self.pluginAPI = pluginAPI
    }

    // MARK: - Channel `objects` property

    /// The `pluginDataValue(forKey:channel:)` key that we use to store the value of the `ARTRealtimeChannel.objects` property.
    private static let pluginDataKey = "LiveObjects"

    /// Retrieves the `RealtimeObjects` for this channel.
    ///
    /// We expect this value to have been previously set by ``prepare(_:)``.
    internal static func realtimeObjects(for channel: AblyPlugin.RealtimeChannel, pluginAPI: AblyPlugin.PluginAPIProtocol) -> InternalDefaultRealtimeObjects {
        guard let pluginData = pluginAPI.pluginDataValue(forKey: pluginDataKey, channel: channel) else {
            // InternalPlugin.prepare was not called
            fatalError("To access LiveObjects functionality, you must pass the LiveObjects plugin in the client options when creating the ARTRealtime instance: `clientOptions.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]`")
        }

        // swiftlint:disable:next force_cast
        return pluginData as! InternalDefaultRealtimeObjects
    }

    // MARK: - LiveObjectsInternalPluginProtocol

    // Populates the channel's `objects` property.
    internal func prepare(_ channel: AblyPlugin.RealtimeChannel, client: AblyPlugin.RealtimeClient) {
        let logger = pluginAPI.logger(for: channel)
        let callbackQueue = pluginAPI.callbackQueue(for: client)

        logger.log("LiveObjects.DefaultInternalPlugin received prepare(_:)", level: .debug)
        let liveObjects = InternalDefaultRealtimeObjects(logger: logger, userCallbackQueue: callbackQueue, clock: DefaultSimpleClock())
        pluginAPI.setPluginDataValue(liveObjects, forKey: Self.pluginDataKey, channel: channel)
    }

    /// Retrieves the internally-typed `objects` property for the channel.
    private func realtimeObjects(for channel: AblyPlugin.RealtimeChannel) -> InternalDefaultRealtimeObjects {
        Self.realtimeObjects(for: channel, pluginAPI: pluginAPI)
    }

    /// A class that wraps an object message.
    ///
    /// We need this intermediate type because we want object messages to be structs — because they're nicer to work with internally — but a struct can't conform to the class-bound `AblyPlugin.ObjectMessageProtocol`.
    private final class ObjectMessageBox<T>: AblyPlugin.ObjectMessageProtocol where T: Sendable {
        internal let objectMessage: T

        init(objectMessage: T) {
            self.objectMessage = objectMessage
        }
    }

    internal func decodeObjectMessage(
        _ serialized: [String: Any],
        context: DecodingContextProtocol,
        format: EncodingFormat,
        error errorPtr: AutoreleasingUnsafeMutablePointer<ARTErrorInfo?>?,
    ) -> (any ObjectMessageProtocol)? {
        let wireObject = WireValue.objectFromAblyPluginData(serialized)

        do {
            let wireObjectMessage = try InboundWireObjectMessage(
                wireObject: wireObject,
                decodingContext: context,
            )
            let objectMessage = try InboundObjectMessage(
                wireObjectMessage: wireObjectMessage,
                format: format,
            )
            return ObjectMessageBox(objectMessage: objectMessage)
        } catch {
            errorPtr?.pointee = error.toARTErrorInfo()
            return nil
        }
    }

    internal func encodeObjectMessage(
        _ publicObjectMessage: any AblyPlugin.ObjectMessageProtocol,
        format: EncodingFormat,
    ) -> [String: Any] {
        guard let outboundObjectMessageBox = publicObjectMessage as? ObjectMessageBox<OutboundObjectMessage> else {
            preconditionFailure("Expected to receive the same OutboundObjectMessage type as we emit")
        }

        let wireObjectMessage = outboundObjectMessageBox.objectMessage.toWire(format: format)
        return wireObjectMessage.toWireObject.toAblyPluginDataDictionary
    }

    internal func onChannelAttached(_ channel: AblyPlugin.RealtimeChannel, hasObjects: Bool) {
        realtimeObjects(for: channel).onChannelAttached(hasObjects: hasObjects)
    }

    internal func handleObjectProtocolMessage(withObjectMessages publicObjectMessages: [any AblyPlugin.ObjectMessageProtocol], channel: AblyPlugin.RealtimeChannel) {
        guard let inboundObjectMessageBoxes = publicObjectMessages as? [ObjectMessageBox<InboundObjectMessage>] else {
            preconditionFailure("Expected to receive the same InboundObjectMessage type as we emit")
        }

        let objectMessages = inboundObjectMessageBoxes.map(\.objectMessage)

        realtimeObjects(for: channel).handleObjectProtocolMessage(
            objectMessages: objectMessages,
        )
    }

    internal func handleObjectSyncProtocolMessage(withObjectMessages publicObjectMessages: [any AblyPlugin.ObjectMessageProtocol], protocolMessageChannelSerial: String?, channel: AblyPlugin.RealtimeChannel) {
        guard let inboundObjectMessageBoxes = publicObjectMessages as? [ObjectMessageBox<InboundObjectMessage>] else {
            preconditionFailure("Expected to receive the same InboundObjectMessage type as we emit")
        }

        let objectMessages = inboundObjectMessageBoxes.map(\.objectMessage)

        realtimeObjects(for: channel).handleObjectSyncProtocolMessage(
            objectMessages: objectMessages,
            protocolMessageChannelSerial: protocolMessageChannelSerial,
        )
    }

    // MARK: - Sending `OBJECT` ProtocolMessage

    internal static func sendObject(
        objectMessages: [OutboundObjectMessage],
        channel: AblyPlugin.RealtimeChannel,
        client: AblyPlugin.RealtimeClient,
        pluginAPI: PluginAPIProtocol,
    ) async throws(InternalError) {
        let objectMessageBoxes: [ObjectMessageBox<OutboundObjectMessage>] = objectMessages.map { .init(objectMessage: $0) }

        try await withCheckedContinuation { (continuation: CheckedContinuation<Result<Void, InternalError>, _>) in
            let internalQueue = pluginAPI.internalQueue(for: client)

            internalQueue.async {
                pluginAPI.sendObject(
                    withObjectMessages: objectMessageBoxes,
                    channel: channel,
                ) { error in
                    if let error {
                        continuation.resume(returning: .failure(error.toInternalError()))
                    } else {
                        continuation.resume(returning: .success(()))
                    }
                }
            }
        }.get()
    }
}
