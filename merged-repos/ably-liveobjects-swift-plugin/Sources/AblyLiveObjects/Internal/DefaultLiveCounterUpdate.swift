@available(macOS 10.15, iOS 13, tvOS 13, *)
internal struct DefaultLiveCounterUpdate: LiveCounterUpdate, Equatable {
    internal var amount: Double
}
