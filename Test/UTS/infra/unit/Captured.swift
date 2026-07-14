import Foundation

/// A thread-safe collector for the spec's "local `captured_*` array" pattern
/// (`uts/.../helpers/mock_http.md` & `mock_websocket.md`, "Common Mistakes").
///
/// The mock handler closures (`onConnectionAttempt`, `onRequest`) are invoked by the SDK on its own
/// queues, while the test reads what was captured on the test thread. A plain local `var array`
/// captured into those `@Sendable` closures is a data race the Swift 6 compiler rejects; this small
/// lock-guarded, `Sendable` reference type lets a test keep a *local* collector (not a property on
/// the mock) while staying race-free.
final class Captured<Element>: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [Element] = []

    init() {}

    /// Records an element (called from a mock handler, on an SDK queue).
    func append(_ element: Element) {
        lock.lock()
        items.append(element)
        lock.unlock()
    }

    /// A snapshot of everything captured so far (read from the test thread, after the operation has settled).
    var all: [Element] {
        lock.lock(); defer { lock.unlock() }
        return items
    }

    var count: Int { all.count }
    var first: Element? { all.first }
    subscript(_ index: Int) -> Element { all[index] }
}
