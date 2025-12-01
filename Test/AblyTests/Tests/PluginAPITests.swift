import Ably.Private
import XCTest
import _AblyPluginSupportPrivate
import Nimble

class PluginAPITests: XCTestCase {
    func test_fetchServerTime() throws {
        // Given: A realtime client
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        var serverTimeRequestCount = 0
        let rest = client.internal.rest
        let hook = rest.testSuite_injectIntoMethod(after: #selector(rest._time(withWrapperSDKAgents:completion:))) {
            serverTimeRequestCount += 1
        }
        defer { hook.remove() }

        let pluginAPI = DependencyStore.sharedInstance().fetchPluginAPI()
        let pluginRealtimeClient = client.internal as! _AblyPluginSupportPrivate.RealtimeClient

        let internalQueue = client.internal.queue

        // When: We call nosync_fetchServerTime twice on the plugin API

        for _ in (1...2) {
            waitUntil(timeout: testTimeout) { done in
                internalQueue.async {
                    pluginAPI.nosync_fetchServerTime(for: pluginRealtimeClient) { serverTime, error in
                        // Then: Both attempts succeed, and the server time is fetched from the REST API on the first attempt but not on the second
                        dispatchPrecondition(condition: .onQueue(internalQueue))
                        XCTAssertNil(error)
                        XCTAssertNotNil(serverTime)
                        XCTAssertEqual(serverTimeRequestCount, 1)
                        done()
                    }
                }
            }
        }
    }
}
