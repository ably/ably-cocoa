import Foundation

/// REST fixture provisioning for the `objects` integration specs — the Swift implementation of the
/// spec's `provision_objects_via_rest` helper (`uts/objects/helpers/standard_test_pool.md`,
/// "REST Fixture Provisioning"). Mirrors ably-java's
/// `uts/.../integration/standard/liveobjects/Helpers.kt`, camelCased.
///
/// The objects REST API uses the **V2 format** (the LiveObjects OpenAPI specification is the source
/// of truth): `POST /channels/{channel}/object` (**singular**), body is a single operation object
/// **or** a bare JSON array of operations — there is **no** `{ "messages": [...] }` envelope. Each
/// operation names its type via a payload key (`mapSet` / `mapRemove` / `mapCreate` / `counterInc`
/// / `counterCreate`) and targets an object by `objectId` **or** `path`; an optional `id` on any
/// operation is an idempotency key. (The spec's legacy `POST …/objects` + `messages` shape was
/// aligned to V2 in ably/specification#497.)
///
/// Unlike ably-java (which drives an `AblyRest` client that must be closed after use), this port
/// posts through the integration infra's plain `URLSession` helpers — nothing to close.

private let objectsProvisioningSession = makeURLSession(requestTimeout: 30)

/// Publishes `operations` to the channel over REST, before any realtime client connects.
/// A single operation is sent as a bare object; several are sent as a JSON array (batch).
/// Returns the server-assigned `objectIds` from the response (empty when the response carries none).
@discardableResult
func provisionObjectsViaRest(apiKey: String,
                             channelName: String,
                             operations: [[String: Any]]) async throws -> [String] {
    precondition(!operations.isEmpty, "operations must not be empty")

    let encodedChannelName = channelName.addingPercentEncoding(
        withAllowedCharacters: CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
    ) ?? channelName
    let url = URL(string: "https://\(SandboxApp.sandboxHost)/channels/\(encodedChannelName)/object")!

    // operations: a single operation object, or an array of operation objects (batch)
    let body: Any = operations.count == 1 ? operations[0] : operations
    var request = try jsonRequest("POST", url, body: body)
    let basic = Data(apiKey.utf8).base64EncodedString()
    request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")

    let (data, status) = try await httpRequest(request, session: objectsProvisioningSession)
    guard (200..<300).contains(status) else {
        throw HTTPError("POST /channels/\(channelName)/object returned \(status): \(String(decoding: data, as: UTF8.self))")
    }

    // The response is a single result object or an array of them, each carrying `objectIds`
    // (ably-java flattens `response.items()` the same way).
    let responseBody = try JSONSerialization.jsonObject(with: data)
    let items: [[String: Any]]
    if let object = responseBody as? [String: Any] {
        items = [object]
    } else if let array = responseBody as? [[String: Any]] {
        items = array
    } else {
        items = []
    }
    return items.flatMap { item in item["objectIds"] as? [String] ?? [] }
}

// MARK: - Operation builders (V2 operation shapes)

/// `{ mapSet: { key, value }, objectId|path, id? }` — set `key` to `value` on the target map.
func mapSetOp(key: String, value: [String: Any], objectId: String? = nil, path: String? = nil, id: String? = nil) -> [String: Any] {
    withTarget(["mapSet": ["key": key, "value": value]], objectId: objectId, path: path, id: id)
}

/// `{ mapRemove: { key }, objectId|path, id? }` — remove `key` from the target map.
func mapRemoveOp(key: String, objectId: String? = nil, path: String? = nil, id: String? = nil) -> [String: Any] {
    withTarget(["mapRemove": ["key": key]], objectId: objectId, path: path, id: id)
}

/// `{ mapCreate: { semantics, entries }, objectId|path?, id? }` — create a map (semantics 0 = LWW).
/// Entry values are wrapped as `{ data: <value> }` per the V2 schema. A create with no target makes
/// a standalone object.
func mapCreateOp(entries: [String: [String: Any]], semantics: Int = 0, objectId: String? = nil, path: String? = nil, id: String? = nil) -> [String: Any] {
    let wrappedEntries = entries.mapValues { value in ["data": value] }
    return withTarget(["mapCreate": ["semantics": semantics, "entries": wrappedEntries]], objectId: objectId, path: path, id: id)
}

/// `{ counterCreate: { count }, objectId|path?, id? }` — create a counter.
func counterCreateOp(count: Double, objectId: String? = nil, path: String? = nil, id: String? = nil) -> [String: Any] {
    withTarget(["counterCreate": ["count": count]], objectId: objectId, path: path, id: id)
}

/// `{ counterInc: { number }, objectId|path, id? }` — increment the target counter
/// (a negative number decrements).
func counterIncOp(number: Double, objectId: String? = nil, path: String? = nil, id: String? = nil) -> [String: Any] {
    withTarget(["counterInc": ["number": number]], objectId: objectId, path: path, id: id)
}

private func withTarget(_ operation: [String: Any], objectId: String?, path: String?, id: String?) -> [String: Any] {
    var operation = operation
    if let objectId { operation["objectId"] = objectId }
    if let path { operation["path"] = path }
    if let id { operation["id"] = id }
    return operation
}

// MARK: - Primitive value builders (V2 `PrimitiveValue` shapes)

/// `{ string: value, encoding? }`
func valueString(_ value: String, encoding: String? = nil) -> [String: Any] {
    var result: [String: Any] = ["string": value]
    if let encoding { result["encoding"] = encoding }
    return result
}

/// `{ number: value }`
func valueNumber(_ value: Double) -> [String: Any] {
    ["number": value]
}

/// `{ boolean: value }`
func valueBoolean(_ value: Bool) -> [String: Any] {
    ["boolean": value]
}

/// `{ bytes: base64, encoding? }`
func valueBytes(_ base64: String, encoding: String? = nil) -> [String: Any] {
    var result: [String: Any] = ["bytes": base64]
    if let encoding { result["encoding"] = encoding }
    return result
}

/// `{ objectId: objectId }` — a reference to an existing object.
func valueObjectId(_ objectId: String) -> [String: Any] {
    ["objectId": objectId]
}
