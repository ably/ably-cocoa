---
description: "Translate a UTS pseudocode test spec into Swift tests in the UTS target. Usage: /uts-to-swift <path-to-spec-file>"
allowed-tools: Bash, Read, Edit, Write
---

Translate the UTS pseudocode test spec at `$ARGUMENTS` into a runnable Swift test in the `UTS` test target (`Test/UTS`).

Reference: [Writing Derived Tests](https://raw.githubusercontent.com/ably/specification/refs/heads/main/uts/docs/writing-derived-tests.md)

---

## Step 0 — Validate arguments

**If `$ARGUMENTS` is empty or blank**, stop immediately and tell the user:

```
Usage: /uts-to-swift <path-to-spec-file>

Example:
  /uts-to-swift ../specification/uts/realtime/unit/connection/connection_recovery_test.md

Please re-run the command with the path to a UTS pseudocode spec file.
```

Do not proceed to Step 1.

**If `$ARGUMENTS` is provided but does not end in `.md`**, stop and tell the user:

```
Error: "<value>" does not look like a spec file path (expected a .md file).

Usage: /uts-to-swift <path-to-spec-file>
```

Do not proceed to Step 1.

**If `$ARGUMENTS` ends in `.md` but the file does not exist** (check with `test -f "$ARGUMENTS"`), stop and tell the user:

```
Error: file not found: "<value>"

Check the path and try again.
```

Do not proceed to Step 1.

Only continue to Step 1 once the file is confirmed to exist.

---

## Step 1 — Read the spec

Read the file at `$ARGUMENTS`. Identify:
- All test cases — each has a structured ID like `realtime/unit/RTN16g/recovery-key-structure-0` and a description.
- The protocol used (WebSocket for Realtime, HTTP for REST).
- Any timer usage (`enable_fake_timers`, `ADVANCE_TIME`).

---

## Step 2 — Determine output path and class name

Map the spec path to a test path:

| Spec location | Test location |
|---|---|
| `.../uts/rest/unit/<name>.md` | `Test/UTS/Tests/<Name>Tests.swift` |
| `.../uts/realtime/unit/<sub>/<name>.md` | `Test/UTS/Tests/<Name>Tests.swift` |

Class name: take the file name, strip a trailing `_test`, convert `snake_case` → `PascalCase`, append `Tests`. Example: `connection_recovery_test.md` → `ConnectionRecoveryTests`. All test classes are flat under `Test/UTS/Tests/` (no per-category subfolders) and subclass `UTSTestCase`.

If a suitable class already exists, add the new test methods to it rather than creating a duplicate.

---

## Step 3 — Read the harness

Read ALL files in `Test/UTS/Harness/` before generating any code (you need the exact method names/signatures).

---

## Step 4 — Generate the Swift test file

Apply the translation rules below, then write the file.

### Client construction

The mock is **installed first** (`installMock(_:)`), then the client is built with `makeRealtime`/`makeRest`. There is no default key — set `options.key` in the `configure` block. The harness already sets `autoConnect = false`, `useBinaryProtocol = false`, and dedicated internal/callback queues.

| Pseudocode | Swift |
|---|---|
| `Rest(options: ClientOptions(key: "..."))` | `installMock(mockHTTP)` then `let rest = makeRest { $0.key = "..." }` |
| `Realtime(options: ClientOptions(key: "...", autoConnect: false))` | `installMock(wsProvider)` then `let client = makeRealtime { $0.key = "..." }` |
| `recover: "..."` / `disconnectedRetryTimeout: 0.5` | set on `options` inside the `configure` block |
| `enable_fake_timers()` | `enableFakeTimers()` — **before** `makeRealtime`/`makeRest` (the clock is injected at construction) |

### Mock setup — WebSocket

Use the **handler pattern**: configure the simulated server in `onConnectionAttempt`. `respondWithSuccess()` opens the socket; `sendToClient(...)` delivers a message (two separate calls, unlike ably-java's combined `respondWithSuccess(msg)`).

```swift
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
let ws = try XCTUnwrap(wsProvider.activeConnection)   // the spec's active_connection
```

When attempts need different behaviour (e.g. first succeeds, reconnects refused), branch on a counter inside the handler:

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

```swift
var capturedRequests: [PendingHTTPRequest] = []
let mockHTTP = MockHTTP(
    onConnectionAttempt: { connection in connection.respondWithSuccess() },
    onRequest: { request in
        capturedRequests.append(request)
        request.respondWith(status: 200, body: [1234567890000])
    }
)
installMock(mockHTTP)
let rest = makeRest { $0.key = "app.key:secret" }
```

### Capturing connection attempts / requests (the spec's local-array pattern)

Per the spec ("Common Mistakes": use a **local** `captured_requests` array, not a mock property), append to a local `var` inside the handler and assert on that. Read it only after the operation has settled (after `awaitConnectionState` / the awaited completion):

```swift
var capturedConnectionAttempts: [MockWebSocket] = []
let wsProvider = MockWebSocketProvider(onConnectionAttempt: { connection in
    capturedConnectionAttempts.append(connection)
    connection.respondWithSuccess()
    connection.sendToClient(.connected(connectionId: "c", connectionKey: "k"))
})
// ... after awaitConnectionState(client, .connected):
XCTAssertEqual(capturedConnectionAttempts[0].queryParams["recover"], "...")
```

### Inspecting outgoing frames

Frames the SDK sent are decoded and recorded on the socket as `sentMessages`. Capture after the channel/connection state confirms the send happened:

```swift
let ws = try XCTUnwrap(wsProvider.activeConnection)   // the spec's active_connection
channelOne.attach()
ws.sendToClient(.attached(channel: "channel-one", channelSerial: "serial-1"))
awaitChannelState(channelOne, .attached)
let attachFrames = ws.sentMessages.filter { $0.action == .attach && $0.channel == "channel-one" }
XCTAssertEqual(attachFrames.count, 1)
XCTAssertEqual(attachFrames.first?.channelSerial, "serial-1")
```

### Mock method reference

`connection` is the object the relevant handler hands you — for WebSocket it's the `MockWebSocket` passed to `onConnectionAttempt` (the spec's `mock_ws`/`conn`); for HTTP it's the `PendingHTTPConnection` passed to the `MockHTTP` `onConnectionAttempt`. `request` is the `PendingHTTPRequest` passed to `onRequest`.

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

`ARTProtocolMessage` is built via the `+UTS` factories — never construct/populate it inline (add new one if needed instead):

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

`AWAIT_STATE x.state == ConnectionState.X` → `awaitConnectionState(client, .x)` (default 2s timeout, or `timeout:`). Channels: `awaitChannelState(channel, .attached)`. For other conditions (e.g. "a frame was sent") use `poll("description") { <bool> }`.

### Timer control

```swift
enableFakeTimers()                     // BEFORE makeRealtime/makeRest
let client = makeRealtime { ... }
// ...
advanceTime(byMilliseconds: 1500)      // fires due timers and settles the cascade
```

For multi-retry scenarios use the spec's loop (don't compute exact jumps):

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
XCTAssertTrue(log.contains(level: .error, message: "recovery key"))
```

### Comments and assertion fidelity

Carry over **every** comment from the spec pseudocode verbatim, as a `//` comment at the matching step — these explain *why* each step exists and must not be dropped or paraphrased.

Translate every spec `ASSERT`/`AWAIT` into a Swift assertion at the same place. If an assertion genuinely has no Swift equivalent (e.g. it checks a language-specific construct, or the SDK exposes no observable hook for it), **do not silently omit it** — keep the spec's comment/line and add a `//` note explaining why no assertion is emitted. Never delete the spec line.

```swift
// The recovery key should round-trip the connection id        ← spec comment, copied verbatim
XCTAssertEqual(recovered.connectionId, "connection-1")

// ASSERT connection.errorReason IS null
// (no assertion: ARTConnection exposes no errorReason getter in this state — see deviations.md)
```

A dropped or weakened assertion that is *not* annotated this way is a bug — Step 7 re-checks for it.

### Assertions

| Pseudocode | Swift |
|---|---|
| `ASSERT x == y` | `XCTAssertEqual(x, y)` |
| `ASSERT x IS NOT null` | `let x = try XCTUnwrap(optional)` (or `XCTAssertNotNil`) |
| `ASSERT x IS null` | `XCTAssertNil(x)` |
| `ASSERT "k" IN map` / `NOT IN` | `XCTAssertNotNil(map["k"])` / `XCTAssertNil(map["k"])` |
| `ASSERT list.length == N` | `XCTAssertEqual(list.count, N)` |
| `AWAIT op FAILS WITH error` | capture the error in the completion (via an `XCTestExpectation`) and assert `error.code` / `error.statusCode` |

Async REST calls (e.g. `rest.time { ... }`) are awaited with `XCTestExpectation` + `wait(for:timeout:)`.

### Test naming and annotation

- `// UTS: <spec-id>` comment immediately above each `func`.
- Method name: `test_<SPEC>_<description_with_underscores>` — keep the spec point intact, join words with underscores. Take description from the spec test title. Keep camelCase for symbol names.

```swift
// UTS: realtime/unit/RTN16g/recovery-key-structure-0
func test_RTN16g_createRecoveryKey_returns_a_recovery_key() throws {
    ...
}
```

### File template

```swift
import XCTest
import Ably
import Ably.Private

/// <Feature> (<spec points>)
/// Derived from <spec URL>
final class <Name>Tests: UTSTestCase {

    // UTS: <spec-id>
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

        XCTAssertEqual(client.connection.state, .connected)
        closeClient(client)
    }
}
```

Put helper methods for the test class into extension at the bottom of the file.

---

## Step 5 — Compile

```bash
swift build --build-tests
```

Fix any compilation errors and recompile until clean.

---

## Step 6 — Run tests

```bash
swift test --filter UTS.<ClassName>
# or a single test:
swift test --filter UTS.<ClassName>/<test_method_name>
```

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

**Env-gated skip (preferred)** — test contains spec-correct assertions but is skipped by default:

```swift
// DEVIATION: see deviations.md
try XCTSkipUnless(ProcessInfo.processInfo.environment["RUN_DEVIATIONS"] != nil)
// ... spec-correct setup and assertions (run only when RUN_DEVIATIONS is set) ...
```

Reproduce with `RUN_DEVIATIONS=1 swift test --filter UTS.<ClassName>/<method>`.

**Adapted assertion** — assert the SDK's actual behaviour to prevent regressions:

```swift
// DEVIATION: spec requires code 40106, SDK returns 40160 — see deviations.md
XCTAssertEqual(error.code, 40160)
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
- **Assertion completeness** — every `ASSERT`/`AWAIT`/observable outcome has a direct `XCTAssert*` / `awaitConnectionState` / `awaitChannelState` / `poll`; none silently dropped or weakened to a comment.
- **Setup fidelity** — client options, mock responses, timer setup, and the order of channel operations match the spec.
- **Spec comments copied** — the pseudocode's inline `#` comments are carried over as `//` comments at the matching steps.

### Deviation honesty

For any place where the generated test diverges from the spec pseudocode (adapted assertion, env-gated skip, or omitted step):
- A `// DEVIATION:` comment explains why
- The deviation is recorded in `deviations.md`

If you find gaps, fix them and re-run Steps 5–6 before finishing.
