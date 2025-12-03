import SwiftUI

public enum Lang: String { case en, zh, zhHant, ja, ko, de, fr, es, it }

public struct AtomContainer<Content: View>: View {
    public let isHighlighted: Bool
    public let content: Content
    public init(isHighlighted: Bool = false, @ViewBuilder content: () -> Content) { self.isHighlighted = isHighlighted; self.content = content() }
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack { content }
                .padding(.vertical, 24)
                .padding(.horizontal, 24)
                .background(isHighlighted ? Color.orange.opacity(0.08) : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(isHighlighted ? Color.orange.opacity(0.3) : Color.clear))
                .clipShape(RoundedRectangle(cornerRadius: 24))
            if isHighlighted {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill").foregroundColor(.orange)
                    Text(Localization.tr("artifactLabel")).font(.system(size: 9, weight: .bold)).foregroundColor(.orange)
                }
                .padding(6)
                .background(Color.white.opacity(0.8))
                .clipShape(Capsule())
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
        }
    }
}

public struct AtomHeader: View {
    public let category: EntryCategory?
    public let isMixed: Bool
    public let lang: Lang
    public init(category: EntryCategory?, isMixed: Bool = false, lang: Lang) { self.category = category; self.isMixed = isMixed; self.lang = lang }
    public var body: some View {
        HStack(spacing: 8) {
            if let cat = category {
                HStack(spacing: 6) {
                    Image(systemName: Icons.categoryIconName(cat)).foregroundColor(Colors.systemGray)
                    Text(Icons.categoryLabel(cat)).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                }
            }
            if isMixed {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.down.forward.fill").foregroundColor(Colors.systemGray)
                    Text(Localization.tr("mixedLabel", lang: lang)).font(.system(size: 8, weight: .regular)).foregroundColor(Colors.systemGray)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
}

public struct AtomTimestamp: View {
    public let timestamp: String
    public init(timestamp: String) { self.timestamp = timestamp }
    public var body: some View {
        HStack { Spacer(); Text(timestamp).font(Typography.fontEngraved).foregroundColor(Colors.systemGray) }.padding(.top, 8)
    }
}

public struct AtomContextReply: View {
    public let text: String
    public init(text: String) { self.text = text }
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrowshape.turn.up.left.fill").foregroundColor(.indigo)
            Text(text).font(.system(size: 11)).foregroundColor(Color.indigo).lineLimit(1)
        }
        .padding(.bottom, 8)
    }
}

public struct MoleculeSealed: View {
    public let date: String
    public let daysLeft: Int
    public let prompt: String?
    public let lang: Lang
    public init(date: String, daysLeft: Int, prompt: String? = nil, lang: Lang) { self.date = date; self.daysLeft = daysLeft; self.prompt = prompt; self.lang = lang }
    public var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill").padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12)).foregroundColor(Colors.systemGray)
                    VStack(spacing: 4) {
                        Text(Localization.tr("sealedMemory", lang: lang)).font(.system(size: 14, weight: .bold)).foregroundColor(Colors.slateText)
                        Text(String(format: Localization.tr("unlocksOn", lang: lang), date)).font(.system(size: 11, weight: .regular, design: .monospaced)).foregroundColor(Colors.systemGray)
                    }
                    if let p = prompt {
                        Text(p).font(.system(size: 12)).foregroundColor(Color(.systemGray2)).blur(radius: 2).padding(.horizontal, 16).padding(.vertical, 8).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(24)
                .modifier(Materials.card())
                Text("+\(daysLeft) " + Localization.tr("daysSuffixShort", lang: lang)).font(.system(size: 9, weight: .bold)).foregroundColor(Colors.systemGray).padding(6).background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 6)).padding(8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}

public struct MoleculeConnection: View {
    public let sender: String
    public let timestamp: String
    public let message: String
    public let isHighlighted: Bool
    public let lang: Lang
    public init(sender: String, timestamp: String, message: String, isHighlighted: Bool = false, lang: Lang) { self.sender = sender; self.timestamp = timestamp; self.message = message; self.isHighlighted = isHighlighted; self.lang = lang }
    public var body: some View {
        VStack(spacing: 8) {
            if isHighlighted {
                HStack { Spacer(); HStack(spacing: 4) { Image(systemName: "trophy.fill").foregroundColor(.orange); Text(Localization.tr("artifactSource", lang: lang)).font(.system(size: 9, weight: .bold)).foregroundColor(.orange) }.padding(6).background(Color.white.opacity(0.8)).clipShape(Capsule()) }
            }
            HStack(spacing: 6) {
                Image(systemName: "heart.fill").foregroundColor(.red)
                Text(Localization.tr("connection", lang: lang)).font(Typography.fontEngraved).foregroundColor(.red)
            }
            Text(message.replacingOccurrences(of: "{sender}", with: sender)).font(.system(size: 16)).foregroundColor(Colors.slateText).frame(maxWidth: .infinity, alignment: .leading)
            AtomTimestamp(timestamp: timestamp)
        }
        .padding(.horizontal, 24)
    }
}

public struct MoleculeEcho: View {
    public let content: String
    public let createdDate: String
    public let lang: Lang
    public init(content: String, createdDate: String, lang: Lang) { self.content = content; self.createdDate = createdDate; self.lang = lang }
    public var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 6) {
                Text(String(format: Localization.tr("noteFrom", lang: lang), createdDate)).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                Image(systemName: "arrow.turn.down.left").foregroundColor(Colors.systemGray)
            }
            Text(content).font(.system(size: 14, weight: .regular, design: .serif)).foregroundColor(Color(.systemGray)).frame(maxWidth: .infinity, alignment: .trailing).overlay(Rectangle().frame(width: 2).foregroundColor(Color(.systemGray4)), alignment: .trailing).padding(.trailing, 4)
        }
        .padding(12)
        .modifier(Materials.glass())
        .padding(.horizontal, 24)
    }
}

public struct MoleculeReview<Content: View>: View {
    public let content: Content
    public let reviewDate: String
    public let isHighlighted: Bool
    public let onJump: () -> Void
    public let lang: Lang
    public init(reviewDate: String, isHighlighted: Bool = false, onJump: @escaping () -> Void, lang: Lang, @ViewBuilder content: () -> Content) { self.content = content(); self.reviewDate = reviewDate; self.isHighlighted = isHighlighted; self.onJump = onJump; self.lang = lang }
    public var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                content
                HStack {
                    Spacer()
                    Button(action: onJump) {
                        HStack(spacing: 6) {
                            Text(String(format: Localization.tr("sentTo", lang: lang), reviewDate)).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
                            Image(systemName: "arrow.right").foregroundColor(Colors.systemGray)
                        }
                    }
                }
            }
            .padding(.leading, isHighlighted ? 24 : 16)
            .overlay(Rectangle().frame(width: 2).foregroundColor(Color(.systemGray3)), alignment: .leading)
            .background(isHighlighted ? Color.orange.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 24)
    }
}
