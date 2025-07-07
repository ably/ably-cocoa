/// This is the equivalent of the `LiveObject` abstract class described in RTLO.
///
/// ``DefaultLiveCounter`` and ``DefaultLiveMap`` include it by composition.
internal struct LiveObjectMutableState {
    // RTLO3a
    internal var objectID: String
    // RTLO3b
    internal var siteTimeserials: [String: String] = [:]
    // RTLO3c
    internal var createOperationIsMerged = false
}
