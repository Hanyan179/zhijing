import SwiftUI
import Foundation

#if canImport(UIKit)

import UIKit

public struct CapsuleTextEditor: UIViewRepresentable {
    @Binding public var text: String
    public var onAddPhoto: () -> Void
    public var onAddFile: () -> Void
    public var onCollapse: () -> Void
    public init(text: Binding<String>, onAddPhoto: @escaping () -> Void, onAddFile: @escaping () -> Void, onCollapse: @escaping () -> Void) {
        self._text = text
        self.onAddPhoto = onAddPhoto
        self.onAddFile = onAddFile
        self.onCollapse = onCollapse
    }
    public func makeCoordinator() -> Coordinator { Coordinator(self) }
    public func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.backgroundColor = .clear
        tv.delegate = context.coordinator

        let toolbar = UIToolbar()
        let plus = UIBarButtonItem(systemItem: .add)
        plus.menu = UIMenu(children: [
            UIAction(title: NSLocalizedString("photo", comment: ""), image: UIImage(systemName: "photo")) { _ in context.coordinator.parent.onAddPhoto() },
            UIAction(title: NSLocalizedString("file", comment: ""), image: UIImage(systemName: "doc")) { _ in context.coordinator.parent.onAddFile() }
        ])
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let collapse = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: context.coordinator, action: #selector(Coordinator.collapse))
        toolbar.items = [plus, flex, collapse]
        toolbar.sizeToFit()
        tv.inputAccessoryView = toolbar
        return tv
    }
    public func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
    }
    public final class Coordinator: NSObject, UITextViewDelegate {
        let parent: CapsuleTextEditor
        init(_ parent: CapsuleTextEditor) { self.parent = parent }
        public func textViewDidChange(_ textView: UITextView) { parent.text = textView.text }
        @objc func collapse() { parent.onCollapse() }
    }
}

#else
public struct CapsuleTextEditor: View {
    @Binding public var text: String
    public var onAddPhoto: () -> Void
    public var onAddFile: () -> Void
    public var onCollapse: () -> Void
    public init(text: Binding<String>, onAddPhoto: @escaping () -> Void, onAddFile: @escaping () -> Void, onCollapse: @escaping () -> Void) {
        self._text = text
        self.onAddPhoto = onAddPhoto
        self.onAddFile = onAddFile
        self.onCollapse = onCollapse
    }
    public var body: some View {
        TextEditor(text: $text)
            .font(Typography.body)
            .padding(8)
    }
}

#endif
