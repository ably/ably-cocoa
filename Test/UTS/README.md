# UTS — Universal Test Suite (ably-cocoa)

Tests derived from the language-neutral specs in [`ably/specification`](https://github.com/ably/specification) under [`uts/`](https://github.com/ably/specification/blob/main/uts).
This is a **standalone Swift Testing target** (`UTS`), separate from `AblyTests`, and deliberately does **not** depend on Nimble or XCTest. It is built in the **Swift 6 language mode** (strict concurrency checking) so the compiler catches data races in the harness and tests.

## Layout

```
Test/UTS/
  Harness/
    UTSTestCase.swift             # base case: installMock, makeRealtime/makeRest, awaitConnectionState/awaitChannelState, advanceTime
    MockWebSocket.swift           # MockWebSocketProvider (the spec's mock_ws) + MockWebSocket (fake socket) + factories
    MockHTTPClient.swift                # MockHTTPClient (fake ARTHTTPExecutor) + PendingHTTPConnection / PendingHTTPRequest
    MockTimeProvider.swift        # deterministic ARTTimeProvider (enable_fake_timers / ADVANCE_TIME)
    Captured.swift                # thread-safe collector for the spec's local captured_* arrays (Swift 6 safe)
    CapturingLog.swift            # ARTLog that records log lines for assertions
    NoOpReachability.swift        # disables OS network monitoring in unit tests
    ProtocolMessage.swift         # Sendable server-message factories (.connected/.attached/.error/.ack/.closed)
  Tests/
    ConnectionRecoveryTests.swift # RTN16
    TimeTests.swift               # RSC16
  deviations.md                   # SDK deviations found during evaluation
```

## How the harness maps the UTS primitives

| UTS pseudocode | cocoa mapping |
|---|---|
| `install_mock(mock_ws)` | `installMock(_:)` — registers the `MockWebSocketProvider`; the next `makeRealtime()` wires it into `ARTClientOptions.testOptions.transportFactory` (per-client DI). The mock is never passed to the constructor. |
| `mock_ws = MockWebSocket(onConnectionAttempt:)` | `MockWebSocketProvider(onConnectionAttempt:)` — builds a real `ARTWebSocketTransport` over a fake `MockWebSocket` per connection |
| `mock_ws.active_connection.respond_with_success()` / `send_to_client(...)` | `MockWebSocket.respondWithSuccess()` / `sendToClient(_:)` |
| `AWAIT_STATE conn.state == s` | `awaitConnectionState(client, s)` — poll until it holds or timeout (state getters sync onto the internal queue) |
| `AWAIT_STATE channel.state == s` | `awaitChannelState(channel, s)` |
| `enable_fake_timers()` / `ADVANCE_TIME(ms)` | shared `MockTimeProvider` / `advanceTime(byMilliseconds:)` |
| `// UTS: <id>` | comment immediately above each test method |

URL/query-param construction (`recover`, `resume`, `format`, …) is exercised by **real** SDK code;
only the socket is faked, through the `ARTWebSocketFactory` seam.

## Running

```bash
swift test --filter UTS
swift test --filter UTS.ConnectionRecoveryTests/<test_name>
```
