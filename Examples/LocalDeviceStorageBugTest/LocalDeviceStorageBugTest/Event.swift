import Foundation
import Ably

/// A unique identifier for this app installation, persisted across launches
/// but not across reinstallations. Stored in a file with no data protection.
let appInstallationID: String = {
    let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask).first!
        .appendingPathComponent("installation-id.txt")
    if let existing = try? String(contentsOf: fileURL, encoding: .utf8), !existing.isEmpty {
        return existing
    }
    let id = UUID().uuidString
    try! id.write(to: fileURL, atomically: true, encoding: .utf8)
    try! FileManager.default.setAttributes(
        [.protectionKey: FileProtectionType.none],
        ofItemAtPath: fileURL.path
    )
    return id
}()

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

/// A `Codable` representation of `ARTLocalDevice`.
struct CodableLocalDevice: Codable {
    /// The unique device ID.
    var id: String

    /// The client ID the device is connected to Ably with.
    var clientId: String?

    /// The platform (e.g. "ios").
    var platform: String

    /// The form factor (e.g. "phone", "tablet").
    var formFactor: String

    /// Key-value metadata for the device.
    var metadata: [String: String]

    /// The push registration details.
    var push: CodablePushDetails

    /// The device identity token details, if available.
    var identityTokenDetails: CodableIdentityTokenDetails?

    /// The device secret, if available.
    var secret: String?

    init(_ device: ARTLocalDevice) {
        self.id = device.id as String
        self.clientId = device.clientId
        self.platform = device.platform
        self.formFactor = device.formFactor
        self.metadata = device.metadata
        self.push = CodablePushDetails(device.push)
        self.identityTokenDetails = device.identityTokenDetails.map { CodableIdentityTokenDetails($0) }
        self.secret = device.secret as String?
    }
}

/// A `Codable` representation of `ARTDevicePushDetails`.
struct CodablePushDetails: Codable {
    /// The push transport and address.
    var recipient: [String: String]

    /// The current state of the push registration.
    var state: String?

    /// The most recent error when the state is Failing or Failed.
    var errorReason: CodableErrorInfo?

    init(_ details: ARTDevicePushDetails) {
        self.recipient = (details.recipient as NSDictionary as? [String: String]) ?? [:]
        self.state = details.state
        self.errorReason = details.errorReason.map { CodableErrorInfo($0) }
    }
}

/// A `Codable` representation of `ARTDeviceIdentityTokenDetails`.
struct CodableIdentityTokenDetails: Codable {
    /// The token string.
    var token: String

    /// When the token was issued.
    var issued: Date

    /// When the token expires.
    var expires: Date

    /// The capability JSON string.
    var capability: String

    /// The client ID assigned to the token, if any.
    var clientId: String?

    init(_ details: ARTDeviceIdentityTokenDetails) {
        self.token = details.token
        self.issued = details.issued
        self.expires = details.expires
        self.capability = details.capability
        self.clientId = details.clientId
    }
}

/// The reason an action was performed (e.g. push activation, channel subscription).
enum ActionReason: String, Codable {
    /// The user tapped a button in the UI.
    case userTappedButton

    /// The action was triggered automatically on app launch, based on settings.
    case appLaunch
}

/// An event emitted by the app, published to the events channel for external observation.
enum Event: Codable {
    /// The app has launched. Published before any other event.
    case appLaunched(AppLaunched)

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

    /// The availability of protected data changed after launch.
    case protectedDataAvailability(ProtectedDataAvailability)

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

        /// The state of the local device at the time the result was received.
        /// Useful for detecting whether device details (e.g. ID, secret) have
        /// changed as a result of the SDK being unable to load persisted data.
        var localDevice: CodableLocalDevice
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

    struct AppLaunched: Codable {
        /// Whether protected data was available at launch time.
        var protectedDataAvailable: Bool

        /// The file protection level of the UserDefaults plist, or an error
        /// string if it could not be read (e.g. the file does not yet exist on
        /// a fresh install before any defaults have been written). The plist
        /// path (`Library/Preferences/<bundle-id>.plist`) is an implementation
        /// detail of `NSUserDefaults` and not guaranteed by Apple. This is
        /// where the SDK persists device details via `ARTLocalDeviceStorage`.
        var userDefaultsFileProtection: String
    }

    struct ProtectedDataAvailability: Codable {
        /// Whether protected data is now available.
        var isAvailable: Bool
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case appInstallationID
        case appLaunchID
        case appLaunched
        case ablyLog
        case voipTokenUpdated
        case voipPushReceived
        case voipTokenInvalidated
        case pushActivateAttempt
        case pushActivateResult
        case pushSubscribeAttempt
        case pushSubscribeResult
        case protectedDataAvailability
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appInstallationID, forKey: .appInstallationID)
        try container.encode(appLaunchID, forKey: .appLaunchID)
        switch self {
        case .appLaunched(let launched):
            try container.encode(launched, forKey: .appLaunched)
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
        case .protectedDataAvailability(let availability):
            try container.encode(availability, forKey: .protectedDataAvailability)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let launched = try container.decodeIfPresent(AppLaunched.self, forKey: .appLaunched) {
            self = .appLaunched(launched)
        } else if let log = try container.decodeIfPresent(Log.self, forKey: .ablyLog) {
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
        } else if let availability = try container.decodeIfPresent(ProtectedDataAvailability.self, forKey: .protectedDataAvailability) {
            self = .protectedDataAvailability(availability)
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
        case .appLaunched: "appLaunched"
        case .ablyLog: "ablyLog"
        case .voipTokenUpdated: "voipTokenUpdated"
        case .voipPushReceived: "voipPushReceived"
        case .voipTokenInvalidated: "voipTokenInvalidated"
        case .pushActivateAttempt: "pushActivateAttempt"
        case .pushActivateResult: "pushActivateResult"
        case .pushSubscribeAttempt: "pushSubscribeAttempt"
        case .pushSubscribeResult: "pushSubscribeResult"
        case .protectedDataAvailability: "protectedDataAvailability"
        }
    }

    /// Encodes this event as a JSON-compatible dictionary for use as Ably
    /// message data.
    func toAblyData() -> Any {
        let jsonData = try! JSONEncoder().encode(self)
        return try! JSONSerialization.jsonObject(with: jsonData)
    }
}
