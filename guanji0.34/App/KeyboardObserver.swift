import SwiftUI
import Combine

#if canImport(UIKit)
public final class KeyboardObserver: ObservableObject {
    @Published public private(set) var height: CGFloat = 0
    private var cancellables: Set<AnyCancellable> = []
    public init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .sink { [weak self] h in self?.height = h }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in self?.height = 0 }
            .store(in: &cancellables)
    }
}
#else
public final class KeyboardObserver: ObservableObject {
    @Published public private(set) var height: CGFloat = 0
    public init() {}
}
#endif
