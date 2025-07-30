import Ably
@testable import AblyLiveObjects

final class MockCoreSDK: CoreSDK {
    /// Synchronizes access to all of this instance's mutable state.
    private let mutex = NSLock()

    private nonisolated(unsafe) var _channelState: ARTRealtimeChannelState

    init(channelState: ARTRealtimeChannelState) {
        _channelState = channelState
    }

    func publish(objectMessages _: [AblyLiveObjects.OutboundObjectMessage]) async throws(AblyLiveObjects.InternalError) {
        protocolRequirementNotImplemented()
    }

    var channelState: ARTRealtimeChannelState {
        get {
            mutex.withLock {
                _channelState
            }
        }
        set {
            mutex.withLock {
                _channelState = newValue
            }
        }
    }
}
