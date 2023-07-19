## Push Notifications Example

This app gives you a brief understanding of how Ably's Push Notifications work. 
You will need a real iOS device to test this functionality.

- First, go to https://ably.com/accounts/, create an app and copy API key from API Keys tab of the app's dashboard.
- Go to the `Notifications` tab of the Ably's app dashboard and scroll to the `Push Notifications Setup` section. Press `Configure Push` and follow the instructions there.
- Insert it instead of an empty string in the `key` property's value inside the `AblyHelper` class.
- Make sure you've selected your development team in the `Signing & Capabilities` tab of the Xcode project target settings and all the provisioning profiles created without errors (update the `bundle-id` for the `AblyPushExample` target as needed).
- Build and Run the app on your device.
- Hit "Activate" button, then hit "Print Token". You should see "IDENTITY TOKEN: exists" printed in the debug output window.
- Hit "Device Details" to display Ably push device registration info after successful activation.
- Go to the `Notifications` tab of the Ably's app dashboard again and scroll to the `Push Inspector` section. Fill in `Title` and `Body` fields of the push notification. Then insert "basic-apns-example" in the `Client ID` field and press enter. Then hit "Push to client" button. You should now see the notification on the screen of your device.
- Also you can send notifications from the app itself if you tick `Push Admin` capability in your API key settings in the app's dashboard. Just hit "Send Push" button to send a predefined push notification which is also will be displayed on your device's screen right away. You can change this behavior in the `UNUserNotificationCenterDelegate` extension for the `AblyHelper` by editing `completionHandler([.banner, .sound])` line of code.

### Location pushes

* In order to use this capability (starting from iOS 15), you need to apply for the special entitlement on the Apple's developer portal. Follow instructions [here](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_location_push) on how to do that.

* Update the `bundle-id` for the `AblyPushExample` and `AblyLocationPush` targets as needed.

* To receive location push notifications you need to request another device token specifically for the location pushes purpose. You do so by calling `CLLocationManager.startMonitoringLocationPushes(completion:)` within a `ARTPushRegistererDelegate.didActivateAblyPush(:)` delegate method (which is a callback for the `ARTRealtime.push.activate()` call).

* Once you receive the location push token, save it by calling a new `ARTPush.didRegisterForLocationNotifications(withDeviceToken:realtime:)` method (note the "Location" word in the name of this method). Ably will call the `ARTPushRegistererDelegate.didUpdateAblyPush:` callback on a successful or failed attempt to save the token.

* Use the "Location push events" button in the example app to open a list of received location pushed notifications.
