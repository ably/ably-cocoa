import AblyLiveObjects
import SwiftUI

struct ContentView: View {
    /// Just used to check that we can successfully import and use the AblyLiveObjects library. TODO remove this once we start building the library
    @State private var ablyLiveObjectsClient = AblyLiveObjectsClient()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
