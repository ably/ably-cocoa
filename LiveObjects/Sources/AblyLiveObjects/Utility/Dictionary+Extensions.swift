@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal extension Dictionary {
    /// Behaves like `Dictionary.mapValues`, but the thrown error has the same type as that thrown by the transform. (`mapValues` uses `rethrows`, which is always an untyped throw.)
    func ablyLiveObjects_mapValuesWithTypedThrow<T, E>(_ transform: (Value) throws(E) -> T) throws(E) -> [Key: T] where E: Error {
        try .init(uniqueKeysWithValues: map { key, value throws(E) in
            try (key, transform(value))
        })
    }
}
