import Foundation

// swift-migration: original location ARTTokenRequest.h, line 12
/**
 * Contains the properties of a request for a token to Ably. Tokens are generated using `-[ARTAuthProtocol requestToken:]`.
 */
public class ARTTokenRequest: NSObject {

    // swift-migration: original location ARTTokenRequest.h, line 17
    /**
     * The name of the key against which this request is made. The key name is public, whereas the key secret is private.
     */
    public let keyName: String

    // swift-migration: original location ARTTokenRequest.h, line 22
    /**
     * The client ID to associate with the requested Ably Token. When provided, the Ably Token may only be used to perform operations on behalf of that client ID.
     */
    public var clientId: String?

    // swift-migration: original location ARTTokenRequest.h, line 27
    /**
     * A cryptographically secure random string of at least 16 characters, used to ensure the `ARTTokenRequest` cannot be reused.
     */
    public let nonce: String

    // swift-migration: original location ARTTokenRequest.h, line 32
    /**
     * The Message Authentication Code for this request.
     */
    public let mac: String

    // swift-migration: original location ARTTokenRequest.h, line 37
    /**
     * Capability of the requested Ably Token. If the Ably `ARTTokenRequest` is successful, the capability of the returned Ably Token will be the intersection of this capability with the capability of the issuing key. The capabilities value is a JSON-encoded representation of the resource paths and associated operations. Read more about capabilities in the [capabilities docs](https://ably.com/docs/realtime/authentication).
     */
    public var capability: String?

    // swift-migration: original location ARTTokenRequest.h, line 42
    /**
     * Requested time to live for the Ably Token in milliseconds. If the Ably `ARTTokenRequest` is successful, the TTL of the returned Ably Token is less than or equal to this value, depending on application settings and the attributes of the issuing key. The default is 60 minutes.
     */
    public var ttl: NSNumber?

    // swift-migration: original location ARTTokenRequest.h, line 47
    /**
     * The timestamp of this request as `NSDate` object.
     */
    public var timestamp: Date?

    // swift-migration: original location ARTTokenRequest.h, line 50
    /// :nodoc:
    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable")
    }

    // swift-migration: original location ARTTokenRequest.h, line 53 and ARTTokenRequest.m, line 9
    /// :nodoc:
    public init(tokenParams: ARTTokenParams, keyName: String, nonce: String, mac: String) {
        self.keyName = keyName
        self.nonce = nonce
        self.mac = mac
        self.ttl = tokenParams.ttl
        self.capability = tokenParams.capability
        self.clientId = tokenParams.clientId
        self.timestamp = tokenParams.timestamp
        super.init()
    }

    // swift-migration: original location ARTTokenRequest.m, line 22
    func asDictionary() -> [String: Any]? {
        return nil
    }

    // swift-migration: original location ARTTokenRequest.m, line 26
    public override var description: String {
        return "ARTTokenRequest: keyName=\(keyName) clientId=\(clientId ?? "nil") nonce=\(nonce) mac=\(mac) ttl=\(ttl?.description ?? "nil") capability=\(capability ?? "nil") timestamp=\(timestamp?.description ?? "nil")"
    }

    // swift-migration: original location ARTTokenRequest.h, line 63 and ARTTokenRequest.m, line 31
    /**
     * A static factory method to create an `ARTTokenRequest` object from a deserialized `TokenRequest`-like object or a JSON stringified `ARTTokenRequest` object. This method is provided to minimize bugs as a result of differing types by platform for fields such as `timestamp` or `ttl`. For example, in Ruby `ttl` in the `TokenRequest` object is exposed in seconds as that is idiomatic for the language, yet when serialized to JSON using `to_json` it is automatically converted to the Ably standard which is milliseconds. By using the `fromJson` method when constructing a `TokenRequest` object, Ably ensures that all fields are consistently serialized and deserialized across platforms.
     *
     * @param json A deserialized `TokenRequest`-like object or a JSON stringified `TokenRequest` object to create an `ARTTokenRequest`.
     * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
     *
     * @return An Ably token request object.
     */
    public static func fromJson(_ json: ARTJsonCompatible) throws -> ARTTokenRequest? {
        let dict = try json.toJSON()
        guard let dict = dict else {
            return nil
        }

        let tokenParams = ARTTokenParams(clientId: dict.artString("clientId"))

        let tokenRequest = ARTTokenRequest(
            tokenParams: tokenParams,
            keyName: dict.artString("keyName") ?? "",
            nonce: dict.artString("nonce") ?? "",
            mac: dict.artString("mac") ?? ""
        )

        tokenRequest.clientId = dict.artString("clientId")
        tokenRequest.capability = dict.artString("capability")
        
        if let timestampNumber = dict.artNumber("timestamp") {
            tokenRequest.timestamp = Date(timeIntervalSince1970: timestampNumber.doubleValue / 1000)
        }

        if let ttlNumber = dict.artNumber("ttl") {
            tokenRequest.ttl = NSNumber(value: millisecondsToTimeInterval(ttlNumber.uint64Value))
        }

        return tokenRequest
    }

}

// swift-migration: original location ARTTokenRequest.h, line 67 and ARTTokenRequest.m, line 59
extension ARTTokenRequest: ARTTokenDetailsCompatible {

    // swift-migration: original location ARTTokenRequest.m, line 61
    public func toTokenDetails(_ auth: ARTAuth, callback: @escaping ARTTokenDetailsCallback) {
        auth.internalAsync { authInternal in
            authInternal.executeTokenRequest(self, callback: callback)
        }
    }

}