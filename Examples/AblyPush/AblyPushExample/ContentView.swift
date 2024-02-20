import Ably
import SwiftUI

struct ContentView: View {
    
    @State var showDeviceDetailsAlert = false
    @State var deviceDetails: ARTDeviceDetails?
    @State var deviceDetailsError: ARTErrorInfo?
    
    @State var showDeviceTokensAlert = false
    @State var defaultDeviceToken: String?
    @State var locationDeviceToken: String?
    @State var deviceTokensError: ARTErrorInfo?
    @Binding var subscribedToExampleChannel1: Bool

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Button("Activate Push") {
                    AblyHelper.shared.activatePush {
                        defaultDeviceToken = $0
                        locationDeviceToken = $1
                        deviceTokensError = $2
                        showDeviceTokensAlert = true
                    }
                }
                .alert(isPresented: $showDeviceTokensAlert) {
                    if let deviceTokensError = deviceTokensError {
                        return Alert(title: Text("Device Tokens"), message: Text("Error: \(deviceTokensError)"))
                    }
                    else if let defaultDeviceToken = defaultDeviceToken, let locationDeviceToken = locationDeviceToken {
                        return Alert(title: Text("Device Tokens"),
                                     message: Text("Default: \(defaultDeviceToken)\n\nLocation: \(locationDeviceToken)"))
                    }
                    else if let defaultDeviceToken = defaultDeviceToken {
                        return Alert(title: Text("Device Tokens"), message: Text("Default: \(defaultDeviceToken)"))
                    }
                    return Alert(title: Text("Push activation"), message: Text("Success"))
                }
                .padding()
                Button("Dectivate") {
                    AblyHelper.shared.deactivatePush()
                }
                .padding()
                PushButton(title: "Remember Me", isOn: $subscribedToExampleChannel1)

                Button("Subscribe to \(Channel.exampleChannel1.rawValue)") {
                    AblyHelper.shared.subscribeToChannel(.exampleChannel1)
                }
                .padding()
                Button("Subscribe to \(Channel.exampleChannel2.rawValue)") {
                    AblyHelper.shared.subscribeToChannel(.exampleChannel2)
                }
                .padding()
                Button("Print Token") {
                    AblyHelper.shared.printIdentityToken()
                }
                .padding()
                Button("Device Details") {
                    AblyHelper.shared.getDeviceDetails { details, error in
                        deviceDetails = details
                        deviceDetailsError = error
                        showDeviceDetailsAlert = true
                    }
                }
                .alert(isPresented: $showDeviceDetailsAlert) {
                    if deviceDetails != nil {
                        return Alert(title: Text("Device Details"), message: Text("\(deviceDetails!)"))
                    }
                    else if deviceDetailsError != nil {
                        return Alert(title: Text("Device Details Error"), message: Text("\(deviceDetailsError!)"))
                    }
                    return Alert(title: Text("Device Details Error"), message: Text("Unknown result."))
                }
                .padding()
                Button("Send Push to deviceId") {
                    AblyHelper.shared.sendAdminPush(title: "Hello", body: "This push was sent with deviceId")
                }
                .padding()
                Button("Send Push to \(Channel.exampleChannel1.rawValue)") {
                    AblyHelper.shared.sendPushToChannel(.exampleChannel1)
                }
                .padding()
                Button("Send Push to \(Channel.exampleChannel2.rawValue)") {
                    AblyHelper.shared.sendPushToChannel(.exampleChannel2)
                }
                .padding()
                #if USE_LOCATION_PUSH
                NavigationLink {
                    LocationPushEventsView()
                } label: {
                    Text("Location push events")
                }
                .padding()
                #endif
                Spacer()
            }
            .navigationTitle("Ably Push Example")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct PushButton: View {
    let title: String
    @Binding var isOn: Bool

    var onColors = [Color.red, Color.yellow]
    var offColors = [Color(white: 0.6), Color(white: 0.4)]

    var body: some View {
        Button(title) {
            isOn.toggle()
        }
        .padding()
        .background(LinearGradient(
            colors: isOn ? onColors : offColors,
            startPoint: .top, endPoint: .bottom
            )
        )
        .foregroundStyle(.white)
        .clipShape(.capsule)
        .shadow(radius: isOn ? 0 : 5)
    }
}
