@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

/// Native smoke tests for the parent-reference graph (RTLO3f, RTLO4g, RTLO4h, RTLO4f) and the
/// RTO5c10 post-sync rebuild. The full UTS port of `objects/unit/parent_references.md` is a
/// separate follow-up; these cover the core behaviours end-to-end.
struct ParentReferencesTests {
    private static func makeCounter(objectID: String, internalQueue: DispatchQueue) -> InternalDefaultLiveCounter {
        InternalDefaultLiveCounter.createZeroValued(
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    private static func makeMap(objectID: String, data: [String: InternalObjectsMapEntry] = [:], internalQueue: DispatchQueue) -> InternalDefaultLiveMap {
        InternalDefaultLiveMap(
            testsOnly_data: data,
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    // RTLO4g1, RTLO4g2: addParentReference creates a new entry for the first reference and adds
    // further keys (and further parents) to the tracking map.
    @Test
    func addParentReferenceCreatesAndExtendsEntries() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)

        internalQueue.ably_syncNoDeadlock {
            child.nosync_addParentReference(parentObjectID: "map:a@1000", key: "x")
            // RTLO4g1: adding a second key to the same parent extends the existing set
            child.nosync_addParentReference(parentObjectID: "map:a@1000", key: "y")
            // RTLO4g: a different parent gets its own entry
            child.nosync_addParentReference(parentObjectID: "map:b@1000", key: "p")
        }

        #expect(child.testsOnly_parentReferences == [
            "map:a@1000": ["x", "y"],
            "map:b@1000": ["p"],
        ])
    }

    // RTLO4h1, RTLO4h2, RTLO4h3: removeParentReference drops a key, removes the entry when its set
    // becomes empty, and no-ops for an absent parent/key.
    @Test
    func removeParentReferenceDropsKeyAndEntry() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        child.testsOnly_setParentReferences(["map:parent@1000": ["score", "points"]])

        internalQueue.ably_syncNoDeadlock {
            // RTLO4h2: removes the key but leaves the others
            child.nosync_removeParentReference(parentObjectID: "map:parent@1000", key: "score")
        }
        #expect(child.testsOnly_parentReferences == ["map:parent@1000": ["points"]])

        internalQueue.ably_syncNoDeadlock {
            // RTLO4h1: absent parent is a no-op
            child.nosync_removeParentReference(parentObjectID: "map:other@1000", key: "points")
            // RTLO4h3: removing the last key removes the entry entirely
            child.nosync_removeParentReference(parentObjectID: "map:parent@1000", key: "points")
        }
        #expect(child.testsOnly_parentReferences.isEmpty)
    }

    // RTO5c10a: clearParentReferences resets the map to empty.
    @Test
    func clearParentReferences() {
        let internalQueue = TestFactories.createInternalQueue()
        let child = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        child.testsOnly_setParentReferences(["map:parent@1000": ["score"]])

        internalQueue.ably_syncNoDeadlock {
            child.nosync_clearParentReferences()
        }

        #expect(child.testsOnly_parentReferences.isEmpty)
    }

    // RTLO4f2: root yields the empty key-path; an orphan yields no paths; a direct child of root
    // yields its single key-path.
    @Test
    func getFullPathsForRootOrphanAndDirectChild() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = ObjectsPool(logger: TestLogger(), internalQueue: internalQueue, userCallbackQueue: .main, clock: MockSimpleClock())

        let counter = Self.makeCounter(objectID: "counter:score@1000", internalQueue: internalQueue)
        let orphan = Self.makeCounter(objectID: "counter:orphan@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(counter), forObjectID: "counter:score@1000")
        pool.testsOnly_setEntry(.counter(orphan), forObjectID: "counter:orphan@1000")

        internalQueue.ably_syncNoDeadlock {
            counter.nosync_addParentReference(parentObjectID: ObjectsPool.rootKey, key: "score")
        }

        // RTLO4f2: root maps to the empty key-path
        #expect(pool.root.testsOnly_getFullPaths(objectsPool: pool) == [[]])
        // RTLO4f: direct child of root
        #expect(counter.testsOnly_getFullPaths(objectsPool: pool) == [["score"]])
        // RTLO4f: orphan (not reachable from root)
        #expect(orphan.testsOnly_getFullPaths(objectsPool: pool).isEmpty)
    }

    // RTLO4f2, RTLO4f3, RTLO4f4: multi-level nesting, diamond (multiple parents), and cycle
    // suppression all produce the expected distinct simple paths.
    @Test
    func getFullPathsForDiamondAndCycle() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = ObjectsPool(logger: TestLogger(), internalQueue: internalQueue, userCallbackQueue: .main, clock: MockSimpleClock())

        // Diamond + deep nesting: root --left--> map:l --mid--> map:m --target--> counter:t
        //                         root --right--> map:r --target--> counter:t
        let mapL = Self.makeMap(objectID: "map:l@1000", internalQueue: internalQueue)
        let mapR = Self.makeMap(objectID: "map:r@1000", internalQueue: internalQueue)
        let mapM = Self.makeMap(objectID: "map:m@1000", internalQueue: internalQueue)
        let target = Self.makeCounter(objectID: "counter:t@1000", internalQueue: internalQueue)
        for (id, entry): (String, ObjectsPool.Entry) in [
            ("map:l@1000", .map(mapL)),
            ("map:r@1000", .map(mapR)),
            ("map:m@1000", .map(mapM)),
            ("counter:t@1000", .counter(target)),
        ] {
            pool.testsOnly_setEntry(entry, forObjectID: id)
        }

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

        // Cycle suppression: add map:l as a parent of map:m via map:m, then create a back-edge
        // map:l -> map:m so that the graph contains a cycle; getFullPaths must still terminate.
        internalQueue.ably_syncNoDeadlock {
            mapL.nosync_addParentReference(parentObjectID: "map:m@1000", key: "loop")
        }
        // map:l is reachable from root at ["left"]; the cycle back through map:m is suppressed.
        let mapLPaths = mapL.testsOnly_getFullPaths(objectsPool: pool)
        #expect(mapLPaths.contains(["left"]))
        #expect(!mapLPaths.isEmpty)
    }

    // RTO5c10, RTO5c10a, RTO5c10b: the rebuild resets every object's parentReferences and re-adds
    // them from every map's non-tombstoned object-valued entries.
    @Test
    func postSyncRebuildPopulatesParentReferences() {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = ObjectsPool(logger: TestLogger(), internalQueue: internalQueue, userCallbackQueue: .main, clock: MockSimpleClock())

        // root --score--> counter:score, root --profile--> map:profile --nested--> counter:nested
        let rootMap = Self.makeMap(
            objectID: ObjectsPool.rootKey,
            data: [
                "score": TestFactories.internalMapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:score@1000")),
                "profile": TestFactories.internalMapEntry(data: ProtocolTypes.ObjectData(objectId: "map:profile@1000")),
            ],
            internalQueue: internalQueue,
        )
        let scoreCounter = Self.makeCounter(objectID: "counter:score@1000", internalQueue: internalQueue)
        let profileMap = Self.makeMap(
            objectID: "map:profile@1000",
            data: ["nested": TestFactories.internalMapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:nested@1000"))],
            internalQueue: internalQueue,
        )
        let nestedCounter = Self.makeCounter(objectID: "counter:nested@1000", internalQueue: internalQueue)

        // Seed a stale reference to prove RTO5c10a clears it before the rebuild.
        scoreCounter.testsOnly_setParentReferences(["map:stale@1000": ["old"]])

        pool.testsOnly_setEntry(.map(rootMap), forObjectID: ObjectsPool.rootKey)
        pool.testsOnly_setEntry(.counter(scoreCounter), forObjectID: "counter:score@1000")
        pool.testsOnly_setEntry(.map(profileMap), forObjectID: "map:profile@1000")
        pool.testsOnly_setEntry(.counter(nestedCounter), forObjectID: "counter:nested@1000")

        internalQueue.ably_syncNoDeadlock {
            pool.nosync_rebuildParentReferences()
        }

        #expect(scoreCounter.testsOnly_parentReferences == [ObjectsPool.rootKey: ["score"]])
        #expect(profileMap.testsOnly_parentReferences == [ObjectsPool.rootKey: ["profile"]])
        #expect(nestedCounter.testsOnly_parentReferences == ["map:profile@1000": ["nested"]])
        // The root has no parents; its stale-free state is preserved.
        #expect(rootMap.testsOnly_parentReferences.isEmpty)

        // getFullPaths works after the rebuild.
        #expect(nestedCounter.testsOnly_getFullPaths(objectsPool: pool).contains(["profile", "nested"]))
    }
}
