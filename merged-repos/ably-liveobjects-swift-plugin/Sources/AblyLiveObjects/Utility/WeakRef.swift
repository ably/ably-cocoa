/// A struct that holds a weak reference to an object.
///
/// This allows us to store a weak reference inside a Sendable object. The pattern comes from the [`weak let` proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0481-weak-let.md). (We can get rid of this type and use `weak let` once Swift 6.2 is out.)
@available(macOS 10.15, iOS 13, tvOS 13, *)
internal struct WeakRef<Referenced: AnyObject> {
    internal weak var referenced: Referenced?
}

@available(macOS 10.15, iOS 13, tvOS 13, *)
extension WeakRef: Sendable where Referenced: Sendable {}
