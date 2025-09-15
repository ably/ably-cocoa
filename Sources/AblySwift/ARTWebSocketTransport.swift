import Foundation
import SocketRocket

// swift-migration: original location ARTWebSocketTransport.m, line 24-37
private enum ARTWebSocketCloseCode: Int {
    case neverConnected = -1
    case buggyClose = -2
    case normal = 1000
    case goingAway = 1001
    case protocolError = 1002
    case refuse = 1003
    case noUtf8 = 1007
    case policyValidation = 1008
    case tooBig = 1009
    case `extension` = 1010
    case unexpectedCondition = 1011
    case tlsError = 1015
}

// swift-migration: original location ARTWebSocketTransport.m, line 39
internal func WebSocketStateToStr(_ state: ARTWebSocketReadyState) -> String {
    switch state {
    case .connecting:
        return "Connecting" // 0
    case .open:
        return "Open" // 1
    case .closing:
        return "Closing" // 2
    case .closed:
        return "Closed" // 3
    @unknown default:
        return "Unknown"
    }
}

// swift-migration: original location ARTWebSocketTransport.m, line 390
internal func ARTRealtimeTransportStateToStr(_ state: ARTRealtimeTransportState) -> String {
    switch state {
    case .opening:
        return "Connecting" // 0
    case .opened:
        return "Open" // 1
    case .closing:
        return "Closing" // 2
    case .closed:
        return "Closed" // 3
    @unknown default:
        return "Unknown"
    }
}

// swift-migration: original location ARTWebSocketTransport.h, line 11 and ARTWebSocketTransport.m, line 51
internal class ARTWebSocketTransport: NSObject, ARTRealtimeTransport, ARTWebSocketDelegate {
    // swift-migration: original location ARTWebSocketTransport.m, line 52
    private weak var _delegate: ARTRealtimeTransportDelegate?
    
    // swift-migration: original location ARTWebSocketTransport.m, line 53
    private var _state: ARTRealtimeTransportState = .closed
    
    // swift-migration: original location ARTWebSocketTransport.m, line 57
    /// The dispatch queue for firing the events. Must be the same for the whole library.
    private let _workQueue: DispatchQueue
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 13
    internal var encoder: ARTEncoder
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 14
    internal let logger: InternalLog
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 15
    internal let options: ARTClientOptions
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 17
    internal var websocket: ARTWebSocket?
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 18
    internal var websocketURL: URL?
    
    // swift-migration: original location ARTWebSocketTransport.h, line 17
    public let resumeKey: String?
    
    // swift-migration: original location ARTWebSocketTransport.m, line 45
    private let webSocketFactory: WebSocketFactory
    
    // swift-migration: original location ARTWebSocketTransport.m, line 61
    public var _stateEmitter: ARTInternalEventEmitter<ARTEvent, Any>
    public var stateEmitter: ARTEventEmitter<ARTEvent, Any> {
        return _stateEmitter
    }

    // swift-migration: original location ARTWebSocketTransport.m, line 60
    public weak var delegate: ARTRealtimeTransportDelegate? {
        get { _delegate }
        set { _delegate = newValue }
    }
    
    @available(*, unavailable, message: "Use initWithRest:options:resumeKey:logger:webSocketFactory: instead")
    public override init() {
        fatalError("Use initWithRest:options:resumeKey:logger:webSocketFactory: instead")
    }
    
    // swift-migration: original location ARTWebSocketTransport.h, line 15 and ARTWebSocketTransport.m, line 63
    public init(rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, logger: InternalLog, webSocketFactory: WebSocketFactory) {
        self._workQueue = rest.queue
        self.websocket = nil
        self._state = .closed
        self.encoder = rest.defaultEncoder
        self.logger = logger
        self.options = options.copy() as! ARTClientOptions
        self.resumeKey = resumeKey
        self._stateEmitter = ARTInternalEventEmitter<ARTEvent, Any>(queue: rest.queue)
        self.webSocketFactory = webSocketFactory
        
        super.init()
        
        ARTLogVerbose(self.logger, "R:\(String(describing: _delegate)) WS:\(self) alloc")
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 81
    deinit {
        ARTLogVerbose(self.logger, "R:\(String(describing: _delegate)) WS:\(self) dealloc")
        self.websocket?.delegate = nil
        self.websocket = nil
        self.delegate = nil
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 88
    internal func send(_ data: Data, withSource decodedObject: Any) -> Bool {
        if websocket?.readyState == .open {
            websocket?.send(data)
            return true
        } else {
            var extraInformation = ""
            if let msg = decodedObject as? ARTProtocolMessage {
                extraInformation = "with action \"\(msg.action.rawValue) - \(ARTProtocolMessageActionToStr(msg.action))\" "
            }
            ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) sending message \(extraInformation)was ignored because websocket isn't ready")
            return false
        }
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 104
    internal func internalSend(_ msg: ARTProtocolMessage) {
        ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket sending action \(msg.action.rawValue) - \(ARTProtocolMessageActionToStr(msg.action))")
        do {
            let data = try encoder.encodeProtocolMessage(msg) ?? Data()
            _ = send(data, withSource: msg)
        } catch {
            ARTLogError(self.logger, "Failed to encode protocol message: \(error)")
        }
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 110
    internal func receive(_ msg: ARTProtocolMessage) {
        delegate?.realtimeTransport(self, didReceiveMessage: msg)
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 114
    @discardableResult
    internal func receive(with data: Data) -> ARTProtocolMessage? {
        do {
            let pm = try encoder.decodeProtocolMessage(data)
            if let pm = pm {
                receive(pm)
            }
            return pm
        } catch {
            ARTLogError(self.logger, "Failed to decode protocol message: \(error)")
            return nil
        }
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 120
    public func connect(withKey key: String) {
        _state = .opening
        ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket connect with key")
        let keyParam = URLQueryItem(name: "key", value: key)
        setupWebSocket([keyParam.name: keyParam], withOptions: options, resumeKey: resumeKey)
        // Connect
        websocket?.open()
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 129
    public func connect(withToken token: String) {
        _state = .opening
        ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket connect with token")
        let accessTokenParam = URLQueryItem(name: "accessToken", value: token)
        setupWebSocket([accessTokenParam.name: accessTokenParam], withOptions: options, resumeKey: resumeKey)
        // Connect
        websocket?.open()
    }
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 20 and ARTWebSocketTransport.m, line 138
    @discardableResult
    internal func setupWebSocket(_ params: [String: URLQueryItem], withOptions options: ARTClientOptions, resumeKey: String?) -> URL {
        var queryItems = params
        
        // ClientID
        if let clientId = options.clientId {
            queryItems["clientId"] = URLQueryItem(name: "clientId", value: clientId)
        }
        
        // Echo
        queryItems["echo"] = URLQueryItem(name: "echo", value: options.echoMessages ? "true" : "false")
        
        // Format: MsgPack, JSON
        queryItems["format"] = URLQueryItem(name: "format", value: encoder.formatAsString())
        
        // RTN16k
        if let recover = options.recover {
            do {
                let recoveryKey = try ARTConnectionRecoveryKey.fromJsonString(recover)
                queryItems["recover"] = URLQueryItem(name: "recover", value: recoveryKey.connectionKey)
            } catch {
                ARTLogError(logger, "Couldn't construct a recovery key from the string provided: \(recover)")
            }
        } else if let resumeKey = resumeKey {
            queryItems["resume"] = URLQueryItem(name: "resume", value: resumeKey) // RTN15b1
        }
        
        queryItems["v"] = URLQueryItem(name: "v", value: ARTDefault.apiVersion())
        
        // Lib
        queryItems["agent"] = URLQueryItem(name: "agent", value: ARTClientInformation.agentIdentifier(withAdditionalAgents: options.agents))
        
        // Transport Params
        if let transportParams = options.transportParams {
            for (key, obj) in transportParams {
                queryItems[key] = URLQueryItem(name: key, value: obj.stringValue)
            }
        }
        
        // URL
        var urlComponents = URLComponents(string: "/")!
        urlComponents.queryItems = Array(queryItems.values)
        let url = urlComponents.url(relativeTo: options.realtimeUrl())!
        
        ARTLogDebug(logger, "R:\(String(describing: _delegate)) WS:\(self) url \(url)")
        
        let request = URLRequest(url: url)
        
        self.websocket = webSocketFactory.createWebSocket(with: request, logger: logger)
        websocket?.delegateDispatchQueue = _workQueue
        websocket?.delegate = self
        self.websocketURL = url
        return url
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 195
    public func sendClose() {
        _state = .closing
        let closeMessage = ARTProtocolMessage()
        closeMessage.action = .close
        internalSend(closeMessage)
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 202
    public func sendPing() {
        let heartbeatMessage = ARTProtocolMessage()
        heartbeatMessage.action = .heartbeat
        internalSend(heartbeatMessage)
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 208
    public func close() {
        delegate = nil
        guard websocket != nil else { return }
        websocket?.delegate = nil
        websocket?.close(withCode: ARTWebSocketCloseCode.normal.rawValue, reason: "Normal Closure")
        self.websocket = nil
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 216
    public func abort(_ reason: ARTStatus) {
        delegate = nil
        guard websocket != nil else { return }
        websocket?.delegate = nil
        if let errorInfo = reason.errorInfo {
            websocket?.close(withCode: ARTWebSocketCloseCode.normal.rawValue, reason: errorInfo.description)
        } else {
            websocket?.close(withCode: ARTWebSocketCloseCode.normal.rawValue, reason: "Abnormal Closure")
        }
        self.websocket = nil
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 229
    public func setHost(_ host: String) {
        options.realtimeHost = host
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 233
    public func host() -> String {
        return options.realtimeHost ?? ""
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 237
    public var state: ARTRealtimeTransportState {
        if websocket?.readyState == .open {
            return .opened
        }
        return _state
    }
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 22 and ARTWebSocketTransport.m, line 244
    internal func setState(_ state: ARTRealtimeTransportState) {
        _state = state
    }
    
    // MARK: - ARTWebSocketDelegate
    
    // swift-migration: original location ARTWebSocketTransport.m, line 254
    // All delegate methods from SocketRocket are called from rest's serial queue,
    // since we pass it as delegate queue on setupWebSocket. So we can safely
    // call all our delegate's methods.
    public func webSocketDidOpen(_ websocket: ARTWebSocket) {
        ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket did open")
        stateEmitter.emit(ARTEvent.new(withTransportState: .opened), with: nil)
        delegate?.realtimeTransportAvailable(self)
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 260
    public func webSocket(_ webSocket: ARTWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket did disconnect (code \(code)) \(reason ?? "")")
        
        switch code {
        case ARTWebSocketCloseCode.normal.rawValue:
            delegate?.realtimeTransportClosed(self)
        case ARTWebSocketCloseCode.neverConnected.rawValue:
            delegate?.realtimeTransportNeverConnected(self)
        case ARTWebSocketCloseCode.buggyClose.rawValue,
             ARTWebSocketCloseCode.goingAway.rawValue:
            // Connectivity issue
            delegate?.realtimeTransportDisconnected(self, withError: nil as ARTRealtimeTransportError?)
        case ARTWebSocketCloseCode.refuse.rawValue,
             ARTWebSocketCloseCode.policyValidation.rawValue:
            let errorInfo = ARTErrorInfo.create(withCode: code, message: reason ?? "")
            // swift-migration: Lawrence added force unwrap
            let error = ARTRealtimeTransportError(error: errorInfo, type: .refused, url: websocketURL!)
            delegate?.realtimeTransportRefused(self, withError: error)
        case ARTWebSocketCloseCode.tooBig.rawValue:
            delegate?.realtimeTransportTooBig(self)
        case ARTWebSocketCloseCode.noUtf8.rawValue,
             ARTWebSocketCloseCode.protocolError.rawValue,
             ARTWebSocketCloseCode.unexpectedCondition.rawValue,
             ARTWebSocketCloseCode.`extension`.rawValue,
             ARTWebSocketCloseCode.tlsError.rawValue:
            // Failed
            let errorInfo = ARTErrorInfo.create(withCode: code, message: reason ?? "")
            // swift-migration: Lawrence added force unwrap
            let error = ARTRealtimeTransportError(error: errorInfo, type: .other, url: websocketURL!)
            delegate?.realtimeTransportFailed(self, withError: error)
        default:
            assert(true, "WebSocket close: unknown code")
        }
        
        _state = .closed
        stateEmitter.emit(ARTEvent.new(withTransportState: .closed), with: nil)
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 309
    public func webSocket(_ webSocket: ARTWebSocket, didFailWithError error: Error) {
        ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket did receive error \(error)")
        
        delegate?.realtimeTransportFailed(self, withError: classifyError(error))
        _state = .closed
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 316
    private func classifyError(_ error: Error) -> ARTRealtimeTransportError {
        let nsError = error as NSError
        var type: ARTRealtimeTransportErrorType = .other
        
        if nsError.domain == "com.squareup.SocketRocket" && nsError.code == 504 {
            type = .timeout
        } else if nsError.domain == kCFErrorDomainCFNetwork as String {
            type = .hostUnreachable
        } else if nsError.domain == "NSPOSIXErrorDomain" && (nsError.code == 57 || nsError.code == 50) {
            type = .noInternet
        } else if nsError.domain == ARTSRWebSocketErrorDomain && nsError.code == 2132 {
            if let status = nsError.userInfo[ARTSRHTTPResponseErrorKey] as? NSNumber {
                // swift-migration: Lawrence added force unwrap
                return ARTRealtimeTransportError(error: nsError, badResponseCode: status.intValue, url: websocketURL!)
            }
        }
        
        // swift-migration: Lawrence added force unwrap
        return ARTRealtimeTransportError(error: nsError, type: type, url: websocketURL!)
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 337
    public func webSocket(_ webSocket: ARTWebSocket, didReceiveMessage message: Any) {
        ARTLogVerbose(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket did receive message")
        
        if websocket?.readyState == .closed {
            ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket is closed, message has been ignored")
            return
        }
        
        if let message = message as? String {
            webSocketMessageText(message)
        } else if let message = message as? Data {
            webSocketMessageData(message)
        } else if let message = message as? ARTProtocolMessage {
            webSocketMessageProtocol(message)
        }
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 354
    private func webSocketMessageText(_ text: String) {
        ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket in \(WebSocketStateToStr(websocket?.readyState ?? .closed)) state did receive message \(text)")
        
        guard let data = text.data(using: .utf8) else { return }
        receive(with: data)
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 363
    private func webSocketMessageData(_ data: Data) {
        ARTLogVerbose(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket in \(WebSocketStateToStr(websocket?.readyState ?? .closed)) state did receive data \(data)")
        
        receive(with: data)
    }
    
    // swift-migration: original location ARTWebSocketTransport.m, line 369
    private func webSocketMessageProtocol(_ message: ARTProtocolMessage) {
        ARTLogDebug(self.logger, "R:\(String(describing: _delegate)) WS:\(self) websocket in \(WebSocketStateToStr(websocket?.readyState ?? .closed)) state did receive protocol message \(message)")
        
        receive(message)
    }
}

// MARK: - ARTEvent (TransportState)

// swift-migration: original location ARTWebSocketTransport.m, line 405
extension ARTEvent {
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 29 and ARTWebSocketTransport.m, line 407
    public convenience init(transportState value: ARTRealtimeTransportState) {
        self.init(string: "ARTRealtimeTransportState\(ARTRealtimeTransportStateToStr(value))")
    }
    
    // swift-migration: original location ARTWebSocketTransport+Private.h, line 30 and ARTWebSocketTransport.m, line 411
    public static func new(withTransportState value: ARTRealtimeTransportState) -> ARTEvent {
        return ARTEvent(string: "ARTRealtimeTransportState\(ARTRealtimeTransportStateToStr(value))")
    }
}
