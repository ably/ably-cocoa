import Foundation

/// An event emitted by the app, published to the events channel for external observation.
enum Event: Codable {
    /// A log message emitted by `mainAbly`'s custom log handler.
    case ablyLog(Log)

    /// PushKit provided a new VoIP device token.
    case voipTokenUpdated(VoIPToken)

    /// A VoIP push notification was received from PushKit.
    case voipPushReceived(VoIPPush)

    /// PushKit invalidated the VoIP device token.
    case voipTokenInvalidated

    /// A log message from the SDK.
    struct Log: Codable {
        /// The log level (e.g. "verbose", "debug", "info", "warn", "error").
        var level: String

        /// The log message text.
        var message: String
    }

    /// A VoIP device token update.
    struct VoIPToken: Codable {
        /// The hex-encoded device token for VoIP pushes.
        var token: String
    }

    /// A received VoIP push notification.
    struct VoIPPush: Codable {
        /// The push notification payload, serialised as a JSON string
        /// (since the raw `[AnyHashable: Any]` from PushKit is not `Codable`).
        var payloadJSON: String
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case ablyLog
        case voipTokenUpdated
        case voipPushReceived
        case voipTokenInvalidated
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .ablyLog(let log):
            try container.encode(log, forKey: .ablyLog)
        case .voipTokenUpdated(let token):
            try container.encode(token, forKey: .voipTokenUpdated)
        case .voipPushReceived(let push):
            try container.encode(push, forKey: .voipPushReceived)
        case .voipTokenInvalidated:
            try container.encodeNil(forKey: .voipTokenInvalidated)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let log = try container.decodeIfPresent(Log.self, forKey: .ablyLog) {
            self = .ablyLog(log)
        } else if let token = try container.decodeIfPresent(VoIPToken.self, forKey: .voipTokenUpdated) {
            self = .voipTokenUpdated(token)
        } else if let push = try container.decodeIfPresent(VoIPPush.self, forKey: .voipPushReceived) {
            self = .voipPushReceived(push)
        } else if container.contains(.voipTokenInvalidated) {
            self = .voipTokenInvalidated
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "No matching event case")
            )
        }
    }

    // MARK: - Ably message helpers

    /// The Ably message event name for this event.
    var name: String {
        switch self {
        case .ablyLog: "ablyLog"
        case .voipTokenUpdated: "voipTokenUpdated"
        case .voipPushReceived: "voipPushReceived"
        case .voipTokenInvalidated: "voipTokenInvalidated"
        }
    }

    /// Encodes this event as a JSON-compatible dictionary for use as Ably
    /// message data.
    func toAblyData() -> Any {
        let jsonData = try! JSONEncoder().encode(self)
        return try! JSONSerialization.jsonObject(with: jsonData)
    }
}
