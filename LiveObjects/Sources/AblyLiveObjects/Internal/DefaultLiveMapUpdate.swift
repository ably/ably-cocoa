@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal struct DefaultLiveMapUpdate: LiveMapUpdate, Equatable {
    internal var update: [String: LiveMapUpdateAction]
}
