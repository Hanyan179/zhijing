import SwiftUI

public struct LocationBadge: View {
    public let location: LocationVO
    public var onClick: (() -> Void)?
    public var align: HorizontalAlignment
    public init(location: LocationVO, onClick: (() -> Void)? = nil, alignRight: Bool = false) {
        self.location = location
        self.onClick = onClick
        self.align = alignRight ? .trailing : .leading
    }

    private func color(_ name: String?) -> (bg: Color, fg: Color, border: Color) {
        switch name {
        case "indigo": return (Color.indigo.opacity(0.1), Color.indigo, Color.indigo.opacity(0.2))
        case "amber": return (Color.orange.opacity(0.1), Color.orange, Color.orange.opacity(0.2))
        case "rose": return (Color.pink.opacity(0.1), Color.pink, Color.pink.opacity(0.2))
        case "emerald": return (Color.green.opacity(0.1), Color.green, Color.green.opacity(0.2))
        case "sky": return (Color.blue.opacity(0.1), Color.blue, Color.blue.opacity(0.2))
        case "fuchsia": return (Color.purple.opacity(0.1), Color.purple, Color.purple.opacity(0.2))
        default: return (Color(.systemGray6), Color(.systemGray), Color(.systemGray5))
        }
    }

    private func iconName(_ name: String?) -> String {
        switch name {
        case "home": return "house"
        case "briefcase": return "briefcase"
        case "coffee": return "cup.and.saucer"
        case "star": return "star"
        case "heart": return "heart"
        case "school": return "graduationcap"
        case "vacation": return "beach.umbrella"
        default: return "mappin"
        }
    }

    public var body: some View {
        if location.status == .no_permission { EmptyView() } else {
            let isMapped = location.status == .mapped
            let c = color(location.color)
            Button(action: {
                if location.status == .raw { onClick?() }
            }) {
                HStack(spacing: 8) {
                    Group {
                        if isMapped {
                            HStack {
                                Image(systemName: iconName(location.icon)).foregroundColor(c.fg)
                            }
                            .padding(6)
                            .background(c.bg)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(c.border))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "location.north").foregroundColor(Color(.systemGray))
                        }
                    }
                    Text(location.displayText)
                        .font(.system(size: 13, weight: isMapped ? .bold : .medium))
                        .foregroundColor(isMapped ? Colors.slateText : Color(.systemGray))
                        .underline(!isMapped, color: Color(.systemGray3))
                }
            }
            .disabled(location.status != .raw)
            .frame(maxWidth: .infinity, alignment: align == .trailing ? .trailing : .leading)
        }
    }
}
