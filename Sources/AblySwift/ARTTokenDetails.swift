import Foundation

// swift-migration: original location ARTTokenDetails.h, line 11
/**
 * Contains an Ably Token and its associated metadata.
 */
public class ARTTokenDetails: NSObject, NSCopying {

    // swift-migration: original location ARTTokenDetails.h, line 16
    /**
     * The [Ably Token](https://ably.com/docs/core-features/authentication#ably-tokens) itself. A typical Ably Token string appears with the form `xVLyHw.A-pwh7wicf3afTfgiw4k2Ku33kcnSA7z6y8FjuYpe3QaNRTEo4`.
     */
    public let token: String

    // swift-migration: original location ARTTokenDetails.h, line 21
    /**
     * The timestamp at which this token expires as a `NSDate` object.
     */
    public let expires: Date?

    // swift-migration: original location ARTTokenDetails.h, line 26
    /**
     * The timestamp at which this token was issued as a `NSDate` object.
     */
    public let issued: Date?

    // swift-migration: original location ARTTokenDetails.h, line 31
    /**
     * The capabilities associated with this Ably Token. The capabilities value is a JSON-encoded representation of the resource paths and associated operations. Read more about capabilities in the [capabilities docs](https://ably.com/docs/core-features/authentication/#capabilities-explained).
     */
    public let capability: String?

    // swift-migration: original location ARTTokenDetails.h, line 36
    /**
     * The client ID, if any, bound to this Ably Token. If a client ID is included, then the Ably Token authenticates its bearer as that client ID, and the Ably Token may only be used to perform operations on behalf of that client ID. The client is then considered to be an [identified client](https://ably.com/docs/core-features/authentication#identified-clients).
     */
    public let clientId: String?

    // swift-migration: original location ARTTokenDetails.h, line 39
    /// :nodoc:
    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable")
    }

    // swift-migration: original location ARTTokenDetails.h, line 42 and ARTTokenDetails.m, line 16
    /// :nodoc:
    public init(token: String) {
        self.token = token
        self.expires = nil
        self.issued = nil
        self.capability = nil
        self.clientId = nil
        super.init()
    }

    // swift-migration: original location ARTTokenDetails.h, line 45 and ARTTokenDetails.m, line 5
    /// :nodoc:
    public init(token: String, expires: Date?, issued: Date?, capability: String?, clientId: String?) {
        self.token = token
        self.expires = expires
        self.issued = issued
        self.capability = capability
        self.clientId = clientId
        super.init()
    }

    // swift-migration: original location ARTTokenDetails.m, line 23
    public override var description: String {
        return "ARTTokenDetails: token=\(token) clientId=\(clientId ?? "nil") issued=\(issued?.description ?? "nil") expires=\(expires?.description ?? "nil")"
    }

    // swift-migration: original location ARTTokenDetails.m, line 28
    public func copy(with zone: NSZone?) -> Any {
        return ARTTokenDetails(
            token: self.token,
            expires: self.expires,
            issued: self.issued,
            capability: self.capability,
            clientId: self.clientId
        )
    }

    // swift-migration: original location ARTTokenDetails.h, line 55 and ARTTokenDetails.m, line 38
    /**
     * A static factory method to create an `ARTTokenDetails` object from a deserialized `TokenDetails`-like object or a JSON stringified `TokenDetails` object. This method is provided to minimize bugs as a result of differing types by platform for fields such as `timestamp` or `ttl`. For example, in Ruby `ttl` in the `TokenDetails` object is exposed in seconds as that is idiomatic for the language, yet when serialized to JSON using `to_json` it is automatically converted to the Ably standard which is milliseconds. By using the `fromJson` method when constructing an `TokenDetails` object, Ably ensures that all fields are consistently serialized and deserialized across platforms.
     *
     * @param json A deserialized `TokenDetails`-like object or a JSON stringified `TokenDetails` object.
     * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
     *
     * @return An Ably authentication token.
     */
    public static func fromJson(_ json: ARTJsonCompatible) throws -> ARTTokenDetails? {
        let dict = try json.toJSON()
        guard let dict = dict else {
            return nil
        }

        var expires: Date?
        if let expiresInterval = dict["expires"] as? NSNumber {
            expires = Date(timeIntervalSince1970: expiresInterval.doubleValue / 1000)
        }

        var issued: Date?
        if let issuedInterval = dict["issued"] as? NSNumber {
            issued = Date(timeIntervalSince1970: issuedInterval.doubleValue / 1000)
        }

        return ARTTokenDetails(
            token: dict["token"] as? String ?? "",
            expires: expires,
            issued: issued,
            capability: dict["capability"] as? String,
            clientId: dict["clientId"] as? String
        )
    }

}

// swift-migration: original location ARTTokenDetails.h, line 59 and ARTTokenDetails.m, line 64
extension ARTTokenDetails: ARTTokenDetailsCompatible {

    // swift-migration: original location ARTTokenDetails.m, line 66
    public func toTokenDetails(_ auth: ARTAuth, callback: @escaping ARTTokenDetailsCallback) {
        callback(self, nil)
    }

}