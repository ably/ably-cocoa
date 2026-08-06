import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
import Foundation
import Testing

/// Tests for the Phase 5 public `RealtimeObject` surface (`PublicDefaultRealtimeObject`): `get()`
/// (RTO23), `on(event:callback:)` / `StatusSubscription.off()` (RTO18), the dispose lifecycle
/// and `PublicObjectsStore` proxy identity.
///
/// Everything is driven through a real `InternalDefaultRealtimeObjects` (the proxied engine) plus a
/// `MockCoreSDK`; sync is completed by feeding the engine an OBJECT_SYNC / ATTACHED directly.
struct PublicRealtimeObjectTests {
    // MARK: - Helpers

    /// A minimal thread-safe call counter for asserting on asynchronously-delivered callbacks.
    private final class CallCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        func increment() { lock.withLock { value += 1 } }
        var isEmpty: Bool { lock.withLock { value == 0 } }
    }

    private static func makeProxied(internalQueue: DispatchQueue) -> InternalDefaultRealtimeObjects {
        InternalDefaultRealtimeObjects(
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    private static func makePublicObject(
        channelState: _AblyPluginSupportPrivate.RealtimeChannelState = .attached,
    ) -> (publicObject: PublicDefaultRealtimeObject, proxied: InternalDefaultRealtimeObjects, coreSDK: MockCoreSDK, internalQueue: DispatchQueue) {
        let internalQueue = TestFactories.createInternalQueue()
        let proxied = makeProxied(internalQueue: internalQueue)
        let coreSDK = MockCoreSDK(channelState: channelState, internalQueue: internalQueue)
        let publicObject = PublicDefaultRealtimeObject(proxied: proxied, coreSDK: coreSDK, logger: TestLogger())
        return (publicObject, proxied, coreSDK, internalQueue)
    }

    /// Drives the engine to `.synced` via a self-contained empty OBJECT_SYNC (RTO5a5), which
    /// transitions Initialized -> Syncing -> Synced.
    private static func driveToSynced(_ proxied: InternalDefaultRealtimeObjects, on internalQueue: DispatchQueue) {
        internalQueue.ably_syncNoDeadlock {
            proxied.nosync_handleObjectSyncProtocolMessage(objectMessages: [], protocolMessageChannelSerial: nil)
        }
    }

    // MARK: - get() (RTO23)

    // @spec RTO23d - get() returns a LiveMapPathObject rooted at the root map (empty path) once synced
    @Test
    func getReturnsRootPathObjectWhenSynced() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        Self.driveToSynced(proxied, on: internalQueue)

        let root = try await publicObject.get()

        // RTO23d / RTPO4c - the root path object has an empty (zero-segment) path.
        #expect(root.path.isEmpty)
        // It resolves to the channel's root map.
        #expect(try root.exists())
        #expect(try root.type() == .liveMap)
    }

    // @spec RTO23c - get() waits for the initial sync to complete, then resolves
    @Test
    func getWaitsForSyncThenResolves() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        // Start get() before the sync completes - it should wait.
        async let getTask = publicObject.get()

        // Confirm it has started waiting for sync.
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        // Now complete the sync; the waiting get() should resolve.
        Self.driveToSynced(proxied, on: internalQueue)

        let root = try await getTask
        #expect(root.path.isEmpty)
    }

    // @spec RTO4b - get() resolves via an ATTACHED with HAS_OBJECTS false (no-objects sync completion)
    @Test
    func getResolvesAfterNoObjectsAttach() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        async let getTask = publicObject.get()
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        // RTO4b: ATTACHED with HAS_OBJECTS false completes the sync immediately.
        internalQueue.ably_syncNoDeadlock {
            proxied.nosync_onChannelAttached(hasObjects: false)
        }

        let root = try await getTask
        #expect(root.path.isEmpty)
        // A no-objects root is an empty map.
        #expect(try root.size() == 0)
    }

    // @spec RTO23c - get() waiting for sync fails with 92008 if the channel leaves a usable state (RTO20e1)
    @Test
    func getThrows92008WhenChannelFailsDuringWait() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        async let getTask = publicObject.get()
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        // The channel enters FAILED while get() is waiting for sync.
        internalQueue.ably_syncNoDeadlock {
            proxied.nosync_onChannelStateChanged(toState: .failed, reason: nil)
        }

        do {
            _ = try await getTask
            Issue.record("Expected get() to throw when the channel fails during the sync wait")
        } catch {
            #expect((error as? ARTErrorInfo)?.code == 92008)
        }
    }

    // @spec RTL33c - get() on a FAILED channel is rejected before waiting for sync
    @Test
    func getOnFailedChannelThrows() async throws {
        let (publicObject, _, _, _) = Self.makePublicObject(channelState: .failed)

        await #expect(throws: ARTErrorInfo.self) {
            _ = try await publicObject.get()
        }
    }

    // @spec RTL33b - get() on a not-yet-attached channel implicitly attaches (RTL33b), then resolves
    // after sync. Mirrors ably-java Helpers.kt `ensureAttached`/`attachAsync`.
    @Test
    func getImplicitlyAttachesNonAttachedChannelThenResolves() async throws {
        let (publicObject, proxied, coreSDK, internalQueue) = Self.makePublicObject(channelState: .initialized)

        // Record that the RTL33b implicit attach is initiated (and resolve it successfully).
        let attachCalled = CallCounter()
        coreSDK.setAttachHandler { callback in
            attachCalled.increment()
            callback(nil)
        }

        // get() should implicitly attach, then wait for sync.
        async let getTask = publicObject.get()
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        // The implicit attach was initiated (RTL33b) before the sync wait.
        #expect(!attachCalled.isEmpty)

        // Completing the sync resolves the waiting get().
        Self.driveToSynced(proxied, on: internalQueue)
        let root = try await getTask
        #expect(root.path.isEmpty)
    }

    // @spec RTL33a - get() on an already-ATTACHED channel performs no implicit attach.
    @Test
    func getOnAttachedChannelDoesNotImplicitlyAttach() async throws {
        let (publicObject, proxied, coreSDK, internalQueue) = Self.makePublicObject(channelState: .attached)

        let attachCalled = CallCounter()
        coreSDK.setAttachHandler { callback in
            attachCalled.increment()
            callback(nil)
        }

        Self.driveToSynced(proxied, on: internalQueue)
        _ = try await publicObject.get()

        // RTL33a: an ATTACHED channel is already usable, so no attach is performed.
        #expect(attachCalled.isEmpty)
    }

    // @spec RTL33b1 - a failed implicit attach propagates the attach error out of get().
    @Test
    func getPropagatesImplicitAttachFailure() async throws {
        let (publicObject, _, coreSDK, _) = Self.makePublicObject(channelState: .detached)

        let attachError = ARTErrorInfo.create(withCode: 90000, message: "attach failed")
        coreSDK.setAttachHandler { callback in
            callback(attachError)
        }

        do {
            _ = try await publicObject.get()
            Issue.record("Expected get() to rethrow the implicit-attach failure (RTL33b1)")
        } catch {
            #expect(error.code == 90000)
        }
    }

    // MARK: - on(event:callback:) / StatusSubscription (RTO18)

    // @spec RTO18 - on(.synced) fires when the sync completes
    @Test
    func onSyncedFires() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            publicObject.on(event: .synced) {
                continuation.resume()
            }
            Self.driveToSynced(proxied, on: internalQueue)
        }
    }

    // @spec RTO18 - on(.syncing) fires when a sync starts
    @Test
    func onSyncingFires() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            publicObject.on(event: .syncing) {
                continuation.resume()
            }
            Self.driveToSynced(proxied, on: internalQueue)
        }
    }

    // @spec RTO18f1 - off() deregisters the status listener; it is not called for subsequent events
    @Test
    func offStopsStatusCallbacks() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        let counter = CallCounter()

        let subscription = publicObject.on(event: .synced) {
            counter.increment()
        }
        // Deregister before any event is emitted.
        subscription.off()

        Self.driveToSynced(proxied, on: internalQueue)

        // Allow any (erroneously) scheduled callback to be delivered on the callback queue.
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(counter.isEmpty)
    }

    // MARK: - Dispose lifecycle

    // dispose() fails a get() that is waiting for sync, but the instance remains usable for a later get()
    @Test
    func disposeCancelsWaitingGetAndInstanceStaysUsable() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        // Start get() - it waits (not yet synced).
        async let getTask = publicObject.get()
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        // Dispose cancels the in-flight wait (surfacing 92008).
        proxied.dispose()
        do {
            _ = try await getTask
            Issue.record("Expected the in-flight get() to be cancelled by dispose()")
        } catch {
            #expect((error as? ARTErrorInfo)?.code == 92008)
        }

        // The instance stays usable: complete a sync and a fresh get() resolves.
        Self.driveToSynced(proxied, on: internalQueue)
        let root = try await publicObject.get()
        #expect(root.path.isEmpty)
    }

    // A channel release (`channels.release()`, routed through the plugin's
    // `nosync_onChannelRelease:` hook → `nosync_disposeForChannelRelease`) fails a get() waiting for sync
    // with 92008 whose *cause* is the release-specific 40000 error — distinct from `deinit`/`dispose()`,
    // which fail waiters with no cause. The instance stays usable for a later get() (scope-survives).
    @Test
    func channelReleaseFailsWaitingGetWithReleaseCause() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        // Start get() - it waits (not yet synced).
        async let getTask = publicObject.get()
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        // Simulate the core SDK's channel-release notification (on the internal queue, as the core does).
        internalQueue.ably_syncNoDeadlock {
            proxied.nosync_disposeForChannelRelease()
        }

        do {
            _ = try await getTask
            Issue.record("Expected the in-flight get() to be failed by the channel release")
        } catch {
            let artError = try #require(error as? ARTErrorInfo)
            #expect(artError.code == 92008)
            // The release-specific cause distinguishes this from a plain dispose()/deinit teardown.
            let cause = try #require(artError.cause)
            #expect(cause.code == 40000)
            #expect(cause.message == "Channel has been released using channels.release()")
        }

        // The instance stays usable: complete a sync and a fresh get() resolves.
        Self.driveToSynced(proxied, on: internalQueue)
        let root = try await publicObject.get()
        #expect(root.path.isEmpty)
    }

    // dispose() drops status subscriptions; a later on()/off() still works (instance usable)
    @Test
    func disposeDropsStatusSubscriptionsButOnStillWorks() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        let preDisposeCounter = CallCounter()

        publicObject.on(event: .synced) { preDisposeCounter.increment() }

        // Dispose drops the existing subscription.
        proxied.dispose()

        // A subscription registered after dispose still receives events.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            publicObject.on(event: .synced) {
                continuation.resume()
            }
            Self.driveToSynced(proxied, on: internalQueue)
        }

        // The pre-dispose subscription was dropped and never fired.
        #expect(preDisposeCounter.isEmpty)
    }

    // MARK: - PublicObjectsStore proxy identity

    // The store returns the same public object across repeated fetches for the same proxied engine.
    @Test
    func publicObjectsStoreReturnsSameInstanceForSameProxied() {
        let store = PublicObjectsStore()
        let internalQueue = TestFactories.createInternalQueue()
        let proxied = Self.makeProxied(internalQueue: internalQueue)
        let coreSDK = MockCoreSDK(channelState: .attached, internalQueue: internalQueue)
        let args = PublicObjectsStore.RealtimeObjectCreationArgs(coreSDK: coreSDK, logger: TestLogger())

        let first = store.getOrCreateRealtimeObject(proxying: proxied, creationArgs: args)
        let second = store.getOrCreateRealtimeObject(proxying: proxied, creationArgs: args)

        #expect(first === second)
    }

    // Distinct proxied engines get distinct public objects.
    @Test
    func publicObjectsStoreReturnsDistinctInstancesForDifferentProxied() {
        let store = PublicObjectsStore()
        let internalQueue = TestFactories.createInternalQueue()
        let coreSDK = MockCoreSDK(channelState: .attached, internalQueue: internalQueue)
        let args = PublicObjectsStore.RealtimeObjectCreationArgs(coreSDK: coreSDK, logger: TestLogger())

        let proxiedA = Self.makeProxied(internalQueue: internalQueue)
        let proxiedB = Self.makeProxied(internalQueue: internalQueue)

        let a = store.getOrCreateRealtimeObject(proxying: proxiedA, creationArgs: args)
        let b = store.getOrCreateRealtimeObject(proxying: proxiedB, creationArgs: args)

        #expect(a !== b)
    }

    // MARK: - Trap-free surface smoke

    // Every public `RealtimeObject` entry point is callable without trapping.
    @Test
    func trapFreeSurfaceSmoke() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        Self.driveToSynced(proxied, on: internalQueue)

        // get()
        let root = try await publicObject.get()
        #expect(root.path.isEmpty)

        // on(event:callback:) + StatusSubscription.off()
        let subscription = publicObject.on(event: .synced) {}
        subscription.off()
        // off() is idempotent.
        subscription.off()
    }
}
