import SwiftUI

public struct ImageEntry: View {
    public let src: String
    public init(src: String) { self.src = src }
    @State private var loaded = false
    public var body: some View {
        ZStack {
            if !loaded {
                Rectangle().fill(Color(.systemGray6)).overlay(ProgressView()).transition(.opacity)
            }
            AsyncImage(url: URL(string: src)) { phase in
                switch phase {
                case .empty:
                    Color.clear
                case .success(let image):
                    image.resizable().scaledToFill().grayscale(0.2).onAppear { loaded = true }
                case .failure:
                    VStack(spacing: 8) {
                        Image(systemName: "photo").foregroundColor(.gray)
                        Text(NSLocalizedString("noImageSource", comment: "")).font(Typography.fontEngraved).foregroundColor(.gray)
                    }
                @unknown default:
                    Color.clear
                }
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

public struct AudioEntry: View {
    @State private var isPlaying = false
    public let duration: String
    public let content: String?
    public init(duration: String, content: String? = nil) { self.duration = duration; self.content = content }
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: { isPlaying.toggle() }) {
                    ZStack {
                        Circle().fill(isPlaying ? Colors.slateText : .white)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill").foregroundColor(isPlaying ? .white : .gray)
                    }
                }
                .frame(width: 40, height: 40)
                HStack(spacing: 2) {
                    ForEach(0..<30, id: \.self) { i in
                        Rectangle()
                            .fill(isPlaying ? Colors.slateText : Color(.systemGray3))
                            .frame(width: 3, height: barHeight(i))
                            .opacity(isPlaying ? 0.8 : 0.5)
                    }
                }
                Spacer()
                Text(duration).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
            }
            if let txt = (content?.trimmingCharacters(in: .whitespacesAndNewlines)), !txt.isEmpty {
                Text(txt).font(.system(size: 14)).foregroundColor(Colors.slateText).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func barHeight(_ i: Int) -> CGFloat {
        let h = 30 + sin(Double(i) * 0.6) * 40 + cos(Double(i) * 0.3) * 20
        return CGFloat(max(20, min(100, h)))
    }
}

public struct SpecialContentRenderer: View {
    public let entry: JournalEntry?
    public let fallback: String?
    public let textStyle: Font?
    public init(entry: JournalEntry?, fallback: String? = nil, textStyle: Font? = nil) { self.entry = entry; self.fallback = fallback; self.textStyle = textStyle }
    public var body: some View {
        Group {
            if let e = entry {
                switch e.type {
                case .mixed:
                    if let blocks = e.metadata?.blocks {
                        VStack(spacing: 12) {
                            ForEach(Array(blocks.enumerated()), id: \.offset) { _, b in
                                switch b.type {
                                case .text:
                                    Text(b.content).font(textStyle ?? .system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
                                case .image:
                                    VStack(alignment: .leading, spacing: 4) {
                                        ImageEntry(src: b.url ?? b.content)
                                        if b.content.count > 0 && b.url != nil {
                                            Text(b.content).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                                        }
                                    }
                                case .audio:
                                    AudioEntry(duration: b.duration ?? "00:15", content: b.content)
                                case .mixed:
                                    EmptyView()
                                }
                            }
                        }
                    }
                case .image:
                    VStack(alignment: .leading, spacing: 6) {
                        if let u = e.url { ImageEntry(src: u) }
                        if let c = e.content { Text(c).font(textStyle ?? .system(size: 14)).foregroundColor(Color(.systemGray)) }
                    }
                case .audio:
                    AudioEntry(duration: e.metadata?.duration ?? "00:15", content: e.content)
                default:
                    Text(e.content ?? "").font(textStyle ?? .system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(fallback ?? NSLocalizedString("dataNotFound", comment: "")).font(.system(size: 12)).foregroundColor(Color(.systemGray3))
            }
        }
    }
}
