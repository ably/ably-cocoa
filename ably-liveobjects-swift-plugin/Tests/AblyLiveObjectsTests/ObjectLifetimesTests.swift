import Ably.Private
@testable import AblyLiveObjects
import Testing

struct ObjectLifetimesTests {
    @Test("LiveObjects functionality works with only a strong reference to channel's public objects property")
    func withStrongReferenceToPublicObjectsProperty() async throws {
        // The objects that we'll create.
        struct CreatedObjects {
            /// The queue on which we expect ably-cocoa's QueuedDealloc mechanism to enqueue the relinquishing of `weakInternalRealtime`.
            var realtimeDeallocQueue: DispatchQueue

            weak var weakPublicRealtime: ARTRealtime?
            weak var weakInternalRealtime: ARTRealtimeInternal?
            weak var weakPublicChannel: ARTRealtimeChannel?
            weak var weakInternalChannel: ARTRealtimeChannelInternal?
            var strongPublicRealtimeObjects: PublicDefaultRealtimeObjects
            weak var weakInternalRealtimeObjects: InternalDefaultRealtimeObjects?
        }

        // What we're left with after discarding a CreatedObjects.
        struct RemainingObjects {
            /// The queue on which we expect ably-cocoa's QueuedDealloc mechanism to enqueue the relinquishing of `weakInternalRealtime`.
            var realtimeDeallocQueue: DispatchQueue

            // weakPublicRealtime is gone now
            weak var weakInternalRealtime: ARTRealtimeInternal?
            // weakPublicChannel is gone now
            weak var weakInternalChannel: ARTRealtimeChannelInternal?
            weak var weakPublicRealtimeObjects: PublicDefaultRealtimeObjects?
            weak var weakInternalRealtimeObjects: InternalDefaultRealtimeObjects?
        }

        func createAndDiscardObjects() async throws -> RemainingObjects {
            func createObjects() async throws -> CreatedObjects {
                // We disable autoConnect since being connected extends the internal Realtime instance's lifetime (it stays alive whilst connected), and I don't want that interfering with this test.
                let realtime = try await ClientHelper.realtimeWithObjects(options: .init(autoConnect: false))
                let channel = realtime.channels.get(UUID().uuidString, options: ClientHelper.channelOptionsWithObjects())
                let anyObjects = channel.objects
                // For some reason putting `channel.objects as? PublicDefaultRealtimeObjects` inside the #require gives "no calls to throwing functions occur within 'try' expression" 🤷
                let objects = try #require(anyObjects as? PublicDefaultRealtimeObjects)

                return .init(
                    realtimeDeallocQueue: realtime.internal.queue,
                    weakPublicRealtime: realtime,
                    weakInternalRealtime: realtime.internal,
                    weakPublicChannel: channel,
                    weakInternalChannel: channel.internal,
                    strongPublicRealtimeObjects: objects,
                    weakInternalRealtimeObjects: objects.testsOnly_proxied,
                )
            }

            let createdObjects = try await createObjects()

            // The only public object we have a strong reference to is strongPublicRealtimeObjects, so the other public objects should have already been deallocated
            #expect(createdObjects.weakPublicRealtime == nil)
            #expect(createdObjects.weakPublicChannel == nil)

            // Now we check that, since we still have a strong reference to strongPublicRealtimeObjects, none of the dependencies that it needs in order to function have been deallocated.
            await withCheckedContinuation { continuation in
                // We wait for everything on realtimeDeallocQueue to execute, to be sure that we'd catch a dealloc that had been enqueued via ably-cocoa's QueuedDealloc mechanism.
                createdObjects.realtimeDeallocQueue.async {
                    continuation.resume()
                }
            }
            #expect(createdObjects.weakInternalRealtime != nil)
            #expect(createdObjects.weakInternalChannel != nil)
            #expect(createdObjects.weakInternalRealtimeObjects != nil)

            // TODO: test that we can receive events on a LiveObject (https://github.com/ably/ably-liveobjects-swift-plugin/issues/30)

            // Note that after this return we no longer have a reference to createdObjects and thus no longer have a strong reference to our public RealtimeObjects instance
            return .init(
                realtimeDeallocQueue: createdObjects.realtimeDeallocQueue,
                weakInternalRealtime: createdObjects.weakInternalRealtime,
                weakInternalChannel: createdObjects.weakInternalChannel,
                weakPublicRealtimeObjects: createdObjects.strongPublicRealtimeObjects,
                weakInternalRealtimeObjects: createdObjects.weakInternalRealtimeObjects,
            )
        }

        let remainingObjects = try await createAndDiscardObjects()

        // Check that the public RealtimeObjects has been deallocated now that we've no longer got a strong reference to it
        #expect(remainingObjects.weakPublicRealtimeObjects == nil)

        // Check that the internal objects that the public RealtimeObjects needed in order to function have now been deallocated
        await withCheckedContinuation { continuation in
            // We wait for everything on realtimeDeallocQueue to execute, to be sure that we'd catch a dealloc that had been enqueued via ably-cocoa's QueuedDealloc mechanism.
            remainingObjects.realtimeDeallocQueue.async {
                continuation.resume()
            }
        }

        #expect(remainingObjects.weakInternalRealtime == nil)
        #expect(remainingObjects.weakInternalChannel == nil)
        #expect(remainingObjects.weakInternalRealtimeObjects == nil)
    }

    @Test("LiveObjects functionality works with only a strong reference to a public LiveObject")
    func withStrongReferenceToPublicLiveObject() async throws {
        // Note: This test is very similar to withStrongReferenceToPublicObjectsProperty but "one layer down" — i.e. it checks that instead of a RealtimeObjects reference keeping everything working, a LiveObject reference keeps everything working. Keep these two tests in sync.

        // The objects that we'll create.
        struct CreatedObjects {
            /// The queue on which we expect ably-cocoa's QueuedDealloc mechanism to enqueue the relinquishing of `weakInternalRealtime`.
            var realtimeDeallocQueue: DispatchQueue

            weak var weakPublicRealtime: ARTRealtime?
            weak var weakInternalRealtime: ARTRealtimeInternal?
            weak var weakPublicChannel: ARTRealtimeChannel?
            weak var weakInternalChannel: ARTRealtimeChannelInternal?
            weak var weakPublicRealtimeObjects: PublicDefaultRealtimeObjects?
            weak var weakInternalRealtimeObjects: InternalDefaultRealtimeObjects?
            var strongPublicLiveObject: PublicDefaultLiveMap
            weak var weakInternalLiveObject: InternalDefaultLiveMap?
        }

        // What we're left with after discarding a CreatedObjects.
        struct RemainingObjects {
            /// The queue on which we expect ably-cocoa's QueuedDealloc mechanism to enqueue the relinquishing of `weakInternalRealtime`.
            var realtimeDeallocQueue: DispatchQueue

            // weakPublicRealtime is gone now
            weak var weakInternalRealtime: ARTRealtimeInternal?
            // weakPublicChannel is gone now
            weak var weakInternalChannel: ARTRealtimeChannelInternal?
            // weakPublicRealtimeObjects is gone now
            weak var weakInternalRealtimeObjects: InternalDefaultRealtimeObjects?
            weak var weakPublicLiveObject: PublicDefaultLiveMap?
            weak var weakInternalLiveObject: InternalDefaultLiveMap?
        }

        func createAndDiscardObjects() async throws -> RemainingObjects {
            func createObjects() async throws -> CreatedObjects {
                // We disable autoConnect since being connected extends the internal Realtime instance's lifetime (it stays alive whilst connected), and I don't want that interfering with this test.
                let realtime = try await ClientHelper.realtimeWithObjects()
                // Unlike in withStrongReferenceToPublicObjectsProperty, we'll have to allow it to connect, because we need to attach so that getRoot() returns. We'll instead manually close the connection before proceeding with the test
                let channel = realtime.channels.get(UUID().uuidString, options: ClientHelper.channelOptionsWithObjects())
                try await channel.attachAsync()
                let anyObjects = channel.objects
                // For some reason putting `channel.objects as? PublicDefaultRealtimeObjects` inside the #require gives "no calls to throwing functions occur within 'try' expression" 🤷
                let objects = try #require(anyObjects as? PublicDefaultRealtimeObjects)
                let root = try #require(try await anyObjects.getRoot() as? PublicDefaultLiveMap)

                // Wait for the connection to close, as mentioned above
                async let connectionClosedPromise: Void = withCheckedContinuation { continuation in
                    realtime.connection.on(.closed) { _ in
                        continuation.resume()
                    }
                }
                realtime.connection.close()
                _ = await connectionClosedPromise

                return .init(
                    realtimeDeallocQueue: realtime.internal.queue,
                    weakPublicRealtime: realtime,
                    weakInternalRealtime: realtime.internal,
                    weakPublicChannel: channel,
                    weakInternalChannel: channel.internal,
                    weakPublicRealtimeObjects: objects,
                    weakInternalRealtimeObjects: objects.testsOnly_proxied,
                    strongPublicLiveObject: root,
                    weakInternalLiveObject: root.proxied,
                )
            }

            let createdObjects = try await createObjects()

            // The only public object we have a strong reference to is strongPublicLiveObject, so the other public objects should have already been deallocated
            #expect(createdObjects.weakPublicRealtime == nil)
            #expect(createdObjects.weakPublicChannel == nil)
            #expect(createdObjects.weakPublicRealtimeObjects == nil)

            // Now we check that, since we still have a strong reference to strongPublicLiveObject, none of the dependencies that it needs in order to function have been deallocated.
            await withCheckedContinuation { continuation in
                // We wait for everything on realtimeDeallocQueue to execute, to be sure that we'd catch a dealloc that had been enqueued via ably-cocoa's QueuedDealloc mechanism.
                createdObjects.realtimeDeallocQueue.async {
                    continuation.resume()
                }
            }
            #expect(createdObjects.weakInternalRealtime != nil)
            #expect(createdObjects.weakInternalChannel != nil)
            #expect(createdObjects.weakInternalRealtimeObjects != nil)
            #expect(createdObjects.weakInternalLiveObject != nil)

            // TODO: test that we can receive events on a LiveObject (https://github.com/ably/ably-liveobjects-swift-plugin/issues/30)

            // Note that after this return we no longer have a reference to createdObjects and thus no longer have a strong reference to our public LiveObject instance
            return .init(
                realtimeDeallocQueue: createdObjects.realtimeDeallocQueue,
                weakInternalRealtime: createdObjects.weakInternalRealtime,
                weakInternalChannel: createdObjects.weakInternalChannel,
                weakInternalRealtimeObjects: createdObjects.weakInternalRealtimeObjects,
                weakPublicLiveObject: createdObjects.strongPublicLiveObject,
                weakInternalLiveObject: createdObjects.weakInternalLiveObject,
            )
        }

        let remainingObjects = try await createAndDiscardObjects()

        // Check that the public LiveObject has been deallocated now that we've no longer got a strong reference to it
        #expect(remainingObjects.weakPublicLiveObject == nil)

        // Check that the internal objects that the public LiveObject needed in order to function have now been deallocated
        await withCheckedContinuation { continuation in
            // We wait for everything on realtimeDeallocQueue to execute, to be sure that we'd catch a dealloc that had been enqueued via ably-cocoa's QueuedDealloc mechanism.
            remainingObjects.realtimeDeallocQueue.async {
                continuation.resume()
            }
        }

        #expect(remainingObjects.weakInternalRealtime == nil)
        #expect(remainingObjects.weakInternalChannel == nil)
        #expect(remainingObjects.weakInternalRealtimeObjects == nil)
        #expect(remainingObjects.weakInternalLiveObject == nil)
    }

    @Test("Public objects have a stable identity")
    func publicObjectIdentity() async throws {
        let realtime = try await ClientHelper.realtimeWithObjects()
        defer { realtime.close() }
        let channel = realtime.channels.get(UUID().uuidString, options: ClientHelper.channelOptionsWithObjects())
        try await channel.attachAsync()

        let objects = try #require(channel.objects as? PublicDefaultRealtimeObjects)
        let root = try #require(try await objects.getRoot() as? PublicDefaultLiveMap)

        let objectsAgain = try #require(channel.objects as? PublicDefaultRealtimeObjects)
        let rootAgain = try #require(try await objectsAgain.getRoot() as? PublicDefaultLiveMap)

        #expect(objects as AnyObject === objectsAgain as AnyObject)
        #expect(root === rootAgain)
        // TODO: when we have an easy way of populating the ObjectsPool (i.e. once we have a write API) then also test with a non-root LiveMap and a counter (https://github.com/ably/ably-liveobjects-swift-plugin/issues/30)
    }
}
