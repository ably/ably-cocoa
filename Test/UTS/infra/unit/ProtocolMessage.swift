import Foundation
import Ably
import Ably.Private
import _AblyPluginSupportPrivate
@testable import AblyLiveObjects

/// A `Sendable` description of a server-to-client protocol message that a test injects via
/// `MockWebSocket.sendToClient(_:)` / `sendToClientAndClose(_:)`.
///
/// The LiveObjects `OBJECT` / `OBJECT_SYNC` variants carry decoded ``ProtocolTypes/InboundObjectMessage``
/// values (which are `Sendable`); the concrete `ARTProtocolMessage.state` — an array of the plugin's
/// `ObjectMessageBox` boxes — is built at delivery time in `makeProtocolMessage()`, so no
/// non-`Sendable` value crosses the queue hop. This mirrors what ably-cocoa's wire decoder produces
/// (the `state` property holds already-decoded `APObjectMessageProtocol` boxes), so the mock can
/// bypass wire encoding entirely.
struct ProtocolMessage: Sendable {

    private enum Kind: Sendable {
        case connected(connectionId: String, connectionKey: String, maxIdleInterval: TimeInterval, connectionStateTtl: TimeInterval, siteCode: String?, objectsGCGracePeriod: Double?)
        case attached(channel: String, channelSerial: String, hasObjects: Bool)
        case error(code: Int, statusCode: Int, message: String)
        case ack(msgSerial: Int, count: Int, serials: [String?]?)
        case closed
        case detached(channel: String)
        case channelError(channel: String, code: Int, statusCode: Int, message: String)
        case objectSync(channel: String, channelSerial: String?, state: [ProtocolTypes.InboundObjectMessage])
        case object(channel: String, state: [ProtocolTypes.InboundObjectMessage])
    }

    private let kind: Kind

    /// A ready-to-use default `CONNECTED` message (ably-java's `CONNECTED_MESSAGE`) so most tests
    /// don't hand-build one: connectionId `test-connection-id`, key `test-connection-key`,
    /// TTL 120 s, max-idle 15 s. A value type, so it is always a fresh instance.
    static var connectedMessage: ProtocolMessage {
        .connected(connectionId: "test-connection-id", connectionKey: "test-connection-key")
    }

    /// A `CONNECTED` message carrying connection details (UTS `ProtocolMessage(action: CONNECTED, ...)`).
    static func connected(connectionId: String,
                          connectionKey: String,
                          maxIdleInterval: TimeInterval = 15,
                          connectionStateTtl: TimeInterval = 120,
                          siteCode: String? = nil,
                          objectsGCGracePeriod: Double? = nil) -> ProtocolMessage {
        .init(kind: .connected(connectionId: connectionId, connectionKey: connectionKey, maxIdleInterval: maxIdleInterval, connectionStateTtl: connectionStateTtl, siteCode: siteCode, objectsGCGracePeriod: objectsGCGracePeriod))
    }

    /// An `ATTACHED` message for a channel (UTS `ProtocolMessage(action: ATTACHED, ...)`). Set
    /// `hasObjects` to raise the `HAS_OBJECTS` flag (RTO4).
    static func attached(channel: String, channelSerial: String, hasObjects: Bool = false) -> ProtocolMessage {
        .init(kind: .attached(channel: channel, channelSerial: channelSerial, hasObjects: hasObjects))
    }

    /// An `ERROR` message (UTS `ProtocolMessage(action: ERROR, error: ErrorInfo(...))`).
    static func error(code: Int, statusCode: Int, message: String) -> ProtocolMessage {
        .init(kind: .error(code: code, statusCode: statusCode, message: message))
    }

    /// An `ACK` message (UTS `ProtocolMessage(action: ACK, msgSerial: ..., count: ...)`). Pass
    /// `serials` to populate the `res` array (UTS `build_ack_message`, one `res` entry carrying all
    /// the object serials).
    static func ack(msgSerial: Int, count: Int, serials: [String?]? = nil) -> ProtocolMessage {
        .init(kind: .ack(msgSerial: msgSerial, count: count, serials: serials))
    }

    /// A `CLOSED` message (UTS `ProtocolMessage(action: CLOSED)`).
    static func closed() -> ProtocolMessage {
        .init(kind: .closed)
    }

    /// A channel `DETACHED` message (UTS `ProtocolMessage(action: DETACHED, channel: ...)`).
    static func detached(channel: String) -> ProtocolMessage {
        .init(kind: .detached(channel: channel))
    }

    /// A channel-level `ERROR` message that transitions the channel to `FAILED`
    /// (UTS `ProtocolMessage(action: ERROR, channel: ..., error: ...)`).
    static func channelError(channel: String, code: Int, statusCode: Int, message: String) -> ProtocolMessage {
        .init(kind: .channelError(channel: channel, code: code, statusCode: statusCode, message: message))
    }

    /// An `OBJECT_SYNC` message carrying object state (UTS `build_object_sync_message`).
    static func objectSync(channel: String, channelSerial: String?, state: [ProtocolTypes.InboundObjectMessage]) -> ProtocolMessage {
        .init(kind: .objectSync(channel: channel, channelSerial: channelSerial, state: state))
    }

    /// An `OBJECT` message carrying object operations (UTS `build_object_message`).
    static func object(channel: String, state: [ProtocolTypes.InboundObjectMessage]) -> ProtocolMessage {
        .init(kind: .object(channel: channel, state: state))
    }

    /// Builds the concrete `ARTProtocolMessage`. Call on the delegate queue, at delivery time.
    func makeProtocolMessage() -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
        switch kind {
        case let .connected(connectionId, connectionKey, maxIdleInterval, connectionStateTtl, siteCode, objectsGCGracePeriod):
            message.action = .connected
            message.connectionId = connectionId
            message.connectionKey = connectionKey
            message.connectionDetails = ARTConnectionDetails(
                clientId: nil,
                connectionKey: connectionKey,
                maxMessageSize: 0,
                maxFrameSize: 0,
                maxInboundRate: 0,
                connectionStateTtl: connectionStateTtl,
                serverId: "",
                maxIdleInterval: maxIdleInterval,
                objectsGCGracePeriod: objectsGCGracePeriod.map { NSNumber(value: $0) },
                siteCode: siteCode
            )
        case let .attached(channel, channelSerial, hasObjects):
            message.action = .attached
            message.channel = channel
            message.channelSerial = channelSerial
            if hasObjects {
                // ARTProtocolMessageFlagHasObjects = 1 << 7
                message.flags |= (1 << 7)
            }
        case let .error(code, statusCode, text):
            message.action = .error
            message.error = ARTErrorInfo.create(withCode: code, status: statusCode, message: text)
        case let .ack(msgSerial, count, serials):
            message.action = .ack
            message.msgSerial = NSNumber(value: msgSerial)
            message.count = Int32(count)
            if let serials {
                message.res = [ARTPublishResult(serials: serials.map { ARTPublishResultSerial(value: $0) })]
            }
        case .closed:
            message.action = .closed
        case let .detached(channel):
            message.action = .detached
            message.channel = channel
        case let .channelError(channel, code, statusCode, text):
            message.action = .error
            message.channel = channel
            message.error = ARTErrorInfo.create(withCode: code, status: statusCode, message: text)
        case let .objectSync(channel, channelSerial, state):
            message.action = .objectSync
            message.channel = channel
            message.channelSerial = channelSerial
            message.setState(state)
        case let .object(channel, state):
            message.action = .object
            message.channel = channel
            message.setState(state)
        }
        return message
    }
}

private extension ARTProtocolMessage {
    /// Sets the object `state` on the protocol message.
    ///
    /// `ARTProtocolMessage.state` is gated behind `#ifdef ABLY_SUPPORTS_PLUGINS` in ably-cocoa, a
    /// define set only for ably-cocoa's own target — so the property is absent from the `Ably` Swift
    /// interface for consumers. (Defining the macro for our import isn't viable: it unlocks other
    /// gated headers, e.g. `ARTPluginAPI.h` → `ARTTypes.h`, that aren't on a consumer's header search
    /// path, breaking the `Ably` module build.) The property exists in the compiled runtime, so we
    /// set it via KVC. The boxes are the same `ObjectMessageProtocol` type the plugin emits and
    /// receives, so ably-cocoa passes them straight back to the plugin's `handleObjectSync…` hook —
    /// mirroring what the wire decoder would have produced, without needing wire encoding.
    func setState(_ objectMessages: [ProtocolTypes.InboundObjectMessage]) {
        let boxes = objectMessages.map { DefaultInternalPlugin.ObjectMessageBox(objectMessage: $0) }
        setValue(boxes, forKey: "state")
    }
}
