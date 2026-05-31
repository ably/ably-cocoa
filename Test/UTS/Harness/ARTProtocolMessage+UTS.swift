import Foundation
import Ably
import Ably.Private

/// Factory helpers for building `ARTProtocolMessage`s in UTS tests
extension ARTProtocolMessage {

    /// A `CONNECTED` message carrying connection details (UTS `ProtocolMessage(action: CONNECTED, ...)`).
    static func connected(connectionId: String,
                          connectionKey: String,
                          maxIdleInterval: TimeInterval = 15,
                          connectionStateTtl: TimeInterval = 120) -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
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
            objectsGCGracePeriod: nil,
            siteCode: nil
        )
        return message
    }

    /// An `ATTACHED` message for a channel (UTS `ProtocolMessage(action: ATTACHED, ...)`).
    static func attached(channel: String, channelSerial: String) -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
        message.action = .attached
        message.channel = channel
        message.channelSerial = channelSerial
        return message
    }

    /// An `ERROR` message (UTS `ProtocolMessage(action: ERROR, error: ErrorInfo(...))`).
    static func error(code: Int, statusCode: Int, message text: String) -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
        message.action = .error
        message.error = ARTErrorInfo.create(withCode: code, status: statusCode, message: text)
        return message
    }

    /// An `ACK` message (UTS `ProtocolMessage(action: ACK, msgSerial: ..., count: ...)`).
    static func ack(msgSerial: Int, count: Int) -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
        message.action = .ack
        message.msgSerial = NSNumber(value: msgSerial)
        message.count = Int32(count)
        return message
    }

    /// A `CLOSED` message (UTS `ProtocolMessage(action: CLOSED)`).
    static func closed() -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
        message.action = .closed
        return message
    }
}
