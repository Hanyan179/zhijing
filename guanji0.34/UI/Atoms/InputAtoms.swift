import SwiftUI

public struct DockContainer<Content: View>: View {
    public let isMenuOpen: Bool
    public let isReplyMode: Bool
    public let isFocused: Bool
    public let content: Content
    
    public init(isMenuOpen: Bool, isReplyMode: Bool = false, isFocused: Bool = false, @ViewBuilder content: () -> Content) {
        self.isMenuOpen = isMenuOpen
        self.isReplyMode = isReplyMode
        self.isFocused = isFocused
        self.content = content()
    }
    
    public var body: some View {
        VStack {
            HStack(spacing: 8) { content }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                // Requirement 6.1: Distinct background color for input area
                .background(inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                // Requirement 6.3: Focus state with subtle shadow
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
                // Requirement 6.3: Focus state with subtle border
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .padding(.horizontal, 16)
        }
        .padding(.bottom, isMenuOpen ? 12 : 20)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    // MARK: - Computed Properties for Styling
    
    /// Background color - distinct from messages area (Requirement 6.1)
    private var inputBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.secondarySystemBackground
                : UIColor.white
        })
    }
    
    /// Border color based on focus and reply state (Requirement 6.3)
    private var borderColor: Color {
        if isReplyMode {
            return Colors.indigo.opacity(0.4)
        } else if isFocused {
            return Colors.indigo.opacity(0.3)
        } else {
            return Color(.systemGray4).opacity(0.5)
        }
    }
    
    /// Border width based on focus state
    private var borderWidth: CGFloat {
        isFocused || isReplyMode ? 1.5 : 1
    }
    
    /// Shadow color based on focus state (Requirement 6.3)
    private var shadowColor: Color {
        if isFocused {
            return Colors.indigo.opacity(0.15)
        } else {
            return Color.black.opacity(0.06)
        }
    }
    
    /// Shadow radius based on focus state
    private var shadowRadius: CGFloat {
        isFocused ? 12 : 8
    }
    
    /// Shadow Y offset based on focus state
    private var shadowY: CGFloat {
        isFocused ? 6 : 4
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
            if let name = systemName { Image(systemName: name).font(.title2) }
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
    
    public init(hasText: Bool, onClick: @escaping () -> Void) {
        self.hasText = hasText
        self.onClick = onClick
    }
    
    public var body: some View {
        // Requirement 6.4: Visual prominence for send button
        // Requirement 6.5: Hide/disable when empty
        Button(action: onClick) {
            Image(systemName: "arrow.up")
                .font(.body.weight(.bold))
        }
        .frame(width: 36, height: 36)
        .background(buttonBackground)
        .foregroundColor(.white)
        .clipShape(Circle())
        // Requirement 6.5: Disable when no text
        .disabled(!hasText)
        // Requirement 6.4 & 6.5: Show/hide based on text content
        .opacity(hasText ? 1 : 0.4)
        .scaleEffect(hasText ? 1 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasText)
    }
    
    /// Button background with visual prominence when active (Requirement 6.4)
    private var buttonBackground: some View {
        Group {
            if hasText {
                // Active state: prominent indigo with subtle gradient
                LinearGradient(
                    colors: [Colors.indigo, Colors.indigo.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // Inactive state: muted gray
                Color(.systemGray5)
            }
        }
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
                Text(isRecording ? durationText : NSLocalizedString("holdToSpeak", comment: "")).font(.footnote.weight(isRecording ? .bold : .medium))
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
                Text(text).font(.caption).foregroundColor(Colors.slateText).lineLimit(1)
            }
            Spacer()
            Button(action: onCancel) { Image(systemName: "xmark").font(.footnote) }
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
                        Text(item.name).font(.caption).foregroundColor(Colors.slateText)
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
    public let onFile: () -> Void
    public let onMore: () -> Void
    public let onModeToggle: (() -> Void)?
    public let onVoiceCall: (() -> Void)?
    
    // Configuration flags
    public let showGallery: Bool
    public let showCamera: Bool
    public let showRecord: Bool
    public let showTimeCapsule: Bool
    public let showMood: Bool
    public let showFile: Bool
    public let showMore: Bool
    public let showModeToggle: Bool
    public let showVoiceCall: Bool
    
    // Current mode for toggle button icon
    public let currentMode: AppMode
    
    // Disabled state for mood button (when daily tracker already completed)
    public let isMoodDisabled: Bool
    
    public init(onGallery: @escaping () -> Void, 
                onCamera: @escaping () -> Void, 
                onRecord: @escaping () -> Void, 
                onTimeCapsule: @escaping () -> Void, 
                onMood: @escaping () -> Void, 
                onFile: @escaping () -> Void, 
                onMore: @escaping () -> Void,
                onModeToggle: (() -> Void)? = nil,
                onVoiceCall: (() -> Void)? = nil,
                showGallery: Bool = true,
                showCamera: Bool = true,
                showRecord: Bool = true,
                showTimeCapsule: Bool = true,
                showMood: Bool = true,
                showFile: Bool = true,
                showMore: Bool = true,
                showModeToggle: Bool = false,
                showVoiceCall: Bool = false,
                currentMode: AppMode = .journal,
                isMoodDisabled: Bool = false) {
        self.onGallery = onGallery
        self.onCamera = onCamera
        self.onRecord = onRecord
        self.onTimeCapsule = onTimeCapsule
        self.onMood = onMood
        self.onFile = onFile
        self.onMore = onMore
        self.onModeToggle = onModeToggle
        self.onVoiceCall = onVoiceCall
        
        self.showGallery = showGallery
        self.showCamera = showCamera
        self.showRecord = showRecord
        self.showTimeCapsule = showTimeCapsule
        self.showMood = showMood
        self.showFile = showFile
        self.showMore = showMore
        self.showModeToggle = showModeToggle
        self.showVoiceCall = showVoiceCall
        self.currentMode = currentMode
        self.isMoodDisabled = isMoodDisabled
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                if showGallery { quickActionButton(image: "photo.on.rectangle", label: "相册", action: onGallery) }
                if showCamera { quickActionButton(image: "camera", label: "相机", action: onCamera) }
                if showRecord { quickActionButton(image: "waveform", label: "录音", action: onRecord) }
                if showTimeCapsule { quickActionButton(image: "hourglass", label: "胶囊", action: onTimeCapsule) }
                if showMood { 
                    quickActionButton(
                        image: isMoodDisabled ? "checkmark.circle.fill" : "face.smiling", 
                        label: "心情", 
                        action: isMoodDisabled ? {} : onMood,
                        isDisabled: isMoodDisabled
                    ) 
                }
                if showFile { quickActionButton(image: "paperclip", label: "文件", action: onFile) }
                // Voice call button (AI mode only)
                if showVoiceCall { 
                    quickActionButton(image: "phone.fill", label: "通话", action: { onVoiceCall?() }) 
                }
                if showMore {
                    quickActionButton(image: "ellipsis.circle", label: "更多", action: onMore)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.4), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
    }
    
    private func quickActionButton(image: String, label: String, action: @escaping () -> Void, isDisabled: Bool = false, tintColor: Color? = nil) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: image)
                    .font(.title2)
                    .foregroundColor(tintColor ?? (isDisabled ? Colors.teal : Colors.slateText))
                    .opacity(isDisabled ? 0.6 : 1.0)
                    .frame(width: 24, height: 24)
            }
            .foregroundColor(Colors.slateText)
        }
    }
}
