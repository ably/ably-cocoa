import Foundation

public class ARTJsonEncoder: ARTJsonLikeEncoderDelegate {
    
    public func mimeType() -> String {
        return "application/json"
    }
    
    public func format() -> ARTEncoderFormat {
        return .json
    }
    
    public func formatAsString() -> String {
        return "json"
    }
    
    public func decode(_ data: Data) throws -> Any? {
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
    
    public func encode(_ obj: Any) throws -> Data? {
        do {
            var options: JSONSerialization.WritingOptions = []
            if #available(macOS 10.13, iOS 11.0, tvOS 11.0, *) {
                options = .sortedKeys
            }
            return try JSONSerialization.data(withJSONObject: obj, options: options)
        } catch {
            // Convert to Ably error format
            let ablyError = NSError(domain: ARTAblyErrorDomain, 
                                   code: ARTClientCodeErrorInvalidType, 
                                   userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
            throw ablyError
        }
    }
}

// Error codes
public let ARTClientCodeErrorInvalidType = 40000