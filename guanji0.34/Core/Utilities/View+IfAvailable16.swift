import SwiftUI

extension View {
    @ViewBuilder
    func ifAvailable16<T: View>(_ transform: (Self) -> T) -> some View {
        if #available(iOS 16.0, *) {
            transform(self)
        } else {
            self
        }
    }
}
