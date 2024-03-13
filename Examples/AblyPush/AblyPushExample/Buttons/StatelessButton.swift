import SwiftUI

struct StatelessButton: View {
    let isButtonEnabled: Bool
    let systemImage: String
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    @State var taps: Int = 0 // purely to trigger animation on every tap
    
    init(
        isButtonEnabled: Bool,
        systemImage: String,
        title: String,
        backgroundColor: Color = Color(red: 0.00, green: 0.56, blue: 0.02),
        action: @escaping () -> Void
    ) {
        self.isButtonEnabled = isButtonEnabled
        self.systemImage = systemImage
        self.title = title
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        let button = Button {
            action()
            taps += 1
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .labelStyle(VerticalLabelStyle())
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .tint(backgroundColor)
        .disabled(!isButtonEnabled)
        .animation(.easeInOut, value: isButtonEnabled)
        
        if #available(iOS 17.0, *) {
            return button.symbolEffect(.bounce.down, value: taps)
        }
        
        return button
    }
}
