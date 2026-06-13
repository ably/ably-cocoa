---
name: uts-to-swift
description: Translate a UTS (Universal Test Suite) pseudocode test spec into Swift tests in the UTS target. Run as /uts-to-swift <path-to-spec-file>
license: proprietary
allowed-tools: Bash, Read, Edit, Write
metadata:
  team: engineering
  version: "1.0.0"
  tags: testing, uts, swift, cocoa, ably-cocoa, test-translation
  marketplace: false
---

# UTS to Swift

Translate the UTS pseudocode test spec at `$ARGUMENTS` into a runnable Swift test in the `UTS` test target (`Test/UTS`).

Reference: [Writing Derived Tests](https://raw.githubusercontent.com/ably/specification/refs/heads/main/uts/docs/writing-derived-tests.md)

---

## Step 0 — Validate arguments

**If `$ARGUMENTS` is empty or blank**, stop immediately and tell the user:

```
Please re-run the command with the path to a UTS pseudocode spec file.

Usage: /uts-to-swift <path-to-spec-file> or /uts-to-swift <spec-file-url>  https://github.com/ably/specification/blob/main/uts/realtime/unit/connection/connection_recovery_test.md

Example:
   /uts-to-swift /path/to/spec/file.md
   /uts-to-swift https://github.com/ably/specification/blob/main/uts/realtime/unit/connection/connection_recovery_test.md

```

Do not proceed to Step 1.

**If `$ARGUMENTS` is provided but does not end in `.md`**, stop and tell the user:

```
Error: "<value>" does not look like a spec file path (expected a .md file).

```

Do not proceed to Step 1.

**If `$ARGUMENTS` ends in `.md` but the file does not exist** (check with `test -f "$ARGUMENTS"`), stop and tell the user:

```
Error: file not found: "<value>"

```

Do not proceed to Step 1.

Only continue to Step 1 once the file is confirmed to exist.

---

## Step 1 — Read the spec

Read the file at `$ARGUMENTS`. Identify all the test cases — each has a title, a structured `Test ID` like `realtime/unit/RTN16g/recovery-key-structure-0` and a requirement.

---

## Step 2 — Determine output path and class name

Map the spec path to a test path:

Mirror the spec's `uts/` directory layout under `Test/UTS/Tests/`: keep the same `rest`/`realtime` top-level folder and the `unit`/`integration` tier below it. This stops files that share a name in different parts of the spec from colliding (e.g. `uts/realtime/integration/auth.md` and `uts/rest/integration/auth.md`).

| Spec file | Test file |
|---|---|
| `.../uts/rest/unit/<name>.md` | `Test/UTS/Tests/rest/unit/<Name>Tests.swift` |
| `.../uts/realtime/unit/<sub>/<name>.md` | `Test/UTS/Tests/realtime/unit/<sub>/<Name>Tests.swift` |

Class name: take the file name, strip a trailing `_test`, convert `snake_case` → `PascalCase`, append `Tests`. Example: `connection_recovery_test.md` → `ConnectionRecoveryTests`. Each test is a **Swift Testing** suite — `@Suite(.serialized) final class <Name>Tests: UTSTestCase`.

If a suitable suite already exists, add the new test methods to it rather than creating a duplicate.

---

## Step 3 — Read the harness

Read ALL files in `Test/UTS/Harness/` before generating any code (you need the exact method names/signatures).

---

## Step 4 — Generate the Swift test file

Apply the translation rules below, then write the file.

### Client construction

Set `ClientOptions` fields (`key`, `autoConnect`, `recover`, `disconnectedRetryTimeout`, etc.) in the `makeRealtime`/`makeRest` configuration block. Set `options.key` to "app.key:secret".

| Pseudocode | Swift |
|---|---|
| `install_mock(mock_http)` / `install_mock(mock_ws)` | `installMock(mockHTTPClient)` / `installMock(wsProvider)` — **before** `makeRealtime`/`makeRest` (the mock is injected at construction) |
| `Rest(options: ClientOptions(key: "..."))` | `let rest = makeRest { $0.key = "..." }` |
| `Realtime(options: ClientOptions(key: "...", autoConnect: false))` | `let client = makeRealtime { $0.key = "..."; $0.autoConnect = false }` |
| `enable_fake_timers()` | `enableFakeTimers()` — **before** `makeRealtime`/`makeRest` (the clock is injected at construction) |

### Mock setup — WebSocket

Use the **handler pattern**: configure the simulated server in `onConnectionAttempt`. As in the spec, opening the socket and delivering the `CONNECTED` message are two separate calls — `respond_with_success()` then `send_to_client(...)`.

Spec pseudocode:

```pseudo
mock_ws = MockWebSocket(
  onConnectionAttempt: (conn) => {
    conn.respond_with_success()
    conn.send_to_client(ProtocolMessage(
      action: CONNECTED,
      connectionId: "connection-1",
      connectionKey: "key-abc-123",
      connectionDetails: ConnectionDetails(connectionKey: "key-abc-123")
    ))
  }
)
install_mock(mock_ws)
client = Realtime(options: ClientOptions(key: "appId.keyId:keySecret", autoConnect: false))
client.connect()
AWAIT_STATE client.connection.state == ConnectionState.connected
ws_connection = mock_ws.events.find(e => e.type == CONNECTION_SUCCESS).connection
```

Swift (the harness exposes `activeConnection` as the cocoa equivalent of the spec's `events.find(CONNECTION_SUCCESS).connection`):

```swift
let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
    connection.respondWithSuccess()
    connection.sendToClient(.connected(connectionId: "connection-1", connectionKey: "key-abc-123"))
})
installMock(wsProvider)
let client = makeRealtime { options in
    options.key = "appId.keyId:keySecret"
    options.autoConnect = false
}
client.connect()
awaitConnectionState(client, .connected)
let ws = try #require(wsProvider.activeConnection)
```

When attempts need different behaviour (e.g. first succeeds, reconnects refused), branch on a counter inside the handler:

Spec pseudocode:

```pseudo
connection_attempt_count = 0
mock_ws = MockWebSocket(
  onConnectionAttempt: (conn) => {
    connection_attempt_count++
    IF connection_attempt_count == 1:
      conn.respond_with_success()
      conn.send_to_client(ProtocolMessage(
        action: CONNECTED,
        connectionId: "conn-s",
        connectionKey: "key-s",
        connectionDetails: ConnectionDetails(connectionKey: "key-s", connectionStateTtl: 2000)
      ))
    ELSE:
      conn.respond_with_refused()
  }
)
```

Swift:

```swift
var attemptCount = 0
let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
    attemptCount += 1
    if attemptCount == 1 {
        connection.respondWithSuccess()
        connection.sendToClient(.connected(connectionId: "conn-s", connectionKey: "key-s", connectionStateTtl: 2))
    } else {
        connection.respondWithRefused()
    }
})
```

### Mock setup — HTTP

Spec pseudocode:

```pseudo
captured_requests = []
mock_http = MockHttpClient(
  onConnectionAttempt: (conn) => conn.respond_with_success(),
  onRequest: (req) => {
    captured_requests.push(req)
    req.respond_with(200, [1704067200000])
  }
)
install_mock(mock_http)
client = Rest(options: ClientOptions(key: "app.key:secret"))
```

Swift:

```swift
let capturedRequests = Captured<PendingHTTPRequest>()
let mockHTTPClient = MockHTTPClient(
    onConnectionAttempt: { connection in connection.respondWithSuccess() },
    onRequest: { request in
        capturedRequests.append(request)
        request.respondWith(status: 200, body: [1704067200000])
    }
)
installMock(mockHTTPClient)
let rest = makeRest { $0.key = "app.key:secret" }
```

### Variable declarations

Take spec variable names (adopted to camel case), for new ones, if needed don't use "noname" names (like "fields"), make the name concrete.

### Capturing connection attempts / requests

The target is built in the Swift 6 language mode. Since mock handler closures are`@Sendable` and run on the SDK's queues, a plain `var array` captured into them is a compile error (a data race). Use the harness's thread-safe (lock-guarded) `Captured<T>` instead:

Spec pseudocode:

```pseudo
captured_connection_attempts = []
mock_ws = MockWebSocket(
  onConnectionAttempt: (conn) => {
    captured_connection_attempts.append(conn)
    conn.respond_with_success()
    conn.send_to_client(ProtocolMessage(
      action: CONNECTED,
      connectionId: "c",
      connectionKey: "k",
      connectionDetails: ConnectionDetails(connectionKey: "k")
    ))
  }
)
# ... after AWAIT_STATE client.connection.state == ConnectionState.connected:
ASSERT captured_connection_attempts[0].url.query_params["recover"] == "..."
```

Swift:

```swift
let capturedConnectionAttempts = Captured<MockWebSocket>()
let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
    capturedConnectionAttempts.append(connection)
    connection.respondWithSuccess()
    connection.sendToClient(.connected(connectionId: "c", connectionKey: "k"))
})
// ... after awaitConnectionState(client, .connected):
#expect(capturedConnectionAttempts[0].queryParams["recover"] == "...")
```

`Captured<T>` exposes `append`, `all`, `count`, `first`, and `subscript(Int)`. Use `capturedConnectionAttempts.count` to change outcome for different connection attemts.

### Inspecting outgoing frames

The spec inspects client-sent frames through the mock's event timeline (`mock_ws.events.filter(e => e.type == "ws_frame" AND e.direction == "client_to_server")`); the cocoa harness exposes the decoded equivalent as `ws.sentMessages`. Capture after the channel/connection state confirms the send happened:

Spec pseudocode:

```pseudo
ws_connection = mock_ws.events.find(e => e.type == CONNECTION_SUCCESS).connection
channel.attach()
ws_connection.send_to_client(ProtocolMessage(action: ATTACHED, channel: "channel-one", channelSerial: "serial-1"))
AWAIT_STATE channel.state == ChannelState.attached
sent_frames = mock_ws.events.filter(e => e.type == "ws_frame" AND e.direction == "client_to_server")
attach_frame = sent_frames.find(f => f.message.action == ATTACH AND f.message.channel == "channel-one")
ASSERT attach_frame.message.channelSerial == "serial-1"
```

Swift:

```swift
let ws = try #require(wsProvider.activeConnection)
channelOne.attach()
ws.sendToClient(.attached(channel: "channel-one", channelSerial: "serial-1"))
awaitChannelState(channelOne, .attached)
// cocoa's decoded equivalent of the spec's events.filter(ws_frame, client_to_server)
let attachFrames = ws.sentMessages.filter { $0.action == .attach && $0.channel == "channel-one" }
#expect(attachFrames.count == 1)
#expect(attachFrames.first?.channelSerial == "serial-1")
```

### Mock method reference

`connection` is the object the relevant handler hands you — for WebSocket it's the `MockWebSocket` passed to `onConnectionAttempt` (the spec's `mock_ws`/`conn`); for HTTP it's the `PendingHTTPConnection` passed to the `MockHTTPClient` `onConnectionAttempt`. `request` is the `PendingHTTPRequest` passed to `onRequest`.

| Pseudocode | Swift |
|---|---|
| `conn.respond_with_success()` | `connection.respondWithSuccess()` |
| `conn.respond_with_refused()` | `connection.respondWithRefused()` |
| `mock_ws.send_to_client(msg)` | `connection.sendToClient(msg)` |
| `mock_ws.send_to_client_and_close(msg)` | `connection.sendToClientAndClose(msg)` |
| `mock_ws.simulate_disconnect()` | `connection.simulateDisconnect()` |
| `req.respond_with(200, {...})` | `request.respondWith(status: 200, body: [...])` |
| `req.respond_with_timeout()` | `request.respondWithTimeout()` |
| `conn.respond_with_refused/timeout/dns_error()` (HTTP) | `connection.respondWithRefused()` / `respondWithTimeout()` / `respondWithDNSError()` |

### Protocol messages and types

Server-to-client messages are described with the `Sendable` `ProtocolMessage` factories — `sendToClient`/`sendToClientAndClose` take a `ProtocolMessage` and build the real `ARTProtocolMessage` at delivery, so no non-Sendable value crosses the queue hop. Use these factories; add a new one (and the matching `makeProtocolMessage()` case) if you need another action:

| Pseudocode | Swift |
|---|---|
| `ProtocolMessage(action: CONNECTED, connectionId, connectionKey, connectionDetails(...))` | `.connected(connectionId:, connectionKey:, maxIdleInterval:, connectionStateTtl:)` |
| `ProtocolMessage(action: ATTACHED, channel, channelSerial)` | `.attached(channel:, channelSerial:)` |
| `ProtocolMessage(action: ERROR, error: ErrorInfo(code, statusCode, message))` | `.error(code:, statusCode:, message:)` |
| `ProtocolMessage(action: ACK, msgSerial, count)` | `.ack(msgSerial:, count:)` |
| `ProtocolMessage(action: CLOSED)` | `.closed()` |
| `connectionStateTtl: 2000` (wire ms) | seconds here: `connectionStateTtl: 2` |
| `ConnectionState.connected` / `ChannelState.attached` | `.connected` / `.attached` (`ARTRealtimeConnectionState` / `ARTRealtimeChannelState`) |

### Awaiting state

`AWAIT_STATE x.state == ConnectionState.X` → `awaitConnectionState(client, .x)` (default 2s timeout, or `timeout:`). Channels: `awaitChannelState(channel, .attached)`. For other conditions (e.g. "a frame was sent") use `poll("description") { <bool> }`. Don't use poll unless you can't find alternative or spec says to do so.

### Timer control

Spec pseudocode:

```pseudo
client = Realtime(...)
# ...
enable_fake_timers()
# ...
ADVANCE_TIME(1500)                     # fires due timers
```

Swift:

```swift
enableFakeTimers()                     // BEFORE makeRealtime/makeRest
let client = makeRealtime { ... }
// ...
advanceTime(byMilliseconds: 1500)      // fires due timers and settles the cascade
```

For multi-retry scenarios use the spec's loop (don't compute exact jumps):

Spec pseudocode:

```pseudo
LOOP up to 10 times:
  ADVANCE_TIME(1500)
  IF client.connection.state == ConnectionState.suspended:
    BREAK
AWAIT_STATE client.connection.state == ConnectionState.suspended
```

Swift:

```swift
for _ in 0..<10 {
    advanceTime(byMilliseconds: 1500)
    if client.connection.state == .suspended { break }
}
awaitConnectionState(client, .suspended)
```

### Asserting on logs

To assert "an error is logged", inject a `CapturingLog` and check it:

```swift
let log = CapturingLog()
let client = makeRealtime { $0.key = "..."; $0.logHandler = log }
// ...
#expect(log.contains(level: .error, message: "recovery key"))
```

### Comments and assertion fidelity

Carry over **every** comment from the spec pseudocode verbatim, as a `//` comment at the matching step — these explain *why* each step exists and must not be dropped or paraphrased.

Translate every spec `ASSERT`/`AWAIT` into a Swift assertion at the same place. If an assertion genuinely has no Swift equivalent (e.g. it checks a language-specific construct, or the SDK exposes no observable hook for it), **do not silently omit it** — keep the spec's comment/line and add a `//` note explaining why no assertion is emitted. Never delete the spec line.

```swift
// The recovery key should round-trip the connection id        ← spec comment, copied verbatim
#expect(recovered.connectionId == "connection-1")

// ASSERT connection.errorReason IS null
// (no assertion: ARTConnection exposes no errorReason getter in this state — see deviations.md)
```

A dropped or weakened assertion that is *not* annotated this way is a bug — Step 7 re-checks for it.

### Assertions (Swift Testing)

Use Swift Testing macros (`import Testing`, **not** `XCTest`):

| Pseudocode | Swift |
|---|---|
| `ASSERT x == y` | `#expect(x == y)` |
| `ASSERT x IS NOT null` | `let x = try #require(optional)` (or `#expect(x != nil)`) |
| `ASSERT x IS null` | `#expect(x == nil)` |
| `ASSERT "k" IN map` / `NOT IN` | `#expect(map["k"] != nil)` / `#expect(map["k"] == nil)` |
| `ASSERT list.length == N` | `#expect(list.count == N)` |
| `ASSERT x == y (with message)` | `#expect(x == y, "message")` |
| `AWAIT op FAILS WITH error` | capture the error (see async below) and `#expect(error.code == ...)` / `#expect(error.statusCode == ...)` |

`#expect(...)` records a failure and continues; `try #require(...)` unwraps/asserts and stops the test on failure (use it when later lines depend on the value, like `XCTUnwrap`).

REST calls will callback (e.g. `rest.time { ... }`) — make the test `async throws` and create a helper method that bridges the completion handler with a continuation:

```swift
private func awaitTime(_ rest: ARTRest, sourceLocation: SourceLocation = #_sourceLocation) async -> Date {
    await withCheckedContinuation { (continuation: CheckedContinuation<Date, Never>) in
        rest.time { date, error in
            if let error { Issue.record("time() failed: \(error)", sourceLocation: sourceLocation) }
            guard let date else { Issue.record("time() failed: date should not be nil", sourceLocation: sourceLocation) }
            continuation.resume(returning: date)   // resume exactly once
        }
    }
}
```

Put these `async` helpers in the test class extention at the bottom of the test file. Inside the harness, report non-assertion failures (timeouts, unexpected errors) with `Issue.record("...", sourceLocation:)`.

### Test naming and annotation

- `// UTS: <spec-id>` comment immediately above each test, then the `@Test` attribute.
- Method name: `test_<SPEC>_<description_with_underscores>` — keep the spec point intact, join words with underscores. Take the description from the spec test title. Keep camelCase for symbol names. Mark the function `throws` (and `async` if it awaits).

```swift
// UTS: realtime/unit/RTN16g/recovery-key-structure-0
@Test
func test_RTN16g_createRecoveryKey_returns_a_recovery_key() throws {
    ...
}
```

### File template

```swift
import Testing
import Foundation
import Ably
import Ably.Private

/// <Feature> (<spec points>)
/// Derived from <spec URL>
@Suite(.serialized)
final class <Name>Tests: UTSTestCase {

    // UTS: <spec-id>
    @Test
    func test_<SPEC>_<description>() throws {
        let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
            connection.respondWithSuccess()
            connection.sendToClient(.connected(connectionId: "connection-1", connectionKey: "key-1"))
        })
        installMock(wsProvider)
        let client = makeRealtime { options in
            options.key = "appId.keyId:keySecret"
        }

        client.connect()
        awaitConnectionState(client, .connected)

        #expect(client.connection.state == .connected)
        closeClient(client)
    }
}
```

Helper methods return types should be ready for use in the test code without additional casting (if you need "value as? String" in the test, move this convertion to the helper instead). Don't return optionals from these methods - assert not `nil` within the method itself, unless test expects optional. Don't create additional helper types for parsing dictionaries - just use a dictionary with the most suited type for the test, accessing its fields by subscript. For dictionaries containing values of different types use `[String: Any]`. Don't wrap dictionary constant initialization into helper method. Put helper methods for the suite into an extension at the bottom of the file. Keep the spec's original tests order in the generated test file. Keep test segmentation by adding comments like "// Setup", "// Test Steps", "// Assertions".

---

## Step 5 — Compile

```bash
swift build --build-tests
```

Fix any compilation errors and recompile until clean.

---

## Step 6 — Run tests

```bash
swift test --filter <ClassName>
# or a single test (Swift Testing matches the function name):
swift test --filter <ClassName>/<test_method_name>
```

(`--filter` takes a regex over test names; `swift test --filter UTS` runs the whole suite.)

Handle failures using this decision tree (see [reference doc](https://github.com/ably/specification/blob/main/uts/docs/writing-derived-tests.md)):

```
Test fails
  |
  +-- Does the UTS spec match the features spec?
  |     NO  → fix the test, record the UTS spec error in deviations.md
  |     YES
  |       +-- Does the test accurately translate the UTS spec?
  |             NO  → fix the test (no deviation entry)
  |             YES → SDK deviation — adapt the test, record in deviations.md
```

### Deviation patterns

**Env-gated skip (preferred)** — test contains spec-correct assertions but is disabled by default via the Swift Testing `.enabled(if:)` trait, so it only runs when `RUN_DEVIATIONS` is set:

```swift
// DEVIATION: see deviations.md
@Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil))
func test_<SPEC>_...() throws {
    // ... spec-correct setup and assertions ...
}
```

Reproduce with `RUN_DEVIATIONS=1 swift test --filter <ClassName>/<method>`.

**Adapted assertion** — assert the SDK's actual behaviour to prevent regressions:

```swift
// DEVIATION: spec requires code 40106, SDK returns 40160 — see deviations.md
#expect(error.code == 40160)
```

**Never use the accommodate-both pattern** Every test must assert either spec behaviour or the SDK's actual behaviour — never both at once.

Note: a *harness-driving* difference (e.g. using fake timers where the spec uses real ones, or a queue-ordering workaround) is **not** an SDK deviation — explain it in a code comment, not `deviations.md`. `deviations.md` is only for SDK non-compliance and mock-capability gaps.

### Deviations file

Append to `Test/UTS/deviations.md` under the matching section (Failing Tests / Adapted Tests / Mock Infrastructure Limitations). Each entry needs:

1. The spec point (e.g. `RSA4c2`)
2. What the spec says
3. What the SDK does
4. Which test is affected and how it was adapted

---

## Step 7 — Review generated output against the spec

Re-read the original spec and the generated Swift test side-by-side. Fix anything that fails a check before declaring the task done.

- **Coverage** — every spec test-case ID has a `func` with a matching `// UTS:` comment and a descriptive name.
- **Assertion completeness** — every `ASSERT`/`AWAIT`/observable outcome has a direct `#expect` / `#require` / `awaitConnectionState` / `awaitChannelState` / `poll`; none silently dropped or weakened to a comment.
- **Setup fidelity** — client options, mock responses, timer setup, and the order of channel operations match the spec.
- **Spec comments copied** — the pseudocode's inline `#` comments are carried over as `//` comments at the matching steps verbatim.

### Deviation honesty

For any place where the generated test diverges from the spec pseudocode (adapted assertion, env-gated skip, or omitted step):
- A `// DEVIATION:` comment explains why
- The deviation is recorded in `deviations.md`

If you find gaps, fix them and re-run Steps 5–6 before finishing.
