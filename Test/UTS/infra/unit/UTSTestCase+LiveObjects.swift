import Ably
import Ably.Private
import Foundation
import Testing
@testable import AblyLiveObjects

/// LiveObjects additions to the UTS harness: the `setup_synced_channel` pattern from
/// `helpers/standard_test_pool.md`.
extension UTSTestCase {
    /// Builds a connected client and an objects channel, but does **not** call `get()` — for tests
    /// that drive `get()` themselves or exercise attach/sync timing. The simulated server responds to
    /// `ATTACH` with `ATTACHED` (`HAS_OBJECTS`) and, when `sync` is `true`, an `OBJECT_SYNC` carrying
    /// ``StandardTestPool/objects``; when `autoAck` is `true`, it auto-`ACK`s `OBJECT` publishes.
    ///
    /// > Note: the granted channel modes carried by `ATTACHED` aren't modelled (the mock always sends
    /// > the standard `HAS_OBJECTS` attach); mode-enforcement tests still request the appropriate
    /// > `modes` on the channel, and trap at the unimplemented API before the granted-mode check runs.
    func objectsChannel(
        _ channelName: String,
        modes: ARTChannelMode = [.objectSubscribe, .objectPublish],
        echoMessages: Bool = true,
        siteCode: String? = StandardTestPool.siteCode,
        gcGracePeriod: Double? = 86_400_000,
        sync: Bool = true,
        autoAck: Bool = true,
    ) -> (client: ARTRealtime, channel: ARTRealtimeChannel, ws: MockWebSocketProvider) {
        let connections = Captured<MockWebSocket>()
        let provider = MockWebSocketProvider(
            onConnectionAttempt: { conn in
                connections.append(conn)
                conn.respondWithSuccess()
                conn.sendToClient(.connected(
                    connectionId: "conn-1",
                    connectionKey: "conn-key-1",
                    siteCode: siteCode,
                    objectsGCGracePeriod: gcGracePeriod,
                ))
            },
            onMessageFromClient: { msg in
                guard let conn = connections.all.last else { return }
                switch msg.action {
                case .attach:
                    let channel = msg.channel ?? channelName
                    conn.sendToClient(.attached(channel: channel, channelSerial: "sync1:", hasObjects: true))
                    if sync {
                        conn.sendToClient(.objectSync(channel: channel, channelSerial: "sync1:", state: StandardTestPool.objects))
                    }
                case .object:
                    guard autoAck else { break }
                    // `state` isn't surfaced to Swift (see ProtocolMessage), so read it via KVC.
                    let stateCount = (msg.value(forKey: "state") as? [Any])?.count ?? 0
                    let msgSerial = msg.msgSerial?.intValue ?? 0
                    let serials: [String?] = (0 ..< stateCount).map { StandardTestPool.ackSerial(msgSerial, $0) }
                    conn.sendToClient(.ack(msgSerial: msgSerial, count: 1, serials: serials))
                default:
                    break
                }
            },
        )
        installMock(provider)

        let client = makeRealtime { options in
            options.key = "fake:key"
            options.echoMessages = echoMessages
            options.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]
        }

        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = modes
        let channel = client.channels.get(channelName, options: channelOptions)
        return (client: client, channel: channel, ws: provider)
    }

    /// Creates a connected client with a synced channel containing the standard test pool (UTS
    /// `setup_synced_channel`), resolving `root` via `channel.object.get()`.
    func setupSyncedChannel(_ channelName: String, autoAck: Bool = true, sourceLocation _: SourceLocation = #_sourceLocation) async throws -> (client: ARTRealtime, channel: ARTRealtimeChannel, root: any LiveMapPathObject, ws: MockWebSocketProvider) {
        let objects = objectsChannel(channelName, autoAck: autoAck)
        let root = try await objects.channel.object.get()
        return (client: objects.client, channel: objects.channel, root: root, ws: objects.ws)
    }

    /// The `operation` of every `OBJECT` message the client has sent, decoded into the internal wire
    /// type ``WireObjectOperation`` (UTS `captured.flatMap(c => c.state).map(op => op.operation)`).
    ///
    /// The captured frames are decoded into the *wire* representation rather than the
    /// `ProtocolTypes` domain type on purpose: the outbound-only `counterCreateWithObjectId` /
    /// `mapCreateWithObjectId` fields that the create tests assert on are retained by
    /// ``WireObjectOperation`` but nil'd out by the `ProtocolTypes.ObjectOperation` inbound
    /// conversion.
    func sentObjectOperations(_ ws: MockWebSocketProvider) throws -> [WireObjectOperation] {
        guard let connection = ws.activeConnection else { return [] }
        var operations: [WireObjectOperation] = []
        for frame in connection.sentFrames {
            guard let root = try? JSONSerialization.jsonObject(with: frame) as? [String: Any],
                  (root["action"] as? Int) == WireAction.object,
                  let state = root["state"] as? [[String: Any]] else { continue }
            for objectMessage in state {
                guard let operationData = objectMessage["operation"] as? [String: Any] else { continue }
                // Decode the operation directly into its wire type. We don't route through
                // `InboundWireObjectMessage`: these are messages the client *sent*, so the inbound
                // decoder (and its `DecodingContext`, which drives inbound synthetic-ID rules) would
                // be the wrong direction. `WireObjectOperation` is `WireObjectCodable`, and its wire
                // form is direction-agnostic and retains the outbound-only `*WithObjectId` fields.
                let wireOperation = WireValue.objectFromPluginSupportData(operationData)
                operations.append(try WireObjectOperation(wireObject: wireOperation))
            }
        }
        return operations
    }

    /// Delivers an `OBJECT` message carrying `state` to the client through the mock (UTS
    /// `mock_ws.send_to_client(build_object_message(channel, state))`). `state` is the decoded inbound
    /// object-message form produced by the ``StandardTestPool`` builders. The channel defaults to
    /// `"test"` (the name every UTS setup uses).
    func sendToClient(_ ws: MockWebSocketProvider, channel: String = "test", _ state: [ProtocolTypes.InboundObjectMessage]) {
        ws.activeConnection?.sendToClient(.object(channel: channel, state: state))
    }
}

/// Wire-level `ProtocolMessage.action` codes (`ARTProtocolMessageAction`).
enum WireAction {
    static let object = 19
    static let objectSync = 20
}

/// Wire-level map semantics code (`ObjectsMapSemantics`, spec OMP2). Used to assert on the
/// `initialValue` JSON string, which encodes semantics as its raw integer.
enum WireMapSemantics {
    static let lww = 0
}
