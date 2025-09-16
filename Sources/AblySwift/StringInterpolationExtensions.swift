import Foundation

// swift-migration: Custom string interpolation extension to support pointer formatting (used for %p in Objective-C log statements)
extension String.StringInterpolation {
    
    /// Custom string interpolation for pointer formatting
    /// Usage: "\(pointer: myObj)" reproduces the %p format from Objective-C
    mutating func appendInterpolation<T: AnyObject>(pointer: T) {
        let address = Unmanaged.passUnretained(pointer).toOpaque()
        appendLiteral(String(format: "%p", Int(bitPattern: address)))
    }
    
    /// Custom string interpolation for pointer formatting with optional objects
    /// Usage: "\(pointer: myOptionalObj)" reproduces the %p format from Objective-C
    mutating func appendInterpolation<T: AnyObject>(pointer: T?) {
        if let pointer = pointer {
            let address = Unmanaged.passUnretained(pointer).toOpaque()
            appendLiteral(String(format: "%p", Int(bitPattern: address)))
        } else {
            appendLiteral("(null)")
        }
    }
}