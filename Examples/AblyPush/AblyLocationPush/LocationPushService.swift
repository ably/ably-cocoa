import CoreLocation

struct LocationPushEvent: Codable {
    var id: UUID
    var receivedAt: Date
    var jsonPayload: Data? // optional just because I've got some data sitting on my device from before this property
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

    private func recordPushPayload(_ payload: [String : Any]) {
        let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.forooghian.AblyPushExample")!

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
