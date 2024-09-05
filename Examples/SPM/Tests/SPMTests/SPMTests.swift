    import XCTest
    import Ably

    final class SPMTests: XCTestCase {
        func ablyInitTest() {
            let clientOptions = ClientOptions()
            let _ = Rest(options: clientOptions)
            let _ = Realtime(options: clientOptions)
        }
    }
