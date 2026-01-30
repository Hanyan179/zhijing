import SwiftUI

/// Attachment preview bar for AI conversation mode
/// Displays indexed attachments with thumbnails and remove buttons
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
public struct AttachmentPreviewBar: View {
    let attachments: [IndexedAttachment]
    let onRemove: (String) -> Void
    
    public init(attachments: [IndexedAttachment], onRemove: @escaping (String) -> Void) {
        self.attachments = attachments
        self.onRemove = onRemove
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    AttachmentPreviewItem(
                        attachment: attachment,
                        onRemove: { onRemove(attachment.id) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

/// Single attachment preview item with index badge
/// Requirements: 4.2, 4.3, 4.4, 8.1, 8.2, 8.3
public struct AttachmentPreviewItem: View {
    let attachment: IndexedAttachment
    let onRemove: () -> Void
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                // Index badge
                Text("[\(attachment.index)]")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Colors.indigo)
                
                // Thumbnail or icon
                thumbnailView
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // File name (truncated)
                Text(attachment.attachment.name ?? "附件")
                    .font(.caption2)
                    .foregroundColor(Colors.slate600)
                    .lineLimit(1)
                    .frame(maxWidth: 50)
            }
            .padding(6)
            .background(Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.callout)
                    .foregroundColor(Color(.systemGray))
                    .background(Circle().fill(Color.white))
            }
            .offset(x: 4, y: -4)
            
            // Processing indicator
            if attachment.processingState == .processing {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailData = attachment.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Fallback icon based on type
            ZStack {
                Color(.systemGray6)
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(Colors.slate600)
            }
        }
    }
    
    private var iconName: String {
        switch attachment.attachment.type {
        case .image:
            return "photo"
        case .audio:
            return "waveform"
        case .file:
            return "doc"
        }
    }
}

#if DEBUG
struct AttachmentPreviewBar_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentPreviewBar(
            attachments: [
                IndexedAttachment(
                    index: 1,
                    attachment: MessageAttachment(type: .image, url: "", name: "photo1.jpg"),
                    processingState: .ready
                ),
                IndexedAttachment(
                    index: 2,
                    attachment: MessageAttachment(type: .image, url: "", name: "photo2.png"),
                    processingState: .processing
                ),
                IndexedAttachment(
                    index: 3,
                    attachment: MessageAttachment(type: .file, url: "", name: "document.pdf"),
                    processingState: .ready
                )
            ],
            onRemove: { _ in }
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif
