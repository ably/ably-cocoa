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
        ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken, realtime: AblyHelper.shared.realtime)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, realtime: AblyHelper.shared.realtime)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { n in
            AblyHelper.shared.createRealtime()
        }
        return true
    }
}
