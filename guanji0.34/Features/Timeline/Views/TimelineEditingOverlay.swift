import SwiftUI

public struct TimelineEditingOverlay: View {
    public let entryId: String
    @Binding public var draft: String
    public let onSave: () -> Void
    public let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    public init(entryId: String, draft: Binding<String>, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.entryId = entryId
        self._draft = draft
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationStack {
            TextEditor(text: $draft)
                .focused($isFocused)
                .font(Typography.body)
                .padding()
                .navigationTitle(Localization.tr("edit"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.tr("cancel")) {
                            onCancel()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Localization.tr("done")) {
                            onSave()
                        }
                    }
                }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}
