import Ably.Private

class TestProxyTransportFactory: RealtimeTransportFactory {
    private let semaphore = DispatchSemaphore(value: 1)
    private var createdTransportCount = 0
    private var firstCreatedTransport: TestProxyTransport?
    var onlyCreatedTransport: TestProxyTransport {
        get {
            semaphore.wait()
            guard createdTransportCount == 1 else {
                preconditionFailure("Expected precisely 1 transport to have already been created, but \(createdTransportCount) have")
            }
            let onlyCreatedTransport = self.firstCreatedTransport
            semaphore.signal()
            return onlyCreatedTransport!
        }
    }

    var actionsIgnored: [ARTProtocolMessageAction]

    init(
        actionsIgnored: [ARTProtocolMessageAction] = []
    ) {
        self.actionsIgnored = actionsIgnored
    }

    func transport(withRest rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, connectionSerial: NSNumber?, logger: InternalLog) -> ARTRealtimeTransport {
        let transport = TestProxyTransport(
            rest: rest,
            options: options,
            resumeKey: resumeKey,
            connectionSerial: connectionSerial,
            logger: logger
        )

        transport.actionsIgnored = actionsIgnored

        semaphore.wait()
        if (createdTransportCount == 0) {
            firstCreatedTransport = transport
        }
        createdTransportCount += 1
        semaphore.signal()

        return transport
    }
}
