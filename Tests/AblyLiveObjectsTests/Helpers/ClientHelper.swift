import Ably
import AblyLiveObjects

/// Helper for creating ably-cocoa objects, for use in integration tests.
enum ClientHelper {
    /// Creates a sandbox Realtime client with LiveObjects support.
    static func realtimeWithObjects(options: PartialClientOptions = .init()) async throws -> ARTRealtime {
        let key = try await Sandbox.fetchSharedAPIKey()
        let clientOptions = ARTClientOptions(key: key)
        clientOptions.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]
        clientOptions.environment = "sandbox"

        clientOptions.testOptions.transportFactory = TestProxyTransportFactory()

        if TestLogger.loggingEnabled {
            clientOptions.logLevel = .verbose
        }

        if let useBinaryProtocol = options.useBinaryProtocol {
            clientOptions.useBinaryProtocol = useBinaryProtocol
        }

        return ARTRealtime(options: clientOptions)
    }

    /// Creates channel options that include the channel modes needed for LiveObjects.
    static func channelOptionsWithObjects() -> ARTRealtimeChannelOptions {
        let options = ARTRealtimeChannelOptions()
        options.modes = [.objectSubscribe, .objectPublish]
        return options
    }

    struct PartialClientOptions: Encodable, Hashable {
        var useBinaryProtocol: Bool?
    }
}
