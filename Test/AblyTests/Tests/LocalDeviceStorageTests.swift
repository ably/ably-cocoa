#if os(iOS)
import Ably
import Ably.Private
import AblyTesting
import Security
import XCTest

final class LocalDeviceStorageTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LocalDeviceStorageTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        clearLegacyUserDefaults()
    }

    override func tearDownWithError() throws {
        if let dir = tempDirectory, FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }
        clearLegacyUserDefaults()
        try super.tearDownWithError()
    }

    // MARK: Storage read/write

    // RSH8a: the persisted LocalDevice attributes must survive a storage
    // round-trip — i.e. what's written is what a fresh instance loads back.
    func test_writesAndReadsThroughTheProtocol() {
        let storage = makeStorage()

        storage.setObject("device-1", forKey: ARTDeviceIdKey)
        storage.setObject("secret-1", forKey: ARTDeviceSecretKey)
        let identityTokenData = Data("token-bytes".utf8)
        storage.setObject(identityTokenData, forKey: ARTDeviceIdentityTokenKey)
        storage.setObject("client-1", forKey: ARTClientIdKey)

        XCTAssertEqual(storage.object(forKey: ARTDeviceIdKey) as? String, "device-1")
        XCTAssertEqual(storage.object(forKey: ARTDeviceSecretKey) as? String, "secret-1")
        XCTAssertEqual(storage.object(forKey: ARTDeviceIdentityTokenKey) as? Data, identityTokenData)
        XCTAssertEqual(storage.object(forKey: ARTClientIdKey) as? String, "client-1")

        // A fresh instance reading the same files must observe the same values.
        let reloaded = makeStorage()
        XCTAssertEqual(reloaded.object(forKey: ARTDeviceIdKey) as? String, "device-1")
        XCTAssertEqual(reloaded.object(forKey: ARTDeviceSecretKey) as? String, "secret-1")
        XCTAssertEqual(reloaded.object(forKey: ARTDeviceIdentityTokenKey) as? Data, identityTokenData)
        XCTAssertEqual(reloaded.object(forKey: ARTClientIdKey) as? String, "client-1")
    }

    // MARK: file protection

    func test_storageFileIsCreatedWithFileProtectionNone() throws {
        let storage = makeStorage()
        storage.setObject("device-1", forKey: ARTDeviceIdKey)
        storage.setObject("secret-1", forKey: ARTDeviceSecretKey)

        let fileURL = tempDirectory.appendingPathComponent("LocalDevice.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        // On a tmp directory the protection key may be absent (it inherits the
        // parent's class), but if present it must be NSFileProtectionNone.
        if let protection = attrs[.protectionKey] as? FileProtectionType {
            XCTAssertEqual(protection, .none)
        }

        // Ensure the contents round-trip via NSPropertyListSerialization.
        let data = try Data(contentsOf: fileURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        XCTAssertNotNil(plist as? [String: Any])
    }

    // MARK: atomicity of performBatchUpdate

    // ARTDeviceStorage atomicity contract: a `performBatchUpdate` persists all
    // of its mutations together in a single flush (so e.g. a
    // `deviceIdentityToken` is never paired with a `deviceId` it doesn't
    // belong to).
    func test_atomicUpdateWritesAllKeysInOneFlush() {
        let storage = makeStorage()

        storage.performBatchUpdate { writer in
            writer.setObject("device-1", forKey: ARTDeviceIdKey)
            writer.setObject("secret-1", forKey: ARTDeviceSecretKey)
            writer.setObject(Data("token".utf8), forKey: ARTDeviceIdentityTokenKey)
            writer.setObject("client-1", forKey: ARTClientIdKey)
        }

        // All four writes must land in the new file content; a follow-up load
        // sees the full tuple.
        let reloaded = makeStorage()
        XCTAssertEqual(reloaded.object(forKey: ARTDeviceIdKey) as? String, "device-1")
        XCTAssertEqual(reloaded.object(forKey: ARTDeviceSecretKey) as? String, "secret-1")
        XCTAssertEqual(reloaded.object(forKey: ARTDeviceIdentityTokenKey) as? Data, Data("token".utf8))
        XCTAssertEqual(reloaded.object(forKey: ARTClientIdKey) as? String, "client-1")
    }

    // MARK: RSH3h ordering

    // In this test the device data is *complete* (legacy id + keychain secret migrate
    // successfully), so the persisted Activation State Machine state survives
    // RSH3h step (1) and the machine constructed in step (2) resumes it.
    func test_RSH3h_persistedActivationStateResumesWhenDeviceDataIsComplete() {
        let logger = InternalLog(core: MockInternalLogCore())
        let archivedState = archivedWaitingForDeviceRegistrationState(logger: logger)

        let defaults = UserDefaults.standard
        defaults.set("legacy-device", forKey: ARTDeviceIdKey)
        defaults.set(archivedState, forKey: ARTPushActivationCurrentStateKey)
        // Keychain secret is available, so migration carries the device data —
        // and the activation state — into the new file.
        let reader: ARTLegacyKeychainSecretReader = { _, outStatus in
            outStatus?.pointee = errSecSuccess
            return "legacy-secret"
        }
        let storage = makeStorage(keychainSecretReader: reader)

        let rest = ARTRest(key: "fake:key")
        rest.internal.storage = storage
        rest.internal.resetDeviceSingleton()
        defer { rest.internal.resetDeviceSingleton() }

        // RSH3h step (1): initialise the LocalDevice (RSH8a) — device data is
        // valid, so the persisted state is retained.
        let device = rest.device
        XCTAssertEqual(device.id, "legacy-device")
        XCTAssertEqual(device.secret, "legacy-secret")
        XCTAssertEqual(storage.object(forKey: ARTDeviceIdKey) as? String, device.id)
        XCTAssertEqual(storage.object(forKey: ARTDeviceSecretKey) as? String, device.secret)

        // RSH3h step (2): the state machine resumes the persisted state.
        let stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate(), logger: logger)
        XCTAssertTrue(stateMachine.current is ARTPushActivationStateWaitingForDeviceRegistration)
    }

    // RSH3h + RSH8a1: here the device data is *incomplete* (legacy id present
    // but the keychain secret can't be read), so step (1) discards the persisted
    // Activation State Machine data, and the machine constructed in step (2)
    // must come up in NotActivated — even though a non-NotActivated state was
    // persisted.
    func test_RSH3h_persistedActivationStateDiscardedWhenDeviceDataIsIncomplete() {
        let logger = InternalLog(core: MockInternalLogCore())
        let archivedState = archivedWaitingForDeviceRegistrationState(logger: logger)

        let defaults = UserDefaults.standard
        defaults.set("legacy-device", forKey: ARTDeviceIdKey)
        defaults.set(archivedState, forKey: ARTPushActivationCurrentStateKey)

        // Keychain secret is unavailable, so RSH8a1 discards the whole legacy
        // record — including the activation state — during migration.
        let reader: ARTLegacyKeychainSecretReader = { _, outStatus in
            outStatus?.pointee = errSecInteractionNotAllowed
            return nil
        }
        let storage = makeStorage(keychainSecretReader: reader)

        let rest = ARTRest(key: "fake:key")
        rest.internal.storage = storage
        rest.internal.resetDeviceSingleton()
        defer { rest.internal.resetDeviceSingleton() }

        // RSH3h step (1): initialise the LocalDevice (RSH8a);
        // The incomplete device data triggers RSH8a1, so no activation state is persisted:
        _ = rest.device
        let device = rest.device
        XCTAssertEqual(device.id.count, 36) // a freshly generated UUID
        XCTAssertNotNil(device.secret)
        XCTAssertEqual(storage.object(forKey: ARTDeviceIdKey) as? String, device.id)
        XCTAssertEqual(storage.object(forKey: ARTDeviceSecretKey) as? String, device.secret)

        // RSH3h step (2): with no persisted state, the machine starts NotActivated.
        let stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate(), logger: logger)
        XCTAssertTrue(stateMachine.current is ARTPushActivationStateNotActivated)
    }

    // ARTDeviceStorage atomicity contract: mid-batch mutations are not visible
    // on disk until the outermost `performBatchUpdate` commits.
    func test_batchUpdateDoesNotReachDiskMidBatch() throws {
        let storage = makeStorage()

        // Seed an initial on-disk state with one outside-batch write.
        storage.setObject("v0", forKey: ARTDeviceIdKey)

        let fileURL = tempDirectory.appendingPathComponent("LocalDevice.plist")

        storage.performBatchUpdate { writer in
            writer.setObject("v1", forKey: ARTDeviceIdKey)
            writer.setObject(Data("token-v1".utf8), forKey: ARTDeviceIdentityTokenKey)

            // Read the file directly from disk while still inside the batch.
            // The pre-batch state must still be on disk; mid-batch mutations
            // live only in the in-memory cache until the block returns.
            let data = try! Data(contentsOf: fileURL)
            let plist = try! PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
            XCTAssertEqual(plist[ARTDeviceIdKey] as? String, "v0")
            XCTAssertNil(plist[ARTDeviceIdentityTokenKey])
        }

        // After the block returns, both writes have landed on disk together.
        let data = try Data(contentsOf: fileURL)
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])
        XCTAssertEqual(plist[ARTDeviceIdKey] as? String, "v1")
        XCTAssertEqual(plist[ARTDeviceIdentityTokenKey] as? Data, Data("token-v1".utf8))
    }

    // MARK: legacy migration

    // Not a spec point: backward-compatible migration of the legacy
    // `NSUserDefaults` + keychain layout into the single persisted file.
    func test_migratesLegacyUserDefaultsOnFirstInit() {
        let defaults = UserDefaults.standard

        defaults.set("legacy-device", forKey: ARTDeviceIdKey)
        defaults.set("legacy-client", forKey: ARTClientIdKey)
        let identityTokenData = Data("legacy-token-archive".utf8)
        defaults.set(identityTokenData, forKey: ARTDeviceIdentityTokenKey)
        let stateData = Data("state-archive".utf8)
        let eventsData = Data("events-archive".utf8)
        defaults.set(stateData, forKey: ARTPushActivationCurrentStateKey)
        defaults.set(eventsData, forKey: ARTPushActivationPendingEventsKey)
        defaults.set("apns-default-token", forKey: "ARTAPNSDeviceToken-default")
        defaults.set("apns-location-token", forKey: "ARTAPNSDeviceToken-location")

        // Keychain reader returns the legacy secret — the happy path lets
        // every field cross into the new file together.
        let reader: ARTLegacyKeychainSecretReader = { deviceId, outStatus in
            outStatus?.pointee = errSecSuccess
            return "legacy-secret"
        }
        let storage = makeStorage(keychainSecretReader: reader)

        XCTAssertEqual(storage.object(forKey: ARTDeviceIdKey) as? String, "legacy-device")
        XCTAssertEqual(storage.object(forKey: ARTDeviceSecretKey) as? String, "legacy-secret")
        XCTAssertEqual(storage.object(forKey: ARTDeviceIdentityTokenKey) as? Data, identityTokenData)
        XCTAssertEqual(storage.object(forKey: ARTClientIdKey) as? String, "legacy-client")
        XCTAssertEqual(storage.object(forKey: ARTPushActivationCurrentStateKey) as? Data, stateData)
        XCTAssertEqual(storage.object(forKey: ARTPushActivationPendingEventsKey) as? Data, eventsData)
        XCTAssertEqual(storage.object(forKey: "ARTAPNSDeviceToken-default") as? String, "apns-default-token")
        XCTAssertEqual(storage.object(forKey: "ARTAPNSDeviceToken-location") as? String, "apns-location-token")

        // The migrated data is flagged as such (see #2207), so future versions
        // can tell it apart from data generated natively in the new file.
        XCTAssertEqual(storage.object(forKey: ARTMigratedFromLegacyStorageKey) as? Bool, true)

        // The legacy entries are deliberately left in place after migration
        // (the post-migration cleanup is commented out pending issue #1257), so
        // they must still be readable from `NSUserDefaults`.
        for key in [
            ARTDeviceIdKey,
            ARTClientIdKey,
            ARTDeviceIdentityTokenKey,
            ARTPushActivationCurrentStateKey,
            ARTPushActivationPendingEventsKey,
            "ARTAPNSDeviceToken-default",
            "ARTAPNSDeviceToken-location",
        ] {
            XCTAssertNotNil(defaults.object(forKey: key), "legacy key \(key) should be left intact pending #1257")
        }
    }

    // RSH8a1 (applied during migration): if the legacy device secret can't be
    // read, the whole legacy record is discarded rather than half-migrated, so
    // the device-fetch path starts clean.
    func test_discardsLegacyDataWhenKeychainSecretIsUnavailable() {
        let defaults = UserDefaults.standard

        defaults.set("legacy-device", forKey: ARTDeviceIdKey)
        defaults.set("legacy-client", forKey: ARTClientIdKey)
        defaults.set(Data("legacy-token-archive".utf8), forKey: ARTDeviceIdentityTokenKey)
        defaults.set(Data("state-archive".utf8), forKey: ARTPushActivationCurrentStateKey)
        defaults.set(Data("events-archive".utf8), forKey: ARTPushActivationPendingEventsKey)
        defaults.set("apns-default-token", forKey: "ARTAPNSDeviceToken-default")
        defaults.set("apns-location-token", forKey: "ARTAPNSDeviceToken-location")

        // Keychain reader returns no secret — the realistic cause is the
        // device being locked before first unlock. RSH8a1 discards every
        // legacy field together; the device-fetch path will start clean.
        let reader: ARTLegacyKeychainSecretReader = { _, outStatus in
            outStatus?.pointee = errSecInteractionNotAllowed
            return nil
        }
        let storage = makeStorage(keychainSecretReader: reader)

        // Nothing crosses into the new file: the incomplete legacy record is
        // discarded wholesale.
        for key in [
            ARTDeviceIdKey,
            ARTDeviceSecretKey,
            ARTDeviceIdentityTokenKey,
            ARTClientIdKey,
            ARTPushActivationCurrentStateKey,
            ARTPushActivationPendingEventsKey,
            "ARTAPNSDeviceToken-default",
            "ARTAPNSDeviceToken-location",
        ] {
            XCTAssertNil(storage.object(forKey: key), "key \(key) survived migration")
        }

        // Nothing was migrated, so the migration marker is not set either.
        XCTAssertNil(storage.object(forKey: ARTMigratedFromLegacyStorageKey))

        // The legacy entries are deliberately left in place after migration
        // (the post-migration cleanup is commented out pending issue #1257), so
        // they must still be readable from `NSUserDefaults`.
        for key in [
            ARTDeviceIdKey,
            ARTClientIdKey,
            ARTDeviceIdentityTokenKey,
            ARTPushActivationCurrentStateKey,
            ARTPushActivationPendingEventsKey,
            "ARTAPNSDeviceToken-default",
            "ARTAPNSDeviceToken-location",
        ] {
            XCTAssertNotNil(defaults.object(forKey: key), "legacy key \(key) should be left intact pending #1257")
        }
    }
}

// MARK: helpers

extension LocalDeviceStorageTests {

    private func makeStorage(keychainSecretReader: ARTLegacyKeychainSecretReader? = nil) -> ARTLocalDeviceStorage {
        return ARTLocalDeviceStorage(baseDirectoryURL: tempDirectory, logger: nil, logValues: false, legacyKeychainReader: keychainSecretReader)
    }

    // An archived activation state, used by the RSH3h test so that its survival/absence
    // is what distinguishes "state retained" from "state discarded".
    private func archivedWaitingForDeviceRegistrationState(logger: InternalLog) -> Data {
        let rest = ARTRest(key: "fake:key")
        rest.internal.storage = MockDeviceStorage()
        let stateMachine = ARTPushActivationStateMachine(rest: rest.internal, delegate: StateMachineDelegate(), logger: logger)
        let state = ARTPushActivationStateWaitingForDeviceRegistration(machine: stateMachine, logger: logger)
        return state.art_archive(withLogger: nil)!
    }

    private func clearLegacyUserDefaults() {
        let defaults = UserDefaults.standard
        for key in [
            ARTDeviceIdKey,
            ARTDeviceIdentityTokenKey,
            ARTClientIdKey,
            ARTPushActivationCurrentStateKey,
            ARTPushActivationPendingEventsKey,
            "ARTAPNSDeviceToken",
            "ARTAPNSDeviceToken-default",
            "ARTAPNSDeviceToken-location",
        ] {
            defaults.removeObject(forKey: key)
        }
    }
}

#endif
