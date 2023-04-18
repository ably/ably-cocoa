import Ably.Private

@objc(ARTMockLocalDeviceFetcher)
class MockLocalDeviceFetcher: NSObject, LocalDeviceFetcher {
    private let semaphore = DispatchSemaphore(value: 1)
    private var device: ARTLocalDevice?

    func fetchLocalDevice(withClientID clientID: String?, storage: ARTDeviceStorage, logger: InternalLog?) -> ARTLocalDevice {
        semaphore.wait()
        let device: ARTLocalDevice
        if let existingDevice = self.device {
            device = existingDevice
        } else {
            device = ARTLocalDevice.load(clientID, storage: storage, logger: logger)
            self.device = device
        }
        semaphore.signal()
        return device
    }
}
