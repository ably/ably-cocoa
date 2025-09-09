import Foundation

// swift-migration: original location NSURLRequest+ARTPush.h, line 10 and NSURLRequest+ARTPush.m, line 8
internal extension URLRequest {
    
    // swift-migration: original location NSURLRequest+ARTPush.h, line 12 and NSURLRequest+ARTPush.m, line 10
    func settingDeviceAuthentication(_ deviceId: ARTDeviceId, localDevice: ARTLocalDevice) -> URLRequest {
        return settingDeviceAuthentication(deviceId, localDevice: localDevice, logger: nil)
    }
    
    // swift-migration: original location NSURLRequest+ARTPush.h, line 13 and NSURLRequest+ARTPush.m, line 14
    func settingDeviceAuthentication(_ deviceId: ARTDeviceId, localDevice: ARTLocalDevice, logger: ARTInternalLog?) -> URLRequest {
        var mutableRequest = self
        
        if localDevice.id == deviceId {
            if let token = localDevice.identityTokenDetails?.token {
                if let logger = logger {
                    ARTLogDebug(logger, "adding device authentication using local device identity token")
                }
                mutableRequest.setValue(token.art_base64Encoded, forHTTPHeaderField: "X-Ably-DeviceToken")
            } else if let secret = localDevice.secret {
                if let logger = logger {
                    ARTLogDebug(logger, "adding device authentication using local device secret")
                }
                mutableRequest.setValue(secret, forHTTPHeaderField: "X-Ably-DeviceSecret")
            }
        }
        
        return mutableRequest
    }
    
    // swift-migration: original location NSURLRequest+ARTPush.h, line 14 and NSURLRequest+ARTPush.m, line 31
    func settingDeviceAuthentication(_ localDevice: ARTLocalDevice) -> URLRequest {
        return settingDeviceAuthentication(localDevice, logger: nil)
    }
    
    // swift-migration: original location NSURLRequest+ARTPush.h, line 15 and NSURLRequest+ARTPush.m, line 35
    func settingDeviceAuthentication(_ localDevice: ARTLocalDevice, logger: ARTInternalLog?) -> URLRequest {
        return settingDeviceAuthentication(localDevice.id ?? "", localDevice: localDevice, logger: logger)
    }
}

// swift-migration: Extensions for NSMutableURLRequest to match Objective-C interface
internal extension NSMutableURLRequest {
    
    func settingDeviceAuthentication(_ deviceId: ARTDeviceId, localDevice: ARTLocalDevice) -> NSURLRequest {
        let urlRequest = self as URLRequest
        let result = urlRequest.settingDeviceAuthentication(deviceId, localDevice: localDevice)
        return result as NSURLRequest
    }
    
    func settingDeviceAuthentication(_ deviceId: ARTDeviceId, localDevice: ARTLocalDevice, logger: ARTInternalLog?) -> NSURLRequest {
        let urlRequest = self as URLRequest
        let result = urlRequest.settingDeviceAuthentication(deviceId, localDevice: localDevice, logger: logger)
        return result as NSURLRequest
    }
    
    func settingDeviceAuthentication(_ localDevice: ARTLocalDevice) -> NSURLRequest {
        let urlRequest = self as URLRequest
        let result = urlRequest.settingDeviceAuthentication(localDevice)
        return result as NSURLRequest
    }
    
    func settingDeviceAuthentication(_ localDevice: ARTLocalDevice, logger: ARTInternalLog?) -> NSURLRequest {
        let urlRequest = self as URLRequest
        let result = urlRequest.settingDeviceAuthentication(localDevice, logger: logger)
        return result as NSURLRequest
    }
}