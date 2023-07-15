import Ably
import UIKit
import CoreLocation

class AblyHelper: NSObject {
    
    static let shared = AblyHelper()
    
    private var locationManager: CLLocationManager!

    private(set) var realtime: ARTRealtime!
    
    private let key = "" // Your API Key from your app's dashboard
    
    var defaultDeviceToken: String?
    
    var locationDeviceToken: String?
    
    var activatePushCallback: ((String?, String?, ARTErrorInfo?) -> ())?
    
    private override init() {
        super.init()
        guard key != "" else {
            preconditionFailure("Obtain your API key at https://ably.com/accounts/")
        }
        let options = ARTClientOptions(key: key)
        options.clientId = "basic-apns-example"
        options.pushRegistererDelegate = self
        self.realtime = ARTRealtime(options: options)
        UNUserNotificationCenter.current().delegate = self
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization() // for simplicity we put it here, but in the real app you should care about particular moment, when you ask for any permissions
    }
}

extension AblyHelper {
    
    func activatePush(_ callback: @escaping (String?, String?, ARTErrorInfo?) -> ()) {
        Self.requestUserNotificationAuthorization()
        realtime.push.activate()
        activatePushCallback = callback
    }
    
    func activateLocationPush() {
        locationManager.startMonitoringLocationPushes { deviceToken, error in
            guard error == nil else {
                return ARTPush.didFailToRegisterForLocationNotificationsWithError(error!, realtime: self.realtime)
            }
            self.locationDeviceToken = (deviceToken! as NSData).art_deviceTokenString()
            ARTPush.didRegisterForLocationNotifications(withDeviceToken: deviceToken!, realtime: self.realtime)
        }
    }
    
    func deactivatePush() {
        realtime.push.deactivate()
    }
    
    func printIdentityToken() {
        if UserDefaults.standard.value(forKey: "ARTDeviceIdentityToken") != nil {
            print("IDENTITY TOKEN: exists")
        } else {
            print("IDENTITY TOKEN: doesn't exist")
        }
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
}

extension AblyHelper: ARTPushRegistererDelegate {
    
    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        print("Push activation: \(error?.localizedDescription ?? "Success")")
        activatePushCallback?(defaultDeviceToken, locationDeviceToken, error)
    }
    
    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        print("Push deactivation: \(error?.localizedDescription ?? "Success")")
    }
    
    func didUpdateAblyPush(_ error: ARTErrorInfo?) {
        print("Push update: \(error?.localizedDescription ?? "Success")")
        activatePushCallback?(defaultDeviceToken, locationDeviceToken, error)
    }
    
    func shouldRequestOtherDeviceTokensForAblyPush() {
        activateLocationPush()
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

extension AblyHelper : CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("Location services always authorized.")
        case .notDetermined, .authorizedWhenInUse, .restricted, .denied:
            print("Location services unavailable for location pushes.")
            break
        default:
            break
        }
    }
}
