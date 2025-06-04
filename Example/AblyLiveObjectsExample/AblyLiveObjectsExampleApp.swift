import Ably
import AblyLiveObjects
import SwiftUI

@main
struct AblyLiveObjectsExampleApp: App {
    @State private var realtime = {
        let clientOptions = ARTClientOptions(key: Secrets.ablyAPIKey)
        clientOptions.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]

        return ARTRealtime(options: clientOptions)
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(realtime: realtime)
        }
    }
}
