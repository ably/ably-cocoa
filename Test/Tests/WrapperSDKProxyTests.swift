import Ably
import XCTest

class WrapperSDKProxyTests: XCTestCase {
    func testRealtimeAPI() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        let proxyClient = client.createWrapperSDKProxy(with: .init(agents: ["some-agent": test.id.uuidString]))

        // TODO get these compiling, then start adding other APIs here

        let _ = proxyClient.connection
//
        let channel = proxyClient.channels.get(test.uniqueChannelName())

        channel.attach()
    }
}
