import Ably
@testable import AblyLiveObjects
import Testing

// This file is copied from the file objects.test.js in ably-js.

// Disable trailing_closure so that we can pass `action:` to the TestScenario initializer, consistent with the JS code
// swiftlint:disable trailing_closure

// MARK: - Top-level helpers

private func realtimeWithObjects(options: ClientHelper.PartialClientOptions) async throws -> ARTRealtime {
    try await ClientHelper.realtimeWithObjects(options: options)
}

private func channelOptionsWithObjects() -> ARTRealtimeChannelOptions {
    ClientHelper.channelOptionsWithObjects()
}

// Swift version of the JS lexicoTimeserial function
//
// Example:
//
//    01726585978590-001@abcdefghij:001
//    |____________| |_| |________| |_|
//          |         |        |     |
//    timestamp   counter  seriesId  idx
private func lexicoTimeserial(seriesId: String, timestamp: Int64, counter: Int, index: Int? = nil) -> String {
    let paddedTimestamp = String(format: "%014d", timestamp)
    let paddedCounter = String(format: "%03d", counter)

    var result = "\(paddedTimestamp)-\(paddedCounter)@\(seriesId)"

    if let index {
        let paddedIndex = String(format: "%03d", index)
        result += ":\(paddedIndex)"
    }

    return result
}

func monitorConnectionThenCloseAndFinishAsync(_ realtime: ARTRealtime, action: @escaping @Sendable () async throws -> Void) async throws {
    defer { realtime.connection.close() }

    try await withThrowingTaskGroup { group in
        // Monitor connection state
        for state in [ARTRealtimeConnectionEvent.failed, .suspended] {
            group.addTask {
                let (stream, continuation) = AsyncThrowingStream<Void, Error>.makeStream()

                let subscription = realtime.connection.on(state) { _ in
                    realtime.close()

                    let error = NSError(
                        domain: "IntegrationTestsError",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Connection monitoring: state changed to \(state), aborting test",
                        ],
                    )
                    continuation.finish(throwing: error)
                }
                continuation.onTermination = { _ in
                    realtime.connection.off(subscription)
                }

                try await stream.first { _ in true }
            }
        }

        // Perform the action
        group.addTask {
            try await action()
        }

        // Wait for either connection monitoring to throw an error or for the action to complete
        guard let result = await group.nextResult() else {
            return
        }

        group.cancelAll()
        try result.get()
    }
}

func waitFixtureChannelIsReady(_: ARTRealtime) async throws {
    // TODO: Implement this using the subscription APIs once we've got a spec for those, but this should be fine for now
    try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
}

func waitForMapKeyUpdate(_ map: any LiveMap, _ key: String) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, _>) in
        do {
            try map.subscribe { update, subscription in
                if update.update[key] != nil {
                    subscription.unsubscribe()
                    continuation.resume()
                }
            }
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

func waitForCounterUpdate(_ counter: any LiveCounter) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, _>) in
        do {
            try counter.subscribe { _, subscription in
                subscription.unsubscribe()
                continuation.resume()
            }
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

// I added this @MainActor as an "I don't understand what's going on there; let's try this" when observing that for some reason the setter of setListenerAfterProcessingIncomingMessage was hanging inside `-[ARTSRDelegateController dispatchQueue]`. This seems to avoid it and I have not investigated more deeply 🤷
@MainActor
func waitForObjectSync(_ realtime: ARTRealtime) async throws {
    let testProxyTransport = try #require(realtime.internal.transport as? TestProxyTransport)

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        testProxyTransport.setListenerAfterProcessingIncomingMessage { protocolMessage in
            if protocolMessage.action == .objectSync {
                testProxyTransport.setListenerAfterProcessingIncomingMessage(nil)
                continuation.resume()
            }
        }
    }
}

// MARK: - Constants

private let objectsFixturesChannel = "objects_fixtures"

// MARK: - Support for parameterised tests

/// The output of `forScenarios`. One element of the one-dimensional arguments array that is passed to a Swift Testing test.
private struct TestCase<Context>: Identifiable, CustomStringConvertible {
    var disabled: Bool
    var scenario: TestScenario<Context>
    var options: ClientHelper.PartialClientOptions
    var channelName: String

    /// This `Identifiable` conformance allows us to re-run individual test cases from the Xcode UI (https://developer.apple.com/documentation/testing/parameterizedtesting#Run-selected-test-cases)
    var id: TestCaseID {
        .init(description: scenario.description, options: options)
    }

    /// This seems to determine the nice name that you see for this when it's used as a test case parameter. (I can't see anywhere that this is documented; found it by experimentation).
    var description: String {
        var result = scenario.description

        if let useBinaryProtocol = options.useBinaryProtocol {
            result += " (\(useBinaryProtocol ? "binary" : "text"))"
        }

        return result
    }
}

/// Enables `TestCase`'s conformance to `Identifiable`.
private struct TestCaseID: Encodable, Hashable {
    var description: String
    var options: ClientHelper.PartialClientOptions?
}

/// The input to `forScenarios`.
private struct TestScenario<Context> {
    var disabled: Bool
    var allTransportsAndProtocols: Bool
    var description: String
    var action: @Sendable (Context) async throws -> Void
}

private func forScenarios<Context>(_ scenarios: [TestScenario<Context>]) -> [TestCase<Context>] {
    scenarios.map { scenario -> [TestCase<Context>] in
        var clientOptions = ClientHelper.PartialClientOptions(logIdentifier: "client1")

        if scenario.allTransportsAndProtocols {
            return [true, false].map { useBinaryProtocol -> TestCase<Context> in
                clientOptions.useBinaryProtocol = useBinaryProtocol

                return .init(
                    disabled: scenario.disabled,
                    scenario: scenario,
                    options: clientOptions,
                    channelName: "\(scenario.description) \(useBinaryProtocol ? "binary" : "text")",
                )
            }
        } else {
            return [.init(disabled: scenario.disabled, scenario: scenario, options: clientOptions, channelName: scenario.description)]
        }
    }
    .flatMap(\.self)
}

private protocol Scenarios {
    associatedtype Context
    static var scenarios: [TestScenario<Context>] { get }
}

private extension Scenarios {
    static var testCases: [TestCase<Context>] {
        forScenarios(scenarios)
    }
}

// MARK: - Test lifecycle

/// Creates the fixtures on ``objectsFixturesChannel`` if not yet created.
///
/// This fulfils the role of JS's `before` hook.
private actor ObjectsFixturesTrait: SuiteTrait, TestScoping {
    private actor SetupManager {
        private var setupTask: Task<Void, Error>?

        func setUpFixtures() async throws {
            let setupTask: Task<Void, Error> = if let existingSetupTask = self.setupTask {
                existingSetupTask
            } else {
                Task {
                    let helper = try await ObjectsHelper()
                    try await helper.initForChannel(objectsFixturesChannel)
                }
            }
            self.setupTask = setupTask

            try await setupTask.value
        }
    }

    private static let setupManager = SetupManager()

    func provideScope(for _: Test, testCase _: Test.Case?, performing function: () async throws -> Void) async throws {
        try await Self.setupManager.setUpFixtures()
        try await function()
    }
}

extension Trait where Self == ObjectsFixturesTrait {
    static var objectsFixtures: Self { Self() }
}

// MARK: - Test suite

@Suite(.objectsFixtures)
private struct ObjectsIntegrationTests {
    // TODO: Add the non-parameterised tests

    enum FirstSetOfScenarios: Scenarios {
        struct Context {
            var objects: any RealtimeObjects
            var root: any LiveMap
            var objectsHelper: ObjectsHelper
            var channelName: String
            var channel: ARTRealtimeChannel
            var client: ARTRealtime
            var clientOptions: ClientHelper.PartialClientOptions
        }

        static let scenarios: [TestScenario<Context>] = {
            let objectSyncSequenceScenarios: [TestScenario<Context>] = [
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "OBJECT_SYNC sequence builds object tree on channel attachment",
                    action: { ctx in
                        let client = ctx.client

                        try await waitFixtureChannelIsReady(client)

                        let channel = client.channels.get(objectsFixturesChannel, options: channelOptionsWithObjects())
                        let objects = channel.objects

                        try await channel.attachAsync()
                        let root = try await objects.getRoot()

                        let counterKeys = ["emptyCounter", "initialValueCounter", "referencedCounter"]
                        let mapKeys = ["emptyMap", "referencedMap", "valuesMap"]
                        let rootKeysCount = counterKeys.count + mapKeys.count

                        #expect(try root.size == rootKeysCount, "Check root has correct number of keys")

                        for key in counterKeys {
                            let counter = try #require(try root.get(key: key))
                            #expect(counter.liveCounterValue != nil, "Check counter at key=\"\(key)\" in root is of type LiveCounter")
                        }

                        for key in mapKeys {
                            let map = try #require(try root.get(key: key))
                            #expect(map.liveMapValue != nil, "Check map at key=\"\(key)\" in root is of type LiveMap")
                        }

                        let valuesMap = try #require(root.get(key: "valuesMap")?.liveMapValue)
                        let valueMapKeys = [
                            "stringKey",
                            "emptyStringKey",
                            "bytesKey",
                            "emptyBytesKey",
                            "numberKey",
                            "zeroKey",
                            "trueKey",
                            "falseKey",
                            "mapKey",
                        ]
                        #expect(try valuesMap.size == valueMapKeys.count, "Check nested map has correct number of keys")
                        for key in valueMapKeys {
                            #expect(try valuesMap.get(key: key) != nil, "Check value at key=\"\(key)\" in nested map exists")
                        }
                    },
                ),
                .init(
                    disabled: true, // Uses LiveMap.set which we haven't implemented yet
                    allTransportsAndProtocols: true,
                    description: "OBJECT_SYNC sequence builds object tree with all operations applied",
                    action: { ctx in
                        let root = ctx.root
                        let objects = ctx.objects

                        // Create the promise first, before the operations that will trigger it
                        async let objectsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                try await waitForMapKeyUpdate(root, "counter")
                            }
                            group.addTask {
                                try await waitForMapKeyUpdate(root, "map")
                            }
                            while try await group.next() != nil {}
                        }

                        // MAP_CREATE
                        let map = try await objects.createMap(entries: ["shouldStay": .primitive(.string("foo")), "shouldDelete": .primitive(.string("bar"))])
                        // COUNTER_CREATE
                        let counter = try await objects.createCounter(count: 1)

                        // Set the values and await the promise
                        async let setMapPromise: Void = root.set(key: "map", value: .liveMap(map))
                        async let setCounterPromise: Void = root.set(key: "counter", value: .liveCounter(counter))
                        _ = try await (setMapPromise, setCounterPromise, objectsCreatedPromise)

                        // Create the promise first, before the operations that will trigger it
                        async let operationsAppliedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                try await waitForMapKeyUpdate(map, "anotherKey")
                            }
                            group.addTask {
                                try await waitForMapKeyUpdate(map, "shouldDelete")
                            }
                            group.addTask {
                                try await waitForCounterUpdate(counter)
                            }
                            while try await group.next() != nil {}
                        }

                        // Perform the operations and await the promise
                        async let setAnotherKeyPromise: Void = map.set(key: "anotherKey", value: .primitive(.string("baz")))
                        async let removeKeyPromise: Void = map.remove(key: "shouldDelete")
                        async let incrementPromise: Void = counter.increment(amount: 10)
                        _ = try await (setAnotherKeyPromise, removeKeyPromise, incrementPromise, operationsAppliedPromise)

                        // create a new client and check it syncs with the aggregated data
                        let client2 = try await realtimeWithObjects(options: ctx.clientOptions)

                        try await monitorConnectionThenCloseAndFinishAsync(client2) {
                            let channel2 = client2.channels.get(ctx.channelName, options: channelOptionsWithObjects())
                            let objects2 = channel2.objects

                            try await channel2.attachAsync()
                            let root2 = try await objects2.getRoot()

                            let counter2 = try #require(root2.get(key: "counter")?.liveCounterValue)
                            #expect(try counter2.value == 11, "Check counter has correct value")

                            let map2 = try #require(root2.get(key: "map")?.liveMapValue)
                            #expect(try map2.size == 2, "Check map has correct number of keys")
                            #expect(try #require(map2.get(key: "shouldStay")?.stringValue) == "foo", "Check map has correct value for \"shouldStay\" key")
                            #expect(try #require(map2.get(key: "anotherKey")?.stringValue) == "baz", "Check map has correct value for \"anotherKey\" key")
                            #expect(try map2.get(key: "shouldDelete") == nil, "Check map does not have \"shouldDelete\" key")
                        }
                    },
                ),
                .init(
                    disabled: true, // Uses LiveMap.set which we haven't implemented yet
                    allTransportsAndProtocols: false,
                    description: "OBJECT_SYNC sequence does not change references to existing objects",
                    action: { ctx in
                        let root = ctx.root
                        let objects = ctx.objects
                        let channel = ctx.channel
                        let client = ctx.client

                        // Create the promise first, before the operations that will trigger it
                        async let objectsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                try await waitForMapKeyUpdate(root, "counter")
                            }
                            group.addTask {
                                try await waitForMapKeyUpdate(root, "map")
                            }
                            while try await group.next() != nil {}
                        }

                        let map = try await objects.createMap()
                        let counter = try await objects.createCounter()

                        // Set the values and await the promise
                        async let setMapPromise: Void = root.set(key: "map", value: .liveMap(map))
                        async let setCounterPromise: Void = root.set(key: "counter", value: .liveCounter(counter))
                        _ = try await (setMapPromise, setCounterPromise, objectsCreatedPromise)

                        try await channel.detachAsync()

                        // wait for the actual OBJECT_SYNC message to confirm it was received and processed
                        async let objectSyncPromise: Void = waitForObjectSync(client)
                        try await channel.attachAsync()
                        try await objectSyncPromise

                        let newRootRef = try await channel.objects.getRoot()
                        let newMapRefMap = try #require(newRootRef.get(key: "map")?.liveMapValue)
                        let newCounterRef = try #require(newRootRef.get(key: "counter")?.liveCounterValue)

                        #expect(newRootRef === root, "Check root reference is the same after OBJECT_SYNC sequence")
                        #expect(newMapRefMap === map, "Check map reference is the same after OBJECT_SYNC sequence")
                        #expect(newCounterRef === counter, "Check counter reference is the same after OBJECT_SYNC sequence")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "LiveCounter is initialized with initial value from OBJECT_SYNC sequence",
                    action: { ctx in
                        let client = ctx.client

                        try await waitFixtureChannelIsReady(client)

                        let channel = client.channels.get(objectsFixturesChannel, options: channelOptionsWithObjects())
                        let objects = channel.objects

                        try await channel.attachAsync()
                        let root = try await objects.getRoot()

                        let counters = [
                            (key: "emptyCounter", value: 0),
                            (key: "initialValueCounter", value: 10),
                            (key: "referencedCounter", value: 20),
                        ]

                        for counter in counters {
                            let counterObj = try #require(root.get(key: counter.key)?.liveCounterValue)
                            #expect(try counterObj.value == Double(counter.value), "Check counter at key=\"\(counter.key)\" in root has correct value")
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "LiveMap is initialized with initial value from OBJECT_SYNC sequence",
                    action: { ctx in
                        let client = ctx.client

                        try await waitFixtureChannelIsReady(client)

                        let channel = client.channels.get(objectsFixturesChannel, options: channelOptionsWithObjects())
                        let objects = channel.objects

                        try await channel.attachAsync()
                        let root = try await objects.getRoot()

                        let emptyMap = try #require(root.get(key: "emptyMap")?.liveMapValue)
                        #expect(try emptyMap.size == 0, "Check empty map in root has no keys")

                        let referencedMap = try #require(root.get(key: "referencedMap")?.liveMapValue)
                        #expect(try referencedMap.size == 1, "Check referenced map in root has correct number of keys")

                        let counterFromReferencedMap = try #require(referencedMap.get(key: "counterKey")?.liveCounterValue)
                        #expect(try counterFromReferencedMap.value == 20, "Check nested counter has correct value")

                        let valuesMap = try #require(root.get(key: "valuesMap")?.liveMapValue)
                        #expect(try valuesMap.size == 9, "Check values map in root has correct number of keys")

                        #expect(try #require(valuesMap.get(key: "stringKey")?.stringValue) == "stringValue", "Check values map has correct string value key")
                        #expect(try #require(valuesMap.get(key: "emptyStringKey")?.stringValue).isEmpty, "Check values map has correct empty string value key")
                        #expect(try #require(valuesMap.get(key: "bytesKey")?.dataValue) == Data(base64Encoded: "eyJwcm9kdWN0SWQiOiAiMDAxIiwgInByb2R1Y3ROYW1lIjogImNhciJ9"), "Check values map has correct bytes value key")
                        #expect(try #require(valuesMap.get(key: "emptyBytesKey")?.dataValue) == Data(base64Encoded: ""), "Check values map has correct empty bytes values key")
                        #expect(try #require(valuesMap.get(key: "numberKey")?.numberValue) == 1, "Check values map has correct number value key")
                        #expect(try #require(valuesMap.get(key: "zeroKey")?.numberValue) == 0, "Check values map has correct zero number value key")
                        #expect(try #require(valuesMap.get(key: "trueKey")?.boolValue as Bool?) == true, "Check values map has correct 'true' value key")
                        #expect(try #require(valuesMap.get(key: "falseKey")?.boolValue as Bool?) == false, "Check values map has correct 'false' value key")

                        let mapFromValuesMap = try #require(valuesMap.get(key: "mapKey")?.liveMapValue)
                        #expect(try mapFromValuesMap.size == 1, "Check nested map has correct number of keys")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "LiveMap can reference the same object in their keys",
                    action: { ctx in
                        let client = ctx.client

                        try await waitFixtureChannelIsReady(client)

                        let channel = client.channels.get(objectsFixturesChannel, options: channelOptionsWithObjects())
                        let objects = channel.objects

                        try await channel.attachAsync()
                        let root = try await objects.getRoot()

                        let referencedCounter = try #require(root.get(key: "referencedCounter")?.liveCounterValue)
                        let referencedMap = try #require(root.get(key: "referencedMap")?.liveMapValue)
                        let valuesMap = try #require(root.get(key: "valuesMap")?.liveMapValue)

                        let counterFromReferencedMap = try #require(referencedMap.get(key: "counterKey")?.liveCounterValue, "Check nested counter is of type LiveCounter")
                        #expect(counterFromReferencedMap === referencedCounter, "Check nested counter is the same object instance as counter on the root")
                        #expect(try counterFromReferencedMap.value == 20, "Check nested counter has correct value")

                        let mapFromValuesMap = try #require(valuesMap.get(key: "mapKey")?.liveMapValue, "Check nested map is of type LiveMap")
                        #expect(try mapFromValuesMap.size == 1, "Check nested map has correct number of keys")
                        #expect(mapFromValuesMap === referencedMap, "Check nested map is the same object instance as map on the root")
                    },
                ),
                .init(
                    disabled: true, // This relies on the LiveMap.get returning `nil` when the referenced object's internal `tombstone` flag is true; this is not yet specified, have asked in https://ably-real-time.slack.com/archives/D067YAXGYQ5/p1751376526929339
                    allTransportsAndProtocols: false,
                    description: "OBJECT_SYNC sequence with object state \"tombstone\" property creates tombstoned object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        let mapId = objectsHelper.fakeMapObjectId()
                        let counterId = objectsHelper.fakeCounterObjectId()

                        try await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:", // empty serial so sync sequence ends immediately
                            // add object states with tombstone=true
                            state: [
                                objectsHelper.mapObject(
                                    objectId: mapId,
                                    siteTimeserials: ["aaa": lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)],
                                    initialEntries: [:],
                                    tombstone: true,
                                ),
                                objectsHelper.counterObject(
                                    objectId: counterId,
                                    siteTimeserials: ["aaa": lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)],
                                    initialCount: 1,
                                    tombstone: true,
                                ),
                                objectsHelper.mapObject(
                                    objectId: "root",
                                    siteTimeserials: ["aaa": lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)],
                                    initialEntries: [
                                        "map": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)),
                                            "data": .object(["objectId": .string(mapId)]),
                                        ]),
                                        "counter": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)),
                                            "data": .object(["objectId": .string(counterId)]),
                                        ]),
                                        "foo": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                    ],
                                ),
                            ],
                        )

                        #expect(try root.get(key: "map") == nil, "Check map does not exist on root after OBJECT_SYNC with \"tombstone=true\" for a map object")
                        #expect(try root.get(key: "counter") == nil, "Check counter does not exist on root after OBJECT_SYNC with \"tombstone=true\" for a counter object")
                        // control check that OBJECT_SYNC was applied at all
                        #expect(try root.get(key: "foo") != nil, "Check property exists on root after OBJECT_SYNC")
                    },
                ),
                .init(
                    disabled: true, // Uses LiveMap.subscribe (through waitForMapKeyUpdate) which we haven't implemented yet. It also seems to rely on the same internal `tombstone` flag as the previous test.
                    allTransportsAndProtocols: true,
                    description: "OBJECT_SYNC sequence with object state \"tombstone\" property deletes existing object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let channel = ctx.channel

                        async let counterCreatedPromise: Void = waitForMapKeyUpdate(root, "counter")
                        let counterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "counter",
                            createOp: objectsHelper.counterCreateRestOp(number: 1),
                        )
                        _ = try await counterCreatedPromise

                        #expect(try root.get(key: "counter") != nil, "Check counter exists on root before OBJECT_SYNC sequence with \"tombstone=true\"")

                        // inject an OBJECT_SYNC message where a counter is now tombstoned
                        try await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:", // empty serial so sync sequence ends immediately
                            state: [
                                objectsHelper.counterObject(
                                    objectId: counterResult.objectId,
                                    siteTimeserials: ["aaa": lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)],
                                    initialCount: 1,
                                    tombstone: true,
                                ),
                                objectsHelper.mapObject(
                                    objectId: "root",
                                    siteTimeserials: ["aaa": lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)],
                                    initialEntries: [
                                        "counter": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)),
                                            "data": .object(["objectId": .string(counterResult.objectId)]),
                                        ]),
                                        "foo": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                    ],
                                ),
                            ],
                        )

                        #expect(try root.get(key: "counter") == nil, "Check counter does not exist on root after OBJECT_SYNC with \"tombstone=true\" for an existing counter object")
                        // control check that OBJECT_SYNC was applied at all
                        #expect(try root.get(key: "foo") != nil, "Check property exists on root after OBJECT_SYNC")
                    },
                ),
                .init(
                    disabled: true, // Uses LiveMap.subscribe (through waitForMapKeyUpdate) which we haven't implemented yet
                    allTransportsAndProtocols: true,
                    description: "OBJECT_SYNC sequence with object state \"tombstone\" property triggers subscription callback for existing object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let channel = ctx.channel

                        async let counterCreatedPromise: Void = waitForMapKeyUpdate(root, "counter")
                        let counterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "counter",
                            createOp: objectsHelper.counterCreateRestOp(number: 1),
                        )
                        _ = try await counterCreatedPromise

                        async let counterSubPromise: Void = withCheckedThrowingContinuation { continuation in
                            do {
                                try #require(root.get(key: "counter")?.liveCounterValue).subscribe { update, _ in
                                    #expect(update.amount == -1, "Check counter subscription callback is called with an expected update object after OBJECT_SYNC sequence with \"tombstone=true\"")
                                    continuation.resume()
                                }
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }

                        // inject an OBJECT_SYNC message where a counter is now tombstoned
                        try await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:", // empty serial so sync sequence ends immediately
                            state: [
                                objectsHelper.counterObject(
                                    objectId: counterResult.objectId,
                                    siteTimeserials: ["aaa": lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)],
                                    initialCount: 1,
                                    tombstone: true,
                                ),
                                objectsHelper.mapObject(
                                    objectId: "root",
                                    siteTimeserials: ["aaa": lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)],
                                    initialEntries: [
                                        "counter": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0)),
                                            "data": .object(["objectId": .string(counterResult.objectId)]),
                                        ]),
                                    ],
                                ),
                            ],
                        )

                        _ = try await counterSubPromise
                    },
                ),
            ]

            let applyOperationsScenarios: [TestScenario<Context>] = [
                // TODO: Implement these scenarios
            ]

            let applyOperationsDuringSyncScenarios: [TestScenario<Context>] = [
                // TODO: Implement these scenarios
            ]

            let writeApiScenarios: [TestScenario<Context>] = [
                // TODO: Implement these scenarios
            ]

            let liveMapEnumerationScenarios: [TestScenario<Context>] = [
                // TODO: Implement these scenarios
            ]

            return [
                objectSyncSequenceScenarios,
                applyOperationsScenarios,
                applyOperationsDuringSyncScenarios,
                writeApiScenarios,
                liveMapEnumerationScenarios,
            ].flatMap(\.self)
        }()
    }

    @Test(arguments: FirstSetOfScenarios.testCases)
    func firstSetOfScenarios(testCase: TestCase<FirstSetOfScenarios.Context>) async throws {
        guard !testCase.disabled else {
            withKnownIssue {
                Issue.record("Test case is disabled")
            }
            return
        }

        let objectsHelper = try await ObjectsHelper()
        let client = try await realtimeWithObjects(options: testCase.options)

        try await monitorConnectionThenCloseAndFinishAsync(client) {
            let channel = client.channels.get(testCase.channelName, options: channelOptionsWithObjects())
            let objects = channel.objects

            try await channel.attachAsync()
            let root = try await objects.getRoot()

            try await testCase.scenario.action(
                .init(
                    objects: objects,
                    root: root,
                    objectsHelper: objectsHelper,
                    channelName: testCase.channelName,
                    channel: channel,
                    client: client,
                    clientOptions: testCase.options,
                ),
            )
        }
    }

    // TODO: Implement the remaining scenarios
}

// swiftlint:enable trailing_closure
