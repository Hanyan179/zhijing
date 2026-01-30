import SwiftUI

public struct GroupLabel: View {
    public let label: String
    public init(label: String) { self.label = label }
    public var body: some View {
        HStack { Text(label).font(Typography.fontEngraved).foregroundColor(Colors.systemGray) }.padding(.horizontal, 20).padding(.vertical, 8)
    }
}

public struct ListGroup<Content: View>: View {
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .modifier(Materials.glass())
    }
}

public struct ListRow: View {
    public let iconName: String
    public let label: String
    public var value: String?
    public var onClick: (() -> Void)?
    public var isDestructive: Bool
    public var hasArrow: Bool
    public var disabled: Bool
    public init(iconName: String, label: String, value: String? = nil, onClick: (() -> Void)? = nil, isDestructive: Bool = false, hasArrow: Bool = true, disabled: Bool = false) {
        self.iconName = iconName
        self.label = label
        self.value = value
        self.onClick = onClick
        self.isDestructive = isDestructive
        self.hasArrow = hasArrow
        self.disabled = disabled
    }
    public var body: some View {
        let row = HStack {
            HStack(spacing: 12) {
                Image(systemName: iconName).foregroundColor(Colors.systemGray)
                Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(isDestructive ? .red : Colors.slateText)
            }
            Spacer()
            HStack(spacing: 6) {
                if let v = value { Text(v).font(.system(size: 12)).foregroundColor(Colors.systemGray) }
                if hasArrow { Image(systemName: "chevron.right").foregroundColor(Colors.systemGray).font(.system(size: 12)) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)

        Group {
            if let onClick = onClick {
                Button(action: { onClick() }) { row }
                    .disabled(disabled)
            } else {
                row
            }
        }
        .background(Color.white.opacity(0.0))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)
    }
}

public struct ToggleSwitch: View {
    @Binding public var checked: Bool
    public init(checked: Binding<Bool>) { self._checked = checked }
    public var body: some View {
        Button(action: { checked.toggle() }) {
            ZStack(alignment: checked ? .trailing : .leading) {
                Capsule().fill(checked ? Colors.slateDark : Colors.slateLight).frame(width: 40, height: 24)
                Circle().fill(Color.white).frame(width: 20, height: 20).shadow(radius: 1).padding(.horizontal, 2)
            }
        }
    }
}
