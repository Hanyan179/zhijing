import SwiftUI

extension View {
    @ViewBuilder
    func ifAvailable17<T: View>(_ transform: (Self) -> T) -> some View {
        if #available(iOS 17.0, *) {
            transform(self)
        } else {
            self
        }
    }
}
