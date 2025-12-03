import SwiftUI

public struct CapsuleCard: View {
    public let question: QuestionEntry
    public let sourceEntry: JournalEntry?
    public let replies: [JournalEntry]
    public let onInitiateReply: () -> Void
    public var onJumpToDate: ((String) -> Void)?
    public var onCollapse: (() -> Void)?
    public let lang: Lang
    public init(question: QuestionEntry, sourceEntry: JournalEntry? = nil, replies: [JournalEntry], onInitiateReply: @escaping () -> Void, onJumpToDate: ((String) -> Void)? = nil, onCollapse: (() -> Void)? = nil, lang: Lang) {
        self.question = question
        self.sourceEntry = sourceEntry
        self.replies = replies
        self.onInitiateReply = onInitiateReply
        self.onJumpToDate = onJumpToDate
        self.onCollapse = onCollapse
        self.lang = lang
    }

    private var hasReplies: Bool { !replies.isEmpty }
    private var originLabel: String { question.created_at }

    private var groupedReplies: [String: [JournalEntry]] {
        var acc: [String: [JournalEntry]] = [:]
        for reply in replies {
            let key = reply.metadata?.createdDate ?? "Today"
            acc[key, default: []].append(reply)
        }
        return acc
    }

    private var sortedDates: [String] { groupedReplies.keys.sorted() }

    public var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 32).fill(LinearGradient(colors: [Color.indigo.opacity(0.1), .white], startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 32).stroke(Color.indigo.opacity(0.3))
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "clock").foregroundColor(.indigo)
                                Text(NSLocalizedString("fromThePast", comment: "")).font(.system(size: 10, weight: .bold)).foregroundColor(.indigo)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.indigo.opacity(0.1))
                            .clipShape(Capsule())
                            Text(originLabel).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(Color.indigo.opacity(0.6))
                            Spacer()
                            if let collapse = onCollapse { Button(action: collapse) { Image(systemName: "chevron.up").foregroundColor(Color.indigo.opacity(0.6)) }.padding(4) }
                        }
                        if let prompt = question.system_prompt, !prompt.isEmpty {
                            Text(prompt).font(.system(size: 18, weight: .medium, design: .serif)).foregroundColor(Colors.slatePrimary)
                        } else {
                            Text(NSLocalizedString("lockedMemory", comment: "")).font(.system(size: 14)).foregroundColor(Colors.systemGray).italic()
                        }
                        if let src = sourceEntry {
                            Button(action: { onJumpToDate?(question.created_at) }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "quote.opening").foregroundColor(Color.indigo.opacity(0.6))
                                        Text(NSLocalizedString("contextLabel", comment: "")).font(.system(size: 10, weight: .bold)).foregroundColor(Color.indigo.opacity(0.6))
                                    }
                                    SpecialContentRenderer(entry: src)
                                }
                                .padding(.leading, 8)
                                .overlay(Rectangle().frame(width: 2).foregroundColor(Color.indigo.opacity(0.3)), alignment: .leading)
                            }
                        }
                    }
                    .padding(16)

                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(Color.indigo.opacity(0.2)).overlay(Divider().opacity(0))
                        Text(NSLocalizedString("echoesLabel", comment: "")).font(.system(size: 9, weight: .bold)).foregroundColor(Color.indigo.opacity(0.6)).padding(.horizontal, 12).padding(.vertical, 6).background(Color.white.opacity(0.8)).clipShape(Capsule()).overlay(Capsule().stroke(Color.indigo.opacity(0.2)))
                        Rectangle().frame(height: 1).foregroundColor(Color.indigo.opacity(0.2)).overlay(Divider().opacity(0))
                    }
                    .padding(.vertical, 8)

                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 12) {
                            if hasReplies {
                                ForEach(sortedDates, id: \.self) { date in
                                    VStack(alignment: .leading, spacing: 8) {
                                        if sortedDates.count > 1 {
                                            HStack(spacing: 6) {
                                                Image(systemName: "calendar").foregroundColor(Colors.systemGray)
                                                Text(date).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(Colors.systemGray)
                                                Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
                                            }
                                        }
                                        VStack(spacing: 8) {
                                            ForEach(groupedReplies[date] ?? [], id: \.id) { reply in
                                                VStack(alignment: .leading, spacing: 6) {
                                                    SpecialContentRenderer(entry: reply, textStyle: .system(size: 15))
                                                    HStack { Spacer(); Text(reply.timestamp).font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundColor(Colors.systemGray) }
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 6) {
                                    Text(NSLocalizedString("waitingEchoes", comment: "")).font(.system(size: 12)).foregroundColor(Colors.systemGray).italic()
                                }
                                .padding(.vertical, 12)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.5))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.6)))
                        .clipShape(RoundedRectangle(cornerRadius: 24))

                        VStack {
                            Button(action: onInitiateReply) {
                                HStack {
                                    Text(hasReplies ? NSLocalizedString("appendReply", comment: "") : NSLocalizedString("writeReply", comment: "")).font(.system(size: 12, weight: .bold)).foregroundColor(.indigo)
                                    Spacer()
                                    Circle().fill(Color.indigo.opacity(0.1)).frame(width: 24, height: 24).overlay(Image(systemName: "arrowshape.turn.up.left.fill").foregroundColor(.indigo).font(.system(size: 12)))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5)))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .background(Color.indigo.opacity(0.04))
                }
            }
            .shadow(color: Color.indigo.opacity(0.06), radius: 30, x: 0, y: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
