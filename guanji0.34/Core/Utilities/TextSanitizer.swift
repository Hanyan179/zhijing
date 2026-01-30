import Foundation

// MARK: - Text Sanitizer

/// 文本脱敏工具 - 统一人物标识 + 敏感数字脱敏
public final class TextSanitizer {
    
    // MARK: - Name Mapping
    
    /// 名称 → 关系信息 映射表
    private var nameMap: [String: (relationshipId: String, displayName: String, type: String)] = [:]
    
    /// 已知名称集合（用于快速查找）
    private var knownNames: Set<String> = []
    
    // MARK: - Init
    
    public init() {}
    
    /// 从关系列表构建映射表
    public func buildNameMap(from relationships: [NarrativeRelationship]) {
        nameMap.removeAll()
        knownNames.removeAll()
        
        for relationship in relationships {
            let entry = (relationship.id, relationship.displayName, relationship.type.rawValue)
            
            // 1. displayName
            nameMap[relationship.displayName] = entry
            knownNames.insert(relationship.displayName)
            
            // 2. realName (如果有)
            if let realName = relationship.realName, !realName.isEmpty {
                nameMap[realName] = entry
                knownNames.insert(realName)
            }
            
            // 3. 所有 aliases
            for alias in relationship.aliases {
                nameMap[alias] = entry
                knownNames.insert(alias)
            }
        }
    }
    
    // MARK: - Sanitize Text
    
    /// 脱敏文本：统一人物标识 + 敏感数字
    public func sanitize(_ text: String?) -> String? {
        guard let text = text, !text.isEmpty else { return nil }
        
        var result = text
        
        // 1. 替换已知关系名称为统一标识符
        result = replaceKnownNames(in: result)
        
        // 2. 脱敏敏感数字
        result = maskSensitiveNumbers(result)
        
        return result
    }
    
    /// 脱敏人名字段（如 sender/receiver）
    public func sanitizeName(_ name: String?) -> String? {
        guard let name = name, !name.isEmpty else { return nil }
        
        // 检查是否是已知关系
        if let (relId, displayName, _) = nameMap[name] {
            return "[REL_\(relId):\(displayName)]"
        }
        
        // 检查是否是 "Me" 或 "我"
        if name == "Me" || name == "我" {
            return "Me"
        }
        
        // 未知人物，标记但保留
        return "[UNKNOWN_PERSON:\(name)]"
    }
    
    // MARK: - Private Methods
    
    /// 替换已知关系名称
    private func replaceKnownNames(in text: String) -> String {
        var result = text
        
        // 按名称长度降序排序，避免短名称先匹配
        let sortedNames = nameMap.keys.sorted { $0.count > $1.count }
        
        for name in sortedNames {
            guard let (relId, displayName, _) = nameMap[name] else { continue }
            let identifier = "[REL_\(relId):\(displayName)]"
            result = result.replacingOccurrences(of: name, with: identifier)
        }
        
        return result
    }
    
    /// 脱敏敏感数字
    private func maskSensitiveNumbers(_ text: String) -> String {
        var result = text
        
        // 手机号: 1[3-9]xxxxxxxxx
        if let phoneRegex = try? NSRegularExpression(pattern: "1[3-9]\\d{9}") {
            result = phoneRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "[PHONE]"
            )
        }
        
        // 身份证: 18位数字（最后一位可能是X）
        if let idCardRegex = try? NSRegularExpression(pattern: "\\d{17}[\\dXx]") {
            result = idCardRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "[ID_CARD]"
            )
        }
        
        // 邮箱
        if let emailRegex = try? NSRegularExpression(pattern: "[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}") {
            result = emailRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "[EMAIL]"
            )
        }
        
        // 银行卡: 16-19位数字（放最后，避免误匹配手机号）
        if let bankCardRegex = try? NSRegularExpression(pattern: "(?<!\\d)\\d{16,19}(?!\\d)") {
            result = bankCardRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "[BANK_CARD]"
            )
        }
        
        return result
    }
    
    // MARK: - Utility
    
    /// 生成关系上下文列表（供 AI 参考）
    public func generateRelationshipContexts(from relationships: [NarrativeRelationship]) -> [RelationshipContext] {
        return relationships.map { rel in
            RelationshipContext(
                id: rel.id,
                ref: "[REL_\(rel.id):\(rel.displayName)]",
                type: rel.type.rawValue,
                displayName: rel.displayName,
                aliases: rel.aliases  // 不包含 realName
            )
        }
    }
}
