// Derived from the UTS spec `objects/unit/object_id.md`.
//
// Drives the internal RTO14 object-id generation directly via the sanctioned
// `ObjectCreationHelpers.testsOnly_createObjectID(type:initialValue:nonce:timestamp:)` wrapper —
// a pure function, no channel/pool/mocks. ObjectId format is
// `{type}:{base64url(SHA-256(initialValue:nonce))}@{timestamp}`. The spec passes epoch-ms integer
// timestamps; cocoa's wrapper takes a `Date`, so each spec `timestamp: 1700000000000` maps to
// `Date(timeIntervalSince1970: 1700000000000 / 1000)` and the emitted `@{timestamp}` is the ms form.

@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct ObjectIdTests {
    // The base64url alphabet (RFC 4648 s.5): A-Z, a-z, 0-9, '-', '_' — no '+', '/', or '=' padding.
    private static let base64URLCharacters = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

    // MARK: - RTO14 - ObjectId format for counter type

    // UTS: objects/unit/RTO14/objectid-format-counter-0
    @Test
    func objectIdFormatForCounterType() throws {
        // Test Steps
        // timestamp: 1700000000000 (spec epoch ms → Date)
        let objectId = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":42}}"#,
            nonce: "test-nonce-12345678",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        )

        // Assertions
        #expect(objectId.hasPrefix("counter:"))
        #expect(objectId.contains("@1700000000000"))
        let parts = objectId.split(separator: ":", maxSplits: 1)
        let typePart = String(parts[0])
        let rest = String(parts[1])
        let hashAndTs = rest.split(separator: "@", maxSplits: 1)
        let hashPart = String(hashAndTs[0])
        let tsPart = String(hashAndTs[1])
        #expect(typePart == "counter")
        #expect(tsPart == "1700000000000")
        // RTO14b2: hash_part IS valid base64url string (non-empty, only base64url alphabet)
        #expect(!hashPart.isEmpty)
        #expect(hashPart.allSatisfy { Self.base64URLCharacters.contains($0) })
        // RTO14b2: hash_part does NOT contain "+" or "/" or "="
        #expect(!hashPart.contains("+"))
        #expect(!hashPart.contains("/"))
        #expect(!hashPart.contains("="))
    }

    // MARK: - RTO14 - ObjectId format for map type

    // UTS: objects/unit/RTO14/objectid-format-map-0
    @Test
    func objectIdFormatForMapType() throws {
        // Test Steps
        let objectId = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "map",
            initialValue: #"{"map":{"semantics":"LWW","entries":{}}}"#,
            nonce: "test-nonce-12345678",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        )

        // Assertions
        #expect(objectId.hasPrefix("map:"))
        #expect(objectId.contains("@1700000000000"))
    }

    // MARK: - RTO14 - Deterministic output for same inputs

    // UTS: objects/unit/RTO14/deterministic-0
    @Test
    func deterministicOutputForSameInputs() throws {
        // Test Steps
        let id1 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "same-nonce-1234567",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        )
        let id2 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "same-nonce-1234567",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        )

        // Assertions
        #expect(id1 == id2)
    }

    // MARK: - RTO14 - Different nonce produces different objectId

    // UTS: objects/unit/RTO14/different-nonce-0
    @Test
    func differentNonceProducesDifferentObjectId() throws {
        // Test Steps
        let id1 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "nonce-aaaaaaaaaaaaa",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        )
        let id2 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "nonce-bbbbbbbbbbbbb",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        )

        // Assertions
        #expect(id1 != id2)
    }

    // MARK: - RTO14b - SHA-256 hash is base64url encoded (not standard base64)

    // UTS: objects/unit/RTO14b/base64url-encoding-0
    @Test
    func sha256HashIsBase64URLEncodedNotStandardBase64() throws {
        // Test Steps
        let objectId = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "test-nonce-12345678",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        )
        let hashPart = String(objectId.split(separator: ":", maxSplits: 1)[1].split(separator: "@", maxSplits: 1)[0])

        // Assertions
        // RTO14b2: Must use URL-safe Base64 per RFC 4648 s.5, not standard Base64
        #expect(!hashPart.contains("+"))
        #expect(!hashPart.contains("/"))
        #expect(!hashPart.hasSuffix("="))
    }
}
