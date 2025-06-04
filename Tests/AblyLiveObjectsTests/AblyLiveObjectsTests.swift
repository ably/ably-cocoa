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
        #expect(channel.objects is DefaultLiveObjects)
    }
}
