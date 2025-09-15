import Foundation

// swift-migration: original location ARTJsonEncoder.h, line 5 and ARTJsonEncoder.m, line 3
internal class ARTJsonEncoder: NSObject, ARTJsonLikeEncoderDelegate {
    
    // swift-migration: original location ARTJsonEncoder.m, line 5
    internal func mimeType() -> String {
        return "application/json"
    }
    
    // swift-migration: original location ARTJsonEncoder.m, line 9
    internal func format() -> ARTEncoderFormat {
        return .json
    }
    
    // swift-migration: original location ARTJsonEncoder.m, line 13
    internal func formatAsString() -> String {
        return "json"
    }
    
    // swift-migration: original location ARTJsonEncoder.m, line 17
    // swift-migration: Updated to use Swift throws pattern instead of NSError** pattern (acceptable deviation per PRD)
    internal func decode(_ data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
    
    // swift-migration: original location ARTJsonEncoder.m, line 21
    // swift-migration: Updated to use Swift throws pattern instead of NSError** pattern (acceptable deviation per PRD)
    internal func encode(_ obj: Any) throws -> Data {
        var options: JSONSerialization.WritingOptions = []
        if #available(macOS 10.13, iOS 11.0, tvOS 11.0, *) {
            options = .sortedKeys
        }
        do {
            return try JSONSerialization.data(withJSONObject: obj, options: options)
        } catch {
            // swift-migration: Preserve original error wrapping behavior but use throws
            let nsError = NSError(
                domain: ARTAblyErrorDomain,
                code: Int(ARTClientCodeError.invalidType.rawValue),
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
            throw nsError
        }
    }
}
