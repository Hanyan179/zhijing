import SwiftUI
import QuickLook
import UIKit

/// Displays attachments within a message bubble
/// Shows images in a grid layout and files in a list
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
public struct MessageBubbleAttachments: View {
    let attachments: [MessageAttachment]
    let isUserMessage: Bool
    
    /// Selected image URL string (supports both data URLs and file URLs)
    @State private var selectedImageURLString: String?
    @State private var showImageViewer = false
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    
    /// Maximum columns for image grid
    private static let maxColumns = 2
    
    public init(attachments: [MessageAttachment], isUserMessage: Bool = false) {
        self.attachments = attachments
        self.isUserMessage = isUserMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image grid (if any images)
            if !imageAttachments.isEmpty {
                imageGrid
            }
            
            // File list (if any files)
            if !fileAttachments.isEmpty {
                fileList
            }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            if let urlString = selectedImageURLString {
                ImageViewerSheet(imageURLString: urlString, isPresented: $showImageViewer)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var imageAttachments: [(index: Int, attachment: MessageAttachment)] {
        attachments.enumerated()
            .filter { $0.element.type == .image }
            .map { (index: $0.offset + 1, attachment: $0.element) }
    }
    
    private var fileAttachments: [(index: Int, attachment: MessageAttachment)] {
        let imageCount = attachments.filter { $0.type == .image }.count
        return attachments.enumerated()
            .filter { $0.element.type == .file || $0.element.type == .audio }
            .map { (index: imageCount + $0.offset + 1 - imageCount, attachment: $0.element) }
    }
    
    // MARK: - Image Grid
    
    private var imageGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(imageAttachments.enumerated()), id: \.element.attachment.id) { arrayIndex, item in
                IndexedImageThumbnail(
                    index: item.index,
                    attachment: item.attachment,
                    isUserMessage: isUserMessage,
                    onTap: {
                        // Store the URL string directly (works for both data URLs and file URLs)
                        selectedImageURLString = item.attachment.url
                        showImageViewer = true
                    }
                )
            }
        }
    }
    
    // MARK: - File List
    
    private var fileList: some View {
        VStack(spacing: 6) {
            ForEach(Array(fileAttachments.enumerated()), id: \.element.attachment.id) { arrayIndex, item in
                IndexedFileRow(
                    index: imageAttachments.count + arrayIndex + 1,
                    attachment: item.attachment,
                    isUserMessage: isUserMessage,
                    onTap: {
                        openFile(item.attachment)
                    }
                )
            }
        }
    }
    
    // MARK: - File Opening
    
    private func openFile(_ attachment: MessageAttachment) {
        // For files stored as data URLs or base64, we need to save to temp and share
        let urlString = attachment.url
        
        // Check if it's a data URL (base64 encoded)
        if urlString.hasPrefix("data:") {
            saveAndShareDataURL(urlString, fileName: attachment.name ?? "file")
            return
        }
        
        // Try to open as regular URL
        if let url = URL(string: urlString) {
            // Check if it's a file URL
            if url.isFileURL {
                shareURL = url
                showShareSheet = true
            } else {
                // For http/https URLs, open in browser
                #if canImport(UIKit)
                UIApplication.shared.open(url)
                #endif
            }
        }
    }
    
    /// Save data URL content to temp file and share
    private func saveAndShareDataURL(_ dataURL: String, fileName: String) {
        // Parse data URL: data:<mime_type>;base64,<data>
        guard let commaIndex = dataURL.firstIndex(of: ",") else { return }
        
        let base64String = String(dataURL[dataURL.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64String) else { return }
        
        // Create temp file
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            shareURL = tempURL
            showShareSheet = true
        } catch {
            print("[MessageBubbleAttachments] Failed to save temp file: \(error)")
        }
    }
}

// MARK: - Indexed Image Thumbnail

private struct IndexedImageThumbnail: View {
    let index: Int
    let attachment: MessageAttachment
    let isUserMessage: Bool
    let onTap: () -> Void
    
    private static let thumbnailSize: CGFloat = 120
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Image
                imageView
                    .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Index badge
                indexBadge
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var imageView: some View {
        if let uiImage = loadImage() {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Placeholder
            Rectangle()
                .fill(Colors.slateLight)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(Colors.slate500)
                )
        }
    }
    
    /// Load image from URL (supports both data URLs and file URLs)
    /// Requirements: 2.1, 2.3, 2.4
    private func loadImage() -> UIImage? {
        let urlString = attachment.url
        
        // Check if it's a data URL (base64 encoded)
        if urlString.hasPrefix("data:") {
            return loadImageFromDataURL(urlString)
        }
        
        // Try loading from file URL
        if let url = URL(string: urlString),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        
        return nil
    }
    
    /// Parse and load image from data URL format
    /// Format: data:image/jpeg;base64,<base64_data>
    private func loadImageFromDataURL(_ dataURL: String) -> UIImage? {
        // Find the base64 data after the comma
        guard let commaIndex = dataURL.firstIndex(of: ",") else {
            return nil
        }
        
        let base64String = String(dataURL[dataURL.index(after: commaIndex)...])
        
        guard let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    private var indexBadge: some View {
        Text("[\(index)]")
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
            )
            .padding(6)
    }
}

// MARK: - Indexed File Row

private struct IndexedFileRow: View {
    let index: Int
    let attachment: MessageAttachment
    let isUserMessage: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Index badge
                Text("[\(index)]")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(isUserMessage ? .white.opacity(0.8) : Colors.indigo)
                
                // File icon
                Image(systemName: fileIconName)
                    .font(.callout)
                    .foregroundColor(isUserMessage ? .white : fileIconColor)
                
                // File name
                Text(attachment.name ?? "文件")
                    .font(Typography.caption)
                    .foregroundColor(isUserMessage ? .white : Colors.slateText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Open indicator
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(isUserMessage ? .white.opacity(0.6) : Colors.slate500)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isUserMessage ? Color.white.opacity(0.15) : Colors.slateLight)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var fileIconName: String {
        let ext = (attachment.name ?? "").components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "pdf":
            return "doc.fill"
        case "txt", "md":
            return "doc.text.fill"
        case "json":
            return "curlybraces"
        default:
            return attachment.type == .audio ? "waveform" : "doc.fill"
        }
    }
    
    private var fileIconColor: Color {
        let ext = (attachment.name ?? "").components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "pdf":
            return Colors.red
        case "txt", "md":
            return Colors.blue
        case "json":
            return Colors.amber
        default:
            return attachment.type == .audio ? Colors.violet : Colors.indigo
        }
    }
}

// MARK: - Image Viewer Sheet

private struct ImageViewerSheet: View {
    /// Image URL string (supports both data URLs and file URLs)
    let imageURLString: String
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let uiImage = loadImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                // Limit scale range
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                } else if scale > 4.0 {
                                    withAnimation {
                                        scale = 4.0
                                        lastScale = 4.0
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                            } else {
                                scale = 2.0
                                lastScale = 2.0
                            }
                        }
                    }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.5))
                    Text("无法加载图片")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Close button overlay - always visible at top-left
            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60) // Account for status bar
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .statusBarHidden(false)
    }
    
    /// Load image from URL string (supports both data URLs and file URLs)
    private func loadImage() -> UIImage? {
        #if DEBUG
        print("[ImageViewerSheet] Loading image, URL length: \(imageURLString.count)")
        print("[ImageViewerSheet] URL prefix: \(String(imageURLString.prefix(50)))")
        #endif
        
        // Check if it's a data URL (base64 encoded)
        if imageURLString.hasPrefix("data:") {
            let image = loadImageFromDataURL(imageURLString)
            #if DEBUG
            print("[ImageViewerSheet] Data URL load result: \(image != nil ? "success" : "failed")")
            #endif
            return image
        }
        
        // Try loading from file URL
        if let url = URL(string: imageURLString),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        
        #if DEBUG
        print("[ImageViewerSheet] Failed to load image from URL")
        #endif
        return nil
    }
    
    /// Parse and load image from data URL format
    private func loadImageFromDataURL(_ dataURL: String) -> UIImage? {
        guard let commaIndex = dataURL.firstIndex(of: ",") else {
            #if DEBUG
            print("[ImageViewerSheet] No comma found in data URL")
            #endif
            return nil
        }
        
        let base64String = String(dataURL[dataURL.index(after: commaIndex)...])
        
        #if DEBUG
        print("[ImageViewerSheet] Base64 string length: \(base64String.count)")
        #endif
        
        guard let imageData = Data(base64Encoded: base64String) else {
            #if DEBUG
            print("[ImageViewerSheet] Failed to decode base64 data")
            #endif
            return nil
        }
        
        #if DEBUG
        print("[ImageViewerSheet] Decoded data size: \(imageData.count) bytes")
        #endif
        
        return UIImage(data: imageData)
    }
}

// MARK: - Preview

#if DEBUG
struct MessageBubbleAttachments_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // User message with attachments
            MessageBubbleAttachments(
                attachments: [
                    MessageAttachment(type: .image, url: "", name: "photo1.jpg"),
                    MessageAttachment(type: .image, url: "", name: "photo2.png"),
                    MessageAttachment(type: .file, url: "", name: "document.pdf")
                ],
                isUserMessage: true
            )
            .padding()
            .background(Colors.indigo)
            .cornerRadius(18)
            
            // AI message with attachments
            MessageBubbleAttachments(
                attachments: [
                    MessageAttachment(type: .image, url: "", name: "result.jpg"),
                    MessageAttachment(type: .file, url: "", name: "analysis.json")
                ],
                isUserMessage: false
            )
            .padding()
        }
        .padding()
    }
}
#endif
