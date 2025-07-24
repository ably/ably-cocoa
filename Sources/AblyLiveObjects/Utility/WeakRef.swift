/// A struct that holds a weak reference to an object.
///
/// This allows us to store a weak reference inside a Sendable object. The pattern comes from the [`weak let` proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0481-weak-let.md). (We can get rid of this type and use `weak let` once Swift 6.2 is out.)
internal struct WeakRef<Referenced: AnyObject> {
    internal weak var referenced: Referenced?
}

extension WeakRef: Sendable where Referenced: Sendable {}

// MARK: - Specialized versions of WeakRef

// These are protocol-specific versions of ``WeakRef`` that hold an existential type (e.g. `any CoreSDK`). (This is because the compiler complains that an existential of a class-bound protocol doesn't conform to `AnyObject`.)

internal struct WeakLiveMapObjectPoolDelegateRef: Sendable {
    internal weak var referenced: LiveMapObjectPoolDelegate?
}
