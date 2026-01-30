import SwiftUI
import Foundation

#if canImport(UIKit)

import UIKit
public final class AutoSizingTextView: UITextView {
    public override var intrinsicContentSize: CGSize {
        let width = max(1, bounds.width)
        return CGSize(width: width, height: contentSize.height)
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

public struct GrowingTextEditor: UIViewRepresentable {
    @Binding public var text: String
    @Binding public var dynamicHeight: CGFloat
    public init(text: Binding<String>, dynamicHeight: Binding<CGFloat>) { self._text = text; self._dynamicHeight = dynamicHeight }
    public func makeUIView(context: Context) -> AutoSizingTextView {
        let tv = AutoSizingTextView()
        tv.isScrollEnabled = false
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        tv.delegate = context.coordinator
        tv.textContainerInset = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        tv.textContainer.widthTracksTextView = true
        tv.inputAssistantItem.leadingBarButtonGroups = []
        tv.inputAssistantItem.trailingBarButtonGroups = []
        tv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tv.showsVerticalScrollIndicator = false
        return tv
    }
    public func updateUIView(_ uiView: AutoSizingTextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        uiView.layoutIfNeeded()
        let h = uiView.contentSize.height
        if dynamicHeight != h {
            DispatchQueue.main.async { self.dynamicHeight = h }
        }
    }
    public func makeCoordinator() -> Coordinator { Coordinator(self) }
    public final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: GrowingTextEditor
        public init(_ parent: GrowingTextEditor) { self.parent = parent }
        public func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            let h = textView.contentSize.height
            if parent.dynamicHeight != h {
                DispatchQueue.main.async { self.parent.dynamicHeight = h }
            }
        }
    }
}

#else
public struct GrowingTextEditor: View {
    @Binding public var text: String
    @Binding public var dynamicHeight: CGFloat
    public init(text: Binding<String>, dynamicHeight: Binding<CGFloat>) { self._text = text; self._dynamicHeight = dynamicHeight }
    public var body: some View {
        ZStack(alignment: .leading) {
            TextEditor(text: $text)
                .font(.system(size: 16))
                .padding(.horizontal, 6)
            Text(text.isEmpty ? "" : (text + " "))
                .font(.system(size: 16))
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .opacity(0)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { updateHeight(max(36, geo.size.height)) }
                            #if os(macOS)
                            .onChange(of: text) { updateHeight(max(36, geo.size.height)) }
                            #else
                            .onChange(of: text) { _ in updateHeight(max(36, geo.size.height)) }
                            #endif
                    }
                )
        }
    }
    private func updateHeight(_ h: CGFloat) {
        if dynamicHeight != h {
            DispatchQueue.main.async { self.dynamicHeight = h }
        }
    }
}

#endif
