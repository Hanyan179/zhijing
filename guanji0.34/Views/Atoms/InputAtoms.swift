import SwiftUI

public struct DockContainer<Content: View>: View {
    public let isMenuOpen: Bool
    public let isReplyMode: Bool
    public let content: Content
    public init(isMenuOpen: Bool, isReplyMode: Bool = false, @ViewBuilder content: () -> Content) {
        self.isMenuOpen = isMenuOpen
        self.isReplyMode = isReplyMode
        self.content = content()
    }
    public var body: some View {
        VStack {
            HStack(spacing: 8) { content }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isReplyMode ? Color.indigo.opacity(0.25) : Color.clear, lineWidth: 1))
                .padding(.horizontal, 16)
        }
        .padding(.bottom, isMenuOpen ? 12 : 20)
    }
}

public struct DockRoundButton: View {
    public let onClick: () -> Void
    public var onPressStart: (() -> Void)? = nil
    public var onPressEnd: (() -> Void)? = nil
    public let systemName: String?
    public let active: Bool
    public let rotate: Bool
    public let disabled: Bool
    public init(onClick: @escaping () -> Void, systemName: String? = nil, active: Bool = false, rotate: Bool = false, disabled: Bool = false, onPressStart: (() -> Void)? = nil, onPressEnd: (() -> Void)? = nil) {
        self.onClick = onClick
        self.systemName = systemName
        self.active = active
        self.rotate = rotate
        self.disabled = disabled
        self.onPressStart = onPressStart
        self.onPressEnd = onPressEnd
    }
    public var body: some View {
        Button(action: onClick) {
            if let name = systemName { Image(systemName: name).font(.system(size: 22, weight: .regular)) }
        }
        .frame(width: 36, height: 36)
        .background(active ? Colors.slateDark : Color(.systemGray6))
        .foregroundColor(active ? .white : Colors.slateText)
        .clipShape(Circle())
        .rotationEffect(.degrees(rotate ? 45 : 0))
        .disabled(disabled)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.15).onEnded { _ in onPressStart?() })
        .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { _ in onPressEnd?() })
    }
}

public struct SubmitButton: View {
    public let hasText: Bool
    public let onClick: () -> Void
    public init(hasText: Bool, onClick: @escaping () -> Void) { self.hasText = hasText; self.onClick = onClick }
    public var body: some View {
        Button(action: onClick) { Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)) }
            .frame(width: 36, height: 36)
            .background(hasText ? .indigo : Color(.systemGray5))
            .foregroundColor(.white)
            .clipShape(Circle())
            .opacity(hasText ? 1 : 0.6)
    }
}

public struct RecordingBar: View {
    @State private var pressed = false
    public let isRecording: Bool
    public let duration: Int
    public let onStart: () -> Void
    public let onStop: () -> Void
    public let onCancel: () -> Void
    public init(isRecording: Bool, duration: Int, onStart: @escaping () -> Void, onStop: @escaping () -> Void, onCancel: @escaping () -> Void) { self.isRecording = isRecording; self.duration = duration; self.onStart = onStart; self.onStop = onStop; self.onCancel = onCancel }
    private var durationText: String {
        let m = duration / 60
        let s = duration % 60
        return String(format: "%02d:%02d", m, s)
    }
    public var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                if isRecording { Circle().fill(.white).frame(width: 8, height: 8).opacity(pressed ? 0.5 : 1) }
                Text(isRecording ? durationText : NSLocalizedString("holdToSpeak", comment: "")).font(.system(size: 14, weight: isRecording ? .bold : .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .background(isRecording ? Color.red : Color(.systemGray4))
        .foregroundColor(isRecording ? .white : Color(.systemGray))
        .clipShape(Capsule())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.1).onEnded { _ in pressed = true; onStart() })
        .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { value in pressed = false; if abs(value.translation.width) > 60 { onCancel() } else { onStop() } })
    }
}

public struct ReplyContextBar: View {
    public let text: String
    public let onCancel: () -> Void
    public init(text: String, onCancel: @escaping () -> Void) { self.text = text; self.onCancel = onCancel }
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("replyingTo", comment: "")).font(Typography.fontEngraved).foregroundColor(.indigo)
                Text(text).font(.system(size: 12)).foregroundColor(Colors.slateText).lineLimit(1)
            }
            Spacer()
            Button(action: onCancel) { Image(systemName: "xmark").font(.system(size: 14)) }
        }
        .padding(10)
        .modifier(Materials.card())
        .padding(.horizontal, 20)
    }
}

public struct AttachmentsBar: View {
    public let items: [InputViewModel.AttachmentItem]
    public let onRemove: (String) -> Void
    public init(items: [InputViewModel.AttachmentItem], onRemove: @escaping (String) -> Void) { self.items = items; self.onRemove = onRemove }
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.type == "photo" ? "photo" : "doc").foregroundColor(Colors.systemGray)
                        Text(item.name).font(.system(size: 12)).foregroundColor(Colors.slateText)
                        Button(action: { onRemove(item.id) }) { Image(systemName: "xmark.circle.fill").foregroundColor(Color(.systemGray3)) }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

public struct InputQuickActions: View {
    public let onGallery: () -> Void
    public let onCamera: () -> Void
    public let onRecord: () -> Void
    public let onTimeCapsule: () -> Void
    public let onMood: () -> Void
    public init(onGallery: @escaping () -> Void, onCamera: @escaping () -> Void, onRecord: @escaping () -> Void, onTimeCapsule: @escaping () -> Void, onMood: @escaping () -> Void) {
        self.onGallery = onGallery
        self.onCamera = onCamera
        self.onRecord = onRecord
        self.onTimeCapsule = onTimeCapsule
        self.onMood = onMood
    }
    public var body: some View {
        HStack(spacing: 0) {
            quickActionButton(image: "photo.on.rectangle", tint: Colors.slateText, action: onGallery)
            quickActionButton(image: "camera", tint: Colors.slateText, action: onCamera)
            quickActionButton(image: "waveform", tint: Colors.slateText, action: onRecord)
            quickActionButton(image: "hourglass", tint: Colors.slateText, action: onTimeCapsule)
            quickActionButton(image: "allergens", tint: Colors.slateText, action: onMood)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .modifier(Materials.prism())
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }
    private func quickActionButton(image: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: image)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(tint)
                .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
    }
}
