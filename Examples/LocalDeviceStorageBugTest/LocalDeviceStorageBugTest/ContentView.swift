//
//  ContentView.swift
//  LocalDeviceStorageBugTest
//
//  Created by Lawrence Forooghian on 15/04/2026.
//

import SwiftUI
import Ably
import PushKit
import CallKit

private let eventsChannelName = "LocalDeviceStorageBugTest-events"

/// Custom log handler that publishes log messages to the events channel via `eventLoggingAbly`.
nonisolated class EventLoggingLogHandler: ARTLog {
    private let eventsChannel: ARTRealtimeChannel

    init(eventsChannel: ARTRealtimeChannel) {
        self.eventsChannel = eventsChannel
        super.init()
    }

    override func log(_ message: String, with level: ARTLogLevel) {
        let levelString: String
        switch level {
        case .verbose: levelString = "verbose"
        case .debug: levelString = "debug"
        case .info: levelString = "info"
        case .warn: levelString = "warn"
        case .error: levelString = "error"
        case .none: levelString = "none"
        @unknown default: levelString = "unknown"
        }

        eventsChannel.publish("log", data: [
            "level": levelString,
            "message": message,
        ])
    }
}

/// Handles PushKit VoIP token registration and CallKit integration.
class PushHandler: NSObject, PKPushRegistryDelegate, CXProviderDelegate {
    private let eventsChannel: ARTRealtimeChannel
    private let pushRegistry: PKPushRegistry
    private let callProvider: CXProvider

    init(eventsChannel: ARTRealtimeChannel) {
        self.eventsChannel = eventsChannel

        let providerConfig = CXProviderConfiguration()
        providerConfig.supportsVideo = false
        self.callProvider = CXProvider(configuration: providerConfig)

        self.pushRegistry = PKPushRegistry(queue: nil)

        super.init()

        self.callProvider.setDelegate(self, queue: nil)
        self.pushRegistry.delegate = self
        self.pushRegistry.desiredPushTypes = [.voIP]
    }

    // MARK: - PKPushRegistryDelegate

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        eventsChannel.publish("voipToken", data: [
            "token": token,
        ])
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        eventsChannel.publish("voipPush", data: [
            "payload": payload.dictionaryPayload,
        ])

        // Must report a call to CallKit when receiving a VoIP push, or iOS will terminate the app.
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "LocalDeviceStorageBugTest")
        update.hasVideo = false

        callProvider.reportNewIncomingCall(with: UUID(), update: update) { error in
            if let error {
                print("Failed to report incoming call: \(error)")
            }
            completion()
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        eventsChannel.publish("voipTokenInvalidated", data: nil)
    }

    // MARK: - CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {}

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
    }
}

struct ContentView: View {
    @State private var eventLoggingAbly: ARTRealtime?
    @State private var mainAbly: ARTRealtime?
    @State private var pushHandler: PushHandler?

    var body: some View {
        VStack {
            Text("LocalDeviceStorageBugTest")
        }
        .padding()
        .task {
            setUp()
        }
    }

    private func setUp() {
        // Set up event logging Ably instance (Realtime, to preserve message ordering)
        let eventLoggingOptions = ARTClientOptions(key: Secrets.ablyAPIKey)
        let eventLogging = ARTRealtime(options: eventLoggingOptions)
        let eventsChannel = eventLogging.channels.get(eventsChannelName)
        self.eventLoggingAbly = eventLogging

        // Set up PushKit VoIP registration and CallKit handler
        self.pushHandler = PushHandler(eventsChannel: eventsChannel)

        // Set up main Ably instance with custom log handler that publishes to the events channel
        let mainOptions = ARTClientOptions(key: Secrets.ablyAPIKey)
        mainOptions.logHandler = EventLoggingLogHandler(eventsChannel: eventsChannel)
        mainOptions.logLevel = .verbose
        let main = ARTRealtime(options: mainOptions)
        self.mainAbly = main
    }
}
