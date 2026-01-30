//
//  MimeTypeMapping.swift
//  guanji0.34
//
//  MIME 类型映射工具
//  提供文件扩展名与 MIME 类型之间的双向映射
//  - Requirements: 2.1, 2.2, 2.3, 2.4
//

import Foundation

/// MIME 类型映射工具
/// 提供文件扩展名到 MIME 类型的映射，以及类型判断辅助方法
/// - Requirements: 2.1, 2.2, 2.3, 2.4
public struct MimeTypeMapping {
    
    // MARK: - Private Properties
    
    /// 文件扩展名到 MIME 类型的映射
    private static let extensionToMimeType: [String: String] = [
        // 图片 - Requirements: 2.1
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "gif": "image/gif",
        "webp": "image/webp",
        "heic": "image/heic",
        "heif": "image/heic",
        // 文档 - Requirements: 2.4
        "pdf": "application/pdf",
        "txt": "text/plain",
        "md": "text/markdown",
        "markdown": "text/markdown",
        "json": "application/json",
        // 音频 - Requirements: 2.2
        "mp3": "audio/mpeg",
        "wav": "audio/wav",
        "ogg": "audio/ogg",
        // 视频 - Requirements: 2.3
        "mp4": "video/mp4",
        "webm": "video/webm",
        "mov": "video/quicktime",
    ]
    
    /// 文档类型 MIME 列表
    private static let documentMimeTypes: Set<String> = [
        "application/pdf",
        "text/plain",
        "text/markdown",
        "application/json"
    ]
    
    // MARK: - Public Methods
    
    /// 根据文件扩展名获取 MIME 类型
    /// - Parameter extension: 文件扩展名（不含点号）
    /// - Returns: 对应的 MIME 类型，未知扩展名返回 "application/octet-stream"
    public static func mimeType(for `extension`: String) -> String {
        extensionToMimeType[`extension`.lowercased()] ?? "application/octet-stream"
    }
    
    /// 根据 MIME 类型获取文件扩展名
    /// - Parameter mimeType: MIME 类型
    /// - Returns: 对应的文件扩展名，未找到返回 nil
    public static func fileExtension(for mimeType: String) -> String? {
        extensionToMimeType.first { $0.value == mimeType.lowercased() }?.key
    }
    
    /// 检查是否为图片类型
    /// - Parameter mimeType: MIME 类型
    /// - Returns: 是否为图片类型
    public static func isImageType(_ mimeType: String) -> Bool {
        mimeType.lowercased().hasPrefix("image/")
    }
    
    /// 检查是否为文档类型
    /// - Parameter mimeType: MIME 类型
    /// - Returns: 是否为文档类型
    public static func isDocumentType(_ mimeType: String) -> Bool {
        documentMimeTypes.contains(mimeType.lowercased())
    }
    
    /// 检查是否为音频类型
    /// - Parameter mimeType: MIME 类型
    /// - Returns: 是否为音频类型
    public static func isAudioType(_ mimeType: String) -> Bool {
        mimeType.lowercased().hasPrefix("audio/")
    }
    
    /// 检查是否为视频类型
    /// - Parameter mimeType: MIME 类型
    /// - Returns: 是否为视频类型
    public static func isVideoType(_ mimeType: String) -> Bool {
        mimeType.lowercased().hasPrefix("video/")
    }
}
