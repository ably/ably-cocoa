import Ably
import SwiftUI

struct ContentView: View {
    
    @State var showDeviceDetailsAlert = false
    @State var deviceDetails: ARTDeviceDetails?
    @State var deviceDetailsError: ARTErrorInfo?
    
    var body: some View {
        VStack {
            Spacer()
            Group {
                Text("Push Notifications")
                .padding()
                Button("Activate") {
                    AblyHelper.shared.activatePush()
                }
                .padding()
                Button("Deactivate") {
                    AblyHelper.shared.deactivatePush()
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
                Button("Send Push") {
                    AblyHelper.shared.sendAdminPush(title: "Hello", body: "This push was sent with deviceId")
                }
                .padding()
            }
            Group {
                Text("Basic Messaging")
                .padding()
                Button("Subscribe") {
                    AblyHelper.shared.subscribe(event: "test")
                }
                .padding()
                Button("Publish") {
                    AblyHelper.shared.publish(event: "test", message: "Hi there!")
                }
            }
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
