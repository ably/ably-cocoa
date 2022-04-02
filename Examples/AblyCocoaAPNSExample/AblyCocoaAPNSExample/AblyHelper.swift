import Ably
import UIKit

class AblyHelper: NSObject {
    
    static let shared = AblyHelper()
    
    private(set) var realtime: ARTRealtime!
    
    private let key = "<YOUR ABLY API KEY>"
    
    private override init() {
        super.init()
        let options = ARTClientOptions(key: key)
        options.clientId = "basic-apns-example"
        self.realtime = ARTRealtime(options: options)
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
            let tokenInfo = ARTDeviceIdentityTokenDetails.unarchive(tokenData)
        else {
            print("IDENTITY TOKEN: doesn't exist")
            return
        }
        print("IDENTITY TOKEN:\n\(tokenInfo.token)")
    }
    
    func getDeviceDetails(_ callback: @escaping (ARTDeviceDetails?, ARTErrorInfo?) -> ()) {
        realtime.push.admin.deviceRegistrations.get(realtime.device.id, callback: callback)
    }
    
    func sendAdminPush() {
        let recipient = [
            "deviceId": realtime.device.id
        ]
        let data = [
            "notification": [
                "title": "Hello",
                "body": "This push was sent with deviceId"
            ],
            "data": [
                "foo": "bar",
                "baz": "qux"
            ]
        ]
        realtime.push.admin.publish(recipient, data: data) { error in
            print("Result: \(error?.localizedDescription ?? "Success")")
        }
    }
}

extension AblyHelper: UNUserNotificationCenterDelegate {
    
    static func requestUserNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { granted, error in
            DispatchQueue.main.async() {
                UIApplication.shared.registerForRemoteNotifications()
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
