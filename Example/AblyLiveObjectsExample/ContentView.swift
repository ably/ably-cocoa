import Ably
import AblyLiveObjects
import SwiftUI

struct ContentView: View {
    var realtime: ARTRealtime

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

            let channel = realtime.channels.get("myChannel")
            Text("`channel.objects`: `\(String(describing: channel.objects))`")
        }
        .padding()
    }
}
