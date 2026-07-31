// @UTS objects/unit/parent_references.md
//
// Port of the parent-reference graph spec (RTLO3f, RTLO4g, RTLO4h, RTLO4f) and the RTO5c10
// post-sync rebuild. `parentReferences` is a `Dict<String, Set<String>>` keyed by parent
// InternalLiveMap objectId; each value is the set of keys at which that map references this object.
// `getFullPaths` walks these reverse edges to enumerate every key-path from root.
//
// Deviations from the UTS spec:
// - (D-1) The spec constructs `InternalLiveCounter(objectId:)` / `InternalLiveMap(objectId:,
//   semantics:)`. The Swift live objects need a logger/queue/callback-queue/clock, so each is built
//   via `InternalDefaultLiveCounter.createZeroValued(...)` / `InternalDefaultLiveMap.createZeroValued(...)`
//   (see the `makeCounter` / `makeMap` helpers). Semantics default to LWW as in the spec.
// - (D-2) Spec reads `obj.parentReferences`; the Swift equivalent is the queue-hopping accessor
//   `obj.testsOnly_parentReferences`. Spec assignment `obj.parentReferences = {…}` maps to
//   `obj.testsOnly_setParentReferences(_:)`.
// - (D-3) Spec `obj.addParentReference(parent, key)` / `removeParentReference(parent, key)` take the
//   parent *object* and derive its objectId. The Swift `nosync_addParentReference(parentObjectID:key:)`
//   / `nosync_removeParentReference(parentObjectID:key:)` take the parent's objectId string directly,
//   and (being `nosync_`) must run on the internal queue, so every call is wrapped in
//   `internalQueue.ably_syncNoDeadlock { }`.
// - (D-4) Spec `obj.getFullPaths()` is a method on the live object. Per audit deviation DEV-15 the RTLO4f
//   DFS lives on `ObjectsPool.nosync_getFullPaths(forObjectID:)` (Kotlin's in-object DFS re-enters the
//   starting object's mutex — a Swift exclusive-access crash). The per-object wrapper
//   `obj.testsOnly_getFullPaths(objectsPool:)` forwards to the pool, so every `obj.getFullPaths()`
//   maps to `obj.testsOnly_getFullPaths(objectsPool: pool)`.
// - (D-5) Spec pool subscript: `pool["id"] = obj` maps to `pool.testsOnly_setEntry(.counter(obj) /
//   .map(obj), forObjectID: "id")`; `pool["root"]` maps to `pool.root`; a read `pool["id"]` maps to
//   `pool.entries[id]` (unwrapped via `#require`, then `.counterValue` / `.mapValue`).
// - (D-6) Spec `Dict<String, Set<String>>` maps 1:1 to Swift `[String: Set<String>]`; `== {}` is
//   asserted as `.isEmpty`, `== {"score"}` as `== ["score"]`.
//   Note (update-model enrichment / strengthen pass): unlike the map parent-reference port, the
//   `parent_references.md` spec asserts NOTHING about `update.objectMessage` or `update.tombstone`
//   (its cases are pure graph/DFS/rebuild operations that return no LiveObjectUpdate), so there are
//   no such assertions to add here.
// - (D-7) The RTO5c10 rebuild spec drives the pool via `processAttached(…)` + `processObjectSync(
//   build_object_sync_message(…))`. The Swift pool exposes the post-sync path via
//   `nosync_applySyncObjectsPool(_:logger:internalQueue:userCallbackQueue:clock:)`, which performs the
//   RTO5c10 rebuild at its tail (`nosync_rebuildParentReferences()`). Sync object states are built with
//   `TestFactories.mapObjectState` / `counterObjectState` and wrapped via `SyncObjectsPool.testsOnly_fromStates(…)`.
//   There is no observable `syncState == SYNCED` at this layer, so that assertion is omitted; the rebuild
//   itself is exercised directly.

@testable import AblyLiveObjects
import Foundation
import Testing

struct ParentReferencesUTSTests {
    // MARK: - Helpers (D-1)

    private static func makeCounter(objectID: String, internalQueue: DispatchQueue) -> InternalDefaultLiveCounter {
        InternalDefaultLiveCounter.createZeroValued(
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    private static func makeMap(objectID: String, internalQueue: DispatchQueue) -> InternalDefaultLiveMap {
        InternalDefaultLiveMap.createZeroValued(
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    private static func makePool(internalQueue: DispatchQueue) -> ObjectsPool {
        ObjectsPool(logger: TestLogger(), internalQueue: internalQueue, userCallbackQueue: .main, clock: MockSimpleClock())
    }

    // MARK: - RTLO3f2: parentReferences initialized to empty map

    // @UTS objects/unit/RTLO3f2/init-empty-counter-0
    @Test
    func parentReferencesInitEmptyCounter() {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        #expect(counter.testsOnly_parentReferences.isEmpty)
    }

    // @UTS objects/unit/RTLO3f2/init-empty-map-0
    @Test
    func parentReferencesInitEmptyMap() {
        let internalQueue = TestFactories.createInternalQueue()
        let map = Self.makeMap(objectID: "map:abc@1000", internalQueue: internalQueue)

        #expect(map.testsOnly_parentReferences.isEmpty)
    }

    // MARK: - RTLO4g: addParentReference

    // @UTS objects/unit/RTLO4g2/first-reference-new-entry-0
    @Test
    func addParentReferenceCreatesNewEntryForFirstReference() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)

        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: "map:parent@1000", key: "score")
        }

        #expect(child.testsOnly_parentReferences["map:parent@1000"] == ["score"])
    }

    // @UTS objects/unit/RTLO4g1/second-key-same-parent-0
    @Test
    func addParentReferenceAddsKeyToExistingEntry() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        child.testsOnly_setParentReferences(["map:parent@1000": ["score"]])

        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: "map:parent@1000", key: "points")
        }

        #expect(child.testsOnly_parentReferences["map:parent@1000"] == ["score", "points"])
    }

    // @UTS objects/unit/RTLO4g/different-parent-separate-entry-0
    @Test
    func addParentReferenceDifferentParentCreatesSeparateEntry() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)

        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: "map:a@1000", key: "x")
            child.nosync_addParentReference(parentObjectID: "map:b@1000", key: "y")
        }

        #expect(child.testsOnly_parentReferences["map:a@1000"] == ["x"])
        #expect(child.testsOnly_parentReferences["map:b@1000"] == ["y"])
    }

    // @UTS objects/unit/RTLO4g/multiple-parents-multiple-keys-0
    @Test
    func addParentReferenceMultipleParentsMultipleKeys() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)

        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: "map:a@1000", key: "x")
            child.nosync_addParentReference(parentObjectID: "map:a@1000", key: "y")
            child.nosync_addParentReference(parentObjectID: "map:b@1000", key: "p")
            child.nosync_addParentReference(parentObjectID: "map:b@1000", key: "q")
        }

        #expect(child.testsOnly_parentReferences["map:a@1000"] == ["x", "y"])
        #expect(child.testsOnly_parentReferences["map:b@1000"] == ["p", "q"])
    }

    // MARK: - RTLO4h: removeParentReference

    // @UTS objects/unit/RTLO4h1/nonexistent-parent-noop-0
    @Test
    func removeParentReferenceNoopForNonexistentParent() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)

        internalQueue.ably_syncNoDeadlock {
            child.nosync_removeParentReference(parentObjectID: "map:parent@1000", key: "score")
        }

        #expect(child.testsOnly_parentReferences.isEmpty)
    }

    // @UTS objects/unit/RTLO4h2/remove-key-leaves-others-0
    @Test
    func removeParentReferenceRemovesKeyButLeavesOthers() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        child.testsOnly_setParentReferences(["map:parent@1000": ["score", "points"]])

        internalQueue.ably_syncNoDeadlock {
            child.nosync_removeParentReference(parentObjectID: "map:parent@1000", key: "score")
        }

        #expect(child.testsOnly_parentReferences["map:parent@1000"] == ["points"])
    }

    // @UTS objects/unit/RTLO4h3/remove-last-key-removes-entry-0
    @Test
    func removeParentReferenceRemovesEntryWhenSetBecomesEmpty() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        child.testsOnly_setParentReferences(["map:parent@1000": ["score"]])

        internalQueue.ably_syncNoDeadlock {
            child.nosync_removeParentReference(parentObjectID: "map:parent@1000", key: "score")
        }

        #expect(child.testsOnly_parentReferences["map:parent@1000"] == nil)
        #expect(child.testsOnly_parentReferences.isEmpty)
    }

    // @UTS objects/unit/RTLO4h/remove-nonexistent-key-0
    @Test
    func removeParentReferenceNonexistentKeyInExistingParent() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        child.testsOnly_setParentReferences(["map:parent@1000": ["score"]])

        internalQueue.ably_syncNoDeadlock {
            child.nosync_removeParentReference(parentObjectID: "map:parent@1000", key: "nonexistent")
        }

        #expect(child.testsOnly_parentReferences["map:parent@1000"] == ["score"])
    }

    // MARK: - RTLO4f: getFullPaths

    // @UTS objects/unit/RTLO4f2/root-returns-empty-path-0
    @Test
    func getFullPathsForRootReturnsEmptyKeyPath() {
        let internalQueue = TestFactories.createInternalQueue()
        let pool = Self.makePool(internalQueue: internalQueue)

        let paths = pool.root.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.count == 1)
        #expect(paths.contains([]))
    }

    // @UTS objects/unit/RTLO4f/direct-child-single-path-0
    @Test
    func getFullPathsForDirectChildOfRoot() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let counter = Self.makeCounter(objectID: "counter:score@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(counter), forObjectID: "counter:score@1000")

        internalQueue.ably_syncNoDeadlock {
            counter.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "score")
        }

        let paths = counter.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.count == 1)
        #expect(paths.contains(["score"]))
    }

    // @UTS objects/unit/RTLO4f/deep-nesting-0
    @Test
    func getFullPathsForDeeplyNestedObject() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        // root --profile--> map:profile --prefs--> map:prefs --theme_counter--> counter:theme
        let profile = Self.makeMap(objectID: "map:profile@1000", internalQueue: internalQueue)
        let prefs = Self.makeMap(objectID: "map:prefs@1000", internalQueue: internalQueue)
        let themeCounter = Self.makeCounter(objectID: "counter:theme@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(profile), forObjectID: "map:profile@1000")
        pool.testsOnly_setEntry(.map(prefs), forObjectID: "map:prefs@1000")
        pool.testsOnly_setEntry(.counter(themeCounter), forObjectID: "counter:theme@1000")

        internalQueue.ably_syncNoDeadlock {
            profile.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "profile")
            prefs.nosync_addParentReference(parentObjectID: "map:profile@1000", key: "prefs")
            themeCounter.nosync_addParentReference(parentObjectID: "map:prefs@1000", key: "theme_counter")
        }

        let paths = themeCounter.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.count == 1)
        #expect(paths.contains(["profile", "prefs", "theme_counter"]))
    }

    // @UTS objects/unit/RTLO4f/diamond-graph-0
    @Test
    func getFullPathsWithMultipleParentsDiamondGraph() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        // root --a--> map:A --x--> counter:leaf ; root --b--> map:B --y--> counter:leaf
        let mapA = Self.makeMap(objectID: "map:a@1000", internalQueue: internalQueue)
        let mapB = Self.makeMap(objectID: "map:b@1000", internalQueue: internalQueue)
        let leaf = Self.makeCounter(objectID: "counter:leaf@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapA), forObjectID: "map:a@1000")
        pool.testsOnly_setEntry(.map(mapB), forObjectID: "map:b@1000")
        pool.testsOnly_setEntry(.counter(leaf), forObjectID: "counter:leaf@1000")

        internalQueue.ably_syncNoDeadlock {
            mapA.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "a")
            mapB.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "b")
            leaf.nosync_addParentReference(parentObjectID: "map:a@1000", key: "x")
            leaf.nosync_addParentReference(parentObjectID: "map:b@1000", key: "y")
        }

        let paths = leaf.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.count == 2)
        #expect(paths.contains(["a", "x"]))
        #expect(paths.contains(["b", "y"]))
    }

    // @UTS objects/unit/RTLO4f/single-parent-multiple-keys-0
    @Test
    func getFullPathsWithSingleParentReferencingAtMultipleKeys() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(child), forObjectID: "counter:child@1000")

        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "primary")
            child.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "alias")
        }

        let paths = child.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.count == 2)
        #expect(paths.contains(["primary"]))
        #expect(paths.contains(["alias"]))
    }

    // @UTS objects/unit/RTLO4f/orphan-returns-empty-0
    @Test
    func getFullPathsForOrphanReturnsEmptyList() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let orphan = Self.makeCounter(objectID: "counter:orphan@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(orphan), forObjectID: "counter:orphan@1000")

        let paths = orphan.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.isEmpty)
    }

    // @UTS objects/unit/RTLO4f/cycle-suppression-0
    @Test
    func getFullPathsSuppressesCycles() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        // root --a--> map:A --b--> map:B --a--> map:A (cycle)
        let mapA = Self.makeMap(objectID: "map:a@1000", internalQueue: internalQueue)
        let mapB = Self.makeMap(objectID: "map:b@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapA), forObjectID: "map:a@1000")
        pool.testsOnly_setEntry(.map(mapB), forObjectID: "map:b@1000")

        internalQueue.ably_syncNoDeadlock {
            mapA.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "a")
            mapB.nosync_addParentReference(parentObjectID: "map:a@1000", key: "b")
            // Create a cycle: map:A also has map:B as a parent
            mapA.nosync_addParentReference(parentObjectID: "map:b@1000", key: "a")
        }

        let pathsB = mapB.testsOnly_getFullPaths(objectsPool: pool)
        #expect(pathsB.count == 1)
        #expect(pathsB.contains(["a", "b"]))

        let pathsA = mapA.testsOnly_getFullPaths(objectsPool: pool)
        #expect(pathsA.count == 1)
        #expect(pathsA.contains(["a"]))
    }

    // @UTS objects/unit/RTLO4f/complex-diamond-deep-0
    @Test
    func getFullPathsWithComplexDiamondAndDeepNesting() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        // root --left--> map:L --mid--> map:M --target--> counter:T
        // root --right--> map:R --target--> counter:T
        let mapL = Self.makeMap(objectID: "map:l@1000", internalQueue: internalQueue)
        let mapR = Self.makeMap(objectID: "map:r@1000", internalQueue: internalQueue)
        let mapM = Self.makeMap(objectID: "map:m@1000", internalQueue: internalQueue)
        let target = Self.makeCounter(objectID: "counter:t@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapL), forObjectID: "map:l@1000")
        pool.testsOnly_setEntry(.map(mapR), forObjectID: "map:r@1000")
        pool.testsOnly_setEntry(.map(mapM), forObjectID: "map:m@1000")
        pool.testsOnly_setEntry(.counter(target), forObjectID: "counter:t@1000")

        internalQueue.ably_syncNoDeadlock {
            mapL.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "left")
            mapR.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "right")
            mapM.nosync_addParentReference(parentObjectID: "map:l@1000", key: "mid")
            target.nosync_addParentReference(parentObjectID: "map:m@1000", key: "target")
            target.nosync_addParentReference(parentObjectID: "map:r@1000", key: "target")
        }

        let paths = target.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.count == 2)
        #expect(paths.contains(["left", "mid", "target"]))
        #expect(paths.contains(["right", "target"]))
    }

    // MARK: - RTO5c10: Post-sync rebuild (D-7)

    // @UTS objects/unit/RTO5c10/rebuild-from-sync-0
    @Test
    func postSyncRebuildPopulatesParentReferencesFromMapEntries() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let logger = TestLogger()
        var pool = Self.makePool(internalQueue: internalQueue)

        // root --score--> counter:score, root --profile--> map:profile --nested--> counter:nested
        let syncObjects = [
            TestFactories.mapObjectState(
                objectId: ObjectsPool.rootKey,
                entries: [
                    "score": TestFactories.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:score@1000")),
                    "profile": TestFactories.mapEntry(data: ProtocolTypes.ObjectData(objectId: "map:profile@1000")),
                ],
            ),
            TestFactories.counterObjectState(objectId: "counter:score@1000", count: 100),
            TestFactories.mapObjectState(
                objectId: "map:profile@1000",
                entries: ["nested": TestFactories.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:nested@1000"))],
            ),
            TestFactories.counterObjectState(objectId: "counter:nested@1000", count: 5),
        ]

        internalQueue.ably_syncNoDeadlock {
            pool.nosync_applySyncObjectsPool(
                .testsOnly_fromStates(syncObjects.map { (state: $0, serialTimestamp: nil) }),
                logger: logger,
                internalQueue: internalQueue,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )
        }

        let score = try #require(pool.entries["counter:score@1000"]?.counterValue)
        #expect(score.testsOnly_parentReferences[ObjectsPool.rootKey] == ["score"])

        let profile = try #require(pool.entries["map:profile@1000"]?.mapValue)
        #expect(profile.testsOnly_parentReferences[ObjectsPool.rootKey] == ["profile"])

        let nested = try #require(pool.entries["counter:nested@1000"]?.counterValue)
        #expect(nested.testsOnly_parentReferences["map:profile@1000"] == ["nested"])

        // root has no parent references
        #expect(pool.root.testsOnly_parentReferences.isEmpty)

        // getFullPaths works correctly after rebuild
        #expect(score.testsOnly_getFullPaths(objectsPool: pool).contains(["score"]))
        #expect(nested.testsOnly_getFullPaths(objectsPool: pool).contains(["profile", "nested"]))
    }

    // @UTS objects/unit/RTO5c10a/rebuild-clears-stale-refs-0
    @Test
    func postSyncRebuildClearsStaleParentReferences() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let logger = TestLogger()
        var pool = Self.makePool(internalQueue: internalQueue)

        // First sync: root --score--> counter:abc@1000
        let firstSync = [
            TestFactories.mapObjectState(
                objectId: ObjectsPool.rootKey,
                entries: ["score": TestFactories.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:abc@1000"))],
            ),
            TestFactories.counterObjectState(objectId: "counter:abc@1000", count: 10),
        ]
        internalQueue.ably_syncNoDeadlock {
            pool.nosync_applySyncObjectsPool(
                .testsOnly_fromStates(firstSync.map { (state: $0, serialTimestamp: nil) }),
                logger: logger,
                internalQueue: internalQueue,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )
        }
        let afterFirst = try #require(pool.entries["counter:abc@1000"]?.counterValue)
        #expect(afterFirst.testsOnly_parentReferences[ObjectsPool.rootKey] == ["score"])

        // Second sync: root --points--> counter:abc@1000 (key changed from "score" to "points")
        let secondSync = [
            TestFactories.mapObjectState(
                objectId: ObjectsPool.rootKey,
                entries: ["points": TestFactories.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:abc@1000"))],
            ),
            TestFactories.counterObjectState(objectId: "counter:abc@1000", count: 20),
        ]
        internalQueue.ably_syncNoDeadlock {
            pool.nosync_applySyncObjectsPool(
                .testsOnly_fromStates(secondSync.map { (state: $0, serialTimestamp: nil) }),
                logger: logger,
                internalQueue: internalQueue,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )
        }

        let counter = try #require(pool.entries["counter:abc@1000"]?.counterValue)
        // Old "score" reference should be gone, replaced by "points"
        #expect(counter.testsOnly_parentReferences[ObjectsPool.rootKey] == ["points"])
        let paths = counter.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.contains(["points"]))
        #expect(paths.count == 1)
    }

    // @UTS objects/unit/RTO5c10/unreferenced-empty-refs-0
    @Test
    func postSyncUnreferencedObjectsHaveEmptyParentReferences() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let logger = TestLogger()
        var pool = Self.makePool(internalQueue: internalQueue)

        let syncObjects = [
            TestFactories.mapObjectState(
                objectId: ObjectsPool.rootKey,
                entries: ["name": TestFactories.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"))],
            ),
            TestFactories.counterObjectState(objectId: "counter:orphan@1000", count: 42),
        ]
        internalQueue.ably_syncNoDeadlock {
            pool.nosync_applySyncObjectsPool(
                .testsOnly_fromStates(syncObjects.map { (state: $0, serialTimestamp: nil) }),
                logger: logger,
                internalQueue: internalQueue,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )
        }

        // The counter exists in the pool but no InternalLiveMap entry points to it
        let orphan = try #require(pool.entries["counter:orphan@1000"]?.counterValue)
        #expect(orphan.testsOnly_parentReferences.isEmpty)
        #expect(orphan.testsOnly_getFullPaths(objectsPool: pool).isEmpty)
    }
}
