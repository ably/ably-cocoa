// Derived from the UTS spec `objects/unit/parent_references.md`.
//
// These ports drive the internal parent-reference graph directly on
// `InternalDefaultLiveCounter` / `InternalDefaultLiveMap` / `ObjectsPool` (no channel, no
// connection): `parentReferences` tracking (RTLO3f), `addParentReference` / `removeParentReference`
// (RTLO4g / RTLO4h), the cycle-safe `getFullPaths` DFS (RTLO4f), and the post-sync rebuild
// (RTO5c10). The spec is entirely internal (objects-mapping.md §13), so the whole suite reaches the
// internal layer via `@testable import AblyLiveObjects` + the `testsOnly_` seams in
// `AblyLiveObjectsTesting`. All `nosync_*` node access is confined to the internal queue via
// `internalQueue.ably_syncNoDeadlock { }` (the off-queue traps described in objects-mapping.md §13).
//
// Internal-API shape mappings (coverage fully preserved — NOT deviations):
// - the spec passes the parent *object* to `addParentReference`/`removeParentReference`; cocoa's
//   `nosync_addParentReference(parentObjectID:key:)` takes the parent's objectId, so we pass
//   `parent.testsOnly_objectID` (or `ObjectsPool.rootKey` for root).
// - `object.getFullPaths()` maps to `object.testsOnly_getFullPaths(objectsPool:)` — the DFS lives on
//   the pool that owns the graph, so the pool is passed explicitly.
// - `object.parentReferences` reads/writes map to `testsOnly_parentReferences` /
//   `testsOnly_setParentReferences(_:)`; `pool["id"]` reads/writes map to `pool.root` /
//   `pool.testsOnly_setEntry(_:forObjectID:)`.
//
// Infra stand-in (unit tier — NOT a deviation): the RTO5c10 spec cases drive a full OBJECT_SYNC via
// `pool.processObjectSync(...)`; the unit tier has no channel/transport, so we seed the settled graph
// directly and invoke the RTO5c10 rebuild (`pool.nosync_rebuildParentReferences()`) — the same
// direct-seeding stand-in `objects-mapping.md` §13 sanctions for `build_object_sync_message`. The
// spec's `ASSERT pool.syncState == SYNCED` has no pool-level counterpart under this stand-in (sync
// state is owned by the realtime-objects layer, not `ObjectsPool`), so it is kept as a note.

@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct ParentReferencesTests {
    // MARK: - RTLO3f2 — parentReferences initialized to empty map

    // UTS: objects/unit/RTLO3f2/init-empty-counter-0
    @Test
    func initEmptyCounter() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Assertions
        // RTLO3f: parentReferences is set to an empty map when the LiveObject is initialized.
        #expect(counter.testsOnly_parentReferences == [:])
    }

    // UTS: objects/unit/RTLO3f2/init-empty-map-0
    @Test
    func initEmptyMap() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "map:abc@1000", internalQueue: internalQueue)

        // Assertions
        // RTLO3f: parentReferences is set to an empty map when the LiveObject is initialized.
        #expect(map.testsOnly_parentReferences == [:])
    }

    // MARK: - RTLO4g — addParentReference

    // UTS: objects/unit/RTLO4g2/first-reference-new-entry-0
    @Test
    func addParentReferenceCreatesNewEntry() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let parent = ObjectsUTS.makeMap(objectID: "map:parent@1000", internalQueue: internalQueue)
        let parentID = parent.testsOnly_objectID

        // Test Steps
        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: parentID, key: "score")
        }

        // Assertions
        // RTLO4g2: no entry for parent.objectId — insert a new entry with a set containing only key.
        #expect(child.testsOnly_parentReferences.keys.contains("map:parent@1000"))
        #expect(child.testsOnly_parentReferences["map:parent@1000"] == ["score"])
    }

    // UTS: objects/unit/RTLO4g1/second-key-same-parent-0
    @Test
    func addParentReferenceAddsKeyToExistingEntry() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let parent = ObjectsUTS.makeMap(objectID: "map:parent@1000", internalQueue: internalQueue)
        let parentID = parent.testsOnly_objectID
        child.testsOnly_setParentReferences(["map:parent@1000": ["score"]])

        // Test Steps
        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: parentID, key: "points")
        }

        // Assertions
        // RTLO4g1: entry already exists — add key to that entry's set.
        #expect(child.testsOnly_parentReferences["map:parent@1000"] == ["score", "points"])
    }

    // UTS: objects/unit/RTLO4g/different-parent-separate-entry-0
    @Test
    func addParentReferenceDifferentParentSeparateEntry() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let parentA = ObjectsUTS.makeMap(objectID: "map:a@1000", internalQueue: internalQueue)
        let parentB = ObjectsUTS.makeMap(objectID: "map:b@1000", internalQueue: internalQueue)
        let parentAID = parentA.testsOnly_objectID
        let parentBID = parentB.testsOnly_objectID

        // Test Steps
        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: parentAID, key: "x")
            child.nosync_addParentReference(parentObjectID: parentBID, key: "y")
        }

        // Assertions
        // RTLO4g: each parent InternalLiveMap gets its own entry in parentReferences.
        #expect(child.testsOnly_parentReferences["map:a@1000"] == ["x"])
        #expect(child.testsOnly_parentReferences["map:b@1000"] == ["y"])
    }

    // UTS: objects/unit/RTLO4g/multiple-parents-multiple-keys-0
    @Test
    func addParentReferenceMultipleParentsMultipleKeys() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let parentA = ObjectsUTS.makeMap(objectID: "map:a@1000", internalQueue: internalQueue)
        let parentB = ObjectsUTS.makeMap(objectID: "map:b@1000", internalQueue: internalQueue)
        let parentAID = parentA.testsOnly_objectID
        let parentBID = parentB.testsOnly_objectID

        // Test Steps
        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: parentAID, key: "x")
            child.nosync_addParentReference(parentObjectID: parentAID, key: "y")
            child.nosync_addParentReference(parentObjectID: parentBID, key: "p")
            child.nosync_addParentReference(parentObjectID: parentBID, key: "q")
        }

        // Assertions
        // RTLO4g: parentReferences correctly tracks multiple keys across multiple parents.
        #expect(child.testsOnly_parentReferences["map:a@1000"] == ["x", "y"])
        #expect(child.testsOnly_parentReferences["map:b@1000"] == ["p", "q"])
    }

    // MARK: - RTLO4h — removeParentReference

    // UTS: objects/unit/RTLO4h1/nonexistent-parent-noop-0
    @Test
    func removeParentReferenceNonexistentParentNoop() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let parent = ObjectsUTS.makeMap(objectID: "map:parent@1000", internalQueue: internalQueue)
        let parentID = parent.testsOnly_objectID

        // Test Steps
        internalQueue.ably_syncNoDeadlock {
            child.nosync_removeParentReference(parentObjectID: parentID, key: "score")
        }

        // Assertions
        // RTLO4h1: no entry for parent.objectId — do nothing.
        #expect(child.testsOnly_parentReferences == [:])
    }

    // UTS: objects/unit/RTLO4h2/remove-key-leaves-others-0
    @Test
    func removeParentReferenceRemovesKeyLeavesOthers() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let parent = ObjectsUTS.makeMap(objectID: "map:parent@1000", internalQueue: internalQueue)
        let parentID = parent.testsOnly_objectID
        child.testsOnly_setParentReferences(["map:parent@1000": ["score", "points"]])

        // Test Steps
        internalQueue.ably_syncNoDeadlock {
            child.nosync_removeParentReference(parentObjectID: parentID, key: "score")
        }

        // Assertions
        // RTLO4h2: remove key from that entry's set.
        #expect(child.testsOnly_parentReferences["map:parent@1000"] == ["points"])
    }

    // UTS: objects/unit/RTLO4h3/remove-last-key-removes-entry-0
    @Test
    func removeParentReferenceRemovesEntryWhenSetEmpty() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let parent = ObjectsUTS.makeMap(objectID: "map:parent@1000", internalQueue: internalQueue)
        let parentID = parent.testsOnly_objectID
        child.testsOnly_setParentReferences(["map:parent@1000": ["score"]])

        // Test Steps
        internalQueue.ably_syncNoDeadlock {
            child.nosync_removeParentReference(parentObjectID: parentID, key: "score")
        }

        // Assertions
        // RTLO4h2 / RTLO4h3: removing the last key removes the entry from parentReferences.
        #expect(child.testsOnly_parentReferences["map:parent@1000"] == nil)
        #expect(child.testsOnly_parentReferences == [:])
    }

    // UTS: objects/unit/RTLO4h/remove-nonexistent-key-0
    @Test
    func removeParentReferenceNonexistentKey() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let parent = ObjectsUTS.makeMap(objectID: "map:parent@1000", internalQueue: internalQueue)
        let parentID = parent.testsOnly_objectID
        child.testsOnly_setParentReferences(["map:parent@1000": ["score"]])

        // Test Steps
        internalQueue.ably_syncNoDeadlock {
            child.nosync_removeParentReference(parentObjectID: parentID, key: "nonexistent")
        }

        // Assertions
        // RTLO4h: removing a key not in the parent's set does not alter the existing keys.
        #expect(child.testsOnly_parentReferences["map:parent@1000"] == ["score"])
    }

    // MARK: - RTLO4f — getFullPaths

    // UTS: objects/unit/RTLO4f2/root-returns-empty-path-0
    @Test
    func getFullPathsForRootReturnsEmptyPath() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let pool = ObjectsUTS.freshPool(internalQueue: internalQueue)
        let root = pool.root

        // Assertions
        let paths = root.testsOnly_getFullPaths(objectsPool: pool)
        // RTLO4f2: the empty simple path (root itself) contributes the empty key-path [].
        #expect(paths.count == 1)
        #expect(paths.contains([]))
    }

    // UTS: objects/unit/RTLO4f/direct-child-single-path-0
    @Test
    func getFullPathsForDirectChildOfRoot() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)
        let counter = ObjectsUTS.makeCounter(objectID: "counter:score@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(counter), forObjectID: "counter:score@1000")

        // RTLO4f1: edges labelled with key derived from parentReferences.
        internalQueue.ably_syncNoDeadlock {
            counter.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "score")
        }

        // Assertions
        let paths = counter.testsOnly_getFullPaths(objectsPool: pool)
        // RTLO4f2: each simple path from root contributes one key-path.
        #expect(paths.count == 1)
        #expect(paths.contains(["score"]))
    }

    // UTS: objects/unit/RTLO4f/deep-nesting-0
    @Test
    func getFullPathsForDeeplyNestedObject() {
        // Setup — root --"profile"--> map:profile --"prefs"--> map:prefs --"theme_counter"--> counter:theme
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        let profile = ObjectsUTS.makeMap(objectID: "map:profile@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(profile), forObjectID: "map:profile@1000")

        let prefs = ObjectsUTS.makeMap(objectID: "map:prefs@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(prefs), forObjectID: "map:prefs@1000")

        let themeCounter = ObjectsUTS.makeCounter(objectID: "counter:theme@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(themeCounter), forObjectID: "counter:theme@1000")

        internalQueue.ably_syncNoDeadlock {
            profile.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "profile")
            prefs.nosync_addParentReference(parentObjectID: "map:profile@1000", key: "prefs")
            themeCounter.nosync_addParentReference(parentObjectID: "map:prefs@1000", key: "theme_counter")
        }

        // Assertions
        let paths = themeCounter.testsOnly_getFullPaths(objectsPool: pool)
        // RTLO4f: getFullPaths traverses multiple levels of parentReferences.
        #expect(paths.count == 1)
        #expect(paths.contains(["profile", "prefs", "theme_counter"]))
    }

    // UTS: objects/unit/RTLO4f/diamond-graph-0
    @Test
    func getFullPathsWithDiamondGraph() {
        // Setup — root --"a"--> map:A --"x"--> counter:leaf, and root --"b"--> map:B --"y"--> counter:leaf
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        let mapA = ObjectsUTS.makeMap(objectID: "map:a@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapA), forObjectID: "map:a@1000")

        let mapB = ObjectsUTS.makeMap(objectID: "map:b@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapB), forObjectID: "map:b@1000")

        let leaf = ObjectsUTS.makeCounter(objectID: "counter:leaf@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(leaf), forObjectID: "counter:leaf@1000")

        internalQueue.ably_syncNoDeadlock {
            mapA.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "a")
            mapB.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "b")
            leaf.nosync_addParentReference(parentObjectID: "map:a@1000", key: "x")
            leaf.nosync_addParentReference(parentObjectID: "map:b@1000", key: "y")
        }

        // Assertions
        let paths = leaf.testsOnly_getFullPaths(objectsPool: pool)
        // RTLO4f2 / RTLO4f3: each simple path contributes one key-path; each appears exactly once.
        #expect(paths.count == 2)
        #expect(paths.contains(["a", "x"]))
        #expect(paths.contains(["b", "y"]))
    }

    // UTS: objects/unit/RTLO4f/single-parent-multiple-keys-0
    @Test
    func getFullPathsWithSingleParentMultipleKeys() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        let child = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(child), forObjectID: "counter:child@1000")

        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "primary")
            child.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "alias")
        }

        // Assertions
        let paths = child.testsOnly_getFullPaths(objectsPool: pool)
        // RTLO4f2 / RTLO4f3: a parent referencing the child at two keys yields two distinct key-paths.
        #expect(paths.count == 2)
        #expect(paths.contains(["primary"]))
        #expect(paths.contains(["alias"]))
    }

    // UTS: objects/unit/RTLO4f/orphan-returns-empty-0
    @Test
    func getFullPathsForOrphanReturnsEmpty() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        let orphan = ObjectsUTS.makeCounter(objectID: "counter:orphan@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(orphan), forObjectID: "counter:orphan@1000")

        // Assertions
        let paths = orphan.testsOnly_getFullPaths(objectsPool: pool)
        // RTLO4f: an object with no parentReferences path to root has no key-paths.
        #expect(paths.count == 0)
    }

    // UTS: objects/unit/RTLO4f/cycle-suppression-0
    @Test
    func getFullPathsSuppressesCycles() {
        // Setup — root --"a"--> map:A --"b"--> map:B --"a"--> map:A (cycle)
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        let mapA = ObjectsUTS.makeMap(objectID: "map:a@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapA), forObjectID: "map:a@1000")

        let mapB = ObjectsUTS.makeMap(objectID: "map:b@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapB), forObjectID: "map:b@1000")

        internalQueue.ably_syncNoDeadlock {
            mapA.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "a")
            mapB.nosync_addParentReference(parentObjectID: "map:a@1000", key: "b")
            // Create a cycle: map:A also has map:B as a parent
            mapA.nosync_addParentReference(parentObjectID: "map:b@1000", key: "a")
        }

        // Assertions
        let pathsB = mapB.testsOnly_getFullPaths(objectsPool: pool)
        // RTLO4f2 / RTLO4f4: a simple path visits each node at most once — the cycle is suppressed.
        #expect(pathsB.count == 1)
        #expect(pathsB.contains(["a", "b"]))

        let pathsA = mapA.testsOnly_getFullPaths(objectsPool: pool)
        #expect(pathsA.count == 1)
        #expect(pathsA.contains(["a"]))
    }

    // UTS: objects/unit/RTLO4f/complex-diamond-deep-0
    @Test
    func getFullPathsWithComplexDiamondAndDeepNesting() {
        // Setup —
        //   root --"left"--> map:L --"mid"--> map:M --"target"--> counter:T
        //   root --"right"--> map:R --"target"--> counter:T
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        let mapL = ObjectsUTS.makeMap(objectID: "map:l@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapL), forObjectID: "map:l@1000")

        let mapR = ObjectsUTS.makeMap(objectID: "map:r@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapR), forObjectID: "map:r@1000")

        let mapM = ObjectsUTS.makeMap(objectID: "map:m@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(mapM), forObjectID: "map:m@1000")

        let target = ObjectsUTS.makeCounter(objectID: "counter:t@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(target), forObjectID: "counter:t@1000")

        internalQueue.ably_syncNoDeadlock {
            mapL.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "left")
            mapR.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "right")
            mapM.nosync_addParentReference(parentObjectID: "map:l@1000", key: "mid")
            target.nosync_addParentReference(parentObjectID: "map:m@1000", key: "target")
            target.nosync_addParentReference(parentObjectID: "map:r@1000", key: "target")
        }

        // Assertions
        let paths = target.testsOnly_getFullPaths(objectsPool: pool)
        // RTLO4f: all distinct simple paths from root, through multiple intermediate nodes.
        #expect(paths.count == 2)
        #expect(paths.contains(["left", "mid", "target"]))
        #expect(paths.contains(["right", "target"]))
    }

    // MARK: - RTO5c10 — post-sync rebuild of parentReferences

    // UTS: objects/unit/RTO5c10/rebuild-from-sync-0
    @Test
    func rebuildPopulatesParentReferencesFromMapEntries() {
        // Setup — the settled graph an OBJECT_SYNC would produce (direct-seeding stand-in):
        //   root --"score"--> counter:score@1000, root --"profile"--> map:profile@1000
        //   map:profile@1000 --"nested"--> counter:nested@1000
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        let root = ObjectsUTS.makeMap(
            objectID: ObjectsPool.rootKey,
            data: [
                "score": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:score@1000")),
                "profile": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "map:profile@1000")),
            ],
            internalQueue: internalQueue,
        )
        let scoreCounter = ObjectsUTS.makeCounter(objectID: "counter:score@1000", data: 100, internalQueue: internalQueue)
        let profile = ObjectsUTS.makeMap(
            objectID: "map:profile@1000",
            data: ["nested": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:nested@1000"))],
            internalQueue: internalQueue,
        )
        let nestedCounter = ObjectsUTS.makeCounter(objectID: "counter:nested@1000", data: 5, internalQueue: internalQueue)

        pool.testsOnly_setEntry(.map(root), forObjectID: ObjectsPool.rootKey)
        pool.testsOnly_setEntry(.counter(scoreCounter), forObjectID: "counter:score@1000")
        pool.testsOnly_setEntry(.map(profile), forObjectID: "map:profile@1000")
        pool.testsOnly_setEntry(.counter(nestedCounter), forObjectID: "counter:nested@1000")

        // Test Steps — RTO5c10: post-sync rebuild (direct invocation stands in for processObjectSync).
        internalQueue.ably_syncNoDeadlock {
            pool.nosync_rebuildParentReferences()
        }

        // Assertions
        // ASSERT pool.syncState == SYNCED — no pool-level sync state under the direct-seeding stand-in.

        // counter:score@1000 is referenced by root at key "score"
        let score = scoreCounter
        #expect(score.testsOnly_parentReferences["root"] == ["score"])

        // map:profile@1000 is referenced by root at key "profile"
        #expect(profile.testsOnly_parentReferences["root"] == ["profile"])

        // counter:nested@1000 is referenced by map:profile@1000 at key "nested"
        #expect(nestedCounter.testsOnly_parentReferences["map:profile@1000"] == ["nested"])

        // root has no parent references
        #expect(root.testsOnly_parentReferences == [:])

        // getFullPaths works correctly after rebuild
        #expect(score.testsOnly_getFullPaths(objectsPool: pool).contains(["score"]))
        #expect(nestedCounter.testsOnly_getFullPaths(objectsPool: pool).contains(["profile", "nested"]))
    }

    // UTS: objects/unit/RTO5c10a/rebuild-clears-stale-refs-0
    @Test
    func rebuildClearsStaleParentReferences() {
        // Setup — First sync: root --"score"--> counter:abc@1000
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        // The counter is reused across both syncs, proving RTO5c10a clears its stale refs.
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 10, internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(counter), forObjectID: "counter:abc@1000")

        let root1 = ObjectsUTS.makeMap(
            objectID: ObjectsPool.rootKey,
            data: ["score": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:abc@1000"))],
            internalQueue: internalQueue,
        )
        pool.testsOnly_setEntry(.map(root1), forObjectID: ObjectsPool.rootKey)

        internalQueue.ably_syncNoDeadlock {
            pool.nosync_rebuildParentReferences()
        }
        #expect(counter.testsOnly_parentReferences["root"] == ["score"])

        // Test Steps — Second sync: root --"points"--> counter:abc@1000 (key changed from "score" to "points")
        let root2 = ObjectsUTS.makeMap(
            objectID: ObjectsPool.rootKey,
            data: ["points": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:abc@1000"))],
            internalQueue: internalQueue,
        )
        pool.testsOnly_setEntry(.map(root2), forObjectID: ObjectsPool.rootKey)

        internalQueue.ably_syncNoDeadlock {
            pool.nosync_rebuildParentReferences()
        }

        // Assertions
        // Old "score" reference should be gone, replaced by "points"
        #expect(counter.testsOnly_parentReferences["root"] == ["points"])
        #expect(counter.testsOnly_getFullPaths(objectsPool: pool).contains(["points"]))

        let paths = counter.testsOnly_getFullPaths(objectsPool: pool)
        #expect(paths.count == 1)
    }

    // UTS: objects/unit/RTO5c10/unreferenced-empty-refs-0
    @Test
    func rebuildUnreferencedObjectsHaveEmptyParentReferences() {
        // Setup — root has only a primitive entry; counter:orphan@1000 is in the pool but unreferenced.
        let internalQueue = ObjectsUTS.createInternalQueue()
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)

        let root = ObjectsUTS.makeMap(
            objectID: ObjectsPool.rootKey,
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )
        pool.testsOnly_setEntry(.map(root), forObjectID: ObjectsPool.rootKey)

        let orphan = ObjectsUTS.makeCounter(objectID: "counter:orphan@1000", data: 42, internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(orphan), forObjectID: "counter:orphan@1000")

        // Test Steps — RTO5c10 rebuild (direct invocation stands in for processObjectSync).
        internalQueue.ably_syncNoDeadlock {
            pool.nosync_rebuildParentReferences()
        }

        // Assertions
        // ASSERT pool.syncState == SYNCED — no pool-level sync state under the direct-seeding stand-in.

        // The counter exists in the pool but no InternalLiveMap entry points to it
        #expect(orphan.testsOnly_parentReferences == [:])

        // getFullPaths returns empty list for unreferenced object
        #expect(orphan.testsOnly_getFullPaths(objectsPool: pool).count == 0)
    }
}
