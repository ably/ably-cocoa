#if os(iOS)
import Ably
import Ably.Private
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

    // MARK: round-trip

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

    // MARK: atomic file protection

    func test_fileIsCreatedWithFileProtectionNoneOnIOS() throws {
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
        XCTAssertEqual(reloaded.object(forKey: ARTClientIdKey) as? String, "client-1")
    }

    // MARK: bug fix — id regeneration writes id + secret + nil-token atomically

    func test_localDeviceLoadFailureDiscardsAllPersistedData() {
        // Storage starts with an id, an identity token, a clientId, an APNS
        // token and persisted state-machine data — but no device secret. This
        // is the inconsistent state RSH8a1 must recover from: loading id or
        // deviceSecret has failed, so all persisted LocalDevice attributes
        // AND all persisted Activation State Machine data must be discarded.
        let storage = makeStorage()
        storage.performBatchUpdate { writer in
            writer.setObject("old-id", forKey: ARTDeviceIdKey)
            writer.setObject(Data("old-token-archive".utf8), forKey: ARTDeviceIdentityTokenKey)
            writer.setObject("client-x", forKey: ARTClientIdKey)
            writer.setObject("apns-default", forKey: "ARTAPNSDeviceToken-default")
            writer.setObject(Data("state-archive".utf8), forKey: ARTPushActivationCurrentStateKey)
            writer.setObject(Data("events-archive".utf8), forKey: ARTPushActivationPendingEventsKey)
        }

        let rest = ARTRest(key: "fake:key")
        rest.internal.storage = storage
        // The device is held in a static cached by `ARTRest`; reset it so the
        // next access reloads it through `storage` and not whatever was cached
        // by an earlier test in the run.
        rest.internal.resetDeviceSingleton()

        // Triggers `+[ARTLocalDevice deviceWithStorage:logger:]`, which sees
        // a missing secret and applies RSH8a1: discard everything, then
        // eagerly generate a fresh (id, secret) pair (RSH8k2 note).
        let device = rest.device

        XCTAssertNotEqual(device.id, "old-id")
        XCTAssertNotNil(device.secret)
        XCTAssertNil(device.identityTokenDetails)
        XCTAssertNil(device.clientId)

        // Every key other than the freshly generated (id, secret) must be
        // cleared, both in the in-memory cache and on disk.
        let reloaded = makeStorage()
        for storageToCheck in [storage as ARTDeviceStorage, reloaded as ARTDeviceStorage] {
            XCTAssertEqual(storageToCheck.object(forKey: ARTDeviceIdKey) as? String, device.id)
            XCTAssertEqual(storageToCheck.object(forKey: ARTDeviceSecretKey) as? String, device.secret)
            XCTAssertNil(storageToCheck.object(forKey: ARTDeviceIdentityTokenKey))
            XCTAssertNil(storageToCheck.object(forKey: ARTClientIdKey))
            XCTAssertNil(storageToCheck.object(forKey: "ARTAPNSDeviceToken-default"))
            XCTAssertNil(storageToCheck.object(forKey: ARTPushActivationCurrentStateKey))
            XCTAssertNil(storageToCheck.object(forKey: ARTPushActivationPendingEventsKey))
        }
    }

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

    func test_migratesLegacyUserDefaultsOnFirstInit() {
        let defaults = UserDefaults.standard

        // Device-identity legacy data — without a keychain secret, the tuple
        // is structurally broken and must be discarded.
        defaults.set("legacy-device", forKey: ARTDeviceIdKey)
        defaults.set("legacy-client", forKey: ARTClientIdKey)
        defaults.set(Data("legacy-token-archive".utf8), forKey: ARTDeviceIdentityTokenKey)

        // Push-runtime legacy data — independent of the secret; migrates
        // as-is.
        let stateData = Data("state-archive".utf8)
        let eventsData = Data("events-archive".utf8)
        defaults.set(stateData, forKey: ARTPushActivationCurrentStateKey)
        defaults.set(eventsData, forKey: ARTPushActivationPendingEventsKey)
        defaults.set("apns-default-token", forKey: "ARTAPNSDeviceToken-default")
        defaults.set("apns-location-token", forKey: "ARTAPNSDeviceToken-location")

        let storage = makeStorage()

        // Device details and state machine are discarded (no secret → broken).
        XCTAssertNil(storage.object(forKey: ARTDeviceIdKey))
        XCTAssertNil(storage.object(forKey: ARTClientIdKey))
        XCTAssertNil(storage.object(forKey: ARTDeviceIdentityTokenKey))
        XCTAssertNil(storage.object(forKey: ARTPushActivationCurrentStateKey))
        XCTAssertNil(storage.object(forKey: ARTPushActivationPendingEventsKey))
        XCTAssertNil(storage.object(forKey: "ARTAPNSDeviceToken-default"))
        XCTAssertNil(storage.object(forKey: "ARTAPNSDeviceToken-location"))

        // All legacy UserDefaults entries are cleaned up.
        for key in [
            ARTDeviceIdKey,
            ARTClientIdKey,
            ARTDeviceIdentityTokenKey,
            ARTPushActivationCurrentStateKey,
            ARTPushActivationPendingEventsKey,
            "ARTAPNSDeviceToken-default",
            "ARTAPNSDeviceToken-location",
        ] {
            XCTAssertNil(defaults.object(forKey: key), "legacy key \(key) still present")
        }
    }

    func test_migrationDefersWhenLegacyKeychainIsLocked() {
        let defaults = UserDefaults.standard
        defaults.set("legacy-device", forKey: ARTDeviceIdKey)
        defaults.set("legacy-client", forKey: ARTClientIdKey)
        defaults.set(Data("legacy-token-archive".utf8), forKey: ARTDeviceIdentityTokenKey)

        // First init: keychain reader reports `errSecInteractionNotAllowed`,
        // the "device locked before first unlock" status the issue is about.
        // The migration must defer — no file written, no legacy entries
        // cleaned up.
        let lockedReader: ARTLegacyKeychainSecretReader = { _, outStatus in
            outStatus?.pointee = errSecInteractionNotAllowed
            return nil
        }
        _ = ARTLocalDeviceStorage(
            baseDirectoryURL: tempDirectory,
            logger: nil,
            logValues: false,
            legacyKeychainReader: lockedReader
        )

        let fileURL = tempDirectory.appendingPathComponent("LocalDevice.plist")
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path),
                       "migration must not write the file when the keychain is locked")
        XCTAssertEqual(defaults.object(forKey: ARTDeviceIdKey) as? String, "legacy-device",
                       "legacy entries must be preserved for the next attempt")
        XCTAssertEqual(defaults.object(forKey: ARTClientIdKey) as? String, "legacy-client")
        XCTAssertNotNil(defaults.object(forKey: ARTDeviceIdentityTokenKey))

        // Second init: keychain now returns the legacy secret. Migration
        // succeeds, the file is written, and legacy entries are cleaned up.
        let unlockedReader: ARTLegacyKeychainSecretReader = { deviceId, outStatus in
            outStatus?.pointee = errSecSuccess
            return deviceId == "legacy-device" ? "legacy-secret" : nil
        }
        let storage = ARTLocalDeviceStorage(
            baseDirectoryURL: tempDirectory,
            logger: nil,
            logValues: false,
            legacyKeychainReader: unlockedReader
        )

        XCTAssertEqual(storage.object(forKey: ARTDeviceIdKey) as? String, "legacy-device")
        XCTAssertEqual(storage.object(forKey: ARTDeviceSecretKey) as? String, "legacy-secret")
        XCTAssertEqual(storage.object(forKey: ARTClientIdKey) as? String, "legacy-client")
        XCTAssertNotNil(storage.object(forKey: ARTDeviceIdentityTokenKey))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertNil(defaults.object(forKey: ARTDeviceIdKey))
        XCTAssertNil(defaults.object(forKey: ARTClientIdKey))
        XCTAssertNil(defaults.object(forKey: ARTDeviceIdentityTokenKey))
    }

    // MARK: helpers

    private func makeStorage() -> ARTLocalDeviceStorage {
        return ARTLocalDeviceStorage(baseDirectoryURL: tempDirectory, logger: nil, logValues: false)
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
