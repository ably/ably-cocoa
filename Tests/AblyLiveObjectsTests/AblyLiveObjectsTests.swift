import Ably
@testable import AblyLiveObjects
import AblyPlugin
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
}
