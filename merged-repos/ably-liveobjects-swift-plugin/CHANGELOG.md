# Change Log

## [0.4.0](https://github.com/ably/ably-liveobjects-swift-plugin/tree/0.4.0)

### Operations are now applied on acknowledgement

When you call a mutation method (e.g. `map.set()`), the SDK now applies the effects of this operation to the local LiveObjects data as soon as it receives the server's acknowledgement of the operation. This is an improvement over earlier versions, in which the SDK did not apply such an operation until receiving the operation's echo.

Concretely, this means that in the following example, `fetchedValue` is now guaranteed to be `myValue`:

```swift
try await map.set(key: "myKey", value: "myValue")
let fetchedValue = try map.get(key: "myKey")
```

### Other changes

These changes do not affect the plugin's public API.

- Buffer operations whilst `SYNCING` per updated RTO8a (https://github.com/ably/ably-liveobjects-swift-plugin/pull/109)
- Fix events emitted upon sync (https://github.com/ably/ably-liveobjects-swift-plugin/pull/111)
- Support the protocol v6 `ObjectMessage` structure (https://github.com/ably/ably-liveobjects-swift-plugin/pull/114)
- Implement new rules for discarding ops buffered during sync (https://github.com/ably/ably-liveobjects-swift-plugin/pull/121)
- Partial object sync (https://github.com/ably/ably-liveobjects-swift-plugin/pull/117)
- Implement `MAP_CLEAR` operation (https://github.com/ably/ably-liveobjects-swift-plugin/pull/122)

**Full Changelog**: https://github.com/ably/ably-liveobjects-swift-plugin/compare/0.3.0...0.4.0

## [0.3.0](https://github.com/ably/ably-liveobjects-swift-plugin/tree/0.3.0)

## What's Changed

No public API changes. Some internal improvements:

- Use server time for object ID ([#98](https://github.com/ably/ably-liveobjects-swift-plugin/pull/98))
- Use server-sent GC grace period ([#99](https://github.com/ably/ably-liveobjects-swift-plugin/pull/99))
- Always transition to `SYNCING` on receipt of `ATTACHED` ([#104](https://github.com/ably/ably-liveobjects-swift-plugin/pull/104))

**Full Changelog**: https://github.com/ably/ably-liveobjects-swift-plugin/compare/0.2.0...0.3.0

## [0.2.0](https://github.com/ably/ably-liveobjects-swift-plugin/tree/0.2.0)

## What's Changed

- Fixes an issue with SPM dependency specification that caused compliation errors. ([#93](https://github.com/ably/ably-liveobjects-swift-plugin/issues/93))
- Changes `JSONValue`'s `number` associated value from `NSNumber` to `Double`. ([#91](https://github.com/ably/ably-liveobjects-swift-plugin/pull/91))

**Full Changelog**: https://github.com/ably/ably-liveobjects-swift-plugin/compare/0.1.0...0.2.0

## [0.1.0](https://github.com/ably/ably-liveobjects-swift-plugin/tree/0.1.0)

## What's New

- Our first release! LiveObjects provides a simple way to build collaborative applications with synchronized state across multiple clients in real-time.

Learn [about Ably LiveObjects.](https://ably.com/docs/liveobjects)

[Getting started with LiveObjects in Swift.](https://ably.com/docs/liveobjects/quickstart/swift)
