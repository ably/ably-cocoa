import Ably
import SwiftUI

@main
struct AblyCocoaAPNSExampleApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AblyHelper.shared.apnsActivated = true
        ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken, realtime: AblyHelper.shared.realtime)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, realtime: AblyHelper.shared.realtime)
    }
}
