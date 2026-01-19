import CoreLocation

struct LocationPushEvent: Codable {
    var id: UUID
    var receivedAt: Date
    var jsonPayload: Data
}

class LocationPushService: NSObject, CLLocationPushServiceExtension, CLLocationManagerDelegate {

    var completion: (() -> Void)?
    var locationManager: CLLocationManager!

    func didReceiveLocationPushPayload(_ payload: [String : Any], completion: @escaping () -> Void) {
        recordPushPayload(payload)

        self.completion = completion
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestLocation()
    }

    /**
     * This method is used to exchange information between the app and the extension.
     * This gives a user, who testing location pushes without access to the debug console, to see actual notifications in the `LocationPushEventsView`.
     */
    private func recordPushPayload(_ payload: [String : Any]) {
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.\(Bundle.main.bundleIdentifier!)") else {
            return print("App Groups were not configured properly. Check 'Signing & Capabilities' tab of the project settings.")
        }

        let dataFileURL = sharedContainerURL.appendingPathComponent("dataFile")

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

        let event = LocationPushEvent(id: UUID(), receivedAt: Date(), jsonPayload: try! JSONSerialization.data(withJSONObject: payload))
        var events: [LocationPushEvent] = []

        if let data {
            events = try! JSONDecoder().decode([LocationPushEvent].self, from: data)
            events.append(event)
        } else {
            events = [event]
        }

        let newData = try! JSONEncoder().encode(events)

        let writeCoordinator = NSFileCoordinator()
        var writeError: NSError? = nil
        writeCoordinator.coordinate(writingItemAt: dataFileURL, error: &writeError) { url in
            try! newData.write(to: url)
        }
    }

    func serviceExtensionWillTerminate() {
        // Called just before the extension will be terminated by the system.
        self.completion?()
    }

    // MARK: - CLLocationManagerDelegate methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Process the location(s) as needed
        print("Locations received: \(locations)")
        self.completion?()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
        self.completion?()
    }
}
