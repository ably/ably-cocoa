import Ably.Private

class TestProxyTransportFactory: RealtimeTransportFactory {
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

        return transport
    }
}
