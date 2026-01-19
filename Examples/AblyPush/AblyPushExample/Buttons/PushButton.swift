import SwiftUI

struct PushButton: View {
    let systemImage: String
    let activeTitle: String
    let inactiveTitle: String
    let action: () -> Void
    let isButtonEnabled: Bool // is the button enabled
    let isActive: Bool // is the action in it's on or off state

    let activeColor = Color(red: 1.00, green: 0.33, blue: 0.09)
    let inActiveColor = Color(red: 0.00, green: 0.56, blue: 0.02)

    init(
        isButtonEnabled: Bool,
        systemImage: String,
        activeTitle: String,
        inactiveTitle: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) {
        self.isButtonEnabled = isButtonEnabled
        self.systemImage = systemImage
        self.activeTitle = activeTitle
        self.inactiveTitle = inactiveTitle
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        let button = Button {
            action() // manage the toggling of isActive binding within the action.
        } label: {
            Label(isActive ? activeTitle : inactiveTitle,
                  systemImage: systemImage)
            .frame(maxWidth: .infinity)
            .labelStyle(VerticalLabelStyle())
            .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle)
        .tint(isActive ? activeColor : inActiveColor)
        .disabled(!isButtonEnabled)
        .animation(.easeInOut, value: isButtonEnabled)

        if #available(iOS 17.0, *) {
            return button.contentTransition(.symbolEffect(.replace))
        }

        return button
    }
}
