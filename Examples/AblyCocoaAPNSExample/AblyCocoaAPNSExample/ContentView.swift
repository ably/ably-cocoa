import Ably
import SwiftUI

struct ContentView: View {
    
    @State var showDeviceDetailsAlert = false
    @State var deviceDetails: ARTDeviceDetails?
    @State var deviceDetailsError: ARTErrorInfo?
    
    var body: some View {
        VStack {
            Spacer()
            Button("Activate") {
                AblyHelper.requestUserNotificationAuthorization()
                AblyHelper.shared.realtime.push.activate()
            }
            .padding()
            Button("Dectivate") {
                AblyHelper.shared.realtime.push.deactivate()
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
                } else if deviceDetailsError != nil {
                    return Alert(title: Text("Device Details Error"), message: Text("\(deviceDetailsError!)"))
                }
                return Alert(title: Text("Device Details Error"), message: Text("Unknown result."))
            }
            .padding()
            Button("Send Push") {
                AblyHelper.shared.sendAdminPush()
            }
            .padding()
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
