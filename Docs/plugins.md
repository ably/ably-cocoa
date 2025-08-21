# Plugin mechanism

ably-cocoa allows users to pass in Ably-authored plugins via the `ARTClientOptions.plugins` property. These plugins extend the functionality of the SDK.

ably-cocoa and its plugins depend on a separate library called `_AblyPluginSupportPrivate`, which can be found in the [ably-cocoa-plugin-support repository](https://github.com/ably/ably-cocoa-plugin-support). This provides an API that plugins can use to access ably-cocoa's internals, and which ably-cocoa can use to communicate with its plugins.

I will expand on this documentation once this mechanism is more mature; currently [ADR-128: Plugins for ably-cocoa SDK](https://ably.atlassian.net/wiki/spaces/ENG/pages/3838574593/ADR-128+Plugins+for+ably-cocoa+SDK) provides a decent description of our approach. The key divergence between ADR-128 and our current approach is that `_AblyPluginSupportPrivate` (called `AblyPlugin` in the ADR) is no longer part of ably-cocoa and instead lives in a separate repository. I will update that ADR or create a new one later on as part of clearing technical debt caused by this last-minute change of approach.

Currently, our only plugin is for adding LiveObjects functionality. This plugin can be found at https://github.com/ably/ably-cocoa-liveobjects-plugin.

## Notes on `_AblyPluginSupportPrivate`

- Everything in ably-cocoa that depends on `_AblyPluginSupportPrivate` is gated behind `#ifdef ABLY_SUPPORTS_PLUGINS`, which is only defined in SPM builds. This is so as not to affect the non-SPM builds (i.e. Xcode, CocoaPods), which do not have access to `_AblyPluginSupportPrivate`.
- ably-cocoa provides an implementation of `_AblyPluginSupportPrivate`'s `APPluginAPI` protocol, which is the interface that plugins use to access ably-cocoa's internals. On library initialization, it registers this implementation with `APDependencyStore`, from where plugins can subsequetly fetch it.
- Currently, the plan is to test all the LiveObjects functionality within the LiveObjects plugin repository, so ably-cocoa does not contain any tests for the plugins mechanism.
- The underscore and `Private` are to reduce the chances of the user accidentally importing it into their project.
- `_AblyPluginSupportPrivate` can not refer to any of ably-cocoa's types (since SPM forbids circular dependencies) and so it contains various types that duplicate ably-cocoa's public types. These fall into two categories:
  - enums e.g. `APRealtimeChannelState`, which are an exact copy of the corresponding ably-cocoa enum (in this example, `ARTRealtimeChannelState`)
  - marker protocols e.g. `APPublicRealtimeChannel` which are empty protocols whose instances can always be safely casted to and from their corresponding ably-cocoa type (in this example, `ARTRealtimeChannel`)
- Do not add instance methods to types such as `APLogger` and `APRealtimeChannel` (instead, favour adding methods to `APPluginAPI`), so that ably-cocoa can make its internal `ARTInternalLog` and `ARTRealtimeChannelInternal` types conform to these protocols without having to worry about return or parameter type clashes due to the enum divergence described in the previous point.

## Development guidelines

- Make good use of `NS_SWIFT_NAME` to make `_AblyPluginSupportPrivate` nicer to use from Swift (e.g. to remove the `AP` prefix from class names).
