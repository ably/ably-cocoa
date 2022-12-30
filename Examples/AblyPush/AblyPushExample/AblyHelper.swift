import Ably
import UIKit

class AblyHelper: NSObject {
    
    static let shared = AblyHelper(clientId: UIDevice.current.name)
    
    private var clientId: String!
    
    private(set) var realtime: ARTRealtime!
    
    private var testChannel: ARTRealtimeChannel {
        realtime.channels.get("testChannel")
    }
    
    private let key = "" // Your API Key from your app's dashboard
    
    func createRealtime() {
        self.realtime?.close()
        let options = ARTClientOptions(key: key)
        options.clientId = clientId
        options.pushRegistererDelegate = self
        self.realtime = ARTRealtime(options: options)
    }
    
    private convenience init(clientId: String) {
        self.init()
        guard key != "" else {
            preconditionFailure("Obtain your API key at https://ably.com/accounts/")
        }
        self.clientId = clientId
        UNUserNotificationCenter.current().delegate = self
    }
}

extension AblyHelper {
    
    func activatePush() {
        Self.requestUserNotificationAuthorization()
        realtime.push.activate()
    }
    
    func deactivatePush() {
        realtime.push.deactivate()
    }
    
    func printIdentityToken() {
        guard
            let tokenData = UserDefaults.standard.value(forKey: "ARTDeviceIdentityToken") as? Data,
            let tokenInfo = ARTDeviceIdentityTokenDetails.unarchive(tokenData, withLogger: ARTLog())
        else {
            print("IDENTITY TOKEN: doesn't exist")
            return
        }
        print("IDENTITY TOKEN:\n\(tokenInfo.token)")
    }
    
    func getDeviceDetails(_ callback: @escaping (ARTDeviceDetails?, ARTErrorInfo?) -> ()) {
        realtime.push.admin.deviceRegistrations.get(realtime.device.id, callback: callback)
    }
    
    // For this to work you must turn on 'Push Admin' capability in your API key settings
    func sendAdminPush(title: String, body: String) {
        let recipient = [
            "deviceId": realtime.device.id
        ]
        let data = [
            "notification": [
                "title": title,
                "body": body
            ],
            "data": [
                "foo": "bar",
                "baz": "qux"
            ]
        ]
        realtime.push.admin.publish(recipient, data: data) { error in
            print("Publish result: \(error?.localizedDescription ?? "Success")")
        }
    }
    
    func subscribe(event: String) {
        testChannel.subscribe(event) { m in
            print("Received a '\(m.name!)' message: '\(m.data!)' from \(m.clientId!)")
        }
    }
    
    func publish(event: String, message: String) {
        testChannel.publish(event, data: message) { error in
            if let error = error {
                print("Message '\(event)' send error: \(error.localizedDescription)")
            } else {
                print("Message '\(event)' sent from \(UIDevice.current.name)")
            }
        }
    }
}

extension AblyHelper: ARTPushRegistererDelegate {
    
    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        print("Push activation: \(error?.localizedDescription ?? "Success")")
    }
    
    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        print("Push deactivation: \(error?.localizedDescription ?? "Success")")
    }
}

extension AblyHelper: UNUserNotificationCenterDelegate {
    
    static func requestUserNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { granted, error in
            DispatchQueue.main.async() {
                print("Push auth: \(error?.localizedDescription ?? (granted ? "Granted" : "Not Granted"))")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Got push notification!")
        completionHandler([.banner, .sound])
    }
}
