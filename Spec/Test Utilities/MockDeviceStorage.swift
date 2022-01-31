import Ably

class MockDeviceStorage: NSObject, ARTDeviceStorage {
    
    enum ReadResult {
        case data(Data)
        case string(String)
        case error(Error)
    }

    var keysRead: [String] = []
    var keysWritten: [String: Any?] = [:]

    private var simulateResults: [String: ReadResult] = [:]

    init(startWith state: ARTPushActivationState? = nil) {
        super.init()
        if let state = state {
            simulateOnNextRead(.data(state.archive()), for: ARTPushActivationCurrentStateKey)
        }
    }

    func getObject(_ ptr: AutoreleasingUnsafeMutablePointer<AnyObject?>?, forKey key: String) throws {
        keysRead.append(key)
        
        if let result = simulateResults[key] {
            simulateResults.removeValue(forKey: key)
            
            switch result {
            case let .data(data): ptr?.pointee = data as NSData
            case let .string(string): ptr?.pointee = string as NSString
            case let .error(error): throw error
            }
        }
    }

    func setObject(_ value: Any?, forKey key: String) throws {
        keysWritten.updateValue(value, forKey: key)
    }

    func getSecret(_ ptr: AutoreleasingUnsafeMutablePointer<NSString?>?, forDevice deviceId: String) throws {
        keysRead.append(ARTDeviceSecretKey)
        if let value = simulateResults[ARTDeviceSecretKey] {
            defer { simulateResults.removeValue(forKey: ARTDeviceSecretKey) }
            
            switch value {
            case .data: preconditionFailure("Don’t know how to handle data-valued secret")
            case let .string(string): ptr?.pointee = string as NSString
            case let .error(error): throw error
            }
        }
    }

    func setSecret(_ value: String?, forDevice deviceId: ARTDeviceId) throws {
        keysWritten.updateValue(value, forKey: ARTDeviceSecretKey)
    }

    func simulateOnNextRead(_ result: ReadResult, `for` key: String) {
        simulateResults[key] = result
    }
}
