// @UTS objects/unit/object_id.md
//
// Port of the UTS ObjectId generation spec (RTO14). ObjectId format is
// `{type}:{base64url(SHA-256(initialValue:nonce))}@{timestamp}`.
//
// Deviations from the UTS spec:
// - (D1) The spec passes timestamps as epoch-millisecond integers (e.g. 1700000000000). The
//   Swift API takes a `Date`, so each is translated as `Date(timeIntervalSince1970: 1_700_000_000)`
//   (= 1_700_000_000 s == 1700000000000 ms). The generated objectId still embeds the
//   millisecond value `@1700000000000`.
// - (D2) The spec function is named `generateObjectId`; the Swift equivalent is
//   `ObjectCreationHelpers.testsOnly_createObjectID(type:initialValue:nonce:timestamp:)`.
// - (D3) The spec file contains five `##` cases. A sixth test (`different-initialValue`) is added
//   per the porting task, symmetric to `different-nonce`, asserting that a different initialValue
//   yields a different objectId. It has no distinct spec-case name.
//
// Note: the spec asserts objectId structure (prefix / timestamp / base64url charset) and
// determinism/uniqueness, not literal hash strings; assertions here mirror the spec faithfully.

@testable import AblyLiveObjects
import Foundation
import Testing

struct ObjectIdUTSTests {
    /// The spec's `1700000000000` epoch-millis, expressed as a `Date` (see deviation D1).
    private static let timestamp = Date(timeIntervalSince1970: 1_700_000_000)

    // @UTS objects/unit/RTO14/objectid-format-counter-0
    @Test
    func objectIdFormatCounter() {
        let objectId = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":42}}"#,
            nonce: "test-nonce-12345678",
            timestamp: Self.timestamp,
        )

        #expect(objectId.hasPrefix("counter:"))
        #expect(objectId.contains("@1700000000000"))

        let typePart = String(objectId.prefix { $0 != ":" })
        let rest = String(objectId.dropFirst(typePart.count + 1))
        let hashPart = String(rest.prefix { $0 != "@" })
        let tsPart = String(rest.dropFirst(hashPart.count + 1))

        #expect(typePart == "counter")
        #expect(tsPart == "1700000000000")
        // hashPart IS a valid base64url string: no standard-base64 / padding characters
        #expect(!hashPart.contains("+"))
        #expect(!hashPart.contains("/"))
        #expect(!hashPart.contains("="))
    }

    // @UTS objects/unit/RTO14/objectid-format-map-0
    @Test
    func objectIdFormatMap() {
        let objectId = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "map",
            initialValue: #"{"map":{"semantics":"LWW","entries":{}}}"#,
            nonce: "test-nonce-12345678",
            timestamp: Self.timestamp,
        )

        #expect(objectId.hasPrefix("map:"))
        #expect(objectId.contains("@1700000000000"))
    }

    // @UTS objects/unit/RTO14/deterministic-0
    @Test
    func deterministicForSameInputs() {
        let id1 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "same-nonce-1234567",
            timestamp: Self.timestamp,
        )
        let id2 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "same-nonce-1234567",
            timestamp: Self.timestamp,
        )

        #expect(id1 == id2)
    }

    // @UTS objects/unit/RTO14/different-nonce-0
    @Test
    func differentNonceProducesDifferentObjectId() {
        let id1 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "nonce-aaaaaaaaaaaaa",
            timestamp: Self.timestamp,
        )
        let id2 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "nonce-bbbbbbbbbbbbb",
            timestamp: Self.timestamp,
        )

        #expect(id1 != id2)
    }

    // @UTS objects/unit/RTO14b/base64url-encoding-0
    @Test
    func hashIsBase64urlEncoded() {
        let objectId = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "test-nonce-12345678",
            timestamp: Self.timestamp,
        )

        let rest = String(objectId.drop { $0 != ":" }.dropFirst())
        let hashPart = String(rest.prefix { $0 != "@" })

        #expect(!hashPart.contains("+"))
        #expect(!hashPart.contains("/"))
        #expect(!hashPart.hasSuffix("="))
    }

    // @UTS different-initialValue (added per porting task; see deviation D3)
    @Test
    func differentInitialValueProducesDifferentObjectId() {
        let id1 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":0}}"#,
            nonce: "same-nonce-1234567",
            timestamp: Self.timestamp,
        )
        let id2 = ObjectCreationHelpers.testsOnly_createObjectID(
            type: "counter",
            initialValue: #"{"counter":{"count":1}}"#,
            nonce: "same-nonce-1234567",
            timestamp: Self.timestamp,
        )

        #expect(id1 != id2)
    }
}
