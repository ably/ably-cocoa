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
private let pushChannelName = "push-test"

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

        eventsChannel.publish(.ablyLog(.init(level: levelString, message: message)))
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
        eventsChannel.publish(.voipTokenUpdated(.init(token: token)))
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let payloadJSON = String(
            data: try! JSONSerialization.data(withJSONObject: payload.dictionaryPayload),
            encoding: .utf8
        )!
        eventsChannel.publish(.voipPushReceived(.init(payloadJSON: payloadJSON)))

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
        eventsChannel.publish(.voipTokenInvalidated)
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

/// Receives push activation/deactivation results from the SDK.
class PushActivationHandler: NSObject, ARTPushRegistererDelegate {
    var onActivate: (@MainActor (ARTErrorInfo?) -> Void)?

    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        MainActor.assumeIsolated {
            onActivate?(error)
        }
    }

    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {}
}

struct ContentView: View {
    @State private var eventLoggingAbly: ARTRealtime?
    @State private var eventsChannel: ARTRealtimeChannel?
    @State private var mainAbly: ARTRealtime?
    @State private var pushHandler: PushHandler?
    @State private var pushActivationHandler: PushActivationHandler?

    @State private var settings = AppSettingsStore.shared.load()
    @State private var activateResult: Result<Void, ARTErrorInfo>?
    @State private var subscribeResult: Result<Void, ARTErrorInfo>?

    var body: some View {
        VStack(spacing: 16) {
            Text("LocalDeviceStorageBugTest")
                .font(.headline)

            Divider()

            Button("Activate Push") {
                activatePush(reason: .userTappedButton)
            }
            .disabled(mainAbly == nil)

            resultView(activateResult, successText: "Activated")

            Divider()

            Button("Subscribe to Push Channel") {
                subscribeToPushChannel(reason: .userTappedButton)
            }
            .disabled(mainAbly == nil)

            resultView(subscribeResult, successText: "Subscribed to \(pushChannelName)")

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.headline)

                Toggle("Auto-activate push on launch", isOn: $settings.autoActivatePush)
                    .onChange(of: settings.autoActivatePush) { saveSettings() }

                Toggle("Auto-subscribe to push channel on launch", isOn: $settings.autoSubscribeToPushChannel)
                    .onChange(of: settings.autoSubscribeToPushChannel) { saveSettings() }
            }
        }
        .padding()
        .task {
            setUp()
        }
    }

    private func activatePush(reason: ActionReason, then completion: (() -> Void)? = nil) {
        let attemptID = UUID().uuidString
        eventsChannel?.publish(.pushActivateAttempt(.init(
            id: attemptID,
            reason: reason
        )))

        pushActivationHandler?.onActivate = { error in
            eventsChannel?.publish(.pushActivateResult(.init(
                attemptID: attemptID,
                error: error.map { CodableErrorInfo($0) },
                localDevice: CodableLocalDevice(mainAbly!.device)
            )))
            if let error {
                activateResult = .failure(error)
            } else {
                activateResult = .success(())
                completion?()
            }
        }

        mainAbly?.push.activate()
    }

    private func subscribeToPushChannel(reason: ActionReason) {
        let attemptID = UUID().uuidString
        eventsChannel?.publish(.pushSubscribeAttempt(.init(
            id: attemptID,
            reason: reason,
            channelName: pushChannelName
        )))

        mainAbly?.channels.get(pushChannelName).push.subscribeDevice { error in
            eventsChannel?.publish(.pushSubscribeResult(.init(
                attemptID: attemptID,
                channelName: pushChannelName,
                error: error.map { CodableErrorInfo($0) }
            )))
            if let error {
                subscribeResult = .failure(error)
            } else {
                subscribeResult = .success(())
            }
        }
    }

    private func resultView(_ result: Result<Void, ARTErrorInfo>?, successText: String) -> some View {
        Group {
            switch result {
            case nil:
                EmptyView()
            case .success:
                Text(successText)
                    .foregroundStyle(.green)
            case .failure(let error):
                Text("Error: \(error.message)")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption)
    }

    private func saveSettings() {
        AppSettingsStore.shared.save(settings)
    }

    private func setUp() {
        // Set up event logging Ably instance (Realtime, to preserve message ordering)
        let clientId = "appInstallation-\(appInstallationID)"

        let eventLoggingOptions = ARTClientOptions(key: Secrets.ablyAPIKey)
        eventLoggingOptions.clientId = clientId
        let eventLogging = ARTRealtime(options: eventLoggingOptions)
        let eventsChannel = eventLogging.channels.get(eventsChannelName)
        self.eventLoggingAbly = eventLogging
        self.eventsChannel = eventsChannel

        // Publish the app launched event before setting up anything else
        eventsChannel.publish(.appLaunched(.init(
            protectedDataAvailable: UIApplication.shared.isProtectedDataAvailable
        )))

        // Set up PushKit VoIP registration and CallKit handler
        self.pushHandler = PushHandler(eventsChannel: eventsChannel)

        // Set up push activation delegate
        self.pushActivationHandler = PushActivationHandler()

        // Set up main Ably instance with custom log handler that publishes to the events channel.
        // Use the appInstallationID as the clientId so that multiple device registrations from
        // the same installation can be correlated (which is the failure mode we're investigating).
        let mainOptions = ARTClientOptions(key: Secrets.ablyAPIKey)
        mainOptions.clientId = clientId
        mainOptions.logHandler = EventLoggingLogHandler(eventsChannel: eventsChannel)
        mainOptions.logLevel = .verbose
        mainOptions.pushRegistererDelegate = pushActivationHandler
        let main = ARTRealtime(options: mainOptions)
        self.mainAbly = main
        mainAblyInstance = main

        // Observe subsequent protected data availability changes
        NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.eventsChannel?.publish(.protectedDataAvailability(.init(
                isAvailable: true
            )))
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.eventsChannel?.publish(.protectedDataAvailability(.init(
                isAvailable: false
            )))
        }

        // Perform automatic actions based on settings
        if settings.autoActivatePush {
            activatePush(reason: .appLaunch) {
                if settings.autoSubscribeToPushChannel {
                    subscribeToPushChannel(reason: .appLaunch)
                }
            }
        } else if settings.autoSubscribeToPushChannel {
            subscribeToPushChannel(reason: .appLaunch)
        }
    }
}
