@available(macOS 11, iOS 14, tvOS 14, *)
internal struct DefaultLiveMapUpdate: LiveMapUpdate, Equatable {
    internal var update: [String: LiveMapUpdateAction]
}
