import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
import Foundation

// This file is copied from the file objects.test.js in ably-js.

/// This is a Swift port of the JavaScript ObjectsHelper class used for testing.
final class ObjectsHelper: Sendable {
    // MARK: - Constants

    /// Object operation actions
    enum Actions: Int {
        case mapCreate = 0
        case mapSet = 1
        case mapRemove = 2
        case counterCreate = 3
        case counterInc = 4
        case objectDelete = 5

        var stringValue: String {
            switch self {
            case .mapCreate:
                "MAP_CREATE"
            case .mapSet:
                "MAP_SET"
            case .mapRemove:
                "MAP_REMOVE"
            case .counterCreate:
                "COUNTER_CREATE"
            case .counterInc:
                "COUNTER_INC"
            case .objectDelete:
                "OBJECT_DELETE"
            }
        }
    }

    // MARK: - Properties

    private let rest: ARTRest

    // MARK: - Initialization

    init() async throws {
        let options = try await ARTClientOptions(key: Sandbox.fetchSharedAPIKey())
        options.useBinaryProtocol = false
        options.environment = "sandbox"
        rest = ARTRest(options: options)
    }

    // MARK: - Static Properties and Methods

    /// Static access to the Actions enum (equivalent to JavaScript static ACTIONS)
    static let ACTIONS = Actions.self

    /// Returns the root keys used in the fixture objects tree
    static func fixtureRootKeys() -> [String] {
        ["emptyCounter", "initialValueCounter", "referencedCounter", "emptyMap", "referencedMap", "valuesMap"]
    }

    // MARK: - Channel Initialization

    /// Sends Objects REST API requests to create objects tree on a provided channel:
    ///
    /// - root "emptyMap" -> Map#1 {} -- empty map
    /// - root "referencedMap" -> Map#2 { "counterKey": <object id Counter#3> }
    /// - root "valuesMap" -> Map#3 { "stringKey": "stringValue", "emptyStringKey": "", "bytesKey": <byte array for "{"productId": "001", "productName": "car"}", encoded in base64>, "emptyBytesKey": <empty byte array>, "numberKey": 1, "zeroKey": 0, "trueKey": true, "falseKey": false, "mapKey": <objectId of Map#2> }
    /// - root "emptyCounter" -> Counter#1 -- no initial value counter, should be 0
    /// - root "initialValueCounter" -> Counter#2 count=10
    /// - root "referencedCounter" -> Counter#3 count=20
    func initForChannel(_ channelName: String) async throws {
        _ = try await createAndSetOnMap(
            channelName: channelName,
            mapObjectId: "root",
            key: "emptyCounter",
            createOp: counterCreateRestOp(),
        )

        _ = try await createAndSetOnMap(
            channelName: channelName,
            mapObjectId: "root",
            key: "initialValueCounter",
            createOp: counterCreateRestOp(number: 10),
        )

        let referencedCounter = try await createAndSetOnMap(
            channelName: channelName,
            mapObjectId: "root",
            key: "referencedCounter",
            createOp: counterCreateRestOp(number: 20),
        )

        _ = try await createAndSetOnMap(
            channelName: channelName,
            mapObjectId: "root",
            key: "emptyMap",
            createOp: mapCreateRestOp(),
        )

        let referencedMapData: [String: JSONValue] = [
            "counterKey": .object(["objectId": .string(referencedCounter.objectId)]),
        ]
        let referencedMap = try await createAndSetOnMap(
            channelName: channelName,
            mapObjectId: "root",
            key: "referencedMap",
            createOp: mapCreateRestOp(data: referencedMapData),
        )

        let valuesMapData: [String: JSONValue] = [
            "stringKey": .object(["string": .string("stringValue")]),
            "emptyStringKey": .object(["string": .string("")]),
            "bytesKey": .object(["bytes": .string("eyJwcm9kdWN0SWQiOiAiMDAxIiwgInByb2R1Y3ROYW1lIjogImNhciJ9")]),
            "emptyBytesKey": .object(["bytes": .string("")]),
            "numberKey": .object(["number": .number(1)]),
            "zeroKey": .object(["number": .number(0)]),
            "trueKey": .object(["boolean": .bool(true)]),
            "falseKey": .object(["boolean": .bool(false)]),
            "mapKey": .object(["objectId": .string(referencedMap.objectId)]),
        ]
        _ = try await createAndSetOnMap(
            channelName: channelName,
            mapObjectId: "root",
            key: "valuesMap",
            createOp: mapCreateRestOp(data: valuesMapData),
        )
    }

    // MARK: - Wire Object Messages

    /// Creates a map create operation
    func mapCreateOp(objectId: String? = nil, entries: [String: WireValue]? = nil) -> [String: WireValue] {
        var operation: [String: WireValue] = [
            "action": .number(NSNumber(value: Actions.mapCreate.rawValue)),
            "nonce": .string(nonce()),
            "map": .object(["semantics": .number(NSNumber(value: 0))]),
        ]

        if let objectId {
            operation["objectId"] = .string(objectId)
        }

        if let entries {
            var mapValue = operation["map"]!.objectValue!
            mapValue["entries"] = .object(entries)
            operation["map"] = .object(mapValue)
        }

        return ["operation": .object(operation)]
    }

    /// Creates a map set operation
    func mapSetOp(objectId: String, key: String, data: WireValue) -> [String: WireValue] {
        [
            "operation": .object([
                "action": .number(NSNumber(value: Actions.mapSet.rawValue)),
                "objectId": .string(objectId),
                "mapOp": .object([
                    "key": .string(key),
                    "data": data,
                ]),
            ]),
        ]
    }

    /// Creates a map remove operation
    func mapRemoveOp(objectId: String, key: String) -> [String: WireValue] {
        [
            "operation": .object([
                "action": .number(NSNumber(value: Actions.mapRemove.rawValue)),
                "objectId": .string(objectId),
                "mapOp": .object([
                    "key": .string(key),
                ]),
            ]),
        ]
    }

    /// Creates a counter create operation
    func counterCreateOp(objectId: String? = nil, count: Int? = nil) -> [String: WireValue] {
        var operation: [String: WireValue] = [
            "action": .number(NSNumber(value: Actions.counterCreate.rawValue)),
            "nonce": .string(nonce()),
        ]

        if let objectId {
            operation["objectId"] = .string(objectId)
        }

        if let count {
            operation["counter"] = .object(["count": .number(NSNumber(value: count))])
        }

        return ["operation": .object(operation)]
    }

    /// Creates a counter increment operation
    func counterIncOp(objectId: String, amount: Int) -> [String: WireValue] {
        [
            "operation": .object([
                "action": .number(NSNumber(value: Actions.counterInc.rawValue)),
                "objectId": .string(objectId),
                "counterOp": .object([
                    "amount": .number(NSNumber(value: amount)),
                ]),
            ]),
        ]
    }

    /// Creates an object delete operation
    func objectDeleteOp(objectId: String) -> [String: WireValue] {
        [
            "operation": .object([
                "action": .number(NSNumber(value: Actions.objectDelete.rawValue)),
                "objectId": .string(objectId),
            ]),
        ]
    }

    /// Creates a map object structure
    func mapObject(
        objectId: String,
        siteTimeserials: [String: String],
        initialEntries: [String: WireValue]? = nil,
        materialisedEntries: [String: WireValue]? = nil,
        tombstone: Bool = false,
    ) -> [String: WireValue] {
        var object: [String: WireValue] = [
            "objectId": .string(objectId),
            "siteTimeserials": .object(siteTimeserials.mapValues { .string($0) }),
            "tombstone": .bool(tombstone),
            "map": .object([
                "semantics": .number(NSNumber(value: 0)),
                "entries": .object(materialisedEntries ?? [:]),
            ]),
        ]

        if let initialEntries {
            let createOp = mapCreateOp(objectId: objectId, entries: initialEntries)
            object["createOp"] = createOp["operation"]!
        }

        return ["object": .object(object)]
    }

    /// Creates a counter object structure
    func counterObject(
        objectId: String,
        siteTimeserials: [String: String],
        initialCount: Int? = nil,
        materialisedCount: Int? = nil,
        tombstone: Bool = false,
    ) -> [String: WireValue] {
        let materialisedCountValue: WireValue = if let materialisedCount {
            .number(NSNumber(value: materialisedCount))
        } else {
            .null
        }

        var object: [String: WireValue] = [
            "objectId": .string(objectId),
            "siteTimeserials": .object(siteTimeserials.mapValues { .string($0) }),
            "tombstone": .bool(tombstone),
            "counter": .object([
                "count": materialisedCountValue,
            ]),
        ]

        if let initialCount {
            let createOp = counterCreateOp(objectId: objectId, count: initialCount)
            object["createOp"] = createOp["operation"]!
        }

        return ["object": .object(object)]
    }

    /// Creates an object operation message
    func objectOperationMessage(
        channelName: String,
        serial: String,
        siteCode: String,
        state: [[String: WireValue]]? = nil,
    ) -> [String: WireValue] {
        let stateWithSerials = state?.map { objectMessage in
            var message = objectMessage
            message["serial"] = .string(serial)
            message["siteCode"] = .string(siteCode)
            return message
        }

        let stateArray = stateWithSerials?.map { dict in WireValue.object(dict) } ?? []

        return [
            "action": .number(NSNumber(value: 19)), // OBJECT
            "channel": .string(channelName),
            "channelSerial": .string(serial),
            "state": .array(stateArray),
        ]
    }

    /// Creates an object state message
    func objectStateMessage(
        channelName: String,
        syncSerial: String,
        state: [[String: WireValue]]? = nil,
    ) -> [String: WireValue] {
        let stateArray = state?.map { dict in WireValue.object(dict) } ?? []
        return [
            "action": .number(NSNumber(value: 20)), // OBJECT_SYNC
            "channel": .string(channelName),
            "channelSerial": .string(syncSerial),
            "state": .array(stateArray),
        ]
    }

    /// This is the equivalent of the JS ObjectHelper's channel.processMessage(createPM(…)).
    private func processDeserializedProtocolMessage(
        _ deserialized: [String: WireValue],
        channel: ARTRealtimeChannel,
    ) async {
        await withCheckedContinuation { continuation in
            channel.internal.queue.async {
                let useBinaryProtocol = channel.realtimeInternal.options.useBinaryProtocol
                let jsonLikeEncoderDelegate: ARTJsonLikeEncoderDelegate = useBinaryProtocol ? ARTMsgPackEncoder() : ARTJsonEncoder()

                let encoder = ARTJsonLikeEncoder(
                    rest: channel.internal.realtime!.rest,
                    delegate: jsonLikeEncoderDelegate,
                    logger: channel.internal.logger,
                )

                let foundationObject = deserialized.toPluginSupportDataDictionary
                let protocolMessage = withExtendedLifetime(jsonLikeEncoderDelegate) {
                    encoder.protocolMessage(from: foundationObject)!
                }

                channel.internal.onChannelMessage(protocolMessage)
                continuation.resume()
            }
        }
    }

    /// Processes an object operation message on a channel
    func processObjectOperationMessageOnChannel(
        channel: ARTRealtimeChannel,
        serial: String,
        siteCode: String,
        state: [[String: WireValue]]? = nil,
    ) async {
        await processDeserializedProtocolMessage(
            objectOperationMessage(
                channelName: channel.name,
                serial: serial,
                siteCode: siteCode,
                state: state,
            ),
            channel: channel,
        )
    }

    /// Processes an object state message on a channel
    func processObjectStateMessageOnChannel(
        channel: ARTRealtimeChannel,
        syncSerial: String,
        state: [[String: WireValue]]? = nil,
    ) async {
        await processDeserializedProtocolMessage(
            objectStateMessage(
                channelName: channel.name,
                syncSerial: syncSerial,
                state: state,
            ),
            channel: channel,
        )
    }

    // MARK: - REST API Operations

    /// Result of a REST API operation
    struct OperationResult {
        let objectId: String
        let success: Bool
    }

    /// Creates an object and sets it on a map
    func createAndSetOnMap(
        channelName: String,
        mapObjectId: String,
        key: String,
        createOp: [String: JSONValue],
    ) async throws -> OperationResult {
        let createResult = try await operationRequest(channelName: channelName, opBody: createOp)
        let objectId = createResult.objectId

        let setOp = mapSetRestOp(
            objectId: mapObjectId,
            key: key,
            value: ["objectId": .string(objectId)],
        )
        _ = try await operationRequest(channelName: channelName, opBody: setOp)

        return createResult
    }

    /// Creates a map create REST operation
    func mapCreateRestOp(objectId: String? = nil, nonce: String? = nil, data: [String: JSONValue]? = nil) -> [String: JSONValue] {
        var opBody: [String: JSONValue] = [
            "operation": .string(Actions.mapCreate.stringValue),
        ]

        if let data {
            opBody["data"] = .object(data)
        }

        if let objectId {
            opBody["objectId"] = .string(objectId)
            opBody["nonce"] = .string(nonce ?? "")
        }

        return opBody
    }

    /// Creates a map set REST operation
    func mapSetRestOp(objectId: String, key: String, value: [String: JSONValue]) -> [String: JSONValue] {
        [
            "operation": .string(Actions.mapSet.stringValue),
            "objectId": .string(objectId),
            "data": .object([
                "key": .string(key),
                "value": .object(value),
            ]),
        ]
    }

    /// Creates a map remove REST operation
    func mapRemoveRestOp(objectId: String, key: String) -> [String: JSONValue] {
        [
            "operation": .string(Actions.mapRemove.stringValue),
            "objectId": .string(objectId),
            "data": .object([
                "key": .string(key),
            ]),
        ]
    }

    /// Creates a counter create REST operation
    func counterCreateRestOp(objectId: String? = nil, nonce: String? = nil, number: Double? = nil) -> [String: JSONValue] {
        var opBody: [String: JSONValue] = [
            "operation": .string(Actions.counterCreate.stringValue),
        ]

        if let number {
            opBody["data"] = .object(["number": .number(NSNumber(value: number))])
        }

        if let objectId {
            opBody["objectId"] = .string(objectId)
            opBody["nonce"] = .string(nonce ?? "")
        }

        return opBody
    }

    /// Creates a counter increment REST operation
    func counterIncRestOp(objectId: String, number: Double) -> [String: JSONValue] {
        [
            "operation": .string(Actions.counterInc.stringValue),
            "objectId": .string(objectId),
            "data": .object(["number": .number(NSNumber(value: number))]),
        ]
    }

    /// Sends an operation request to the REST API
    func operationRequest(channelName: String, opBody: [String: JSONValue]) async throws -> OperationResult {
        let path = "/channels/\(channelName)/objects"

        do {
            let response = try await rest.requestAsync("POST", path: path, params: nil, body: opBody.toJSONSerializationInput, headers: nil)

            guard (200 ..< 300).contains(response.statusCode) else {
                throw NSError(
                    domain: "ObjectsHelper",
                    code: response.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: "REST API request failed",
                        "path": path,
                        "operation": opBody.toJSONSerializationInput,
                    ],
                )
            }

            guard let firstItem = response.items.first as? [String: Any] else {
                throw NSError(
                    domain: "ObjectsHelper",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response format - no items"],
                )
            }

            // Extract objectId from the response
            let objectId: String
            if let objectIds = firstItem["objectIds"] as? [String], let firstObjectId = objectIds.first {
                objectId = firstObjectId
            } else if let directObjectId = firstItem["objectId"] as? String {
                objectId = directObjectId
            } else {
                throw NSError(
                    domain: "ObjectsHelper",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No objectId found in response"],
                )
            }

            return OperationResult(objectId: objectId, success: true)
        } catch let error as ARTErrorInfo {
            throw error
        } catch {
            throw error
        }
    }

    // MARK: - Utility Methods

    /// Generates a fake map object ID
    func fakeMapObjectId() -> String {
        "map:\(randomString())@\(Int(Date().timeIntervalSince1970 * 1000))"
    }

    /// Generates a fake counter object ID
    func fakeCounterObjectId() -> String {
        "counter:\(randomString())@\(Int(Date().timeIntervalSince1970 * 1000))"
    }

    // MARK: - Private Methods

    /// Generates a random nonce
    private func nonce() -> String {
        randomString()
    }

    /// Generates a random string
    private func randomString() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< 16).map { _ in letters.randomElement()! })
    }
}
