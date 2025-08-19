# Plugin mechanism

ably-cocoa allows users to pass in Ably-authored plugins via the `ARTClientOptions.plugins` property. These plugins extend the functionality of the SDK.

ably-cocoa exposes a separate library called `_AblyPluginSupportPrivate`. This provides an API that plugins can use to access ably-cocoa's internals.

I will expand on this documentation once this mechanism is more mature; currently [ADR-128: Plugins for ably-cocoa SDK](https://ably.atlassian.net/wiki/spaces/ENG/pages/3838574593/ADR-128+Plugins+for+ably-cocoa+SDK) provides a decent description of our approach.

Currently, our only plugin is for adding LiveObjects functionality. This plugin can be found at https://github.com/ably/ably-cocoa-liveobjects-plugin.

## Notes on `_AblyPluginSupportPrivate`

- Written in Objective-C (so that it can access ably-cocoa's private headers).
- There is a two-way dependency between ably-cocoa and `_AblyPluginSupportPrivate`:
    - ably-cocoa imports `_AblyPluginSupportPrivate`'s plugin headers (e.g. `APLiveObjectsPlugin.h`) so that it can access the methods exposed by plugins. However, ably-cocoa does not _link_ to `_AblyPluginSupportPrivate`, and so it cannot depend on any classes defined in `_AblyPluginSupportPrivate`.
    - `_AblyPluginSupportPrivate` imports ably-cocoa's private headers so that it can expose ably-cocoa's internals to plugins via `PluginAPI`.
- Currently, the plan is to test all the LiveObjects functionality within the LiveObjects plugin repository, so ably-cocoa does not contain any tests for the plugins mechanism.
- The underscore and `Private` are to reduce the chances of the user accidentally importing it into their project.

## Development guidelines

- Make good use of `NS_SWIFT_NAME` to make `_AblyPluginSupportPrivate` nicer to use from Swift (e.g. to remove the `AP` prefix from class names).
