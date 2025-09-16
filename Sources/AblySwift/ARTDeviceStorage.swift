import Foundation

// Instances of ARTDeviceStorage should expect to have their methods called
// from any thread.
// swift-migration: original location ARTDeviceStorage.h, line 9
/// :nodoc:
internal protocol ARTDeviceStorage {
    // swift-migration: original location ARTDeviceStorage.h, line 10
    func objectForKey(_ key: String) -> Any?
    
    // swift-migration: original location ARTDeviceStorage.h, line 11
    func setObject(_ value: Any?, forKey key: String)
    
    // swift-migration: original location ARTDeviceStorage.h, line 12
    func secretForDevice(_ deviceId: ARTDeviceId) -> String?
    
    // swift-migration: original location ARTDeviceStorage.h, line 13
    func setSecret(_ value: String?, forDevice deviceId: ARTDeviceId)
}