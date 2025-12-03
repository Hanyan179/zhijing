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
    private var categories: [EntryCategory] { [.emotion, .work, .idea, .social, .dream, .media] }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.0001).ignoresSafeArea().onTapGesture { onClose() }
            if isEditing {
                VStack(spacing: 8) {
                    Text(Localization.tr("edit", lang: lang)).font(Typography.fontEngraved)
                    TextEditor(text: $editValue).frame(height: 120).padding(8).background(Color.white.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4))).clipShape(RoundedRectangle(cornerRadius: 12))
                    HStack { Spacer(); Button(Localization.tr("cancel", lang: lang)) { onClose() }; Button(Localization.tr("save", lang: lang)) { onEdit(editValue); onClose() } }
                }
                .padding(12)
                .frame(width: 300)
                .modifier(Materials.card())
            } else {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        if isContentEditable {
                            Button(action: { isEditing = true }) {
                                HStack(spacing: 8) { Image(systemName: "pencil").foregroundColor(Colors.systemGray); Text(Localization.tr("edit", lang: lang)).font(.system(size: 12, weight: .medium)).foregroundColor(Colors.slate600) }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
                        }
                        HStack(spacing: 6) { Image(systemName: "tag").foregroundColor(Color(.systemGray3)); Text(Localization.tr("categoryLabel", lang: lang)).font(Typography.fontEngraved).foregroundColor(Color(.systemGray3)) }.padding(.horizontal, 12).padding(.vertical, 6)
                        ForEach(categories, id: \.self) { cat in
                            Button(action: { onSelect(cat); onClose() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: Icons.categoryIconName(cat)).foregroundColor(Colors.systemGray)
                                    Text(Icons.categoryLabel(cat)).font(.system(size: 12)).foregroundColor(Colors.slate500)
                                }
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                        }
                    }
                    .padding(.vertical, 8)
                    .modifier(Materials.glass())
                    .frame(width: 180)
                    .position(x: min(state.x, geo.size.width - 180), y: min(state.y, geo.size.height - 300))
                }
            }
        }
        .zIndex(999)
    }
}
