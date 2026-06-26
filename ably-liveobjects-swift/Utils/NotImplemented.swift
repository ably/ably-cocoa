/// Marks an API surface point that has not yet been implemented in this experimental target.
///
/// Every public type in this target is currently a skeleton: the API shape is defined, but the
/// behaviour is not. Calling into any of it traps. This mirrors the requested `fail("Not implemented")`
/// behaviour; we use `fatalError` (rather than Nimble's `fail`, which is test-only and returns `Void`)
/// because it returns `Never` and therefore satisfies any return type, including `throws`/`async`
/// contexts.
internal func notImplemented(_ function: StaticString = #function) -> Never {
    fatalError("Not implemented: \(function)")
}
