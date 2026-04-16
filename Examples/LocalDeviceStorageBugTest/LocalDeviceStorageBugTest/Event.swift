import Foundation
import Ably

/// A unique identifier for this app launch, included in every event payload.
let appLaunchID = UUID().uuidString

/// A `Codable` representation of `ARTErrorInfo`.
final class CodableErrorInfo: Codable {
    /// The Ably error code.
    var code: Int

    /// HTTP status code corresponding to this error, where applicable.
    var statusCode: Int

    /// Additional message information.
    var message: String

    /// The reason why the error occurred, where available.
    var reason: String?

    /// A URL for additional help on the error code, where available.
    var href: String?

    /// The request ID, if the failing request had one.
    var requestId: String?

    /// Information pertaining to what caused the error, where available.
    var cause: CodableErrorInfo?

    init(_ errorInfo: ARTErrorInfo) {
        self.code = errorInfo.code
        self.statusCode = Int(errorInfo.statusCode)
        self.message = errorInfo.message
        self.reason = errorInfo.reason
        self.href = errorInfo.href
        self.requestId = errorInfo.requestId
        self.cause = errorInfo.cause.map { CodableErrorInfo($0) }
    }

    private enum CodingKeys: String, CodingKey {
        case code, statusCode, message, reason, href, requestId, cause
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encodeIfPresent(href, forKey: .href)
        try container.encodeIfPresent(requestId, forKey: .requestId)
        try container.encodeIfPresent(cause, forKey: .cause)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        message = try container.decode(String.self, forKey: .message)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        href = try container.decodeIfPresent(String.self, forKey: .href)
        requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
        cause = try container.decodeIfPresent(CodableErrorInfo.self, forKey: .cause)
    }
}

/// The reason an action was performed (e.g. push activation, channel subscription).
enum ActionReason: String, Codable {
    /// The user tapped a button in the UI.
    case userTappedButton
}

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

    /// A call to `push.activate()` was initiated.
    case pushActivateAttempt(PushActivateAttempt)

    /// A call to `push.activate()` completed.
    case pushActivateResult(PushActivateResult)

    /// A call to `push.subscribeDevice` was initiated.
    case pushSubscribeAttempt(PushSubscribeAttempt)

    /// A call to `push.subscribeDevice` completed.
    case pushSubscribeResult(PushSubscribeResult)

    // MARK: - Payload types

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

    struct PushActivateAttempt: Codable {
        /// Unique identifier for this attempt.
        var id: String

        /// Why the activation was performed.
        var reason: ActionReason
    }

    struct PushActivateResult: Codable {
        /// The identifier of the attempt this result corresponds to.
        var attemptID: String

        /// The error, or `nil` on success.
        var error: CodableErrorInfo?
    }

    struct PushSubscribeAttempt: Codable {
        /// Unique identifier for this attempt.
        var id: String

        /// Why the subscription was performed.
        var reason: ActionReason

        /// The channel being subscribed to.
        var channelName: String
    }

    struct PushSubscribeResult: Codable {
        /// The identifier of the attempt this result corresponds to.
        var attemptID: String

        /// The channel that was subscribed to.
        var channelName: String

        /// The error, or `nil` on success.
        var error: CodableErrorInfo?
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case appLaunchID
        case ablyLog
        case voipTokenUpdated
        case voipPushReceived
        case voipTokenInvalidated
        case pushActivateAttempt
        case pushActivateResult
        case pushSubscribeAttempt
        case pushSubscribeResult
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appLaunchID, forKey: .appLaunchID)
        switch self {
        case .ablyLog(let log):
            try container.encode(log, forKey: .ablyLog)
        case .voipTokenUpdated(let token):
            try container.encode(token, forKey: .voipTokenUpdated)
        case .voipPushReceived(let push):
            try container.encode(push, forKey: .voipPushReceived)
        case .voipTokenInvalidated:
            try container.encodeNil(forKey: .voipTokenInvalidated)
        case .pushActivateAttempt(let attempt):
            try container.encode(attempt, forKey: .pushActivateAttempt)
        case .pushActivateResult(let result):
            try container.encode(result, forKey: .pushActivateResult)
        case .pushSubscribeAttempt(let attempt):
            try container.encode(attempt, forKey: .pushSubscribeAttempt)
        case .pushSubscribeResult(let result):
            try container.encode(result, forKey: .pushSubscribeResult)
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
        } else if let attempt = try container.decodeIfPresent(PushActivateAttempt.self, forKey: .pushActivateAttempt) {
            self = .pushActivateAttempt(attempt)
        } else if let result = try container.decodeIfPresent(PushActivateResult.self, forKey: .pushActivateResult) {
            self = .pushActivateResult(result)
        } else if let attempt = try container.decodeIfPresent(PushSubscribeAttempt.self, forKey: .pushSubscribeAttempt) {
            self = .pushSubscribeAttempt(attempt)
        } else if let result = try container.decodeIfPresent(PushSubscribeResult.self, forKey: .pushSubscribeResult) {
            self = .pushSubscribeResult(result)
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
        case .pushActivateAttempt: "pushActivateAttempt"
        case .pushActivateResult: "pushActivateResult"
        case .pushSubscribeAttempt: "pushSubscribeAttempt"
        case .pushSubscribeResult: "pushSubscribeResult"
        }
    }

    /// Encodes this event as a JSON-compatible dictionary for use as Ably
    /// message data.
    func toAblyData() -> Any {
        let jsonData = try! JSONEncoder().encode(self)
        return try! JSONSerialization.jsonObject(with: jsonData)
    }
}
