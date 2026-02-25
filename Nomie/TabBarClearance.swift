import SwiftUI

let nomieTabBarClearanceValue: CGFloat = 90

extension View {
    func nomieTabBarContentPadding() -> some View {
        padding(.bottom, nomieTabBarClearanceValue)
    }
}
