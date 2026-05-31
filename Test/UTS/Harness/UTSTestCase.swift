import XCTest
import Ably
import Ably.Private

/// Base class for UTS-derived unit tests.
///
/// Provides the cocoa mappings of the UTS harness primitives:
/// - `installMock(_:)` — the spec's `install_mock`: registers the `MockWebSocketProvider` so the
///   next client built by `makeRealtime()` picks it up. The mock is never passed to the client
///   constructor (a mistake per `uts/docs/writing-test-specs.md`).
/// - `awaitConnectionState` / `awaitChannelState` — the spec's `AWAIT_STATE`: proceed immediately
///   if the condition already holds, otherwise poll until it does or the timeout expires.
/// - `advanceTime(byMilliseconds:)` — fake-timer advancement (`ADVANCE_TIME`).
/// - protocol-message builders, and cleanup of clients and scheduled timers.
class UTSTestCase: XCTestCase {

    /// Default `AWAIT_STATE` timeout. Generous: with a frozen `FakeTimeProvider` the SDK settles in
    /// microseconds, so this only bites when a state genuinely never arrives (a real failure).
    static let defaultAwaitTimeout: TimeInterval = 2

    /// The deterministic clock, installed into clients only after `enableFakeTimers()` is called.
    var timeProvider: FakeTimeProvider?

    private var installedWebSocketProvider: MockWebSocketProvider?
    private var installedMockHTTP: MockHTTP?
    private var clients: [ARTRealtime] = []

    // MARK: Enable fake timers

    /// UTS `enable_fake_timers()`. Clients built *after* this call use the deterministic
    /// `FakeTimeProvider` (advanced via `advanceTime(byMilliseconds:)`); by default — and for clients
    /// built before this call — they use the real `ARTSystemTimeProvider`. Mirrors the spec, where
    /// most tests run on real timers and only those exercising timeouts/retries opt into fake ones.
    func enableFakeTimers() {
        timeProvider = FakeTimeProvider()
    }

    // MARK: Install mock

    /// Registers `wsProvider` to be used by the next `makeRealtime()` call (UTS `install_mock`).
    func installMock(_ wsProvider: MockWebSocketProvider) {
        installedWebSocketProvider = wsProvider
    }

    /// Registers `mockHTTP` to be used by the next `makeRest()` call (UTS `install_mock`).
    func installMock(_ mockHTTP: MockHTTP) {
        installedMockHTTP = mockHTTP
    }

    // MARK: Client construction

    /// Builds an `ARTRealtime` wired to the currently installed `MockWebSocketProvider` and the
    /// shared `FakeTimeProvider`. `autoConnect` defaults to `false`, matching the UTS specs. A
    /// provider must be installed first via `installMock(_:)`.
    func makeRealtime(configure: (ARTClientOptions) -> Void = { _ in }, file: StaticString = #file, line: UInt = #line) -> ARTRealtime {
        guard let wsProvider = installedWebSocketProvider else {
            XCTFail("No MockWebSocketProvider installed — call installMock(_:) before makeRealtime()", file: file, line: line)
            fatalError("No MockWebSocketProvider installed")
        }

        let options = ARTClientOptions()
        options.autoConnect = false
        options.useBinaryProtocol = false

        let suffix = UUID().uuidString
        options.internalDispatchQueue = DispatchQueue(label: "io.ably.uts.internal.\(suffix)")
        options.dispatchQueue = DispatchQueue(label: "io.ably.uts.callback.\(suffix)")

        if let timeProvider {
            options.testOptions.timeProvider = timeProvider
        }
        options.testOptions.transportFactory = MockWebSocketTransportFactory(wsProvider: wsProvider)

        configure(options)

        let client = ARTRealtime(options: options)
        client.internal.setReachabilityClass(NoOpReachability.self)
        clients.append(client)
        return client
    }

    /// Builds an `ARTRest` whose HTTP layer is the currently installed `MockHTTP` (so requests are
    /// intercepted, not sent over the network). A mock must be installed first via `installMock(_:)`.
    func makeRest(configure: (ARTClientOptions) -> Void = { _ in }, file: StaticString = #file, line: UInt = #line) -> ARTRest {
        guard let mockHTTP = installedMockHTTP else {
            XCTFail("No MockHTTP installed — call installMock(_:) before makeRest()", file: file, line: line)
            fatalError("No MockHTTP installed")
        }

        let options = ARTClientOptions()
        options.useBinaryProtocol = false

        let suffix = UUID().uuidString
        options.internalDispatchQueue = DispatchQueue(label: "io.ably.uts.internal.\(suffix)")
        options.dispatchQueue = DispatchQueue(label: "io.ably.uts.callback.\(suffix)")

        if let timeProvider {
            options.testOptions.timeProvider = timeProvider
        }

        configure(options)

        let rest = ARTRest(options: options)
        rest.internal.httpExecutor = mockHTTP
        return rest
    }

    // MARK: AWAIT_STATE

    /// Waits until `client.connection.state == expected` (UTS `AWAIT_STATE`).
    func awaitConnectionState(_ client: ARTRealtime,
                              _ expected: ARTRealtimeConnectionState,
                              timeout: TimeInterval = defaultAwaitTimeout,
                              file: StaticString = #file,
                              line: UInt = #line) {
        poll("connection.state == \(ARTRealtimeConnectionStateToStr(expected))",
             timeout: timeout, file: file, line: line) {
            client.connection.state == expected
        }
    }

    /// Waits until `channel.state == expected` (UTS `AWAIT_STATE`).
    func awaitChannelState(_ channel: ARTRealtimeChannel,
                           _ expected: ARTRealtimeChannelState,
                           timeout: TimeInterval = defaultAwaitTimeout,
                           file: StaticString = #file,
                           line: UInt = #line) {
        poll("channel '\(channel.name)'.state == \(ARTRealtimeChannelStateToStr(expected))",
             timeout: timeout, file: file, line: line) {
            channel.state == expected
        }
    }

    /// Generic `AWAIT_STATE`: proceed immediately if `condition` already holds, otherwise poll until
    /// it does or `timeout` elapses (then fail). Used for non-state conditions such as "a frame has
    /// been sent". The small sleep just avoids a hot busy-loop.
    @discardableResult
    func poll(_ description: String,
              timeout: TimeInterval = defaultAwaitTimeout,
              file: StaticString = #file,
              line: UInt = #line,
              until condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline {
                XCTFail("Timed out after \(timeout)s awaiting: \(description)", file: file, line: line)
                return false
            }
            Thread.sleep(forTimeInterval: 0.0005)
        }
        return true
    }

    // MARK: Fake timers

    /// Advances the fake clock (UTS `ADVANCE_TIME`). Requires `enableFakeTimers()` to have been
    /// called — otherwise clients are on the real clock and there is nothing to advance.
    func advanceTime(byMilliseconds milliseconds: Double, file: StaticString = #file, line: UInt = #line) {
        guard let timeProvider else {
            XCTFail("advanceTime requires enableFakeTimers() before makeRealtime()", file: file, line: line)
            return
        }
        timeProvider.advanceTime(byMilliseconds: milliseconds)
    }

    /// Closes a client (UTS `CLOSE_CLIENT`).
    func closeClient(_ client: ARTRealtime) {
        client.close()
    }

    // MARK: Cleanup

    override func tearDown() {
        for client in clients {
            client.close()
        }
        timeProvider?.cancelAllScheduled()
        timeProvider = nil
        clients.removeAll()
        installedWebSocketProvider = nil
        installedMockHTTP = nil
        super.tearDown()
    }
}
