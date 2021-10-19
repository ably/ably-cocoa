import Ably

class MockDeviceStorage: NSObject, ARTDeviceStorage {

    var keysRead: [String] = []
    var keysWritten: [String: Any?] = [:]

    private var simulateData: [String: Data] = [:]
    private var simulateString: [String: String] = [:]

    init(startWith state: ARTPushActivationState? = nil) {
        super.init()
        if let state = state {
            simulateOnNextRead(data: state.archive(), for: ARTPushActivationCurrentStateKey)
        }
    }

    func object(forKey key: String) -> Any? {
        keysRead.append(key)
        if let data = simulateData[key] {
            defer { simulateData.removeValue(forKey: key) }
            return data
        }
        if let string = simulateString[key] {
            defer { simulateString.removeValue(forKey: key) }
            return string
        }
        return nil
    }

    func setObject(_ value: Any?, forKey key: String) {
        keysWritten.updateValue(value, forKey: key)
    }

    func secret(forDevice deviceId: ARTDeviceId) -> String? {
        keysRead.append(ARTDeviceSecretKey)
        if let value = simulateString[ARTDeviceSecretKey] {
            defer { simulateString.removeValue(forKey: ARTDeviceSecretKey) }
            return value
        }
        return nil
    }

    func setSecret(_ value: String?, forDevice deviceId: ARTDeviceId) {
        keysWritten.updateValue(value, forKey: ARTDeviceSecretKey)
    }

    func simulateOnNextRead(data value: Data, `for` key: String) {
        simulateData[key] = value
    }

    func simulateOnNextRead(string value: String, `for` key: String) {
        simulateString[key] = value
    }

}
