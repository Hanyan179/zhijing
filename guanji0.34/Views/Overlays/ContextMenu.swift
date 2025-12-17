import SwiftUI

public struct ContextMenuState {
    public let x: CGFloat
    public let y: CGFloat
    public let entryId: String
    public let currentContent: String?
    public let type: EntryType
    public init(x: CGFloat, y: CGFloat, entryId: String, currentContent: String? = nil, type: EntryType) { self.x = x; self.y = y; self.entryId = entryId; self.currentContent = currentContent; self.type = type }
}

public struct ContextMenuOverlay: View {
    public let state: ContextMenuState
    public let onClose: () -> Void
    public let onSelect: (EntryCategory) -> Void
    public let onEdit: (String) -> Void
    public let lang: Lang
    @EnvironmentObject private var appState: AppState
    @State private var isEditing = false
    @State private var editValue: String
    public init(state: ContextMenuState, onClose: @escaping () -> Void, onSelect: @escaping (EntryCategory) -> Void, onEdit: @escaping (String) -> Void, lang: Lang) {
        self.state = state
        self.onClose = onClose
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.lang = lang
        _editValue = State(initialValue: state.currentContent ?? "")
    }

    private var isContentEditable: Bool { state.type == .text || state.type == .audio || state.type == .image }
    private var categories: [EntryCategory] { [.health, .emotion, .social, .work, .life] }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.0001).ignoresSafeArea().onTapGesture { onClose() }
            if isEditing {
                VStack(spacing: 8) {
                    Text(Localization.tr("edit", lang: lang)).font(Typography.fontEngraved)
                    TextEditor(text: $editValue).frame(height: 120).padding(8).background(Color.white.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Colors.slateLight)).clipShape(RoundedRectangle(cornerRadius: 12))
                    HStack { Spacer(); Button(Localization.tr("cancel", lang: lang)) { onClose() }; Button(Localization.tr("save", lang: lang)) { onEdit(editValue); onClose() } }
                }
                .padding(12)
                .frame(width: 300)
                .modifier(Materials.card())
            } else {
                GeometryReader { geo in
                    let w: CGFloat = 320
                    let h: CGFloat = 64
                    let posX = max(w/2, min(state.x, geo.size.width - w/2))
                    let upY = state.y - (h/2 + 20)
                    let downY = state.y + (h/2 + 20)
                    let posY = upY > h/2 ? upY : min(downY, geo.size.height - h/2)
                    CategoryPillBar(categories: categories,
                                    onSelect: { cat in onSelect(cat); onClose() },
                                    onEdit: (isContentEditable ? { appState.editingEntryId = state.entryId; appState.editingDraft = state.currentContent ?? ""; onClose() } : nil),
                                    dark: false)
                        .frame(width: w, height: h)
                        .position(x: posX, y: posY)
                }
            }
        }
        .zIndex(999)
    }
}
