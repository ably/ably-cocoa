import Ably
import AblyLiveObjects
import SwiftUI

@MainActor
final class TaskBoardViewModel: ObservableObject {
    @Published var tasks: [String: String] = [:]
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var realtime: ARTRealtime
    private var channel: ARTRealtimeChannel
    private var objects: any RealtimeObjects
    private var root: (any LiveMap)?
    private var tasksMap: (any LiveMap)?

    private var subscribeResponses: [String: any SubscribeResponse] = [:]

    init(realtime: ARTRealtime, channelName: String = "objects-live-map") {
        self.realtime = realtime

        let channelOptions = ARTRealtimeChannelOptions()
        channelOptions.modes = [.objectPublish, .objectSubscribe]
        channel = realtime.channels.get(channelName, options: channelOptions)
        objects = channel.objects

        Task {
            await initializeTasks()
        }
    }

    deinit {
        // Clean up subscriptions
        subscribeResponses.values.forEach { $0.unsubscribe() }
        subscribeResponses.removeAll()
    }

    private func initializeTasks() async {
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
                    // Handle root updates - this will fire when tasks map is reset
                    if update.update["tasks"] == .updated {
                        if let newTasksMap = try? root.get(key: "tasks")?.liveMapValue {
                            self?.tasksMap = newTasksMap
                            self?.subscribeToTasksUpdates(tasksMap: newTasksMap)
                        }
                    }
                }
            }
            subscribeResponses["root"] = rootSubscription

            // Initialize or get existing tasks map
            if let existingTasksMap = try root.get(key: "tasks")?.liveMapValue {
                tasksMap = existingTasksMap
                subscribeToTasksUpdates(tasksMap: existingTasksMap)
            } else {
                let newTasksMap = try await objects.createMap()
                try await root.set(key: "tasks", value: .liveMap(newTasksMap))
                tasksMap = newTasksMap
                subscribeToTasksUpdates(tasksMap: newTasksMap)
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to initialize: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func subscribeToTasksUpdates(tasksMap: any LiveMap) {
        do {
            // Load existing tasks
            let entries = try tasksMap.entries
            var currentTasks: [String: String] = [:]

            for (key, value) in entries {
                if let stringValue = value.stringValue {
                    currentTasks[key] = stringValue
                }
            }

            tasks = currentTasks

            // Clean up existing subscription
            subscribeResponses["tasks"]?.unsubscribe()

            // Subscribe to updates
            subscribeResponses["tasks"] = try tasksMap.subscribe { [weak self] update, _ in
                MainActor.assumeIsolated {
                    for (taskId, action) in update.update {
                        switch action {
                        case .updated:
                            if let updatedValue = try? tasksMap.get(key: taskId)?.stringValue {
                                self?.tasks[taskId] = updatedValue
                            }
                        case .removed:
                            self?.tasks.removeValue(forKey: taskId)
                        }
                    }
                }
            }
        } catch {
            errorMessage = "Failed to subscribe to tasks: \(error.localizedDescription)"
        }
    }

    func addTask(_ title: String) {
        let taskTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !taskTitle.isEmpty else {
            return
        }

        Task {
            do {
                if let tasksMap {
                    let taskId = UUID().uuidString
                    try await tasksMap.set(key: taskId, value: .string(taskTitle))
                }
            } catch {
                errorMessage = "Failed to add task: \(error.localizedDescription)"
            }
        }
    }

    func editTask(id: String, newTitle: String) {
        let taskTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !taskTitle.isEmpty else {
            return
        }

        Task {
            do {
                if let tasksMap {
                    try await tasksMap.set(key: id, value: .string(taskTitle))
                }
            } catch {
                errorMessage = "Failed to edit task: \(error.localizedDescription)"
            }
        }
    }

    func removeTask(id: String) {
        Task {
            do {
                if let tasksMap {
                    try await tasksMap.remove(key: id)
                }
            } catch {
                errorMessage = "Failed to remove task: \(error.localizedDescription)"
            }
        }
    }

    func removeAllTasks() {
        Task {
            do {
                guard let root = self.root else {
                    return
                }

                let newTasksMap = try await objects.createMap()
                try await root.set(key: "tasks", value: .liveMap(newTasksMap))
            } catch {
                errorMessage = "Failed to remove all tasks: \(error.localizedDescription)"
            }
        }
    }
}
