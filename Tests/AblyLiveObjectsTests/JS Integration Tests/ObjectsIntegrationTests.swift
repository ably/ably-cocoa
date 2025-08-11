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

func waitForMapKeyUpdate(_ updates: AsyncStream<LiveMapUpdate>, _ key: String) async {
    _ = await updates.first { $0.update[key] != nil }
}

func waitForCounterUpdate(_ updates: AsyncStream<LiveCounterUpdate>) async {
    _ = await updates.first { _ in true }
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

// MARK: - Top-level fixtures (ported from JS objects.test.js)

// Primitive key data fixture used across multiple test scenarios
// liveMapValue field contains the value as LiveMapValue for use in map operations
private let primitiveKeyData: [(key: String, data: [String: JSONValue], liveMapValue: LiveMapValue)] = [
    (
        key: "stringKey",
        data: ["string": .string("stringValue")],
        liveMapValue: .primitive(.string("stringValue"))
    ),
    (
        key: "emptyStringKey",
        data: ["string": .string("")],
        liveMapValue: .primitive(.string(""))
    ),
    (
        key: "bytesKey",
        data: ["bytes": .string("eyJwcm9kdWN0SWQiOiAiMDAxIiwgInByb2R1Y3ROYW1lIjogImNhciJ9")],
        liveMapValue: .primitive(.data(Data(base64Encoded: "eyJwcm9kdWN0SWQiOiAiMDAxIiwgInByb2R1Y3ROYW1lIjogImNhciJ9")!))
    ),
    (
        key: "emptyBytesKey",
        data: ["bytes": .string("")],
        liveMapValue: .primitive(.data(Data(base64Encoded: "")!))
    ),
    (
        key: "maxSafeIntegerKey",
        data: ["number": .number(.init(value: Int.max))],
        liveMapValue: .primitive(.number(Double(Int.max)))
    ),
    (
        key: "negativeMaxSafeIntegerKey",
        data: ["number": .number(.init(value: -Int.max))],
        liveMapValue: .primitive(.number(-Double(Int.max)))
    ),
    (
        key: "numberKey",
        data: ["number": .number(1)],
        liveMapValue: .primitive(.number(1))
    ),
    (
        key: "zeroKey",
        data: ["number": .number(0)],
        liveMapValue: .primitive(.number(0))
    ),
    (
        key: "trueKey",
        data: ["boolean": .bool(true)],
        liveMapValue: .primitive(.bool(true))
    ),
    (
        key: "falseKey",
        data: ["boolean": .bool(false)],
        liveMapValue: .primitive(.bool(false))
    ),
]

// Primitive maps fixtures used in map creation and write API scenarios
// entries field contains the map entries in the format expected by ObjectsHelper
// restData field contains the data in the format expected by REST API operations
// liveMapEntries field contains entries as LiveMapValue for direct map operations
private let primitiveMapsFixtures: [(name: String, entries: [String: [String: JSONValue]]?, restData: [String: JSONValue]?, liveMapEntries: [String: LiveMapValue]?)] = [
    (name: "emptyMap", entries: nil, restData: nil, liveMapEntries: nil),
    (name: "valuesMap",
     entries: Dictionary(uniqueKeysWithValues: primitiveKeyData.map { ($0.key, ["data": .object($0.data)]) }),
     restData: Dictionary(uniqueKeysWithValues: primitiveKeyData.map { ($0.key, .object($0.data)) }),
     liveMapEntries: Dictionary(uniqueKeysWithValues: primitiveKeyData.map { ($0.key, $0.liveMapValue) })),
]

// Counters fixtures used in counter creation and write API scenarios
// count field supports both Int and Double types depending on the test scenario
private let countersFixtures: [(name: String, count: Double?)] = [
    (name: "emptyCounter", count: nil),
    (name: "zeroCounter", count: 0),
    (name: "valueCounter", count: 10),
    (name: "negativeValueCounter", count: -10),
    (name: "maxSafeIntegerCounter", count: Double(Int.max)),
    (name: "negativeMaxSafeIntegerCounter", count: -Double(Int.max)),
]

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
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "OBJECT_SYNC sequence builds object tree with all operations applied",
                    action: { ctx in
                        let root = ctx.root
                        let objects = ctx.objects

                        // Create the promise first, before the operations that will trigger it
                        let objectsCreatedPromiseUpdates1 = try root.updates()
                        let objectsCreatedPromiseUpdates2 = try root.updates()
                        async let objectsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates1, "counter")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates2, "map")
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
                        let operationsAppliedPromiseUpdates1 = try map.updates()
                        let operationsAppliedPromiseUpdates2 = try map.updates()
                        let operationsAppliedPromiseUpdates3 = try counter.updates()
                        async let operationsAppliedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await waitForMapKeyUpdate(operationsAppliedPromiseUpdates1, "anotherKey")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(operationsAppliedPromiseUpdates2, "shouldDelete")
                            }
                            group.addTask {
                                await waitForCounterUpdate(operationsAppliedPromiseUpdates3)
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
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "OBJECT_SYNC sequence does not change references to existing objects",
                    action: { ctx in
                        let root = ctx.root
                        let objects = ctx.objects
                        let channel = ctx.channel
                        let client = ctx.client

                        // Create the promise first, before the operations that will trigger it
                        let objectsCreatedPromiseUpdates1 = try root.updates()
                        let objectsCreatedPromiseUpdates2 = try root.updates()
                        async let objectsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates1, "counter")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates2, "map")
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
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "OBJECT_SYNC sequence with object state \"tombstone\" property creates tombstoned object",
                    action: { ctx throws in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        let mapId = objectsHelper.fakeMapObjectId()
                        let counterId = objectsHelper.fakeCounterObjectId()

                        await objectsHelper.processObjectStateMessageOnChannel(
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
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "OBJECT_SYNC sequence with object state \"tombstone\" property deletes existing object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let channel = ctx.channel

                        let counterCreatedPromiseUpdates = try root.updates()
                        async let counterCreatedPromise: Void = waitForMapKeyUpdate(counterCreatedPromiseUpdates, "counter")
                        let counterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "counter",
                            createOp: objectsHelper.counterCreateRestOp(number: 1),
                        )
                        _ = await counterCreatedPromise

                        #expect(try root.get(key: "counter") != nil, "Check counter exists on root before OBJECT_SYNC sequence with \"tombstone=true\"")

                        // inject an OBJECT_SYNC message where a counter is now tombstoned
                        await objectsHelper.processObjectStateMessageOnChannel(
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
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "OBJECT_SYNC sequence with object state \"tombstone\" property triggers subscription callback for existing object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let channel = ctx.channel

                        let counterCreatedPromiseUpdates = try root.updates()
                        async let counterCreatedPromise: Void = waitForMapKeyUpdate(counterCreatedPromiseUpdates, "counter")
                        let counterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "counter",
                            createOp: objectsHelper.counterCreateRestOp(number: 1),
                        )
                        _ = await counterCreatedPromise

                        let counterSubPromiseUpdates = try #require(root.get(key: "counter")?.liveCounterValue).updates()
                        async let counterSubPromise: Void = {
                            let update = try await #require(counterSubPromiseUpdates.first { _ in true })
                            #expect(update.amount == -1, "Check counter subscription callback is called with an expected update object after OBJECT_SYNC sequence with \"tombstone=true\"")
                        }()

                        // inject an OBJECT_SYNC message where a counter is now tombstoned
                        await objectsHelper.processObjectStateMessageOnChannel(
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
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "can apply MAP_CREATE with primitives object operation messages",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName

                        // Check no maps exist on root
                        for fixture in primitiveMapsFixtures {
                            let key = fixture.name
                            #expect(try root.get(key: key) == nil, "Check \"\(key)\" key doesn't exist on root before applying MAP_CREATE ops")
                        }

                        // Create promises for waiting for map updates
                        let mapsCreatedPromiseUpdates = try primitiveMapsFixtures.map { _ in try root.updates() }
                        async let mapsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            for (i, fixture) in primitiveMapsFixtures.enumerated() {
                                group.addTask {
                                    await waitForMapKeyUpdate(mapsCreatedPromiseUpdates[i], fixture.name)
                                }
                            }
                            while try await group.next() != nil {}
                        }

                        // Create new maps and set on root
                        _ = try await withThrowingTaskGroup(of: ObjectsHelper.OperationResult.self) { group in
                            for fixture in primitiveMapsFixtures {
                                group.addTask {
                                    try await objectsHelper.createAndSetOnMap(
                                        channelName: channelName,
                                        mapObjectId: "root",
                                        key: fixture.name,
                                        createOp: objectsHelper.mapCreateRestOp(data: fixture.restData),
                                    )
                                }
                            }
                            var results: [ObjectsHelper.OperationResult] = []
                            while let result = try await group.next() {
                                results.append(result)
                            }
                            return results
                        }
                        _ = try await mapsCreatedPromise

                        // Check created maps
                        for fixture in primitiveMapsFixtures {
                            let mapKey = fixture.name
                            let mapObj = try #require(root.get(key: mapKey)?.liveMapValue)

                            // Check all maps exist on root and are of correct type
                            #expect(try mapObj.size == (fixture.entries?.count ?? 0), "Check map \"\(mapKey)\" has correct number of keys")

                            if let entries = fixture.entries {
                                for (key, keyData) in entries {
                                    let data = keyData["data"]!.objectValue!

                                    if let bytesString = data["bytes"]?.stringValue {
                                        let expectedData = Data(base64Encoded: bytesString)
                                        #expect(try mapObj.get(key: key)?.dataValue == expectedData, "Check map \"\(mapKey)\" has correct value for \"\(key)\" key")
                                    } else if let numberValue = data["number"]?.numberValue {
                                        #expect(try mapObj.get(key: key)?.numberValue == numberValue.doubleValue, "Check map \"\(mapKey)\" has correct value for \"\(key)\" key")
                                    } else if let stringValue = data["string"]?.stringValue {
                                        #expect(try mapObj.get(key: key)?.stringValue == stringValue, "Check map \"\(mapKey)\" has correct value for \"\(key)\" key")
                                    } else if let boolValue = data["boolean"]?.boolValue {
                                        #expect(try mapObj.get(key: key)?.boolValue == boolValue, "Check map \"\(mapKey)\" has correct value for \"\(key)\" key")
                                    }
                                }
                            }
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "can apply MAP_CREATE with object ids object operation messages",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let withReferencesMapKey = "withReferencesMap"

                        // Check map does not exist on root
                        #expect(try root.get(key: withReferencesMapKey) == nil, "Check \"\(withReferencesMapKey)\" key doesn't exist on root before applying MAP_CREATE ops")

                        let mapCreatedPromiseUpdates = try root.updates()
                        async let mapCreatedPromise: Void = waitForMapKeyUpdate(mapCreatedPromiseUpdates, withReferencesMapKey)

                        // Create map with references - need to create referenced objects first to obtain their object ids
                        // We'll create them separately first, then reference them
                        let tempMapUpdates = try root.updates()
                        let tempCounterUpdates = try root.updates()
                        async let tempObjectsPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await waitForMapKeyUpdate(tempMapUpdates, "tempMap")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(tempCounterUpdates, "tempCounter")
                            }
                            while try await group.next() != nil {}
                        }

                        let referencedMapResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "tempMap",
                            createOp: objectsHelper.mapCreateRestOp(data: ["stringKey": .object(["string": .string("stringValue")])]),
                        )
                        let referencedCounterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "tempCounter",
                            createOp: objectsHelper.counterCreateRestOp(number: 1),
                        )
                        _ = try await tempObjectsPromise

                        _ = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: withReferencesMapKey,
                            createOp: objectsHelper.mapCreateRestOp(data: [
                                "mapReference": .object(["objectId": .string(referencedMapResult.objectId)]),
                                "counterReference": .object(["objectId": .string(referencedCounterResult.objectId)]),
                            ]),
                        )
                        _ = await mapCreatedPromise

                        // Check map with references exist on root
                        let withReferencesMap = try #require(root.get(key: withReferencesMapKey)?.liveMapValue)
                        #expect(try withReferencesMap.size == 2, "Check map \"\(withReferencesMapKey)\" has correct number of keys")

                        let referencedCounter = try #require(withReferencesMap.get(key: "counterReference")?.liveCounterValue)
                        #expect(try referencedCounter.value == 1, "Check counter at \"counterReference\" key has correct value")

                        let referencedMap = try #require(withReferencesMap.get(key: "mapReference")?.liveMapValue)
                        #expect(try referencedMap.size == 1, "Check map at \"mapReference\" key has correct number of keys")
                        #expect(try #require(referencedMap.get(key: "stringKey")?.stringValue) == "stringValue", "Check map at \"mapReference\" key has correct \"stringKey\" value")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "MAP_CREATE object operation messages are applied based on the site timeserials vector of the object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        // Need to use multiple maps as MAP_CREATE op can only be applied once to a map object
                        let mapIds = [
                            objectsHelper.fakeMapObjectId(),
                            objectsHelper.fakeMapObjectId(),
                            objectsHelper.fakeMapObjectId(),
                            objectsHelper.fakeMapObjectId(),
                            objectsHelper.fakeMapObjectId(),
                        ]

                        // Send MAP_SET ops first to create zero-value maps with forged site timeserials vector
                        for (i, mapId) in mapIds.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0),
                                siteCode: "bbb",
                                state: [objectsHelper.mapSetOp(objectId: mapId, key: "foo", data: .object(["string": .string("bar")]))],
                            )
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "aaa", timestamp: Int64(i), counter: 0),
                                siteCode: "aaa",
                                state: [objectsHelper.mapSetOp(objectId: "root", key: mapId, data: .object(["objectId": .string(mapId)]))],
                            )
                        }

                        // Inject operations with various timeserial values
                        let timeserialTestCases = [
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0), siteCode: "bbb"), // existing site, earlier CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0), siteCode: "bbb"), // existing site, same CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb"), // existing site, later CGO, applied
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0), siteCode: "aaa"), // different site, earlier CGO, applied
                            (serial: lexicoTimeserial(seriesId: "ccc", timestamp: 9, counter: 0), siteCode: "ccc"), // different site, later CGO, applied
                        ]

                        for (i, testCase) in timeserialTestCases.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: testCase.serial,
                                siteCode: testCase.siteCode,
                                state: [
                                    objectsHelper.mapCreateOp(
                                        objectId: mapIds[i],
                                        entries: [
                                            "baz": .object([
                                                "timeserial": .string(testCase.serial),
                                                "data": .object(["string": .string("qux")]),
                                            ]),
                                        ],
                                    ),
                                ],
                            )
                        }

                        // Check only operations with correct timeserials were applied
                        let expectedMapValues: [[String: String]] = [
                            ["foo": "bar"],
                            ["foo": "bar"],
                            ["foo": "bar", "baz": "qux"], // applied MAP_CREATE
                            ["foo": "bar", "baz": "qux"], // applied MAP_CREATE
                            ["foo": "bar", "baz": "qux"], // applied MAP_CREATE
                        ]

                        for (i, mapId) in mapIds.enumerated() {
                            let expectedMapValue = expectedMapValues[i]
                            let expectedKeysCount = expectedMapValue.count

                            let mapObj = try #require(root.get(key: mapId)?.liveMapValue)
                            #expect(try mapObj.size == expectedKeysCount, "Check map #\(i + 1) has expected number of keys after MAP_CREATE ops")

                            for (key, value) in expectedMapValue {
                                #expect(try #require(mapObj.get(key: key)?.stringValue) == value, "Check map #\(i + 1) has expected value for \"\(key)\" key after MAP_CREATE ops")
                            }
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "can apply MAP_SET with primitives object operation messages",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName

                        // Check root is empty before ops
                        for keyData in primitiveKeyData {
                            #expect(try root.get(key: keyData.key) == nil, "Check \"\(keyData.key)\" key doesn't exist on root before applying MAP_SET ops")
                        }

                        // Create promises for waiting for key updates
                        let keysUpdatedPromiseUpdates = try primitiveKeyData.map { _ in try root.updates() }
                        async let keysUpdatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            for (i, keyData) in primitiveKeyData.enumerated() {
                                group.addTask {
                                    await waitForMapKeyUpdate(keysUpdatedPromiseUpdates[i], keyData.key)
                                }
                            }
                            while try await group.next() != nil {}
                        }

                        // Apply MAP_SET ops using createAndSetOnMap helper which internally uses MAP_SET
                        _ = try await withThrowingTaskGroup(of: ObjectsHelper.OperationResult.self) { group in
                            for keyData in primitiveKeyData {
                                group.addTask {
                                    // We'll create dummy objects and set them, which uses MAP_SET internally
                                    try await objectsHelper.createAndSetOnMap(
                                        channelName: channelName,
                                        mapObjectId: "root",
                                        key: keyData.key,
                                        createOp: objectsHelper.mapCreateRestOp(data: ["value": .object(keyData.data)]),
                                    )
                                }
                            }
                            var results: [ObjectsHelper.OperationResult] = []
                            while let result = try await group.next() {
                                results.append(result)
                            }
                            return results
                        }
                        _ = try await keysUpdatedPromise

                        // Check everything is applied correctly
                        for keyData in primitiveKeyData {
                            let mapValue = try #require(root.get(key: keyData.key)?.liveMapValue)

                            if let bytesString = keyData.data["bytes"]?.stringValue {
                                let expectedData = Data(base64Encoded: bytesString)
                                #expect(try mapValue.get(key: "value")?.dataValue == expectedData, "Check root has correct value for \"\(keyData.key)\" key after MAP_SET op")
                            } else if let numberValue = keyData.data["number"]?.numberValue {
                                #expect(try mapValue.get(key: "value")?.numberValue == numberValue.doubleValue, "Check root has correct value for \"\(keyData.key)\" key after MAP_SET op")
                            } else if let stringValue = keyData.data["string"]?.stringValue {
                                #expect(try mapValue.get(key: "value")?.stringValue == stringValue, "Check root has correct value for \"\(keyData.key)\" key after MAP_SET op")
                            } else if let boolValue = keyData.data["boolean"]?.boolValue {
                                #expect(try mapValue.get(key: "value")?.boolValue == boolValue, "Check root has correct value for \"\(keyData.key)\" key after MAP_SET op")
                            }
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "can apply MAP_SET with object ids object operation messages",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName

                        // Check no object ids are set on root
                        #expect(try root.get(key: "keyToCounter") == nil, "Check \"keyToCounter\" key doesn't exist on root before applying MAP_SET ops")
                        #expect(try root.get(key: "keyToMap") == nil, "Check \"keyToMap\" key doesn't exist on root before applying MAP_SET ops")

                        let objectsCreatedPromiseUpdates1 = try root.updates()
                        let objectsCreatedPromiseUpdates2 = try root.updates()
                        async let objectsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates1, "keyToCounter")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates2, "keyToMap")
                            }
                            while try await group.next() != nil {}
                        }

                        // Create new objects and set on root
                        _ = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "keyToCounter",
                            createOp: objectsHelper.counterCreateRestOp(number: 1),
                        )

                        _ = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "keyToMap",
                            createOp: objectsHelper.mapCreateRestOp(data: ["stringKey": .object(["string": .string("stringValue")])]),
                        )
                        _ = try await objectsCreatedPromise

                        // Check root has refs to new objects and they are not zero-value
                        let counter = try #require(root.get(key: "keyToCounter")?.liveCounterValue)
                        #expect(try counter.value == 1, "Check counter at \"keyToCounter\" key in root has correct value")

                        let map = try #require(root.get(key: "keyToMap")?.liveMapValue)
                        #expect(try map.size == 1, "Check map at \"keyToMap\" key in root has correct number of keys")
                        #expect(try #require(map.get(key: "stringKey")?.stringValue) == "stringValue", "Check map at \"keyToMap\" key in root has correct \"stringKey\" value")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "can apply COUNTER_CREATE object operation messages",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName

                        // Check no counters exist on root
                        for fixture in countersFixtures {
                            let key = fixture.name
                            #expect(try root.get(key: key) == nil, "Check \"\(key)\" key doesn't exist on root before applying COUNTER_CREATE ops")
                        }

                        // Create promises for waiting for counter updates
                        let countersCreatedPromiseUpdates = try countersFixtures.map { _ in try root.updates() }
                        async let countersCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            for (i, fixture) in countersFixtures.enumerated() {
                                group.addTask {
                                    await waitForMapKeyUpdate(countersCreatedPromiseUpdates[i], fixture.name)
                                }
                            }
                            while try await group.next() != nil {}
                        }

                        // Create new counters and set on root
                        _ = try await withThrowingTaskGroup(of: ObjectsHelper.OperationResult.self) { group in
                            for fixture in countersFixtures {
                                group.addTask {
                                    try await objectsHelper.createAndSetOnMap(
                                        channelName: channelName,
                                        mapObjectId: "root",
                                        key: fixture.name,
                                        createOp: objectsHelper.counterCreateRestOp(number: fixture.count),
                                    )
                                }
                            }
                            var results: [ObjectsHelper.OperationResult] = []
                            while let result = try await group.next() {
                                results.append(result)
                            }
                            return results
                        }
                        _ = try await countersCreatedPromise

                        // Check created counters
                        for fixture in countersFixtures {
                            let key = fixture.name
                            let counterObj = try #require(root.get(key: key)?.liveCounterValue)

                            // Check counters have correct values
                            let expectedValue = fixture.count ?? 0
                            #expect(try counterObj.value == expectedValue, "Check counter at \"\(key)\" key in root has correct value")
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "can apply COUNTER_INC object operation messages",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let counterKey = "counter"
                        var expectedCounterValue = 0.0

                        let counterCreatedPromiseUpdates = try root.updates()
                        async let counterCreatedPromise: Void = waitForMapKeyUpdate(counterCreatedPromiseUpdates, counterKey)

                        // Create new counter and set on root
                        let counterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: counterKey,
                            createOp: objectsHelper.counterCreateRestOp(number: expectedCounterValue),
                        )
                        _ = await counterCreatedPromise

                        let counter = try #require(root.get(key: counterKey)?.liveCounterValue)
                        // Check counter has expected value before COUNTER_INC
                        #expect(try counter.value == expectedCounterValue, "Check counter at \"\(counterKey)\" key in root has correct value before COUNTER_INC")

                        let increments = [1, 10, 100, -111, -1, -10]

                        // Send increments one at a time and check expected value
                        for (i, increment) in increments.enumerated() {
                            expectedCounterValue += Double(increment)

                            let counterUpdatedPromiseUpdates = try counter.updates()
                            async let counterUpdatedPromise: Void = waitForCounterUpdate(counterUpdatedPromiseUpdates)

                            // Use the public API to increment - this will send COUNTER_INC internally
                            try await counter.increment(amount: Double(increment))
                            _ = await counterUpdatedPromise

                            #expect(try counter.value == expectedCounterValue, "Check counter at \"\(counterKey)\" key in root has correct value after \(i + 1) COUNTER_INC ops")
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "can apply OBJECT_DELETE object operation messages",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let channel = ctx.channel

                        let objectsCreatedPromiseUpdates1 = try root.updates()
                        let objectsCreatedPromiseUpdates2 = try root.updates()
                        async let objectsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates1, "map")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates2, "counter")
                            }
                            while try await group.next() != nil {}
                        }

                        // Create initial objects and set on root
                        let mapResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "map",
                            createOp: objectsHelper.mapCreateRestOp(),
                        )
                        let counterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "counter",
                            createOp: objectsHelper.counterCreateRestOp(),
                        )
                        _ = try await objectsCreatedPromise

                        #expect(try root.get(key: "map") != nil, "Check map exists on root before OBJECT_DELETE")
                        #expect(try root.get(key: "counter") != nil, "Check counter exists on root before OBJECT_DELETE")

                        // Inject OBJECT_DELETE operations
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: mapResult.objectId)],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 1, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: counterResult.objectId)],
                        )

                        #expect(try root.get(key: "map") == nil, "Check map is not accessible on root after OBJECT_DELETE")
                        #expect(try root.get(key: "counter") == nil, "Check counter is not accessible on root after OBJECT_DELETE")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: true,
                    description: "can apply MAP_REMOVE object operation messages",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let mapKey = "map"

                        let mapCreatedPromiseUpdates = try root.updates()
                        async let mapCreatedPromise: Void = waitForMapKeyUpdate(mapCreatedPromiseUpdates, mapKey)

                        // Create new map and set on root
                        let mapResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: mapKey,
                            createOp: objectsHelper.mapCreateRestOp(data: [
                                "shouldStay": .object(["string": .string("foo")]),
                                "shouldDelete": .object(["string": .string("bar")]),
                            ]),
                        )
                        _ = await mapCreatedPromise

                        let map = try #require(root.get(key: mapKey)?.liveMapValue)
                        // Check map has expected keys before MAP_REMOVE ops
                        #expect(try map.size == 2, "Check map at \"\(mapKey)\" key in root has correct number of keys before MAP_REMOVE")
                        #expect(try #require(map.get(key: "shouldStay")?.stringValue) == "foo", "Check map at \"\(mapKey)\" key in root has correct \"shouldStay\" value before MAP_REMOVE")
                        #expect(try #require(map.get(key: "shouldDelete")?.stringValue) == "bar", "Check map at \"\(mapKey)\" key in root has correct \"shouldDelete\" value before MAP_REMOVE")

                        let keyRemovedPromiseUpdates = try map.updates()
                        async let keyRemovedPromise: Void = waitForMapKeyUpdate(keyRemovedPromiseUpdates, "shouldDelete")

                        // Send MAP_REMOVE op using the public API
                        try await map.remove(key: "shouldDelete")
                        _ = await keyRemovedPromise

                        // Check map has correct keys after MAP_REMOVE ops
                        #expect(try map.size == 1, "Check map at \"\(mapKey)\" key in root has correct number of keys after MAP_REMOVE")
                        #expect(try #require(map.get(key: "shouldStay")?.stringValue) == "foo", "Check map at \"\(mapKey)\" key in root has correct \"shouldStay\" value after MAP_REMOVE")
                        #expect(try map.get(key: "shouldDelete") == nil, "Check map at \"\(mapKey)\" key in root has no \"shouldDelete\" key after MAP_REMOVE")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "OBJECT_DELETE for unknown object id creates zero-value tombstoned object",
                    action: { ctx throws in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        let counterId = objectsHelper.fakeCounterObjectId()
                        // Inject OBJECT_DELETE - should create a zero-value tombstoned object which can't be modified
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: counterId)],
                        )

                        // Try to create and set tombstoned object on root
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0),
                            siteCode: "bbb",
                            state: [objectsHelper.counterCreateOp(objectId: counterId)],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0),
                            siteCode: "bbb",
                            state: [objectsHelper.mapSetOp(objectId: "root", key: "counter", data: .object(["objectId": .string(counterId)]))],
                        )

                        #expect(try root.get(key: "counter") == nil, "Check counter is not accessible on root")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "MAP_SET with reference to a tombstoned object results in undefined value on key",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let channel = ctx.channel

                        let objectCreatedPromiseUpdates = try root.updates()
                        async let objectCreatedPromise: Void = waitForMapKeyUpdate(objectCreatedPromiseUpdates, "foo")

                        // Create initial objects and set on root
                        let counterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "foo",
                            createOp: objectsHelper.counterCreateRestOp(),
                        )
                        _ = await objectCreatedPromise

                        #expect(try root.get(key: "foo") != nil, "Check counter exists on root before OBJECT_DELETE")

                        // Inject OBJECT_DELETE
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: counterResult.objectId)],
                        )

                        // Set tombstoned counter to another key on root
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.mapSetOp(objectId: "root", key: "bar", data: .object(["objectId": .string(counterResult.objectId)]))],
                        )

                        #expect(try root.get(key: "bar") == nil, "Check counter is not accessible on new key in root after OBJECT_DELETE")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "object operation message on a tombstoned object does not revive it",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let channel = ctx.channel

                        let objectsCreatedPromiseUpdates1 = try root.updates()
                        let objectsCreatedPromiseUpdates2 = try root.updates()
                        let objectsCreatedPromiseUpdates3 = try root.updates()
                        async let objectsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates1, "map1")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates2, "map2")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates3, "counter1")
                            }
                            while try await group.next() != nil {}
                        }

                        // Create initial objects and set on root
                        let mapResult1 = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "map1",
                            createOp: objectsHelper.mapCreateRestOp(),
                        )
                        let mapResult2 = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "map2",
                            createOp: objectsHelper.mapCreateRestOp(data: ["foo": .object(["string": .string("bar")])]),
                        )
                        let counterResult1 = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "counter1",
                            createOp: objectsHelper.counterCreateRestOp(),
                        )
                        _ = try await objectsCreatedPromise

                        #expect(try root.get(key: "map1") != nil, "Check map1 exists on root before OBJECT_DELETE")
                        #expect(try root.get(key: "map2") != nil, "Check map2 exists on root before OBJECT_DELETE")
                        #expect(try root.get(key: "counter1") != nil, "Check counter1 exists on root before OBJECT_DELETE")

                        // Inject OBJECT_DELETE operations
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: mapResult1.objectId)],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 1, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: mapResult2.objectId)],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 2, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: counterResult1.objectId)],
                        )

                        // Inject object operations on tombstoned objects
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 3, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.mapSetOp(objectId: mapResult1.objectId, key: "baz", data: .object(["string": .string("qux")]))],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 4, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.mapRemoveOp(objectId: mapResult2.objectId, key: "foo")],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 5, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.counterIncOp(objectId: counterResult1.objectId, amount: 1)],
                        )

                        // Objects should still be deleted
                        #expect(try root.get(key: "map1") == nil, "Check map1 does not exist on root after OBJECT_DELETE and another object op")
                        #expect(try root.get(key: "map2") == nil, "Check map2 does not exist on root after OBJECT_DELETE and another object op")
                        #expect(try root.get(key: "counter1") == nil, "Check counter1 does not exist on root after OBJECT_DELETE and another object op")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "MAP_SET object operation messages are applied based on the site timeserials vector of the object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        // Create new map and set it on a root with forged timeserials
                        let mapId = objectsHelper.fakeMapObjectId()
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0),
                            siteCode: "bbb",
                            state: [
                                objectsHelper.mapCreateOp(
                                    objectId: mapId,
                                    entries: [
                                        "foo1": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo2": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo3": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo4": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo5": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo6": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                    ],
                                ),
                            ],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.mapSetOp(objectId: "root", key: "map", data: .object(["objectId": .string(mapId)]))],
                        )

                        // Inject operations with various timeserial values
                        let timeserialTestCases = [
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0), siteCode: "bbb"), // existing site, earlier site CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0), siteCode: "bbb"), // existing site, same site CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb"), // existing site, later site CGO, applied, site timeserials updated
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb"), // existing site, same site CGO (updated from last op), not applied
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0), siteCode: "aaa"), // different site, earlier entry CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "ccc", timestamp: 9, counter: 0), siteCode: "ccc"), // different site, later entry CGO, applied
                        ]

                        for (i, testCase) in timeserialTestCases.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: testCase.serial,
                                siteCode: testCase.siteCode,
                                state: [objectsHelper.mapSetOp(objectId: mapId, key: "foo\(i + 1)", data: .object(["string": .string("baz")]))],
                            )
                        }

                        // Check only operations with correct timeserials were applied
                        let expectedMapKeys: [(key: String, value: String)] = [
                            (key: "foo1", value: "bar"),
                            (key: "foo2", value: "bar"),
                            (key: "foo3", value: "baz"), // updated
                            (key: "foo4", value: "bar"),
                            (key: "foo5", value: "bar"),
                            (key: "foo6", value: "baz"), // updated
                        ]

                        let mapObj = try #require(root.get(key: "map")?.liveMapValue)
                        for expectedMapKey in expectedMapKeys {
                            #expect(try #require(mapObj.get(key: expectedMapKey.key)?.stringValue) == expectedMapKey.value, "Check \"\(expectedMapKey.key)\" key on map has expected value after MAP_SET ops")
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "COUNTER_INC object operation messages are applied based on the site timeserials vector of the object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        // Create new counter and set it on a root with forged timeserials
                        let counterId = objectsHelper.fakeCounterObjectId()
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0),
                            siteCode: "bbb",
                            state: [objectsHelper.counterCreateOp(objectId: counterId, count: 1)],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.mapSetOp(objectId: "root", key: "counter", data: .object(["objectId": .string(counterId)]))],
                        )

                        // Inject operations with various timeserial values
                        let timeserialTestCases = [
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0), siteCode: "bbb", amount: 10), // existing site, earlier CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0), siteCode: "bbb", amount: 100), // existing site, same CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb", amount: 1000), // existing site, later CGO, applied, site timeserials updated
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb", amount: 10000), // existing site, same CGO (updated from last op), not applied
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0), siteCode: "aaa", amount: 100_000), // different site, earlier CGO, applied
                            (serial: lexicoTimeserial(seriesId: "ccc", timestamp: 9, counter: 0), siteCode: "ccc", amount: 1_000_000), // different site, later CGO, applied
                        ]

                        for testCase in timeserialTestCases {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: testCase.serial,
                                siteCode: testCase.siteCode,
                                state: [objectsHelper.counterIncOp(objectId: counterId, amount: testCase.amount)],
                            )
                        }

                        // Check only operations with correct timeserials were applied
                        let counter = try #require(root.get(key: "counter")?.liveCounterValue)
                        let expectedValue = 1.0 + 1000.0 + 100_000.0 + 1_000_000.0 // sum of passing operations and the initial value
                        #expect(try counter.value == expectedValue, "Check counter has expected value after COUNTER_INC ops")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "MAP_REMOVE object operation messages are applied based on the site timeserials vector of the object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        // Create new map and set it on a root with forged timeserials
                        let mapId = objectsHelper.fakeMapObjectId()
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0),
                            siteCode: "bbb",
                            state: [
                                objectsHelper.mapCreateOp(
                                    objectId: mapId,
                                    entries: [
                                        "foo1": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo2": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo3": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo4": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo5": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo6": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                    ],
                                ),
                            ],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.mapSetOp(objectId: "root", key: "map", data: .object(["objectId": .string(mapId)]))],
                        )

                        // Inject operations with various timeserial values
                        let timeserialTestCases = [
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0), siteCode: "bbb"), // existing site, earlier site CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0), siteCode: "bbb"), // existing site, same site CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb"), // existing site, later site CGO, applied, site timeserials updated
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb"), // existing site, same site CGO (updated from last op), not applied
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0), siteCode: "aaa"), // different site, earlier entry CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "ccc", timestamp: 9, counter: 0), siteCode: "ccc"), // different site, later entry CGO, applied
                        ]

                        for (i, testCase) in timeserialTestCases.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: testCase.serial,
                                siteCode: testCase.siteCode,
                                state: [objectsHelper.mapRemoveOp(objectId: mapId, key: "foo\(i + 1)")],
                            )
                        }

                        // Check only operations with correct timeserials were applied
                        let expectedMapKeys: [(key: String, exists: Bool)] = [
                            (key: "foo1", exists: true),
                            (key: "foo2", exists: true),
                            (key: "foo3", exists: false), // removed
                            (key: "foo4", exists: true),
                            (key: "foo5", exists: true),
                            (key: "foo6", exists: false), // removed
                        ]

                        let mapObj = try #require(root.get(key: "map")?.liveMapValue)
                        for expectedMapKey in expectedMapKeys {
                            if expectedMapKey.exists {
                                #expect(try mapObj.get(key: expectedMapKey.key) != nil, "Check \"\(expectedMapKey.key)\" key on map still exists after MAP_REMOVE ops")
                            } else {
                                #expect(try mapObj.get(key: expectedMapKey.key) == nil, "Check \"\(expectedMapKey.key)\" key on map does not exist after MAP_REMOVE ops")
                            }
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "COUNTER_CREATE object operation messages are applied based on the site timeserials vector of the object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        // Need to use multiple counters as COUNTER_CREATE op can only be applied once to a counter object
                        let counterIds = [
                            objectsHelper.fakeCounterObjectId(),
                            objectsHelper.fakeCounterObjectId(),
                            objectsHelper.fakeCounterObjectId(),
                            objectsHelper.fakeCounterObjectId(),
                            objectsHelper.fakeCounterObjectId(),
                        ]

                        // Send COUNTER_INC ops first to create zero-value counters with forged site timeserials vector
                        for (i, counterId) in counterIds.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0),
                                siteCode: "bbb",
                                state: [objectsHelper.counterIncOp(objectId: counterId, amount: 1)],
                            )
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "aaa", timestamp: Int64(i), counter: 0),
                                siteCode: "aaa",
                                state: [objectsHelper.mapSetOp(objectId: "root", key: counterId, data: .object(["objectId": .string(counterId)]))],
                            )
                        }

                        // Inject operations with various timeserial values
                        let timeserialTestCases = [
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0), siteCode: "bbb"), // existing site, earlier CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0), siteCode: "bbb"), // existing site, same CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb"), // existing site, later CGO, applied
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0), siteCode: "aaa"), // different site, earlier CGO, applied
                            (serial: lexicoTimeserial(seriesId: "ccc", timestamp: 9, counter: 0), siteCode: "ccc"), // different site, later CGO, applied
                        ]

                        for (i, testCase) in timeserialTestCases.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: testCase.serial,
                                siteCode: testCase.siteCode,
                                state: [objectsHelper.counterCreateOp(objectId: counterIds[i], count: 10)],
                            )
                        }

                        // Check only operations with correct timeserials were applied
                        let expectedCounterValues = [
                            1.0,
                            1.0,
                            11.0, // applied COUNTER_CREATE
                            11.0, // applied COUNTER_CREATE
                            11.0, // applied COUNTER_CREATE
                        ]

                        for (i, counterId) in counterIds.enumerated() {
                            let expectedValue = expectedCounterValues[i]
                            let counter = try #require(root.get(key: counterId)?.liveCounterValue)
                            #expect(try counter.value == expectedValue, "Check counter #\(i + 1) has expected value after COUNTER_CREATE ops")
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "OBJECT_DELETE object operation messages are applied based on the site timeserials vector of the object",
                    action: { ctx throws in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        // Need to use multiple objects as OBJECT_DELETE op can only be applied once to an object
                        let counterIds = [
                            objectsHelper.fakeCounterObjectId(),
                            objectsHelper.fakeCounterObjectId(),
                            objectsHelper.fakeCounterObjectId(),
                            objectsHelper.fakeCounterObjectId(),
                            objectsHelper.fakeCounterObjectId(),
                        ]

                        // Create objects and set them on root with forged timeserials
                        for (i, counterId) in counterIds.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0),
                                siteCode: "bbb",
                                state: [objectsHelper.counterCreateOp(objectId: counterId)],
                            )
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "aaa", timestamp: Int64(i), counter: 0),
                                siteCode: "aaa",
                                state: [objectsHelper.mapSetOp(objectId: "root", key: counterId, data: .object(["objectId": .string(counterId)]))],
                            )
                        }

                        // Inject OBJECT_DELETE operations with various timeserial values
                        let timeserialTestCases = [
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0), siteCode: "bbb"), // existing site, earlier CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0), siteCode: "bbb"), // existing site, same CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb"), // existing site, later CGO, applied
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0), siteCode: "aaa"), // different site, earlier CGO, applied
                            (serial: lexicoTimeserial(seriesId: "ccc", timestamp: 9, counter: 0), siteCode: "ccc"), // different site, later CGO, applied
                        ]

                        for (i, testCase) in timeserialTestCases.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: testCase.serial,
                                siteCode: testCase.siteCode,
                                state: [objectsHelper.objectDeleteOp(objectId: counterIds[i])],
                            )
                        }

                        // Check only operations with correct timeserials were applied
                        let expectedCounters: [Bool] = [
                            true, // exists
                            true, // exists
                            false, // OBJECT_DELETE applied
                            false, // OBJECT_DELETE applied
                            false, // OBJECT_DELETE applied
                        ]

                        for (i, counterId) in counterIds.enumerated() {
                            let exists = expectedCounters[i]

                            if exists {
                                #expect(try root.get(key: counterId) != nil, "Check counter #\(i + 1) exists on root as OBJECT_DELETE op was not applied")
                            } else {
                                #expect(try root.get(key: counterId) == nil, "Check counter #\(i + 1) does not exist on root as OBJECT_DELETE op was applied")
                            }
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "OBJECT_DELETE triggers subscription callback with deleted data",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channelName = ctx.channelName
                        let channel = ctx.channel

                        let objectsCreatedPromiseUpdates1 = try root.updates()
                        let objectsCreatedPromiseUpdates2 = try root.updates()
                        async let objectsCreatedPromise: Void = withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates1, "map")
                            }
                            group.addTask {
                                await waitForMapKeyUpdate(objectsCreatedPromiseUpdates2, "counter")
                            }
                            while try await group.next() != nil {}
                        }

                        // Create initial objects and set on root
                        let mapResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "map",
                            createOp: objectsHelper.mapCreateRestOp(data: [
                                "foo": .object(["string": .string("bar")]),
                                "baz": .object(["number": .number(1)]),
                            ]),
                        )
                        let counterResult = try await objectsHelper.createAndSetOnMap(
                            channelName: channelName,
                            mapObjectId: "root",
                            key: "counter",
                            createOp: objectsHelper.counterCreateRestOp(number: 1),
                        )
                        _ = try await objectsCreatedPromise

                        let mapSubPromiseUpdates = try #require(root.get(key: "map")?.liveMapValue).updates()
                        let counterSubPromiseUpdates = try #require(root.get(key: "counter")?.liveCounterValue).updates()

                        async let mapSubPromise: Void = {
                            let update = try await #require(mapSubPromiseUpdates.first { _ in true })
                            #expect(update.update["foo"] == .removed, "Check map subscription callback is called with an expected update object after OBJECT_DELETE operation for 'foo' key")
                            #expect(update.update["baz"] == .removed, "Check map subscription callback is called with an expected update object after OBJECT_DELETE operation for 'baz' key")
                        }()

                        async let counterSubPromise: Void = {
                            let update = try await #require(counterSubPromiseUpdates.first { _ in true })
                            #expect(update.amount == -1, "Check counter subscription callback is called with an expected update object after OBJECT_DELETE operation")
                        }()

                        // Inject OBJECT_DELETE
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: mapResult.objectId)],
                        )
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "aaa", timestamp: 1, counter: 0),
                            siteCode: "aaa",
                            state: [objectsHelper.objectDeleteOp(objectId: counterResult.objectId)],
                        )

                        _ = try await (mapSubPromise, counterSubPromise)
                    },
                ),
            ]

            let applyOperationsDuringSyncScenarios: [TestScenario<Context>] = [
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "object operation messages are buffered during OBJECT_SYNC sequence",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel
                        let client = ctx.client

                        // Start new sync sequence with a cursor so client will wait for the next OBJECT_SYNC messages
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:cursor",
                        )

                        // Inject operations, they should not be applied as sync is in progress
                        // Note that unlike in the JS test we do not perform this concurrently because if we were to do that in Swift Concurrency we would not be able to guarantee that the operations are applied in the correct order (if they're not then messages will be discarded due to serials being out of order)
                        for keyData in primitiveKeyData {
                            var wireData = keyData.data.mapValues { WireValue(jsonValue: $0) }

                            if let bytesValue = wireData["bytes"], client.internal.options.useBinaryProtocol {
                                let bytesString = try #require(bytesValue.stringValue)
                                wireData["bytes"] = try .data(#require(.init(base64Encoded: bytesString)))
                            }

                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0),
                                siteCode: "aaa",
                                state: [objectsHelper.mapSetOp(objectId: "root", key: keyData.key, data: .object(wireData))],
                            )
                        }

                        // Check root doesn't have data from operations
                        for keyData in primitiveKeyData {
                            #expect(try root.get(key: keyData.key) == nil, "Check \"\(keyData.key)\" key doesn't exist on root during OBJECT_SYNC")
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "buffered object operation messages are applied when OBJECT_SYNC sequence ends",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel
                        let client = ctx.client

                        // Start new sync sequence with a cursor so client will wait for the next OBJECT_SYNC messages
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:cursor",
                        )

                        // Inject operations, they should be applied when sync ends
                        // Note that unlike in the JS test we do not perform this concurrently because if we were to do that in Swift Concurrency we would not be able to guarantee that the operations are applied in the correct order (if they're not then messages will be discarded due to serials being out of order)
                        for (i, keyData) in primitiveKeyData.enumerated() {
                            var wireData = keyData.data.mapValues { WireValue(jsonValue: $0) }

                            if let bytesValue = wireData["bytes"], client.internal.options.useBinaryProtocol {
                                let bytesString = try #require(bytesValue.stringValue)
                                wireData["bytes"] = try .data(#require(.init(base64Encoded: bytesString)))
                            }

                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "aaa", timestamp: Int64(i), counter: 0),
                                siteCode: "aaa",
                                state: [objectsHelper.mapSetOp(objectId: "root", key: keyData.key, data: .object(wireData))],
                            )
                        }

                        // End the sync with empty cursor
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:",
                        )

                        // Check everything is applied correctly
                        for keyData in primitiveKeyData {
                            if let bytesValue = keyData.data["bytes"] {
                                if case let .string(base64String) = bytesValue {
                                    let expectedData = Data(base64Encoded: base64String)
                                    #expect(try #require(root.get(key: keyData.key)?.dataValue) == expectedData, "Check root has correct value for \"\(keyData.key)\" key after OBJECT_SYNC has ended and buffered operations are applied")
                                }
                            } else {
                                // Handle other value types
                                if let stringValue = keyData.data["string"] {
                                    if case let .string(expectedString) = stringValue {
                                        #expect(try #require(root.get(key: keyData.key)?.stringValue) == expectedString, "Check root has correct value for \"\(keyData.key)\" key after OBJECT_SYNC has ended and buffered operations are applied")
                                    }
                                } else if let numberValue = keyData.data["number"] {
                                    if case let .number(expectedNumber) = numberValue {
                                        #expect(try #require(root.get(key: keyData.key)?.numberValue) == expectedNumber.doubleValue, "Check root has correct value for \"\(keyData.key)\" key after OBJECT_SYNC has ended and buffered operations are applied")
                                    }
                                } else if let boolValue = keyData.data["boolean"] {
                                    if case let .bool(expectedBool) = boolValue {
                                        #expect(try #require(root.get(key: keyData.key)?.boolValue as Bool?) == expectedBool, "Check root has correct value for \"\(keyData.key)\" key after OBJECT_SYNC has ended and buffered operations are applied")
                                    }
                                }
                            }
                        }
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "buffered object operation messages are discarded when new OBJECT_SYNC sequence starts",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel
                        let client = ctx.client

                        // Start new sync sequence with a cursor so client will wait for the next OBJECT_SYNC messages
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:cursor",
                        )

                        // Inject operations, expect them to be discarded when sync with new sequence id starts
                        // Note that unlike in the JS test we do not perform this concurrently because if we were to do that in Swift Concurrency we would not be able to guarantee that the operations are applied in the correct order (if they're not then messages will be discarded due to serials being out of order)
                        for (i, keyData) in primitiveKeyData.enumerated() {
                            var wireData = keyData.data.mapValues { WireValue(jsonValue: $0) }

                            if let bytesValue = wireData["bytes"], client.internal.options.useBinaryProtocol {
                                let bytesString = try #require(bytesValue.stringValue)
                                wireData["bytes"] = try .data(#require(.init(base64Encoded: bytesString)))
                            }

                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "aaa", timestamp: Int64(i), counter: 0),
                                siteCode: "aaa",
                                state: [objectsHelper.mapSetOp(objectId: "root", key: keyData.key, data: .object(wireData))],
                            )
                        }

                        // Start new sync with new sequence id
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "otherserial:cursor",
                        )

                        // Inject another operation that should be applied when latest sync ends
                        await objectsHelper.processObjectOperationMessageOnChannel(
                            channel: channel,
                            serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0),
                            siteCode: "bbb",
                            state: [objectsHelper.mapSetOp(objectId: "root", key: "foo", data: .object(["string": .string("bar")]))],
                        )

                        // End sync
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "otherserial:",
                        )

                        // Check root doesn't have data from operations received during first sync
                        for keyData in primitiveKeyData {
                            #expect(try root.get(key: keyData.key) == nil, "Check \"\(keyData.key)\" key doesn't exist on root when OBJECT_SYNC has ended")
                        }

                        // Check root has data from operations received during second sync
                        #expect(try #require(root.get(key: "foo")?.stringValue) == "bar", "Check root has data from operations received during second OBJECT_SYNC sequence")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "buffered object operation messages are applied based on the site timeserials vector of the object",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel

                        // Start new sync sequence with a cursor so client will wait for the next OBJECT_SYNC messages
                        let mapId = objectsHelper.fakeMapObjectId()
                        let counterId = objectsHelper.fakeCounterObjectId()

                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:cursor",
                            // Add object state messages with non-empty site timeserials
                            state: [
                                // Next map and counter objects will be checked to have correct operations applied on them based on site timeserials
                                objectsHelper.mapObject(
                                    objectId: mapId,
                                    siteTimeserials: [
                                        "bbb": lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0),
                                        "ccc": lexicoTimeserial(seriesId: "ccc", timestamp: 5, counter: 0),
                                    ],
                                    materialisedEntries: [
                                        "foo1": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo2": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo3": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "ccc", timestamp: 5, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo4": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo5": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo6": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "ccc", timestamp: 2, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo7": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "ccc", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                        "foo8": .object([
                                            "timeserial": .string(lexicoTimeserial(seriesId: "ccc", timestamp: 0, counter: 0)),
                                            "data": .object(["string": .string("bar")]),
                                        ]),
                                    ],
                                ),
                                objectsHelper.counterObject(
                                    objectId: counterId,
                                    siteTimeserials: [
                                        "bbb": lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0),
                                    ],
                                    initialCount: 1,
                                ),
                                // Add objects to the root so they're discoverable in the object tree
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
                                    ],
                                ),
                            ],
                        )

                        // Inject operations with various timeserial values
                        // Map:
                        let mapOperations: [(serial: String, siteCode: String)] = [
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0), siteCode: "bbb"), // existing site, earlier site CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb"), // existing site, same site CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 3, counter: 0), siteCode: "bbb"), // existing site, later site CGO, earlier entry CGO, not applied but site timeserial updated
                            // message with later site CGO, same entry CGO case is not possible, as timeserial from entry would be set for the corresponding site code or be less than that
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 3, counter: 0), siteCode: "bbb"), // existing site, same site CGO (updated from last op), later entry CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 4, counter: 0), siteCode: "bbb"), // existing site, later site CGO, later entry CGO, applied
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 1, counter: 0), siteCode: "aaa"), // different site, earlier entry CGO, not applied but site timeserial updated
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 1, counter: 0), siteCode: "aaa"), // different site, same site CGO (updated from last op), later entry CGO, not applied
                            // different site with matching entry CGO case is not possible, as matching entry timeserial means that that timeserial is in the site timeserials vector
                            (serial: lexicoTimeserial(seriesId: "ddd", timestamp: 1, counter: 0), siteCode: "ddd"), // different site, later entry CGO, applied
                        ]

                        for (i, operation) in mapOperations.enumerated() {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: operation.serial,
                                siteCode: operation.siteCode,
                                state: [objectsHelper.mapSetOp(objectId: mapId, key: "foo\(i + 1)", data: .object(["string": .string("baz")]))],
                            )
                        }

                        // Counter:
                        let counterOperations: [(serial: String, siteCode: String, amount: Double)] = [
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 0, counter: 0), siteCode: "bbb", amount: 10), // existing site, earlier CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 1, counter: 0), siteCode: "bbb", amount: 100), // existing site, same CGO, not applied
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb", amount: 1000), // existing site, later CGO, applied, site timeserials updated
                            (serial: lexicoTimeserial(seriesId: "bbb", timestamp: 2, counter: 0), siteCode: "bbb", amount: 10000), // existing site, same CGO (updated from last op), not applied
                            (serial: lexicoTimeserial(seriesId: "aaa", timestamp: 0, counter: 0), siteCode: "aaa", amount: 100_000), // different site, earlier CGO, applied
                            (serial: lexicoTimeserial(seriesId: "ccc", timestamp: 9, counter: 0), siteCode: "ccc", amount: 1_000_000), // different site, later CGO, applied
                        ]

                        for operation in counterOperations {
                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: operation.serial,
                                siteCode: operation.siteCode,
                                state: [objectsHelper.counterIncOp(objectId: counterId, amount: Int(operation.amount))],
                            )
                        }

                        // End sync
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:",
                        )

                        // Check only operations with correct timeserials were applied
                        let expectedMapKeys: [(key: String, value: String)] = [
                            (key: "foo1", value: "bar"),
                            (key: "foo2", value: "bar"),
                            (key: "foo3", value: "bar"),
                            (key: "foo4", value: "bar"),
                            (key: "foo5", value: "baz"), // updated
                            (key: "foo6", value: "bar"),
                            (key: "foo7", value: "bar"),
                            (key: "foo8", value: "baz"), // updated
                        ]

                        let map = try #require(root.get(key: "map")?.liveMapValue)
                        for expectedMapKey in expectedMapKeys {
                            #expect(try #require(map.get(key: expectedMapKey.key)?.stringValue) == expectedMapKey.value, "Check \"\(expectedMapKey.key)\" key on map has expected value after OBJECT_SYNC has ended")
                        }

                        let counter = try #require(root.get(key: "counter")?.liveCounterValue)
                        let expectedCounterValue = 1.0 + 1000.0 + 100_000.0 + 1_000_000.0 // sum of passing operations and the initial value
                        #expect(try counter.value == expectedCounterValue, "Check counter has expected value after OBJECT_SYNC has ended")
                    },
                ),
                .init(
                    disabled: false,
                    allTransportsAndProtocols: false,
                    description: "subsequent object operation messages are applied immediately after OBJECT_SYNC ended and buffers are applied",
                    action: { ctx in
                        let root = ctx.root
                        let objectsHelper = ctx.objectsHelper
                        let channel = ctx.channel
                        let channelName = ctx.channelName
                        let client = ctx.client

                        // Start new sync sequence with a cursor so client will wait for the next OBJECT_SYNC messages
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:cursor",
                        )

                        // Inject operations, they should be applied when sync ends
                        // Note that unlike in the JS test we do not perform this concurrently because if we were to do that in Swift Concurrency we would not be able to guarantee that the operations are applied in the correct order (if they're not then messages will be discarded due to serials being out of order)
                        for (i, keyData) in primitiveKeyData.enumerated() {
                            var wireData = keyData.data.mapValues { WireValue(jsonValue: $0) }

                            if let bytesValue = wireData["bytes"], client.internal.options.useBinaryProtocol {
                                let bytesString = try #require(bytesValue.stringValue)
                                wireData["bytes"] = try .data(#require(.init(base64Encoded: bytesString)))
                            }

                            await objectsHelper.processObjectOperationMessageOnChannel(
                                channel: channel,
                                serial: lexicoTimeserial(seriesId: "aaa", timestamp: Int64(i), counter: 0),
                                siteCode: "aaa",
                                state: [objectsHelper.mapSetOp(objectId: "root", key: keyData.key, data: .object(wireData))],
                            )
                        }

                        // End the sync with empty cursor
                        await objectsHelper.processObjectStateMessageOnChannel(
                            channel: channel,
                            syncSerial: "serial:",
                        )

                        let keyUpdatedPromiseUpdates = try root.updates()
                        async let keyUpdatedPromise: Void = waitForMapKeyUpdate(keyUpdatedPromiseUpdates, "foo")

                        // Send some more operations
                        let operationResult = try await objectsHelper.operationRequest(
                            channelName: channelName,
                            opBody: objectsHelper.mapSetRestOp(
                                objectId: "root",
                                key: "foo",
                                value: ["string": .string("bar")],
                            ),
                        )
                        await keyUpdatedPromise

                        // Check buffered operations are applied, as well as the most recent operation outside of the sync sequence is applied
                        for keyData in primitiveKeyData {
                            if let bytesValue = keyData.data["bytes"] {
                                if case let .string(base64String) = bytesValue {
                                    let expectedData = Data(base64Encoded: base64String)
                                    #expect(try #require(root.get(key: keyData.key)?.dataValue) == expectedData, "Check root has correct value for \"\(keyData.key)\" key after OBJECT_SYNC has ended and buffered operations are applied")
                                }
                            } else {
                                // Handle other value types
                                if let stringValue = keyData.data["string"] {
                                    if case let .string(expectedString) = stringValue {
                                        #expect(try #require(root.get(key: keyData.key)?.stringValue) == expectedString, "Check root has correct value for \"\(keyData.key)\" key after OBJECT_SYNC has ended and buffered operations are applied")
                                    }
                                } else if let numberValue = keyData.data["number"] {
                                    if case let .number(expectedNumber) = numberValue {
                                        #expect(try #require(root.get(key: keyData.key)?.numberValue) == expectedNumber.doubleValue, "Check root has correct value for \"\(keyData.key)\" key after OBJECT_SYNC has ended and buffered operations are applied")
                                    }
                                } else if let boolValue = keyData.data["boolean"] {
                                    if case let .bool(expectedBool) = boolValue {
                                        #expect(try #require(root.get(key: keyData.key)?.boolValue as Bool?) == expectedBool, "Check root has correct value for \"\(keyData.key)\" key after OBJECT_SYNC has ended and buffered operations are applied")
                                    }
                                }
                            }
                        }

                        #expect(try #require(root.get(key: "foo")?.stringValue) == "bar", "Check root has correct value for \"foo\" key from operation received outside of OBJECT_SYNC after other buffered operations were applied")
                    },
                ),
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
