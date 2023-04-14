import Ably.Private
import XCTest

class DefaultLocalDeviceFetcherTests: XCTestCase {
    func test_fetchLocalDevice_returnsSameDeviceInstance() {
        let fetcher = DefaultLocalDeviceFetcher.sharedInstance
        defer { fetcher.resetDevice() }

        let device1 = fetcher.fetchLocalDevice(
            withClientID: "clientID-1",
            storage: MockDeviceStorage(),
            logger: nil
        )

        let device2 = fetcher.fetchLocalDevice(
            withClientID: "clientID-2",
            storage: MockDeviceStorage(),
            logger: nil
        )

        XCTAssertTrue(device1 === device2)
        XCTAssertEqual(device1.clientId, "clientID-1")
    }

    func test_resetDevice() {
        let fetcher = DefaultLocalDeviceFetcher.sharedInstance
        defer { fetcher.resetDevice() }

        let device1 = fetcher.fetchLocalDevice(
            withClientID: "clientID-1",
            storage: MockDeviceStorage(),
            logger: nil
        )

        fetcher.resetDevice()

        let device2 = fetcher.fetchLocalDevice(
            withClientID: "clientID-2",
            storage: MockDeviceStorage(),
            logger: nil
        )

        XCTAssertTrue(device1 !== device2)
        XCTAssertEqual(device2.clientId, "clientID-2")
    }
}
