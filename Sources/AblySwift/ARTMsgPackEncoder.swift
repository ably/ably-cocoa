import Foundation
import msgpack

// swift-migration: original location ARTMsgPackEncoder.h, line 5 and ARTMsgPackEncoder.m, line 4
internal class ARTMsgPackEncoder: NSObject, ARTJsonLikeEncoderDelegate {
    
    // swift-migration: original location ARTMsgPackEncoder.m, line 6
    internal func mimeType() -> String {
        return "application/x-msgpack"
    }
    
    // swift-migration: original location ARTMsgPackEncoder.m, line 10
    internal func format() -> ARTEncoderFormat {
        return .msgPack
    }
    
    // swift-migration: original location ARTMsgPackEncoder.m, line 14
    internal func formatAsString() -> String {
        return "msgpack"
    }
    
    // swift-migration: original location ARTMsgPackEncoder.m, line 18
    // swift-migration: Updated to use Swift throws pattern instead of NSError** pattern (acceptable deviation per PRD)
    internal func decode(_ data: Data) throws -> Any? {
        return (data as NSData).messagePackParse()
    }
    
    // swift-migration: original location ARTMsgPackEncoder.m, line 22
    // swift-migration: Updated to use Swift throws pattern instead of NSError** pattern (acceptable deviation per PRD)
    internal func encode(_ obj: Any) throws -> Data? {
        // swift-migration: Note - messagePack method is added by msgpack library extension
        guard let result = (obj as AnyObject).messagePack?() else {
            let nsError = NSError(
                domain: ARTAblyErrorDomain,
                code: Int(ARTClientCodeErrorInvalidType.rawValue),
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode object to msgpack"]
            )
            throw nsError
        }
        return result
    }
}