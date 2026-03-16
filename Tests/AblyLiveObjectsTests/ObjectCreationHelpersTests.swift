@testable import AblyLiveObjects
import Foundation
import Testing

struct ObjectCreationHelpersTests {
    struct CreationOperationTests {
        // @spec RTO11f14c
        // @spec RTO11f14c1a
        // @spec RTO11f14c1b
        // @spec RTO11f14c1c
        // @spec RTO11f14c1d
        // @spec RTO11f14c1e
        // @spec RTO11f14c1f
        // @spec RTO11f14c2
        // @spec RTO11f9
        // @spec RTO11f16
        // @spec RTO11f17
        // @spec RTO11f15
        @available(iOS 16.0.0, tvOS 16.0.0, *) // because of using Regex
        @Test
        func map() throws {
            // Given
            let timestamp = Date(timeIntervalSince1970: 1_754_042_434)
            let logger = TestLogger()
            let clock = MockSimpleClock()
            let internalQueue = TestFactories.createInternalQueue()
            let referencedMap = InternalDefaultLiveMap.createZeroValued(objectID: "referencedMapID", logger: logger, internalQueue: internalQueue, userCallbackQueue: .main, clock: clock)
            let referencedCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "referencedCounterID", logger: logger, internalQueue: internalQueue, userCallbackQueue: .main, clock: clock)

            // When
            let creationOperation = internalQueue.ably_syncNoDeadlock {
                ObjectCreationHelpers.nosync_creationOperationForLiveMap(
                    entries: [
                        // RTO11f14c1a
                        "mapRef": .liveMap(referencedMap),
                        // RTO11f14c1a
                        "counterRef": .liveCounter(referencedCounter),
                        // RTO11f14c1b
                        "jsonArrayKey": .jsonArray([.string("arrayItem1"), .string("arrayItem2")]),
                        "jsonObjectKey": .jsonObject(["nestedKey": .string("nestedValue")]),
                        // RTO11f14c1c
                        "stringKey": .string("stringValue"),
                        // RTO11f14c1d
                        "numberKey": .number(42.5),
                        // RTO11f14c1e
                        "booleanKey": .bool(true),
                        // RTO11f14c1f
                        "dataKey": .data(Data([0x01, 0x02, 0x03])),
                    ],
                    timestamp: timestamp,
                )
            }

            // Then

            // Check that objectMessage has mapCreateWithObjectId with derivedFrom (RTO11f18)
            let mapCreateWithObjectId = try #require(creationOperation.objectMessage.operation?.mapCreateWithObjectId)
            #expect(mapCreateWithObjectId.derivedFrom?.semantics == .known(creationOperation.semantics))

            // Check that the initial value JSON is correctly populated on the mapCreateWithObjectId.initialValue property per RTO11f15, using the RTO11f14 partial ObjectOperation and correctly encoded per RTO11f15. Per RTO11f15, the initialValue is a JSON string of the MapCreate object itself (not wrapped in a type key).
            let initialValueString = try #require(creationOperation.objectMessage.operation?.mapCreateWithObjectId?.initialValue)
            let deserializedInitialValue = try #require(try JSONObjectOrArray(jsonString: initialValueString).objectValue)
            #expect(deserializedInitialValue == [
                // RTO11f14a
                "semantics": .number(Double(ObjectsMapSemantics.lww.rawValue)),
                "entries": [
                    // RTO11f14c1a
                    "mapRef": [
                        "data": [
                            "objectId": "referencedMapID",
                        ],
                    ],
                    "counterRef": [
                        "data": [
                            "objectId": "referencedCounterID",
                        ],
                    ],
                    // RTO11f14c1b
                    "jsonArrayKey": [
                        "data": [
                            "json": #"["arrayItem1","arrayItem2"]"#,
                        ],
                    ],
                    "jsonObjectKey": [
                        "data": [
                            "json": #"{"nestedKey":"nestedValue"}"#,
                        ],
                    ],
                    // RTO11f14c1c
                    "stringKey": [
                        "data": [
                            "string": "stringValue",
                        ],
                    ],
                    // RTO11f14c1d
                    "numberKey": [
                        "data": [
                            "number": 42.5,
                        ],
                    ],
                    // RTO11f14c1e
                    "booleanKey": [
                        "data": [
                            "boolean": true,
                        ],
                    ],
                    // RTO11f14c1f
                    "dataKey": [
                        "data": [
                            "bytes": .string(Data([0x01, 0x02, 0x03]).base64EncodedString()),
                        ],
                    ],
                ],
            ])

            // Check that derivedFrom has the mapCreate properties
            let derivedMapCreate = try #require(mapCreateWithObjectId.derivedFrom)

            #expect(derivedMapCreate.semantics == .known(.lww))

            let expectedEntries: [String: ObjectsMapEntry] = [
                "mapRef": .init(data: .init(objectId: "referencedMapID")),
                "counterRef": .init(data: .init(objectId: "referencedCounterID")),
                "jsonArrayKey": .init(data: .init(json: .array(["arrayItem1", "arrayItem2"]))),
                "jsonObjectKey": .init(data: .init(json: .object(["nestedKey": "nestedValue"]))),
                "stringKey": .init(data: .init(string: "stringValue")),
                "numberKey": .init(data: .init(number: 42.5)),
                "booleanKey": .init(data: .init(boolean: true)),
                "dataKey": .init(data: .init(bytes: Data([0x01, 0x02, 0x03]))),
            ]
            #expect(derivedMapCreate.entries == expectedEntries)

            // Check the other ObjectMessage.operation properties
            let operation = try #require(creationOperation.objectMessage.operation)

            // RTO11f9
            #expect(operation.action == .known(.mapCreate))

            // Check that objectId has been populated on ObjectMessage per RTO11f10, and do a quick sense check that its format is what we'd expect from RTO11f8 (RTO14 is properly tested elsewhere)
            #expect(try /map:.*@1754042434000/.firstMatch(in: operation.objectId) != nil)

            // Check that nonce has been populated per RTO11f16, and has 16+ characters per RTO11f6
            #expect(mapCreateWithObjectId.nonce.count >= 16)
        }

        // @specOneOf(1/2) RTO12f12a
        // @spec RTO12f15
        // @spec RTO12f6
        // @spec RTO12f8
        // @spec RTO12f14
        // @spec RTO12f13
        @Test
        @available(iOS 16.0.0, tvOS 16.0.0, *) // because of using Regex
        func counter() throws {
            // Given
            let timestamp = Date(timeIntervalSince1970: 1_754_042_434)

            // When
            let creationOperation = ObjectCreationHelpers.creationOperationForLiveCounter(
                count: 10.5,
                timestamp: timestamp,
            )

            // Then

            // Check that objectMessage has counterCreateWithObjectId with derivedFrom (RTO12f16)
            let counterCreateWithObjectId = try #require(creationOperation.objectMessage.operation?.counterCreateWithObjectId)

            // Check that the initial value JSON is correctly populated on the counterCreateWithObjectId.initialValue property per RTO12f13, using the RTO12f12 partial ObjectOperation and correctly encoded per RTO12f13. Per RTO12f13, the initialValue is a JSON string of the CounterCreate object itself (not wrapped in a type key).
            let initialValueString = try #require(creationOperation.objectMessage.operation?.counterCreateWithObjectId?.initialValue)
            let deserializedInitialValue = try #require(try JSONObjectOrArray(jsonString: initialValueString).objectValue)
            #expect(deserializedInitialValue == [
                // RTO12f12a
                "count": 10.5,
            ])

            // Check that derivedFrom has the counterCreate properties
            #expect(counterCreateWithObjectId.derivedFrom?.count == 10.5)

            // Check the other ObjectMessage.operation properties
            let operation = try #require(creationOperation.objectMessage.operation)

            // RTO12f7
            #expect(operation.action == .known(.counterCreate))

            // Check that objectId has been populated on ObjectMessage per RTO12f8, and do a quick sense check that its format is what we'd expect from RTO12f6 (RTO14 is properly tested elsewhere)
            #expect(try /counter:.*@1754042434000/.firstMatch(in: operation.objectId) != nil)

            // Check that nonce has been populated per RTO12f14, and has 16+ characters per RTO12f4
            #expect(counterCreateWithObjectId.nonce.count >= 16)
        }
    }

    /// Tests for the RTO14 objectID generation.
    struct ObjectIDTests {
        // @spec RTO14
        // @spec RTO14b1
        // @spec RTO14b2
        // @spec RTO14c
        @Test
        func createObjectID() {
            let objectID = ObjectCreationHelpers.testsOnly_createObjectID(
                type: "counter",
                initialValue: "arbitraryInitialValue",
                nonce: "arbitraryNonceABC", // Chosen to provoke a Base64 encoding that contains Base64URL-prohibited characters +, /, and =; see below
                timestamp: Date(
                    timeIntervalSince1970: 1_754_042_434,
                ),
            )

            // (The Base64-encoded SHA-256 of "arbitraryInitialValue:arbitraryNonceABC" is X5cX5Wv32Wj84/tzyuj5XD/Qpa76E+JkjPPQMK5aouw=)
            #expect(objectID == "counter:X5cX5Wv32Wj84_tzyuj5XD_Qpa76E-JkjPPQMK5aouw@1754042434000")
        }
    }
}
