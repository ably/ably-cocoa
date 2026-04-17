//
//  LocalDeviceStorageBugTestApp.swift
//  LocalDeviceStorageBugTest
//
//  Created by Lawrence Forooghian on 15/04/2026.
//

import SwiftUI
import Ably

/// Shared reference to `mainAbly`, so the app delegate can forward APNs tokens.
var mainAblyInstance: ARTRealtime?

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let mainAbly = mainAblyInstance else { return }
        ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken, realtime: mainAbly)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        guard let mainAbly = mainAblyInstance else { return }
        ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, realtime: mainAbly)
    }
}

@main
struct LocalDeviceStorageBugTestApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
