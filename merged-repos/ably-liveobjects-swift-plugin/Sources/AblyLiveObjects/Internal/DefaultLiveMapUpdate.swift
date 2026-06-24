@available(macOS 10.15, iOS 13, tvOS 13, *)
internal struct DefaultLiveMapUpdate: LiveMapUpdate, Equatable {
    internal var update: [String: LiveMapUpdateAction]
}
