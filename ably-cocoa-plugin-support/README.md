# Ably Cocoa SDK Plugin Support Library

This is an Ably-internal library that defines the private APIs that the [Ably Pub/Sub Cocoa SDK](https://github.com/ably/ably-cocoa) uses to communicate with its plugins.

> [!note]
> This library is an implementation detail of the Ably SDK and should not be used directly by end users of the SDK.

Further documentation will be added in the future.

## Conventions

- Methods whose names begin with `nosync_` must always be called on the client's internal queue.
