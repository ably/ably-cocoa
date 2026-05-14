import Ably
import AblyLiveObjects
import SwiftUI

enum VoteColor: String, CaseIterable {
    case red
    case green
    case blue

    var displayName: String {
        rawValue.capitalized
    }

    var swiftUIColor: SwiftUI.Color {
        switch self {
        case .red:
            .red
        case .green:
            .green
        case .blue:
            .blue
        }
    }
}

@MainActor
final class LiveCounterViewModel: ObservableObject {
    @Published var redCount: Double = 0
    @Published var greenCount: Double = 0
    @Published var blueCount: Double = 0
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var realtime: ARTRealtime
    private var channel: ARTRealtimeChannel
    private var objects: any RealtimeObjects
    private var root: (any LiveMap)?

    private var redCounter: (any LiveCounter)?
    private var greenCounter: (any LiveCounter)?
    private var blueCounter: (any LiveCounter)?

    private var subscribeResponses: [String: any SubscribeResponse] = [:]

    init(realtime: ARTRealtime) {
        self.realtime = realtime

        // Use URL parameters or default channel name
        let channelName = "live-objects-counter"
        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = [.objectPublish, .objectSubscribe]
        channel = realtime.channels.get(channelName, options: channelOptions)
        objects = channel.objects

        Task {
            await initializeCounters()
        }
    }

    deinit {
        // Clean up subscriptions
        subscribeResponses.values.forEach { $0.unsubscribe() }
        subscribeResponses.removeAll()
    }

    private func initializeCounters() async {
        do {
            isLoading = true
            errorMessage = nil

            // Attach channel first
            try await channel.attachAsync()

            // Get root object
            let root = try await objects.getRoot()
            self.root = root

            // Subscribe to root changes
            let rootSubscription = try root.subscribe { [weak self] update, _ in
                MainActor.assumeIsolated {
                    // Handle root updates - this will fire when counters are reset
                    for (keyName, change) in update.update {
                        if change == .updated, let color = VoteColor(rawValue: keyName) {
                            self?.subscribeToCounter(color: color)
                        }
                    }
                }
            }
            subscribeResponses["root"] = rootSubscription

            // Initialize all color counters
            for color in VoteColor.allCases {
                await initializeCounter(for: color)
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to initialize: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func initializeCounter(for color: VoteColor) async {
        do {
            guard let root else {
                return
            }

            // Check if counter already exists
            if let existingValue = try root.get(key: color.rawValue), let existingCounter = existingValue.liveCounterValue {
                // Counter exists, store it
                setCounter(existingCounter, for: color)
            } else {
                // Counter doesn't exist, create it
                let newCounter = try await objects.createCounter(count: 0)
                try await root.set(key: color.rawValue, value: .liveCounter(newCounter))
                setCounter(newCounter, for: color)
            }
            // Subscribe to it
            subscribeToCounter(color: color)
        } catch {
            errorMessage = "Failed to initialize \(color.rawValue) counter: \(error.localizedDescription)"
        }
    }

    private func setCounter(_ counter: any LiveCounter, for color: VoteColor) {
        do {
            let value = try counter.value
            switch color {
            case .red:
                redCounter = counter
                redCount = value
            case .green:
                greenCounter = counter
                greenCount = value
            case .blue:
                blueCounter = counter
                blueCount = value
            }
        } catch {
            errorMessage = "Error getting \(color.rawValue) counter value: \(error)"
        }
    }

    private func subscribeToCounter(color: VoteColor) {
        do {
            guard let root,
                  let value = try root.get(key: color.rawValue),
                  let counter = value.liveCounterValue else { return }

            subscribeResponses[color.rawValue]?.unsubscribe()

            subscribeResponses[color.rawValue] = try counter.subscribe { [weak self] _, _ in
                MainActor.assumeIsolated {
                    // Update current value
                    self?.updateCounterValue(for: color, counter: counter)
                }
            }

            // Set counter with value
            setCounter(counter, for: color)
        } catch {
            errorMessage = "Failed to subscribe to \(color.rawValue) counter: \(error)"
        }
    }

    private func updateCounterValue(for color: VoteColor, counter: any LiveCounter) {
        do {
            let value = try counter.value
            switch color {
            case .red:
                redCount = value
            case .green:
                greenCount = value
            case .blue:
                blueCount = value
            }
        } catch {
            errorMessage = "Error updating \(color.rawValue) counter value: \(error)"
        }
    }

    func vote(for color: VoteColor) {
        Task {
            do {
                let counter: (any LiveCounter)? = switch color {
                case .red:
                    redCounter
                case .green:
                    greenCounter
                case .blue:
                    blueCounter
                }

                try await counter?.increment(amount: 1)
            } catch {
                errorMessage = "Failed to vote for \(color.rawValue): \(error.localizedDescription)"
            }
        }
    }

    func resetCounter(color: VoteColor) {
        Task {
            do {
                let newCounter = try await objects.createCounter(count: 0)
                try await self.root?.set(key: color.rawValue, value: .liveCounter(newCounter))
            } catch {
                errorMessage = "Failed to reset counters: \(error.localizedDescription)"
            }
        }
    }

    func resetAllCounters() {
        for color in VoteColor.allCases {
            resetCounter(color: color)
        }
    }
}
