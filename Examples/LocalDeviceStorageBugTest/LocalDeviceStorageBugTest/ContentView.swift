//
//  ContentView.swift
//  LocalDeviceStorageBugTest
//
//  Created by Lawrence Forooghian on 15/04/2026.
//

import SwiftUI
import Ably

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

struct ContentView: View {
    @State private var eventLoggingAbly: ARTRealtime?
    @State private var mainAbly: ARTRealtime?

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

        // Set up main Ably instance with custom log handler that publishes to the events channel
        let mainOptions = ARTClientOptions(key: Secrets.ablyAPIKey)
        mainOptions.logHandler = EventLoggingLogHandler(eventsChannel: eventsChannel)
        mainOptions.logLevel = .verbose
        let main = ARTRealtime(options: mainOptions)
        self.mainAbly = main
    }
}
