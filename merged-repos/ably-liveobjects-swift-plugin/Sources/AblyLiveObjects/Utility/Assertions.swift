/// Stops execution because we tried to use a feature that is not yet implemented.
@available(macOS 10.15, iOS 13, tvOS 13, *)
internal func notYetImplemented(_ message: @autoclosure () -> String = String(), file _: StaticString = #file, line _: UInt = #line) -> Never {
    fatalError({
        let returnedMessage = message()
        return "Not yet implemented\(returnedMessage.isEmpty ? "" : ": \(returnedMessage)")"
    }())
}
