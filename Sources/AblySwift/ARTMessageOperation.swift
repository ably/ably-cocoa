import Foundation

// swift-migration: original location ARTMessageOperation.h, line 8 and ARTMessageOperation.m, line 4
/// An interface outlining the optional `ARTMessageOperation` object which resides in an `ARTMessage` object. This is populated within the `ARTMessage` object when the message is an update or delete operation.
public class ARTMessageOperation: NSObject {
    
    // swift-migration: original location ARTMessageOperation.h, line 10
    public var clientId: String?
    
    // swift-migration: original location ARTMessageOperation.h, line 11
    public var descriptionText: String?
    
    // swift-migration: original location ARTMessageOperation.h, line 12
    public var metadata: [String: String]?
    
    public override init() {
        super.init()
    }
    
    // MARK: - Private Methods
    
    // swift-migration: original location ARTMessageOperation+Private.h, line 9 and ARTMessageOperation.m, line 6
    /// Serialize the Operation object
    internal func writeToDictionary(_ dictionary: inout [String: Any]) {
        if let clientId = self.clientId {
            dictionary["clientId"] = clientId
        }
        if let descriptionText = self.descriptionText {
            dictionary["description"] = descriptionText
        }
        if let metadata = self.metadata {
            dictionary["metadata"] = metadata
        }
    }
    
    // swift-migration: original location ARTMessageOperation+Private.h, line 12 and ARTMessageOperation.m, line 18
    /// Deserialize an Operation object from a NSDictionary object
    internal static func createFromDictionary(_ jsonObject: [String: Any]) -> ARTMessageOperation {
        let operation = ARTMessageOperation()
        if let clientId = jsonObject["clientId"] as? String {
            operation.clientId = clientId
        }
        if let description = jsonObject["description"] as? String {
            operation.descriptionText = description
        }
        
        if let metadata = jsonObject["metadata"] as? [String: String] {
            operation.metadata = metadata
        }
        
        return operation
    }
}