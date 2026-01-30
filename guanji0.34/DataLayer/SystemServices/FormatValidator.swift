//
//  FormatValidator.swift
//  guanji0.34
//
//  格式校验器
//  根据模型能力配置验证文件格式和大小
//  - Requirements: 3.1, 4.1, 4.4, 7.1, 7.2, 7.3, 7.4
//

import Foundation

// MARK: - Format Validation Result

/// 格式校验结果
/// 表示文件格式或大小校验的结果
public enum FormatValidationResult: Equatable {
    /// 校验通过
    case valid
    /// MIME 类型不支持
    case unsupportedMimeType(actual: String, supported: [String])
    /// 文件过大
    case fileTooLarge(actual: Int, max: Int, isImage: Bool)
    /// 附件数量超限
    case tooManyAttachments(current: Int, max: Int)
}

// MARK: - Format Validator

/// 格式校验器
/// 根据当前模型的能力配置验证文件 MIME 类型和大小
/// - Requirements: 3.1, 4.1, 4.4
public struct FormatValidator {
    
    // MARK: - MIME Type Validation
    
    /// 验证文件 MIME 类型
    /// - Parameters:
    ///   - mimeType: 文件的 MIME 类型
    ///   - capability: 当前模型的能力配置
    /// - Returns: 校验结果
    /// - Requirement: 3.1
    public static func validateMimeType(
        _ mimeType: String,
        capability: ModelCapability
    ) -> FormatValidationResult {
        if capability.isMimeTypeSupported(mimeType) {
            return .valid
        }
        return .unsupportedMimeType(
            actual: mimeType,
            supported: capability.allSupportedMimeTypes
        )
    }
    
    // MARK: - Size Validation
    
    /// 验证文件大小
    /// - Parameters:
    ///   - size: 文件大小（字节）
    ///   - mimeType: 文件的 MIME 类型
    ///   - capability: 当前模型的能力配置
    /// - Returns: 校验结果
    /// - Requirement: 4.1, 4.4
    public static func validateSize(
        _ size: Int,
        mimeType: String,
        capability: ModelCapability
    ) -> FormatValidationResult {
        let isImage = capability.supportedImageTypes.contains(mimeType.lowercased())
        let maxSize = capability.getSizeLimit(for: mimeType)
        
        if size <= maxSize {
            return .valid
        }
        return .fileTooLarge(actual: size, max: maxSize, isImage: isImage)
    }
    
    // MARK: - Attachment Count Validation
    
    /// 验证附件数量
    /// - Parameters:
    ///   - currentCount: 当前附件数量
    ///   - addingCount: 要添加的附件数量
    ///   - capability: 当前模型的能力配置
    /// - Returns: 校验结果
    public static func validateAttachmentCount(
        currentCount: Int,
        addingCount: Int,
        capability: ModelCapability
    ) -> FormatValidationResult {
        let totalCount = currentCount + addingCount
        if totalCount <= capability.maxAttachmentCount {
            return .valid
        }
        return .tooManyAttachments(current: totalCount, max: capability.maxAttachmentCount)
    }
    
    // MARK: - Compatibility Check
    
    /// 检查附件与模型的兼容性
    /// 用于模型切换时检查已选附件是否与新模型兼容
    /// - Parameters:
    ///   - attachments: 附件列表
    ///   - capability: 目标模型的能力配置
    /// - Returns: 不兼容的附件列表
    /// - Requirement: 3.4, 3.5, 4.5, 8.1
    public static func checkCompatibility(
        attachments: [IndexedAttachment],
        capability: ModelCapability
    ) -> [IndexedAttachment] {
        attachments.filter { attachment in
            let mimeType = getMimeType(for: attachment)
            
            // Check MIME type compatibility
            let mimeResult = validateMimeType(mimeType, capability: capability)
            if case .unsupportedMimeType = mimeResult {
                return true // Incompatible
            }
            
            // Check size compatibility
            if let size = getFileSize(for: attachment) {
                let sizeResult = validateSize(size, mimeType: mimeType, capability: capability)
                if case .fileTooLarge = sizeResult {
                    return true // Incompatible
                }
            }
            
            return false // Compatible
        }
    }
    
    // MARK: - Private Helpers
    
    /// 获取附件的 MIME 类型
    /// - Parameter attachment: 附件
    /// - Returns: MIME 类型字符串
    private static func getMimeType(for attachment: IndexedAttachment) -> String {
        let fileName = attachment.attachment.name ?? ""
        let ext = (fileName as NSString).pathExtension.lowercased()
        return MimeTypeMapping.mimeType(for: ext)
    }
    
    /// 获取附件的文件大小
    /// - Parameter attachment: 附件
    /// - Returns: 文件大小（字节），如果无法确定则返回 nil
    private static func getFileSize(for attachment: IndexedAttachment) -> Int? {
        if let base64 = attachment.base64Data {
            // Base64 解码后大小约为编码大小的 3/4
            return (base64.count * 3) / 4
        }
        return nil
    }
}


// MARK: - Format Validation Error Message

/// 格式校验错误消息生成器
/// 生成用户友好的错误消息和格式转换建议
/// - Requirements: 7.1, 7.2, 7.3, 7.4
public struct FormatValidationErrorMessage {
    
    // MARK: - Message Generation
    
    /// 生成用户友好的错误消息
    /// - Parameters:
    ///   - result: 校验结果
    ///   - language: 语言代码（默认 "zh"）
    /// - Returns: 用户友好的错误消息
    /// - Requirements: 7.1, 7.2, 7.3, 7.4
    public static func message(
        for result: FormatValidationResult,
        language: String = "zh"
    ) -> String {
        let isZh = language.lowercased().hasPrefix("zh")
        
        switch result {
        case .valid:
            return ""
            
        case .unsupportedMimeType(let actual, let supported):
            return unsupportedMimeTypeMessage(
                actual: actual,
                supported: supported,
                isZh: isZh
            )
            
        case .fileTooLarge(let actual, let max, let isImage):
            return fileTooLargeMessage(
                actual: actual,
                max: max,
                isImage: isImage,
                isZh: isZh
            )
            
        case .tooManyAttachments(let current, let max):
            return tooManyAttachmentsMessage(
                current: current,
                max: max,
                isZh: isZh
            )
        }
    }
    
    // MARK: - Suggestion Generation
    
    /// 生成格式转换建议
    /// 针对常见不支持格式提供转换建议
    /// - Parameters:
    ///   - mimeType: 不支持的 MIME 类型
    ///   - language: 语言代码（默认 "zh"）
    /// - Returns: 格式转换建议，如果没有建议则返回 nil
    /// - Requirements: 7.2
    public static func suggestion(
        for mimeType: String,
        language: String = "zh"
    ) -> String? {
        let isZh = language.lowercased().hasPrefix("zh")
        let ext = MimeTypeMapping.fileExtension(for: mimeType) ?? extractExtension(from: mimeType)
        
        // 常见不支持格式的转换建议
        switch ext.lowercased() {
        case "doc", "docx":
            return isZh ? "建议转换为 PDF 格式" : "Consider converting to PDF"
        case "xls", "xlsx":
            return isZh ? "建议导出为 CSV 或 JSON 格式" : "Consider exporting as CSV or JSON"
        case "ppt", "pptx":
            return isZh ? "建议导出为 PDF 格式" : "Consider exporting as PDF"
        case "bmp", "tiff", "tif":
            return isZh ? "建议转换为 PNG 或 JPEG 格式" : "Consider converting to PNG or JPEG"
        case "avi", "wmv", "flv":
            return isZh ? "建议转换为 MP4 格式" : "Consider converting to MP4"
        case "wma", "aac", "flac":
            return isZh ? "建议转换为 MP3 格式" : "Consider converting to MP3"
        default:
            return nil
        }
    }
    
    /// 根据文件扩展名生成格式转换建议
    /// - Parameters:
    ///   - fileExtension: 文件扩展名
    ///   - language: 语言代码（默认 "zh"）
    /// - Returns: 格式转换建议，如果没有建议则返回 nil
    public static func suggestion(
        forExtension fileExtension: String,
        language: String = "zh"
    ) -> String? {
        let isZh = language.lowercased().hasPrefix("zh")
        
        switch fileExtension.lowercased() {
        case "doc", "docx":
            return isZh ? "建议转换为 PDF 格式" : "Consider converting to PDF"
        case "xls", "xlsx":
            return isZh ? "建议导出为 CSV 或 JSON 格式" : "Consider exporting as CSV or JSON"
        case "ppt", "pptx":
            return isZh ? "建议导出为 PDF 格式" : "Consider exporting as PDF"
        case "bmp", "tiff", "tif":
            return isZh ? "建议转换为 PNG 或 JPEG 格式" : "Consider converting to PNG or JPEG"
        case "avi", "wmv", "flv":
            return isZh ? "建议转换为 MP4 格式" : "Consider converting to MP4"
        case "wma", "aac", "flac":
            return isZh ? "建议转换为 MP3 格式" : "Consider converting to MP3"
        default:
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    /// 生成不支持 MIME 类型的错误消息
    /// - Requirements: 7.1, 7.2
    private static func unsupportedMimeTypeMessage(
        actual: String,
        supported: [String],
        isZh: Bool
    ) -> String {
        let ext = MimeTypeMapping.fileExtension(for: actual) ?? extractExtension(from: actual)
        let supportedExts = supported.compactMap { MimeTypeMapping.fileExtension(for: $0) }
        let uniqueExts = Array(Set(supportedExts)).sorted()
        let supportedList = uniqueExts.prefix(5).joined(separator: ", ")
        
        if isZh {
            if ext.isEmpty {
                return "不支持此文件格式。支持的格式：\(supportedList) 等"
            }
            return "不支持 .\(ext) 格式。支持的格式：\(supportedList) 等"
        } else {
            if ext.isEmpty {
                return "This file format is not supported. Supported: \(supportedList), etc."
            }
            return ".\(ext) format not supported. Supported: \(supportedList), etc."
        }
    }
    
    /// 生成文件过大的错误消息
    /// - Requirements: 7.3
    private static func fileTooLargeMessage(
        actual: Int,
        max: Int,
        isImage: Bool,
        isZh: Bool
    ) -> String {
        let actualStr = formatFileSize(actual, isZh: isZh)
        let maxStr = formatFileSize(max, isZh: isZh)
        let typeStr = isImage ? (isZh ? "图片" : "Image") : (isZh ? "文件" : "File")
        
        if isZh {
            return "\(typeStr)过大：\(actualStr)，最大 \(maxStr)"
        } else {
            return "\(typeStr) too large: \(actualStr), max \(maxStr)"
        }
    }
    
    /// 生成附件数量超限的错误消息
    private static func tooManyAttachmentsMessage(
        current: Int,
        max: Int,
        isZh: Bool
    ) -> String {
        if isZh {
            return "附件数量超限：\(current) 个，最多 \(max) 个"
        } else {
            return "Too many attachments: \(current), max \(max)"
        }
    }
    
    /// 格式化文件大小
    private static func formatFileSize(_ bytes: Int, isZh: Bool) -> String {
        let kb = 1024
        let mb = kb * 1024
        let gb = mb * 1024
        
        if bytes >= gb {
            let value = Double(bytes) / Double(gb)
            return String(format: "%.1f GB", value)
        } else if bytes >= mb {
            let value = Double(bytes) / Double(mb)
            return String(format: "%.1f MB", value)
        } else if bytes >= kb {
            let value = Double(bytes) / Double(kb)
            return String(format: "%.1f KB", value)
        } else {
            return isZh ? "\(bytes) 字节" : "\(bytes) bytes"
        }
    }
    
    /// 从 MIME 类型中提取扩展名
    private static func extractExtension(from mimeType: String) -> String {
        // 尝试从 MIME 类型中提取扩展名
        // 例如 "application/vnd.ms-excel" -> "xls"
        let components = mimeType.split(separator: "/")
        guard components.count == 2 else { return "" }
        
        let subtype = String(components[1]).lowercased()
        
        // 常见的 MIME 子类型到扩展名映射
        let subtypeToExt: [String: String] = [
            "vnd.ms-excel": "xls",
            "vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx",
            "msword": "doc",
            "vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
            "vnd.ms-powerpoint": "ppt",
            "vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
            "x-msvideo": "avi",
            "x-ms-wmv": "wmv",
            "x-flv": "flv",
            "x-ms-wma": "wma",
            "x-aac": "aac",
            "x-flac": "flac",
            "bmp": "bmp",
            "tiff": "tiff",
        ]
        
        return subtypeToExt[subtype] ?? ""
    }
}
