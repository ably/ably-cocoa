import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
import Testing

struct AblyLiveObjectsTests {
    @Test
    func objectsProperty() async throws {
        // Given

        let clientOptions = ARTClientOptions(key: "foo:bar")
        clientOptions.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]
        // Don't need to connect
        clientOptions.autoConnect = false

        let realtime = ARTRealtime(options: clientOptions)

        let channel = realtime.channels.get("someChannel")

        // Then

        // Check that the `channel.objects` property works and gives the internal type we expect
        #expect(channel.objects is PublicDefaultRealtimeObjects)
    }

    /// A basic test of the core interactions between this plugin and ably-cocoa.
    @Test(arguments: [true, false])
    func plumbingSmokeTest(useBinaryProtocol: Bool) async throws {
        let key = try await Sandbox.fetchSharedAPIKey()
        let clientOptions = ARTClientOptions(key: key)
        clientOptions.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]
        clientOptions.environment = "sandbox"
        clientOptions.useBinaryProtocol = useBinaryProtocol

        let realtime = ARTRealtime(options: clientOptions)
        defer { realtime.close() }

        // 1. Create a Map on a channel using the REST API.
        // https://ably.com/docs/api/liveobjects-rest

        let channelName = UUID().uuidString

        // swiftlint:disable:next force_cast
        let restClientOptions = clientOptions.copy() as! ARTClientOptions
        // TODO: Understand why the LiveObjects REST API is failing when I try to use MessagePack (asked in https://ably-real-time.slack.com/archives/CURL4U2FP/p1749739112276359); for now am just using a separate client that always uses JSON.
        restClientOptions.useBinaryProtocol = false
        let rest = ARTRest(options: restClientOptions)

        let currentAblyTimestamp = UInt64(Date().timeIntervalSince1970) * MSEC_PER_SEC

        let mapCreateResponse = try await rest.requestAsync(
            "POST",
            path: "/channels/\(channelName)/objects",
            params: nil,
            body: [
                "operation": "MAP_CREATE",
                "data": [
                    "title": [
                        "string": "LiveObjects is awesome",
                    ],
                    "createdAt": [
                        "number": currentAblyTimestamp,
                    ],
                    "isPublished": [
                        "boolean": true,
                    ],
                ],
            ],
            headers: nil,
        )

        try #require(mapCreateResponse.statusCode == 201)
        let restCreatedMapObjectID = try #require((mapCreateResponse.items.first?["objectIds"] as? [String])?.first)

        // 2. Attach to the channel on which we just created the Map.
        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = [.objectPublish, .objectSubscribe]
        let channel = realtime.channels.get(channelName, options: channelOptions)
        try await channel.attachAsync()

        // 3. Check that ably-cocoa called our onChannelAttached and passed the HAS_OBJECTS flag.
        #expect(channel.testsOnly_nonTypeErasedObjects.testsOnly_onChannelAttachedHasObjects == true)

        // 4. Check that ably-cocoa used us to decode the ObjectMessages in the OBJECT_SYNC, and then called our handleObjectSyncProtocolMessage with these ObjectMessages; we expect the OBJECT_SYNC to contain the root object and the map that we created in the REST call above.
        let objectSyncObjectMessages = try #require(await channel.testsOnly_nonTypeErasedObjects.testsOnly_receivedObjectSyncProtocolMessages.first { _ in true })
        #expect(Set(objectSyncObjectMessages.map(\.object?.objectId)) == ["root", restCreatedMapObjectID])

        // 5. Now, send an OBJECT ProtocolMessage that creates a new Map. This confirms that Ably is using us to encode this ProtocolMessage's contained ObjectMessages.

        // (This objectId comes from copying that which was given in an expected value in an error message from Realtime)
        let realtimeCreatedMapObjectID = "map:iC4Nq8EbTSEmw-_tDJdVV8HfiBvJGpZmO_WbGbh0_-4@\(currentAblyTimestamp)"

        try await channel.testsOnly_nonTypeErasedObjects.testsOnly_publish(objectMessages: [
            OutboundObjectMessage(
                operation: .init(
                    action: .known(.mapCreate),
                    objectId: realtimeCreatedMapObjectID,
                    nonce: "1",
                ),
            ),
        ])

        // 6. Check that ably-cocoa used us to decode the ObjectMessages in the OBJECT triggered by this map creation, and then called our handleObjectProtocolMessage with these ObjectMessages; we expect the OBJECT to contain the map create operation that we just performed.
        let objectObjectMessages = try #require(await channel.testsOnly_nonTypeErasedObjects.testsOnly_receivedObjectProtocolMessages.first { _ in true })
        try #require(objectObjectMessages.count == 1)
        let receivedMapCreateObjectMessage = objectObjectMessages[0]
        #expect(receivedMapCreateObjectMessage.operation?.objectId == realtimeCreatedMapObjectID)
        #expect(receivedMapCreateObjectMessage.operation?.action == .known(.mapCreate))

        // 7. Now, send an invalid OBJECT ProtocolMessage to check that ably-cocoa correctly reports on its NACK.
        let invalidObjectThrownError = try await #require(throws: ARTErrorInfo.self) {
            do throws(InternalError) {
                try await channel.testsOnly_nonTypeErasedObjects.testsOnly_publish(objectMessages: [
                    .init(),
                ])
            } catch {
                throw error.toARTErrorInfo()
            }
        }

        // (These are just based on what I observed in the NACK)
        #expect(invalidObjectThrownError.code == 92000)
        #expect(invalidObjectThrownError.message == "invalid object message: object operation required")
    }

    /// A basic test of the public API of the LiveObjects plugin.
    @Test(arguments: [true, false])
    func smokeTest(useBinaryProtocol: Bool) async throws {
        let client = try await ClientHelper.realtimeWithObjects(options: .init(useBinaryProtocol: useBinaryProtocol))
        let channel = client.channels.get(UUID().uuidString, options: ClientHelper.channelOptionsWithObjects())
        try await channel.attachAsync()

        let root = try await channel.objects.getRoot()
        let rootSubscription = try root.updates()

        // Create a counter
        let counter = try await channel.objects.createCounter(count: 52)
        let counterSubscription = try counter.updates()

        // Create a map and check its initial entries
        let map = try await channel.objects.createMap(entries: [
            "boolKey": true,
            "numberKey": 10,
        ])
        #expect(
            try Dictionary(uniqueKeysWithValues: map.entries) == [
                "boolKey": true,
                "numberKey": 10,
            ],
        )
        let mapSubscription = try map.updates()

        // Perform a `set` on the root and check it comes through on subscription
        try await root.set(key: "mapKey", value: .liveMap(map))
        let rootUpdate = try #require(await rootSubscription.first { _ in true })
        #expect(rootUpdate.update == ["mapKey": .updated])
        #expect(try Dictionary(uniqueKeysWithValues: root.entries) == ["mapKey": .liveMap(map)])

        // Perform a `set` on the map and check it comes through on subscription and that the map is updated
        try await map.set(key: "counterKey", value: .liveCounter(counter))
        let mapUpdate = try #require(await mapSubscription.first { _ in true })
        #expect(mapUpdate.update == ["counterKey": .updated])
        #expect(
            try Dictionary(uniqueKeysWithValues: map.entries) == [
                "boolKey": true,
                "numberKey": 10,
                "counterKey": .liveCounter(counter),
            ],
        )

        // Perform an `increment` on the counter and check it comes through on subscription and that the counter is updated
        try await counter.increment(amount: 30)
        let counterUpdate = try #require(await counterSubscription.first { _ in true })
        #expect(counterUpdate.amount == 30)
        #expect(try counter.value == 82)

        // Perform a `remove` on the map and check it comes through on subscription and that the map is updated
        try await map.remove(key: "boolKey")
        let mapRemoveUpdate = try #require(await mapSubscription.first { _ in true })
        #expect(mapRemoveUpdate.update == ["boolKey": .removed])
        #expect(
            try Dictionary(uniqueKeysWithValues: map.entries) == [
                "numberKey": 10,
                "counterKey": .liveCounter(counter),
            ],
        )
    }
}
