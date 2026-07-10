internal import _AblyPluginSupportPrivate

/// As described by `PBR*` spec points.
///
/// We use this internally instead of `_AblyCocoaPluginSupportPrivate.PublishResultProtocol` because Swift allows us to directly store `nil` values in an array.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal struct PublishResult {
    internal var serials: [String?]
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal extension PublishResult {
    init(pluginPublishResult: _AblyPluginSupportPrivate.PublishResultProtocol) {
        serials = pluginPublishResult.serials.map(\.value)
    }
}
