import SwiftUI

/**
 * The content of this file is used to exchange information between the app and the extension.
 * This gives a user, who testing location pushes without access to the debug console, to see actual notifications in the `LocationPushEventsView`.
 */

struct LocationPushEvent: Identifiable, Codable {
    var id: UUID
    var receivedAt: Date
    var jsonPayload: Data
}

class DataLoader: NSObject, NSFilePresenter, ObservableObject {
    var presentedItemOperationQueue: OperationQueue = .main
    var notificationObservers: [Any] = []

    @Published private (set) var events: [LocationPushEvent] = []

    override init() {
        super.init()
        loadEvents()

        let didEnterBackgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.tearDownCoordinator()
        }
        notificationObservers.append(didEnterBackgroundObserver)

        let willEnterForegroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.setUpCoordinator()
            self?.loadEvents()
        }
        notificationObservers.append(willEnterForegroundObserver)
    }

    func setUpCoordinator() {
        print("set up coordinator")
        NSFileCoordinator.addFilePresenter(self)
    }

    func tearDownCoordinator() {
        print("tear down coordinator")
        NSFileCoordinator.removeFilePresenter(self)
    }

    deinit {
        print("deinit DataLoader")
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func loadEvents() {
        let dataFileURL = presentedItemURL!

        let readCoordinator = NSFileCoordinator()
        var readError: NSError? = nil
        var data: Data? = nil
        readCoordinator.coordinate(readingItemAt: dataFileURL, error: &readError) { url in
            if FileManager.default.fileExists(atPath: url.path) {
                data = FileManager.default.contents(atPath: url.path)!
            }
        }

        guard readError == nil else {
            return
        }

        if let data {
            events = try! JSONDecoder().decode([LocationPushEvent].self, from: data)
        } else {
            events = []
        }
    }

    var presentedItemURL: URL? {
        let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.io.ably.basic-apns-example")!

        return sharedContainerURL.appendingPathComponent("dataFile")
    }

    func presentedItemDidChange() {
        loadEvents()
    }
}

struct LocationPushEventsView: View {
    @StateObject private var dataLoader = DataLoader()

    var body: some View {
        return List(dataLoader.events.sorted { $0.receivedAt > $1.receivedAt }) { event in
            VStack(alignment: .leading) {
                Text("Received at: \(event.receivedAt.ISO8601Format())")
                Text("Payload: \(payloadDescription(for: event))")
            }
        }
        .navigationTitle("Location push events")
        .onAppear { dataLoader.setUpCoordinator() }
        .onDisappear { dataLoader.tearDownCoordinator() }
    }

    private func payloadDescription(for event: LocationPushEvent) -> String {
        return String(data: event.jsonPayload, encoding: .utf8)!
    }
}
