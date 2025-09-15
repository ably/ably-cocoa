import Foundation
import _AblyPluginSupportPrivate

// swift-migration: Lawrence: have added a lot of unwrapValueWithAmbiguousObjectiveCNullability just to try and get this thing to compile; our nullabilities are quite a mess. wouldn't be surprised at all if this crashes when we run the tests
// swift-migration: Lawrence: have added a lot of `uintValue` to get this to compile

// swift-migration: original location ARTJsonLikeEncoder.h, line 10 and ARTJsonLikeEncoder.m, line 21
internal protocol ARTJsonLikeEncoderDelegate {
    func mimeType() -> String
    func format() -> ARTEncoderFormat
    func formatAsString() -> String
    
    func decode(_ data: Data) throws -> Any?
    func encode(_ obj: Any) throws -> Data?
}

// swift-migration: original location ARTJsonLikeEncoder.h, line 21 and ARTJsonLikeEncoder.m, line 34
internal class ARTJsonLikeEncoder: NSObject, ARTEncoder {
    // swift-migration: original location ARTJsonLikeEncoder.h, line 23
    internal var delegate: ARTJsonLikeEncoderDelegate?
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 35
    private weak var _rest: ARTRestInternal? // weak because rest owns self
    // swift-migration: original location ARTJsonLikeEncoder.m, line 36
    private var _logger: ARTInternalLog?
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 39
    override init() {
        super.init()
        self._rest = nil
        self._logger = nil
        self.delegate = ARTJsonEncoder()
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 25 and ARTJsonLikeEncoder.m, line 43
    init(delegate: ARTJsonLikeEncoderDelegate) {
        super.init()
        self._rest = nil
        self._logger = nil
        self.delegate = delegate
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 26 and ARTJsonLikeEncoder.m, line 52
    init(logger: ARTInternalLog, delegate: ARTJsonLikeEncoderDelegate?) {
        super.init()
        self._rest = nil
        self._logger = logger
        self.delegate = delegate
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 27 and ARTJsonLikeEncoder.m, line 61
    init(rest: ARTRestInternal, delegate: ARTJsonLikeEncoderDelegate?, logger: ARTInternalLog) {
        super.init()
        self._rest = rest
        self._logger = logger
        self.delegate = delegate
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 70
    func mimeType() -> String {
        return delegate?.mimeType() ?? ""
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 74
    func format() -> ARTEncoderFormat {
        return delegate?.format() ?? ARTEncoderFormat.json
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 78
    func formatAsString() -> String {
        return delegate?.formatAsString() ?? ""
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 82
    func decodeMessage(_ data: Data) throws -> ARTMessage? {
        let dictionary = try decodeDictionary(data)
        return messageFromDictionary(dictionary, protocolMessage: nil)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 86
    func decodeMessages(_ data: Data) throws -> [ARTMessage]? {
        let array = try decodeArray(data)
        return messagesFromArray(array, protocolMessage: nil)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 90
    func encodeMessage(_ message: ARTMessage) throws -> Data? {
        let dictionary = messageToDictionary(message)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 94
    func encodeMessages(_ messages: [ARTMessage]) throws -> Data? {
        let array = messagesToArray(messages)
        return try encode(array)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 98
    func decodePresenceMessage(_ data: Data) throws -> ARTPresenceMessage? {
        let dictionary = try decodeDictionary(data)
        return presenceMessageFromDictionary(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 102
    func decodePresenceMessages(_ data: Data) throws -> [ARTPresenceMessage]? {
        let array = try decodeArray(data)
        return presenceMessagesFromArray(array)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 106
    func encodePresenceMessage(_ message: ARTPresenceMessage) throws -> Data? {
        let dictionary = presenceMessageToDictionary(message)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 110
    func encodePresenceMessages(_ messages: [ARTPresenceMessage]) throws -> Data? {
        let array = presenceMessagesToArray(messages)
        return try encode(array)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 114
    func encodeProtocolMessage(_ message: ARTProtocolMessage) throws -> Data? {
        let dictionary = protocolMessageToDictionary(message)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 118
    func decodeProtocolMessage(_ data: Data) throws -> ARTProtocolMessage? {
        let dictionary = try decodeDictionary(data)
        return protocolMessageFromDictionary(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 122
    func decodeTokenDetails(_ data: Data) throws -> ARTTokenDetails? {
        let dictionary = try decodeDictionary(data)
        return try tokenFromDictionary(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 126
    func decodeTokenRequest(_ data: Data) throws -> ARTTokenRequest? {
        let dictionary = try decodeDictionary(data)
        return try tokenRequestFromDictionary(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 130
    func encodeTokenRequest(_ request: ARTTokenRequest) throws -> Data? {
        let dictionary = tokenRequestToDictionary(request)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 134
    func encodeTokenDetails(_ tokenDetails: ARTTokenDetails) throws -> Data? {
        let dictionary = tokenDetailsToDictionary(tokenDetails)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 138
    func encodeDeviceDetails(_ deviceDetails: ARTDeviceDetails) throws -> Data? {
        let dictionary = deviceDetailsToDictionary(deviceDetails)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 142
    func encodeLocalDevice(_ device: ARTLocalDevice) throws -> Data? {
        let dictionary = localDeviceToDictionary(device)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 146
    func decodeDeviceDetails(_ data: Data) throws -> ARTDeviceDetails? {
        let dictionary = try decodeDictionary(data)
        return try deviceDetailsFromDictionary(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 150
    func decodeChannelDetails(_ data: Data) throws -> ARTChannelDetails? {
        let dictionary = try decodeDictionary(data)
        return channelDetailsFromDictionary(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 154
    func decodeDevicesDetails(_ data: Data) throws -> [ARTDeviceDetails]? {
        let array = try decodeArray(data)
        return try devicesDetailsFromArray(array)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 158
    private func devicesDetailsFromArray(_ input: [Any]?) throws -> [ARTDeviceDetails]? {
        guard let input = input else { return nil }
        
        var output: [ARTDeviceDetails] = []
        for item in input {
            guard let itemDict = item as? [String: Any] else { return nil }
            guard let deviceDetails = try deviceDetailsFromDictionary(itemDict) else {
                return nil
            }
            output.append(deviceDetails)
        }
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 170
    func decodeDeviceIdentityTokenDetails(_ data: Data) throws -> ARTDeviceIdentityTokenDetails? {
        let dictionary = try decodeDictionary(data)
        return try deviceIdentityTokenDetailsFromDictionary(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 174
    func encodeDevicePushDetails(_ devicePushDetails: ARTDevicePushDetails) throws -> Data? {
        let dictionary = devicePushDetailsToDictionary(devicePushDetails)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 178
    func decodeDevicePushDetails(_ data: Data) throws -> ARTDevicePushDetails? {
        let decoded = try decode(data)
        return try devicePushDetailsFromDictionary(decoded)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 182
    func encodePushChannelSubscription(_ channelSubscription: ARTPushChannelSubscription) throws -> Data? {
        let dictionary = pushChannelSubscriptionToDictionary(channelSubscription)
        return try encode(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 186
    func decodePushChannelSubscription(_ data: Data) throws -> ARTPushChannelSubscription? {
        let dictionary = try decodeDictionary(data)
        return try pushChannelSubscriptionFromDictionary(dictionary)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 190
    func decodePushChannelSubscriptions(_ data: Data) throws -> [ARTPushChannelSubscription]? {
        let array = try decodeArray(data)
        return try pushChannelSubscriptionsFromArray(array)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 194
    private func pushChannelSubscriptionsFromArray(_ input: [Any]?) throws -> [ARTPushChannelSubscription]? {
        guard let input = input else { return nil }
        
        var output: [ARTPushChannelSubscription] = []
        for item in input {
            guard let itemDict = item as? [String: Any] else { return nil }
            guard let subscription = try pushChannelSubscriptionFromDictionary(itemDict) else {
                return nil
            }
            output.append(subscription)
        }
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 206
    private func pushChannelSubscriptionToDictionary(_ channelSubscription: ARTPushChannelSubscription) -> [String: Any] {
        var output: [String: Any] = [:]
        
//        if let channel = channelSubscription.channel {
        // swift-migration: Lawrence removed this check of statically non-nil
        output["channel"] = channelSubscription.channel
//        }
        
        if let clientId = channelSubscription.clientId {
            output["clientId"] = clientId
        }
        
        if let deviceId = channelSubscription.deviceId {
            output["deviceId"] = deviceId
        }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: pushChannelSubscriptionToDictionary \\(output)")
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 225
    private func pushChannelSubscriptionFromDictionary(_ input: [String: Any]?) throws -> ARTPushChannelSubscription? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: pushChannelSubscriptionFromDictionary \\(input)")
        
        let clientId = input.artString("clientId")
        let deviceId = input.artString("deviceId")
        
        if (clientId != nil && deviceId != nil) || (clientId == nil && deviceId == nil) {
            // ARTLogError(_logger, "ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: clientId and deviceId are both present or both nil")
            throw NSError(domain: ARTAblyErrorDomain,
                         code: Int(ARTErrorCode.incompatibleCredentials.rawValue),
                         userInfo: [NSLocalizedDescriptionKey: "clientId and deviceId are both present or both nil"])
        }
        
        let channelName = unwrapValueWithAmbiguousObjectiveCNullability(input.artString("channel"))

        let channelSubscription: ARTPushChannelSubscription
        if let clientId = clientId {
            channelSubscription = ARTPushChannelSubscription(clientId: clientId, channel: channelName)
        } else {
            channelSubscription = ARTPushChannelSubscription(deviceId: unwrapValueWithAmbiguousObjectiveCNullability(deviceId), channel: channelName)
        }
        
        return channelSubscription
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 258
    func decodeTime(_ data: Data) throws -> Date? {
        guard let resp = try decodeArray(data) as? [Any] else { return nil }
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: decodeTime \\(resp)")
        if resp.count == 1 {
            if let num = resp[0] as? NSNumber {
                return Date(timeIntervalSince1970: millisecondsToTimeInterval(num.uint64Value))
            }
        }
        return nil
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 270
    func decodeStats(_ data: Data) throws -> [ARTStats]? {
        let array = try decodeArray(data)
        return statsFromArray(array)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 33 and ARTJsonLikeEncoder.m, line 274
    func messageFromDictionary(_ input: [String: Any]?, protocolMessage: ARTProtocolMessage?) -> ARTMessage? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: messageFromDictionary \\(input)")
        
        let message = ARTMessage()
        message.id = input.artString("id")
        message.name = input.artString("name")
        message.action = ARTMessageAction(rawValue: (input.artNumber("action") ?? NSNumber(value: ARTMessageAction.create.rawValue)).uintValue) ?? .create
        message.version = input.artString("version") // TM2p
        message.serial = input.artString("serial")
        if message.serial == nil && message.version != nil && message.action == .create { // TM2k
            message.serial = message.version
        }
        message.clientId = input.artString("clientId")
        message.data = input["data"]
        message.encoding = input.artString("encoding")
        message.timestamp = input.artTimestamp("timestamp")
        message.createdAt = input.artTimestamp("createdAt")
        message.updatedAt = input.artTimestamp("updatedAt")
        if message.createdAt == nil && message.action == .create { // TM2o
            message.createdAt = message.timestamp
        }
        message.connectionId = input.artString("connectionId")
        message.extras = input["extras"] as? ARTJsonCompatible

        if let operation = input["operation"] as? [String: Any] {
            message.operation = ARTMessageOperation.createFromDictionary(operation)
        }
        // swift-migration: Lawrence added as?
        message.summary = input["summary"] as? ARTJsonCompatible

        return message
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 34 and ARTJsonLikeEncoder.m, line 310
    func messagesFromArray(_ input: [Any]?, protocolMessage: ARTProtocolMessage?) -> [ARTMessage]? {
        guard let input = input else { return nil }
        
        var output: [ARTMessage] = []
        for item in input {
            guard let itemDict = item as? [String: Any] else { return nil }
            guard let message = messageFromDictionary(itemDict, protocolMessage: protocolMessage) else {
                return nil
            }
            output.append(message)
        }
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 326
    private func presenceActionFromInt(_ action: Int) -> ARTPresenceAction {
        switch action {
        case 0:
            return .absent
        case 1:
            return .present
        case 2:
            return .enter
        case 3:
            return .leave
        case 4:
            return .update
        default:
            // ARTLogError(_logger, "RS:\\(pointer: _rest) ARTJsonEncoder invalid ARTPresenceAction \\(action)")
            return .absent
        }
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 344
    private func annotationActionFromInt(_ action: Int) -> ARTAnnotationAction {
        switch action {
        case 0:
            return .create
        case 1:
            return .delete
        default:
            // ARTLogError(_logger, "RS:\\(pointer: _rest) ARTJsonEncoder invalid ARTAnnotationAction \\(action)")
            return .create
        }
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 356
    private func intFromPresenceMessageAction(_ action: ARTPresenceAction) -> Int {
        switch action {
        case .absent:
            return 0
        case .present:
            return 1
        case .enter:
            return 2
        case .leave:
            return 3
        case .update:
            return 4
        }
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 36 and ARTJsonLikeEncoder.m, line 372
    private func presenceMessageFromDictionary(_ input: [String: Any]?) -> ARTPresenceMessage? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: presenceMessageFromDictionary \\(input)")
        
        let message = ARTPresenceMessage()
        message.id = input.artString("id")
        message.data = input["data"]
        message.encoding = input.artString("encoding")
        message.clientId = input.artString("clientId")
        message.timestamp = input.artTimestamp("timestamp")
        
        let action = (input.artNumber("action") ?? NSNumber(value: 0)).intValue
        message.action = presenceActionFromInt(action)
        
        message.connectionId = input.artString("connectionId")
        
        return message
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 37 and ARTJsonLikeEncoder.m, line 393
    private func presenceMessagesFromArray(_ input: [Any]?) -> [ARTPresenceMessage]? {
        guard let input = input else { return nil }
        
        var output: [ARTPresenceMessage] = []
        for item in input {
            guard let itemDict = item as? [String: Any] else { return nil }
            guard let message = presenceMessageFromDictionary(itemDict) else {
                return nil
            }
            output.append(message)
        }
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 409
    private func annotationFromDictionary(_ input: [String: Any]?) -> ARTAnnotation? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: annotationFromDictionary \\(input)")
        
        let action = (input.artNumber("action") ?? NSNumber(value: 0)).intValue

        let annotation = ARTAnnotation(
            id: input.artString("id"),
            action: annotationActionFromInt(action),
            clientId: input.artString("clientId"),
            name: input.artString("name"),
            count: input.artNumber("count"),
            data: input["data"],
            encoding: input.artString("encoding"),
            timestamp: unwrapValueWithAmbiguousObjectiveCNullability(input.artTimestamp("timestamp")),
            serial: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("serial")),
            messageSerial: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("messageSerial")),
            type: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("type")),
            extras: input["extras"] as? ARTJsonCompatible
        )
        return annotation
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 430
    private func annotationsFromArray(_ input: [Any]?) -> [ARTAnnotation]? {
        guard let input = input else { return nil }
        
        var output: [ARTAnnotation] = []
        for item in input {
            guard let itemDict = item as? [String: Any] else { return nil }
            guard let annotation = annotationFromDictionary(itemDict) else {
                return nil
            }
            output.append(annotation)
        }
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 39 and ARTJsonLikeEncoder.m, line 446
    private func messageToDictionary(_ message: ARTMessage) -> [String: Any] {
        var output: [String: Any] = [:]
        
        if let id = message.id {
            output["id"] = id
        }
        
        if let timestamp = message.timestamp {
            output["timestamp"] = timestamp.artToNumberMs()
        }
        
        if let clientId = message.clientId {
            output["clientId"] = clientId
        }
        
        if let data = message.data {
            writeData(data, encoding: message.encoding, toDictionary: &output)
        }
        
        if let name = message.name {
            output["name"] = name
        }
        
        if let extras = message.extras {
            output["extras"] = extras
        }
        
        if let connectionId = message.connectionId {
            output["connectionId"] = connectionId
        }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: messageToDictionary \\(output)")
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 50 and ARTJsonLikeEncoder.m, line 480
    private func authDetailsToDictionary(_ authDetails: ARTAuthDetails) -> [String: Any] {
        var output: [String: Any] = [:]
        
        output["accessToken"] = authDetails.accessToken
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: authDetailsToDictionary \\(output)")
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 51 and ARTJsonLikeEncoder.m, line 489
    private func authDetailsFromDictionary(_ input: [String: Any]?) -> ARTAuthDetails? {
        guard let input = input else { return nil }
        return ARTAuthDetails(token: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("accessToken")))
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 40 and ARTJsonLikeEncoder.m, line 496
    private func messagesToArray(_ messages: [ARTMessage]) -> [Any] {
        var output: [Any] = []
        
        for message in messages {
            let item = messageToDictionary(message)
            output.append(item)
        }
        
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 42 and ARTJsonLikeEncoder.m, line 507
    private func presenceMessageToDictionary(_ message: ARTPresenceMessage) -> [String: Any] {
        var output: [String: Any] = [:]
        
        if let timestamp = message.timestamp {
            output["timestamp"] = timestamp.artToNumberMs()
        }
        
        if let clientId = message.clientId {
            output["clientId"] = clientId
        }
        
        if let data = message.data {
            writeData(data, encoding: message.encoding, toDictionary: &output)
        }
        
        if let connectionId = message.connectionId {
            output["connectionId"] = connectionId
        }
        
        let action = intFromPresenceMessageAction(message.action)
        output["action"] = NSNumber(value: action)
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: presenceMessageToDictionary \\(output)")
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 43 and ARTJsonLikeEncoder.m, line 532
    private func presenceMessagesToArray(_ messages: [ARTPresenceMessage]) -> [Any] {
        var output: [Any] = []
        
        for message in messages {
            let item = presenceMessageToDictionary(message)
            output.append(item)
        }
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 45 and ARTJsonLikeEncoder.m, line 542
    private func protocolMessageToDictionary(_ message: ARTProtocolMessage) -> [String: Any] {
        var output: [String: Any] = [:]
        output["action"] = NSNumber(value: message.action.rawValue)
        
        if let channel = message.channel {
            output["channel"] = channel
        }
        
        if let channelSerial = message.channelSerial {
            output["channelSerial"] = channelSerial
        }
        
        if let msgSerial = message.msgSerial {
            output["msgSerial"] = msgSerial
        }
        
        if let messages = message.messages {
            output["messages"] = messagesToArray(messages)
        }
        
        if let presence = message.presence {
            output["presence"] = presenceMessagesToArray(presence)
        }
        
        if let auth = message.auth {
            output["auth"] = authDetailsToDictionary(auth)
        }
        
        if message.flags != 0 {
            output["flags"] = NSNumber(value: message.flags)
        }
        
        if let params = message.params {
            output["params"] = params
        }
        
        if let state = message.state {
            output["state"] = objectMessagesToArray(state)
        }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: protocolMessageToDictionary \\(output)")
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 586
    private func tokenFromDictionary(_ input: [String: Any]?) throws -> ARTTokenDetails? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: tokenFromDictionary \\(input)")
        
        if let jsonError = input.artDictionary("error") {
            // ARTLogError(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: tokenFromDictionary error \\(jsonError)")
            var details: [String: Any] = [:]
            if let message = jsonError.artString("message") {
                details[NSLocalizedDescriptionKey] = message
            }
            throw NSError(domain: ARTAblyErrorDomain,
                         code: (jsonError.artNumber("code") ?? NSNumber(value: 0)).intValue,
                         userInfo: details)
        }
        
        let token = input.artString("token")
        let expiresTimeInterval = input["expires"] as? NSNumber
        let expires = expiresTimeInterval != nil ? Date(timeIntervalSince1970: millisecondsToTimeInterval(expiresTimeInterval!.uint64Value)) : nil
        let issuedInterval = input["issued"] as? NSNumber
        let issued = issuedInterval != nil ? Date(timeIntervalSince1970: millisecondsToTimeInterval(issuedInterval!.uint64Value)) : nil

        return ARTTokenDetails(token: unwrapValueWithAmbiguousObjectiveCNullability(token),
                              expires: expires,
                              issued: issued,
                              capability: input.artString("capability"),
                              clientId: input.artString("clientId"))
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 48 and ARTJsonLikeEncoder.m, line 621
    private func tokenRequestToDictionary(_ tokenRequest: ARTTokenRequest) -> [String: Any] {
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: tokenRequestToDictionary \\(tokenRequest)")
        
        let timestamp: NSNumber
        if let requestTimestamp = tokenRequest.timestamp {
            timestamp = NSNumber(value: dateToMilliseconds(requestTimestamp))
        } else {
            timestamp = NSNumber(value: dateToMilliseconds(Date()))
        }
        
        var dictionary: [String: Any] = [
            "keyName": tokenRequest.keyName ?? "",
            "timestamp": timestamp,
            "nonce": tokenRequest.nonce ?? "",
            "mac": tokenRequest.mac ?? ""
        ]
        
        if let capability = tokenRequest.capability {
            dictionary["capability"] = capability
        }
        if let clientId = tokenRequest.clientId {
            dictionary["clientId"] = clientId
        }
        if let ttl = tokenRequest.ttl {
            dictionary["ttl"] = NSNumber(value: timeIntervalToMilliseconds(ttl.doubleValue))
        }
        
        return dictionary
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 650
    private func tokenRequestFromDictionary(_ input: [String: Any]?) throws -> ARTTokenRequest? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: tokenRequestFromDictionary \\(input)")
        
        if let jsonError = input.artDictionary("error") {
            // ARTLogError(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: tokenRequestFromDictionary error \\(jsonError)")
            var details: [String: Any] = [:]
            if let message = jsonError.artString("message") {
                details[NSLocalizedDescriptionKey] = message
            }
            throw NSError(domain: ARTAblyErrorDomain,
                         code: (jsonError.artNumber("code") ?? NSNumber(value: 0)).intValue,
                         userInfo: details)
        }
        
        let params = ARTTokenParams(clientId: input.artString("clientId"), nonce: input.artString("nonce"))
        let millisecondsTtl = input.artInteger("ttl")
        if millisecondsTtl != 0 {
            params.ttl = NSNumber(value: millisecondsToTimeInterval(UInt64(millisecondsTtl)))
        }
        params.capability = input.artString("capability")
        params.timestamp = input.artTimestamp("timestamp")
        
        return ARTTokenRequest(tokenParams: params,
                              keyName: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("keyName")),
                              nonce: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("nonce")),
                              mac: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("mac")))
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 686
    private func tokenDetailsToDictionary(_ tokenDetails: ARTTokenDetails) -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        dictionary["token"] = tokenDetails.token
        
        if let issued = tokenDetails.issued {
            dictionary["issued"] = String(format: "%llu", dateToMilliseconds(issued))
        }
        
        if let expires = tokenDetails.expires {
            dictionary["expires"] = String(format: "%llu", dateToMilliseconds(expires))
        }
        
        if let capability = tokenDetails.capability {
            dictionary["capability"] = capability
        }
        
        if let clientId = tokenDetails.clientId {
            dictionary["clientId"] = clientId
        }
        
        return dictionary
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 710
    private func deviceDetailsToDictionary(_ deviceDetails: ARTDeviceDetails) -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        dictionary["id"] = deviceDetails.id
        dictionary["platform"] = deviceDetails.platform
        dictionary["formFactor"] = deviceDetails.formFactor
        
        if let clientId = deviceDetails.clientId {
            dictionary["clientId"] = clientId
        }
        
        dictionary["push"] = devicePushDetailsToDictionary(deviceDetails.push)
        
        return dictionary
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 726
    private func localDeviceToDictionary(_ device: ARTLocalDevice) -> [String: Any] {
        var dictionary = deviceDetailsToDictionary(device)
        dictionary["deviceSecret"] = device.secret
        return dictionary
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 732
    private func deviceDetailsFromDictionary(_ input: [String: Any]?) throws -> ARTDeviceDetails? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: deviceDetailsFromDictionary \\(input)")
        
        let deviceDetails = ARTDeviceDetails(id: input.artString("id"))
        deviceDetails.clientId = input.artString("clientId")
        // swift-migration: Lawrence added these force-unwraps
        deviceDetails.platform = input.artString("platform")!
        deviceDetails.formFactor = input.artString("formFactor")!
        // swift-migration: Lawrence added `as?`
        deviceDetails.metadata = input["metadata"] as? [String: String]
        deviceDetails.push = try devicePushDetailsFromDictionary(input["push"])!

        return deviceDetails
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 749
    private func deviceIdentityTokenDetailsFromDictionary(_ input: [String: Any]?) throws -> ARTDeviceIdentityTokenDetails? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: deviceIdentityTokenDetailsFromDictionary \\(input)")
        
        let deviceIdentityTokenInput = input["deviceIdentityToken"] as? [String: Any]
        let token = unwrapValueWithAmbiguousObjectiveCNullability(deviceIdentityTokenInput?.artString("token"))
        let issuedMsecs = deviceIdentityTokenInput?.artNumber("issued")
        let issued = unwrapValueWithAmbiguousObjectiveCNullability(issuedMsecs != nil ? Date.art_date(withMillisecondsSince1970: issuedMsecs!.uint64Value) : nil)
        let expiresMsecs = deviceIdentityTokenInput?.artNumber("expires")
        let expires = unwrapValueWithAmbiguousObjectiveCNullability(expiresMsecs != nil ? Date.art_date(withMillisecondsSince1970: expiresMsecs!.uint64Value) : nil)
        let capability = unwrapValueWithAmbiguousObjectiveCNullability(deviceIdentityTokenInput?.artString("capability"))
        let clientId = unwrapValueWithAmbiguousObjectiveCNullability(deviceIdentityTokenInput?.artString("clientId"))

        let deviceIdentityTokenDetails = ARTDeviceIdentityTokenDetails(token: token, issued: issued, expires: expires, capability: capability, clientId: clientId)
        
        return deviceIdentityTokenDetails
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 770
    private func devicePushDetailsToDictionary(_ devicePushDetails: ARTDevicePushDetails) -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        dictionary["recipient"] = devicePushDetails.recipient
        
        return dictionary
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 778
    private func devicePushDetailsFromDictionary(_ input: Any?) throws -> ARTDevicePushDetails? {
        guard let input = input as? [String: Any] else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: devicePushDetailsFromDictionary \\(input)")
        
        let devicePushDetails = ARTDevicePushDetails()
        devicePushDetails.state = input.artString("state")
        if let errorReason = input["errorReason"] as? [String: Any] {
            devicePushDetails.errorReason = ARTErrorInfo.create(
                withCode: (errorReason.artNumber("code") ?? NSNumber(value: 0)).intValue,
                status: (errorReason.artNumber("statusCode") ?? NSNumber(value: 0)).intValue,
                // swift-migration: Lawrence added ?? ""
                message: errorReason.artString("message") ?? ""
            )
        }
        // swift-migration: Lawrence added as? and mutableCopy
        devicePushDetails.recipient = unwrapValueWithAmbiguousObjectiveCNullability(input["recipient"] as? NSDictionary).mutableCopy() as! NSMutableDictionary

        return devicePushDetails
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 46 and ARTJsonLikeEncoder.m, line 796
    private func protocolMessageFromDictionary(_ input: [String: Any]?) -> ARTProtocolMessage? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: protocolMessageFromDictionary \\(input)")
        
        let message = ARTProtocolMessage()
        message.action = ARTProtocolMessageAction(rawValue: (input.artNumber("action") ?? NSNumber(value: 0)).uintValue) ?? .heartbeat
        message.count = (input.artNumber("count") ?? NSNumber(value: 0)).int32Value
        message.channel = input.artString("channel")
        message.channelSerial = input.artString("channelSerial")
        message.connectionId = input.artString("connectionId")
        message.id = input.artString("id")
        message.msgSerial = input.artNumber("msgSerial")
        message.timestamp = input.artTimestamp("timestamp")
        message.connectionKey = input.artString("connectionKey")
        message.flags = (input.artNumber("flags") ?? NSNumber(value: 0)).uintValue
        message.connectionDetails = connectionDetailsFromDictionary(input["connectionDetails"] as? [String: Any])
        message.auth = authDetailsFromDictionary(input["auth"] as? [String: Any])
        // swift-migration: Lawrence added `as?`
        message.params = input["params"] as? [String: String]

        if let error = input["error"] as? [String: Any] {
            message.error = ARTErrorInfo.create(
                withCode: (error.artNumber("code") ?? NSNumber(value: 0)).intValue,
                status: (error.artNumber("statusCode") ?? NSNumber(value: 0)).intValue,
                // swift-migration: Lawrence added ?? ""
                message: error.artString("message") ?? ""
            )
        }
        
        if let messagesArray = (input["messages"] as? [Any])?.compactMap({ $0 as? [String: Any] }) {
            message.messages = messagesFromArray(messagesArray, protocolMessage: message)
        }
        message.presence = presenceMessagesFromArray(input["presence"] as? [Any])
        message.annotations = annotationsFromArray(input["annotations"] as? [Any])
        message.state = objectMessagesFromArray(input["state"] as? [Any], protocolMessage: message)
        
        return message
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 831
    private func connectionDetailsFromDictionary(_ input: [String: Any]?) -> ARTConnectionDetails? {
        guard let input = input else { return nil }
        
        return ARTConnectionDetails(
            clientId: input.artString("clientId"),
            connectionKey: input.artString("connectionKey"),
            maxMessageSize: input.artInteger("maxMessageSize"),
            maxFrameSize: input.artInteger("maxFrameSize"),
            maxInboundRate: input.artInteger("maxInboundRate"),
            connectionStateTtl: millisecondsToTimeInterval(UInt64(input.artInteger("connectionStateTtl"))),
            serverId: input.artString("serverId"),
            maxIdleInterval: millisecondsToTimeInterval(UInt64(input.artInteger("maxIdleInterval")))
        )
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 845
    private func channelMetricsFromDictionary(_ input: [String: Any]?) -> ARTChannelMetrics? {
        guard let input = input else { return nil }
        return ARTChannelMetrics(
            connections: input.artInteger("connections"),
            publishers: input.artInteger("publishers"),
            subscribers: input.artInteger("subscribers"),
            presenceConnections: input.artInteger("presenceConnections"),
            presenceMembers: input.artInteger("presenceMembers"),
            presenceSubscribers: input.artInteger("presenceSubscribers"),
            objectPublishers: input.artInteger("objectPublishers"),
            objectSubscribers: input.artInteger("objectSubscribers")
        )
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 856
    private func channelOccupancyFromDictionary(_ input: [String: Any]?) -> ARTChannelOccupancy? {
        guard let input = input else { return nil }
        let metricsDict = input["metrics"] as? [String: Any]
        let metrics = unwrapValueWithAmbiguousObjectiveCNullability(channelMetricsFromDictionary(metricsDict))
        let occupancy = ARTChannelOccupancy(metrics: metrics)
        return occupancy
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 863
    private func channelStatusFromDictionary(_ input: [String: Any]?) -> ARTChannelStatus? {
        guard let input = input else { return nil }
        let occupancyDict = input["occupancy"] as? [String: Any]
        let occupancy = unwrapValueWithAmbiguousObjectiveCNullability(channelOccupancyFromDictionary(occupancyDict))
        let status = ARTChannelStatus(occupancy: occupancy, active: input.artBoolean("isActive"))
        return status
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 870
    private func channelDetailsFromDictionary(_ input: [String: Any]?) -> ARTChannelDetails? {
        guard let input = input else { return nil }
        let statusDict = input["status"] as? [String: Any]
        let status = unwrapValueWithAmbiguousObjectiveCNullability(channelStatusFromDictionary(statusDict))
        let details = ARTChannelDetails(channelId: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("channelId")), status: status)
        return details
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 53 and ARTJsonLikeEncoder.m, line 877
    private func statsFromArray(_ input: [Any]?) -> [ARTStats]? {
        guard let input = input else { return nil }
        
        var output: [ARTStats] = []
        
        for item in input {
            guard let itemDict = item as? [String: Any] else { return nil }
            guard let statsItem = statsFromDictionary(itemDict) else {
                return nil
            }
            output.append(statsItem)
        }
        
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 54 and ARTJsonLikeEncoder.m, line 898
    private func statsFromDictionary(_ input: [String: Any]?) -> ARTStats? {
        guard let input = input else { return nil }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: statsFromDictionary \\(input)")
        
        return ARTStats(
            all: statsMessageTypesFromDictionary(input["all"] as? [String: Any]),
            inbound: statsMessageTrafficFromDictionary(input["inbound"] as? [String: Any]),
            outbound: statsMessageTrafficFromDictionary(input["outbound"] as? [String: Any]),
            persisted: statsMessageTypesFromDictionary(input["persisted"] as? [String: Any]),
            connections: statsConnectionTypesFromDictionary(input["connections"] as? [String: Any]),
            channels: statsResourceCountFromDictionary(input["channels"] as? [String: Any]),
            apiRequests: statsRequestCountFromDictionary(input["apiRequests"] as? [String: Any]),
            tokenRequests: statsRequestCountFromDictionary(input["tokenRequests"] as? [String: Any]),
            pushes: statsPushCountFromDictionary(input["push"] as? [String: Any]),
            inProgress: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("inProgress")),
            count: (input.artNumber("count") ?? NSNumber(value: 0)).uintValue,
            intervalId: unwrapValueWithAmbiguousObjectiveCNullability(input.artString("intervalId"))
        )
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 55 and ARTJsonLikeEncoder.m, line 918
    private func statsMessageTypesFromDictionary(_ input: [String: Any]?) -> ARTStatsMessageTypes {
        guard let input = input else { return ARTStatsMessageTypes.empty }

        let all = statsMessageCountFromDictionary(input["all"] as? [String: Any])
        let messages = statsMessageCountFromDictionary(input["messages"] as? [String: Any])
        let presence = statsMessageCountFromDictionary(input["presence"] as? [String: Any])
        
        if all != nil || messages != nil || presence != nil {
            return ARTStatsMessageTypes(all: all, messages: messages, presence: presence)
        }
        
        return ARTStatsMessageTypes.empty
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 56 and ARTJsonLikeEncoder.m, line 934
    private func statsMessageCountFromDictionary(_ input: [String: Any]?) -> ARTStatsMessageCount {
        guard let input = input else { return ARTStatsMessageCount.empty }

        let count = input.artTyped(NSNumber.self, key: "count")
        let data = input.artTyped(NSNumber.self, key: "data")
        
        return ARTStatsMessageCount(count: count?.uintValue ?? 0, data: data?.uintValue ?? 0)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 57 and ARTJsonLikeEncoder.m, line 945
    private func statsMessageTrafficFromDictionary(_ input: [String: Any]?) -> ARTStatsMessageTraffic {
        guard let input = input else { return ARTStatsMessageTraffic.empty }

        let all = statsMessageTypesFromDictionary(input["all"] as? [String: Any])
        let realtime = statsMessageTypesFromDictionary(input["realtime"] as? [String: Any])
        let rest = statsMessageTypesFromDictionary(input["rest"] as? [String: Any])
        let webhook = statsMessageTypesFromDictionary(input["webhook"] as? [String: Any])

        // swift-migration: Lawrence removed this check that Claude mis-migrated
        /*
        if all.isEmpty && realtime.isEmpty && rest.isEmpty && webhook.isEmpty {
            return ARTStatsMessageTraffic.empty
        }
         */

        return ARTStatsMessageTraffic(all: all, realtime: realtime, rest: rest, webhook: webhook)
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 58 and ARTJsonLikeEncoder.m, line 965
    private func statsConnectionTypesFromDictionary(_ input: [String: Any]?) -> ARTStatsConnectionTypes {
        guard let input = input else { return ARTStatsConnectionTypes.empty }

        let all = statsResourceCountFromDictionary(input["all"] as? [String: Any])
        let plain = statsResourceCountFromDictionary(input["plain"] as? [String: Any])
        let tls = statsResourceCountFromDictionary(input["tls"] as? [String: Any])
        
        if all != nil || plain != nil || tls != nil {
            return ARTStatsConnectionTypes(all: all, plain: plain, tls: tls)
        }
        
        return ARTStatsConnectionTypes.empty
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 59 and ARTJsonLikeEncoder.m, line 981
    private func statsResourceCountFromDictionary(_ input: [String: Any]?) -> ARTStatsResourceCount {
        guard let input = input else { return ARTStatsResourceCount.empty }
        
        let opened = input.artTyped(NSNumber.self, key: "opened")
        let peak = input.artTyped(NSNumber.self, key: "peak")
        let mean = input.artTyped(NSNumber.self, key: "mean")
        let min = input.artTyped(NSNumber.self, key: "min")
        let refused = input.artTyped(NSNumber.self, key: "refused")
        
        return ARTStatsResourceCount(
            opened: opened?.uintValue ?? 0,
            peak: peak?.uintValue ?? 0,
            mean: mean?.uintValue ?? 0,
            min: min?.uintValue ?? 0,
            refused: refused?.uintValue ?? 0
        )
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 999
    func decodeErrorInfo(_ artError: Data) throws -> ARTErrorInfo? {
        let decodedError = try decodeDictionary(artError)
        guard let error = decodedError?["error"] as? [String: Any] else { return nil }
        return ARTErrorInfo.create(
            withCode: (error["code"] as? Int) ?? 0,
            status: (error["statusCode"] as? Int) ?? 0,
            // swift-migration: Lawrence added ?? ""
            message: error["message"] as? String ?? ""
        )
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 60 and ARTJsonLikeEncoder.m, line 1007
    private func statsRequestCountFromDictionary(_ input: [String: Any]?) -> ARTStatsRequestCount {
        guard let input = input else { return ARTStatsRequestCount.empty }

        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: statsRequestCountFromDictionary \\(input)")
        
        let succeeded = input.artTyped(NSNumber.self, key: "succeeded")
        let failed = input.artTyped(NSNumber.self, key: "failed")
        let refused = input.artTyped(NSNumber.self, key: "refused")
        
        return ARTStatsRequestCount(
            succeeded: succeeded?.uintValue ?? 0,
            failed: failed?.uintValue ?? 0,
            refused: refused?.uintValue ?? 0
        )
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 1022
    private func statsPushCountFromDictionary(_ input: [String: Any]?) -> ARTStatsPushCount {
        guard let input = input else { return ARTStatsPushCount.empty }
        
        // ARTLogVerbose(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: statsPushCountFromDictionary \\(input)")
        
        let messages = input.artNumber("messages")
        let direct = input.artNumber("directPublishes")
        
        let notifications = input["notifications"] as? [String: Any]
        let succeeded = notifications?.artNumber("successful")
        let invalid = notifications?.artNumber("invalid")
        let attempted = notifications?.artNumber("attempted")
        let failed = notifications?.artNumber("failed")
        
        return ARTStatsPushCount(
            succeeded: succeeded?.uintValue ?? 0,
            invalid: invalid?.uintValue ?? 0,
            attempted: attempted?.uintValue ?? 0,
            failed: failed?.uintValue ?? 0,
            messages: messages?.uintValue ?? 0,
            direct: direct?.uintValue ?? 0
        )
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 62 and ARTJsonLikeEncoder.m, line 1045
    private func writeData(_ data: Any, encoding: String?, toDictionary output: inout [String: Any]) {
        if let encoding = encoding, !encoding.isEmpty {
            output["encoding"] = encoding
        }
        output["data"] = data
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 64 and ARTJsonLikeEncoder.m, line 1052
    private func decodeDictionary(_ data: Data) throws -> [String: Any]? {
        let obj = try decode(data)
        return obj as? [String: Any]
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.h, line 65 and ARTJsonLikeEncoder.m, line 1060
    private func decodeArray(_ data: Data) throws -> [Any]? {
        let obj = try decode(data)
        return obj as? [Any]
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 1068
    func decodeToArray(_ data: Data) throws -> [[String: Any]]? {
        let obj = try decode(data)
        if let dict = obj as? [String: Any] {
            return [dict]
        }
        return obj as? [[String: Any]]
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 1079
    func decode(_ data: Data) throws -> Any? {
        do {
            let decoded = try delegate?.decode(data)
            // ARTLogDebug(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")> decoding '\\(data)'; got: \\(decoded as Any)")
            return decoded
        } catch {
            // ARTLogError(_logger, "failed decoding data \\(data) with, \\(error.localizedDescription) (\\((error as NSError).localizedFailureReason ?? ""))")
            throw error
        }
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 1092
    func encode(_ obj: Any) throws -> Data? {
        do {
            let encoded = try delegate?.encode(obj)
            // ARTLogDebug(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")> encoding '\\(obj)'; got: \\(encoded as Any)")
            return encoded
        } catch {
            // ARTLogError(_logger, "failed encoding object \\(obj) with, \\(error.localizedDescription) (\\((error as NSError).localizedFailureReason ?? ""))")
            throw error
        }
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 1105
    /// Converts an `ARTEncoderFormat` to an `APEncodingFormat`.
    private func apEncodingFormatFromARTEncoderFormat(_ format: ARTEncoderFormat) -> _AblyPluginSupportPrivate.EncodingFormat {
        switch format {
        case .json:
            return .json
        case .msgPack:
            return .messagePack
        }
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 1115
    /// Uses the LiveObjects plugin to decode an array of `ObjectMessage`s.
    ///
    /// Returns `nil` if the LiveObjects plugin has not been supplied, or if we fail to decode any of the `ObjectMessage`s.
    private func objectMessagesFromArray(_ input: [Any]?, protocolMessage: ARTProtocolMessage?) -> [_AblyPluginSupportPrivate.ObjectMessageProtocol]? {
        guard let input = input else { return nil }
        
        guard let liveObjectsPlugin = _rest?.options.liveObjectsPlugin else {
            return nil
        }
        
        var output: [_AblyPluginSupportPrivate.ObjectMessageProtocol] = []

        for (i, item) in input.enumerated() {
            guard let itemDict = item as? [String: Any] else { return nil }
            
            let decodingContext = ARTPluginDecodingContext(
                parentID: protocolMessage?.id,
                parentConnectionID: protocolMessage?.connectionId,
                parentTimestamp: protocolMessage?.timestamp,
                indexInParent: i
            )
            
            let format = apEncodingFormatFromARTEncoderFormat(self.format())

            do {
                let objectMessage = try liveObjectsPlugin.decodeObjectMessage(itemDict, context: decodingContext, format: format)
                output.append(objectMessage)
            } catch {
//                ARTLogWarn(_logger, "RS:\\(pointer: _rest) ARTJsonLikeEncoder<\\(delegate?.formatAsString() ?? "")>: LiveObjects plugin failed to decode ObjectMessage \\(itemDict), error \\(error as Any)")
                return nil
            }
        }
        
        return output
    }
    
    // swift-migration: original location ARTJsonLikeEncoder.m, line 1165
    /// Uses the LiveObjects plugin to encode an array of `ObjectMessage`s.
    ///
    /// Returns `nil` if the input is `nil`.
    private func objectMessagesToArray(_ objectMessages: [_AblyPluginSupportPrivate.ObjectMessageProtocol]?) -> [[String: Any]]? {
        guard let objectMessages = objectMessages else { return nil }
        
        guard let liveObjectsPlugin = _rest?.options.liveObjectsPlugin else {
            // The only thing that sends ObjectMessage is the LiveObjects plugin, so if we have some to encode then the plugin must be present
            fatalError("Attempted to encode ObjectMessages without a LiveObjects plugin; this should not be possible.")
        }
        
        var result: [[String: Any]] = []
        let format = apEncodingFormatFromARTEncoderFormat(self.format())
        
        for objectMessage in objectMessages {
            result.append(liveObjectsPlugin.encodeObjectMessage(objectMessage, format: format))
        }
        
        return result
    }
}
