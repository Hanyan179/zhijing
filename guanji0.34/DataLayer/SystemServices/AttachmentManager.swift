import Foundation
import UIKit
import Combine

// MARK: - Attachment Error

/// Error types for attachment operations
public enum AttachmentError: Error, LocalizedError, Equatable {
    /// File type not supported
    case unsupportedType(String)
    /// File exceeds size limit (actual bytes, max bytes)
    case fileTooLarge(Int, Int)
    /// Too many attachments selected
    case tooManyAttachments(Int)
    /// Processing failed with reason
    case processingFailed(String)
    /// File not found at path
    case fileNotFound
    /// Incompatible attachments when switching models
    case incompatibleAttachments([IndexedAttachment])
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedType(let type):
            return "不支持的文件类型: \(type)"
        case .fileTooLarge(let actual, let max):
            let actualMB = actual / 1024 / 1024
            let maxMB = max / 1024 / 1024
            return "文件过大: \(actualMB)MB，最大 \(maxMB)MB"
        case .tooManyAttachments(let max):
            return "附件数量超限，最多 \(max) 个"
        case .processingFailed(let reason):
            return "处理失败: \(reason)"
        case .fileNotFound:
            return "文件不存在"
        case .incompatibleAttachments(let attachments):
            let names = attachments.compactMap { $0.attachment.name }.joined(separator: ", ")
            return "以下附件与新模型不兼容: \(names)"
        }
    }
}

// MARK: - Attachment Manager

/// Manages attachment selection, validation, processing, and indexing
/// - Note: Handles image compression, Base64 encoding, and thumbnail generation
/// - Requirements: 3.1-3.5, 4.1-4.5, 8.1, 8.4, 9.1
@MainActor
public final class AttachmentManager: ObservableObject {
    
    // MARK: - Configuration Constants
    
    /// Maximum number of attachments per message
    public static let maxAttachmentCount = 10
    
    /// Maximum image file size in bytes (20MB)
    public static let maxImageSizeBytes = 20 * 1024 * 1024
    
    /// Maximum document file size in bytes (50MB)
    public static let maxFileSizeBytes = 50 * 1024 * 1024
    
    /// Supported image file extensions
    public static let supportedImageTypes = ["jpeg", "jpg", "png", "gif", "webp", "heic"]
    
    /// Supported document file extensions
    public static let supportedDocTypes = ["pdf", "txt", "md", "json", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "csv", "rtf", "xml", "html", "htm"]
    
    /// All supported file extensions
    public static var supportedTypes: [String] {
        supportedImageTypes + supportedDocTypes
    }
    
    /// Thumbnail size for preview
    private static let thumbnailSize = CGSize(width: 120, height: 120)
    
    /// JPEG compression quality for Base64 encoding
    private static let compressionQuality: CGFloat = 0.8
    
    /// Default model ID for format validation
    private static let defaultModelId = "gemini-2.5-flash"
    
    // MARK: - Published State
    
    /// Pending attachments waiting to be sent
    @Published public private(set) var pendingAttachments: [IndexedAttachment] = []
    
    /// Whether any attachment is currently being processed
    @Published public private(set) var isProcessing: Bool = false
    
    /// Current error message (if any)
    @Published public var errorMessage: String?
    
    /// Current model ID for format validation
    /// - Requirements: 3.1, 8.1
    @Published public private(set) var currentModelId: String = defaultModelId
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// Get attachments that are ready to send (processingState == .ready)
    public func getReadyAttachments() -> [IndexedAttachment] {
        pendingAttachments.filter { $0.processingState == .ready }
    }
    
    /// Check if all attachments are ready to send
    public var allAttachmentsReady: Bool {
        !pendingAttachments.isEmpty && pendingAttachments.allSatisfy { $0.processingState == .ready }
    }
    
    /// Check if any attachment is still processing
    public var hasProcessingAttachments: Bool {
        pendingAttachments.contains { $0.processingState == .processing }
    }
    
    /// Current attachment count
    public var attachmentCount: Int {
        pendingAttachments.count
    }
    
    /// Check if can add more attachments
    public var canAddMoreAttachments: Bool {
        pendingAttachments.count < Self.maxAttachmentCount
    }
    
    // MARK: - Validation Methods
    
    /// Validate file type from URL
    /// - Parameter url: File URL to validate
    /// - Returns: AttachmentType if valid, error otherwise
    public func validateFileType(_ url: URL) -> Result<AttachmentType, AttachmentError> {
        let fileExtension = url.pathExtension.lowercased()
        
        guard !fileExtension.isEmpty else {
            return .failure(.unsupportedType("unknown"))
        }
        
        if Self.supportedImageTypes.contains(fileExtension) {
            return .success(.image)
        } else if Self.supportedDocTypes.contains(fileExtension) {
            return .success(.file)
        } else {
            return .failure(.unsupportedType(fileExtension))
        }
    }
    
    /// Validate file size based on type
    /// - Parameters:
    ///   - url: File URL to validate
    ///   - type: Attachment type (determines size limit)
    /// - Returns: Success if valid, error otherwise
    public func validateFileSize(_ url: URL, type: AttachmentType) -> Result<Void, AttachmentError> {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attributes[.size] as? Int else {
                return .failure(.fileNotFound)
            }
            
            let maxSize = type == .image ? Self.maxImageSizeBytes : Self.maxFileSizeBytes
            
            if fileSize > maxSize {
                return .failure(.fileTooLarge(fileSize, maxSize))
            }
            
            return .success(())
        } catch {
            return .failure(.fileNotFound)
        }
    }
    
    // MARK: - Model Capability Integration
    
    /// Set the current model for format validation
    /// - Parameter modelId: The model ID to use for validation
    /// - Requirements: 3.1, 8.1
    public func setCurrentModel(_ modelId: String) {
        currentModelId = modelId
    }
    
    /// Get the current model capability configuration
    /// Falls back to default Gemini configuration if model not found
    /// - Requirements: 9.1, 9.2
    public var currentCapability: ModelCapability {
        ModelCapabilityRegistry.shared.getCapability(for: currentModelId)
            ?? .gemini3FlashPreview
    }
    
    /// Validate file type using model capability configuration
    /// - Parameter url: File URL to validate
    /// - Returns: AttachmentType if valid, error otherwise
    /// - Requirements: 3.1, 3.2, 3.3
    public func validateFileTypeWithCapability(_ url: URL) -> Result<AttachmentType, AttachmentError> {
        let fileExtension = url.pathExtension.lowercased()
        let mimeType = MimeTypeMapping.mimeType(for: fileExtension)
        
        let result = FormatValidator.validateMimeType(mimeType, capability: currentCapability)
        
        switch result {
        case .valid:
            if MimeTypeMapping.isImageType(mimeType) {
                return .success(.image)
            } else if MimeTypeMapping.isAudioType(mimeType) {
                return .success(.audio)
            } else {
                return .success(.file)
            }
        case .unsupportedMimeType:
            let message = FormatValidationErrorMessage.message(for: result)
            return .failure(.unsupportedType(message))
        default:
            return .failure(.unsupportedType(fileExtension))
        }
    }
    
    /// Validate file size using model capability configuration
    /// - Parameters:
    ///   - url: File URL to validate
    ///   - type: Attachment type (used to determine MIME type category)
    /// - Returns: Success if valid, error otherwise
    /// - Requirements: 4.1, 4.2, 4.3, 4.4
    public func validateFileSizeWithCapability(
        _ url: URL,
        type: AttachmentType
    ) -> Result<Void, AttachmentError> {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attributes[.size] as? Int else {
                return .failure(.fileNotFound)
            }
            
            let mimeType = MimeTypeMapping.mimeType(for: url.pathExtension)
            let result = FormatValidator.validateSize(
                fileSize,
                mimeType: mimeType,
                capability: currentCapability
            )
            
            switch result {
            case .valid:
                return .success(())
            case .fileTooLarge(let actual, let max, _):
                return .failure(.fileTooLarge(actual, max))
            default:
                return .failure(.fileNotFound)
            }
        } catch {
            return .failure(.fileNotFound)
        }
    }
    
    /// Check attachment compatibility when switching models
    /// - Parameter newModelId: The target model ID to switch to
    /// - Returns: Array of incompatible attachments (empty if all compatible)
    /// - Requirements: 8.1, 8.2, 8.3
    public func checkModelSwitchCompatibility(
        to newModelId: String
    ) -> [IndexedAttachment] {
        guard let newCapability = ModelCapabilityRegistry.shared.getCapability(for: newModelId) else {
            // If model not found, assume all attachments are compatible
            return []
        }
        
        return FormatValidator.checkCompatibility(
            attachments: pendingAttachments,
            capability: newCapability
        )
    }
    
    /// Remove incompatible attachments and renumber remaining ones
    /// - Parameter attachments: Array of attachments to remove
    /// - Requirements: 8.4
    public func removeIncompatibleAttachments(_ attachments: [IndexedAttachment]) {
        let idsToRemove = Set(attachments.map { $0.id })
        pendingAttachments.removeAll { idsToRemove.contains($0.id) }
        renumberAttachments()
    }
    
    // MARK: - Add Attachments
    
    /// Add images from UIImage array
    /// - Parameter images: Array of UIImage to add
    /// - Returns: Array of added IndexedAttachments
    @discardableResult
    public func addImages(_ images: [UIImage]) async throws -> [IndexedAttachment] {
        // Check attachment count limit
        let newCount = pendingAttachments.count + images.count
        guard newCount <= Self.maxAttachmentCount else {
            let error = AttachmentError.tooManyAttachments(Self.maxAttachmentCount)
            errorMessage = error.localizedDescription
            throw error
        }
        
        isProcessing = true
        errorMessage = nil
        
        var addedAttachments: [IndexedAttachment] = []
        
        for image in images {
            let nextIndex = pendingAttachments.count + 1
            
            // Create initial attachment with pending state
            let attachment = MessageAttachment(
                type: .image,
                url: "",
                name: "image_\(nextIndex).jpg"
            )
            
            var indexedAttachment = IndexedAttachment(
                index: nextIndex,
                attachment: attachment,
                processingState: .processing
            )
            
            pendingAttachments.append(indexedAttachment)
            
            // Process image asynchronously
            do {
                let (base64Data, thumbnailData) = try await processImage(image)
                
                // Update attachment with processed data
                indexedAttachment = indexedAttachment.with(
                    base64Data: base64Data,
                    thumbnailData: thumbnailData,
                    processingState: .ready
                )
                
                // Update in array
                if let idx = pendingAttachments.firstIndex(where: { $0.id == indexedAttachment.id }) {
                    pendingAttachments[idx] = indexedAttachment
                }
                
                addedAttachments.append(indexedAttachment)
            } catch {
                // Mark as failed
                indexedAttachment = indexedAttachment.with(processingState: .failed)
                if let idx = pendingAttachments.firstIndex(where: { $0.id == indexedAttachment.id }) {
                    pendingAttachments[idx] = indexedAttachment
                }
                errorMessage = "图片处理失败"
            }
        }
        
        isProcessing = false
        return addedAttachments
    }
    
    /// Add files from URL array
    /// - Parameter urls: Array of file URLs to add
    /// - Returns: Array of added IndexedAttachments
    @discardableResult
    public func addFiles(_ urls: [URL]) async throws -> [IndexedAttachment] {
        print("[AttachmentManager] addFiles called with \(urls.count) URLs")
        
        // Check attachment count limit
        let newCount = pendingAttachments.count + urls.count
        guard newCount <= Self.maxAttachmentCount else {
            let error = AttachmentError.tooManyAttachments(Self.maxAttachmentCount)
            errorMessage = error.localizedDescription
            throw error
        }
        
        isProcessing = true
        errorMessage = nil
        
        var addedAttachments: [IndexedAttachment] = []
        
        for url in urls {
            print("[AttachmentManager] Processing file: \(url.lastPathComponent), extension: \(url.pathExtension)")
            
            // Validate file type
            let typeResult = validateFileType(url)
            guard case .success(let attachmentType) = typeResult else {
                if case .failure(let error) = typeResult {
                    print("[AttachmentManager] File type validation failed: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
                continue
            }
            
            print("[AttachmentManager] File type validated: \(attachmentType)")
            
            // Validate file size
            let sizeResult = validateFileSize(url, type: attachmentType)
            guard case .success = sizeResult else {
                if case .failure(let error) = sizeResult {
                    print("[AttachmentManager] File size validation failed: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
                continue
            }
            
            print("[AttachmentManager] File size validated")
            
            let nextIndex = pendingAttachments.count + 1
            let fileName = url.lastPathComponent
            
            // Create initial attachment with pending state
            let attachment = MessageAttachment(
                type: attachmentType,
                url: url.absoluteString,
                name: fileName
            )
            
            var indexedAttachment = IndexedAttachment(
                index: nextIndex,
                attachment: attachment,
                processingState: .processing
            )
            
            pendingAttachments.append(indexedAttachment)
            print("[AttachmentManager] Added attachment to pending list, count: \(pendingAttachments.count)")
            
            // Process file asynchronously
            do {
                let (base64Data, thumbnailData) = try await processFile(url, type: attachmentType)
                
                print("[AttachmentManager] File processed successfully, base64 length: \(base64Data.count)")
                
                // Update attachment with processed data
                indexedAttachment = indexedAttachment.with(
                    base64Data: base64Data,
                    thumbnailData: thumbnailData,
                    processingState: .ready
                )
                
                // Update in array
                if let idx = pendingAttachments.firstIndex(where: { $0.id == indexedAttachment.id }) {
                    pendingAttachments[idx] = indexedAttachment
                }
                
                addedAttachments.append(indexedAttachment)
                print("[AttachmentManager] Attachment ready, total ready: \(addedAttachments.count)")
            } catch {
                print("[AttachmentManager] File processing failed: \(error.localizedDescription)")
                // Mark as failed
                indexedAttachment = indexedAttachment.with(processingState: .failed)
                if let idx = pendingAttachments.firstIndex(where: { $0.id == indexedAttachment.id }) {
                    pendingAttachments[idx] = indexedAttachment
                }
                errorMessage = "文件处理失败: \(fileName)"
            }
        }
        
        isProcessing = false
        print("[AttachmentManager] addFiles completed, total attachments: \(pendingAttachments.count)")
        return addedAttachments
    }
    
    // MARK: - Remove Attachments
    
    /// Remove attachment at specified index and renumber remaining attachments
    /// - Parameter index: 1-based index of attachment to remove
    public func removeAttachment(at index: Int) {
        guard let arrayIndex = pendingAttachments.firstIndex(where: { $0.index == index }) else {
            return
        }
        
        pendingAttachments.remove(at: arrayIndex)
        renumberAttachments()
    }
    
    /// Remove attachment by ID
    /// - Parameter id: Attachment ID to remove
    public func removeAttachment(id: String) {
        pendingAttachments.removeAll { $0.id == id }
        renumberAttachments()
    }
    
    /// Clear all pending attachments
    public func clearAll() {
        pendingAttachments.removeAll()
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// Renumber attachments to maintain consecutive 1-based indices
    private func renumberAttachments() {
        pendingAttachments = pendingAttachments.enumerated().map { arrayIndex, attachment in
            attachment.with(index: arrayIndex + 1)
        }
    }
    
    /// Process image: compress and encode to Base64, generate thumbnail
    /// - Parameter image: UIImage to process
    /// - Returns: Tuple of (base64Data, thumbnailData)
    private func processImage(_ image: UIImage) async throws -> (String, Data?) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Generate Base64 data
                guard let imageData = image.jpegData(compressionQuality: Self.compressionQuality) else {
                    continuation.resume(throwing: AttachmentError.processingFailed("无法压缩图片"))
                    return
                }
                
                let base64String = imageData.base64EncodedString()
                
                // Generate thumbnail
                let thumbnailData = self.generateThumbnail(from: image)
                
                continuation.resume(returning: (base64String, thumbnailData))
            }
        }
    }
    
    /// Process file: read and encode to Base64, generate thumbnail if image
    /// - Parameters:
    ///   - url: File URL to process
    ///   - type: Attachment type
    /// - Returns: Tuple of (base64Data, thumbnailData)
    private func processFile(_ url: URL, type: AttachmentType) async throws -> (String, Data?) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Start accessing security-scoped resource
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    let fileData = try Data(contentsOf: url)
                    let base64String = fileData.base64EncodedString()
                    
                    // Generate thumbnail for images
                    var thumbnailData: Data? = nil
                    if type == .image, let image = UIImage(data: fileData) {
                        thumbnailData = self.generateThumbnail(from: image)
                    }
                    
                    continuation.resume(returning: (base64String, thumbnailData))
                } catch {
                    continuation.resume(throwing: AttachmentError.processingFailed(error.localizedDescription))
                }
            }
        }
    }
    
    /// Generate thumbnail from image
    /// - Parameter image: Source image
    /// - Returns: Thumbnail data as JPEG
    private func generateThumbnail(from image: UIImage) -> Data? {
        let size = Self.thumbnailSize
        let aspectRatio = image.size.width / image.size.height
        
        var targetSize: CGSize
        if aspectRatio > 1 {
            // Landscape
            targetSize = CGSize(width: size.width, height: size.width / aspectRatio)
        } else {
            // Portrait or square
            targetSize = CGSize(width: size.height * aspectRatio, height: size.height)
        }
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail?.jpegData(compressionQuality: 0.7)
    }
}
