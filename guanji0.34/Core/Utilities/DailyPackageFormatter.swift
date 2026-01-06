import Foundation

// MARK: - Daily Package Formatter

/// 每日数据包格式化工具 - 将 DailyExtractionPackage 格式化为可导出的文本
public final class DailyPackageFormatter {
    
    public static let shared = DailyPackageFormatter()
    
    private init() {}
    
    // MARK: - Format to JSON
    
    /// 格式化为 JSON 字符串（用于 API 请求）
    public func formatToJSON(_ package: DailyExtractionPackage, prettyPrint: Bool = true) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        
        do {
            let data = try encoder.encode(package)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{ \"error\": \"\(error.localizedDescription)\" }"
        }
    }
    
    // MARK: - Format to Markdown (Human Readable)
    
    /// 格式化为 Markdown 文本（人类可读，用于调试和测试）
    public func formatToMarkdown(_ package: DailyExtractionPackage) -> String {
        var md = ""
        
        // Header
        md += "# 每日数据包: \(package.dayId)\n\n"
        md += "提取时间: \(formatDate(package.extractedAt))\n\n"
        
        // Journal Entries
        if !package.journalEntries.isEmpty {
            md += "## 📝 日记记录\n\n"
            for entry in package.journalEntries {
                md += "### [\(entry.timestamp)] \(entry.type)\n"
                if let category = entry.category {
                    md += "- 分类: \(category)\n"
                }
                md += "- 时态: \(entry.chronology)\n"
                if let targetDate = entry.targetDate {
                    md += "- 目标日期: \(targetDate)\n"
                }
                if let sender = entry.sender {
                    md += "- 发送者: \(sender)\n"
                }
                if let content = entry.content, !content.isEmpty {
                    md += "\n> \(content)\n"
                }
                md += "\n"
            }
        }
        
        // Tracker Record
        if let tracker = package.trackerRecord {
            md += "## 🎯 每日追踪\n\n"
            md += "- 身体能量: \(tracker.bodyEnergy)/100\n"
            md += "- 心情天气: \(tracker.moodWeather)/100\n\n"
            
            if !tracker.activities.isEmpty {
                md += "### 活动列表\n\n"
                for activity in tracker.activities {
                    md += "#### \(activity.activityType)\n"
                    md += "- 同伴类型: \(activity.companions.joined(separator: ", "))\n"
                    if !activity.companionRefs.isEmpty {
                        md += "- 同伴引用: \(activity.companionRefs.joined(separator: ", "))\n"
                    }
                    if !activity.tags.isEmpty {
                        md += "- 标签: \(activity.tags.joined(separator: ", "))\n"
                    }
                    if let details = activity.details, !details.isEmpty {
                        md += "- 详情: \(details)\n"
                    }
                    md += "\n"
                }
            }
        }
        
        // Love Logs
        if !package.loveLogs.isEmpty {
            md += "## 💕 爱表记录\n\n"
            for log in package.loveLogs {
                md += "### [\(log.timestamp)] \(log.senderRef) → \(log.receiverRef)\n"
                md += "> \(log.content)\n\n"
            }
        }
        
        // AI Conversations
        if !package.aiConversations.isEmpty {
            md += "## 🤖 AI对话\n\n"
            for conv in package.aiConversations {
                md += "### [\(conv.timestamp)] 对话 (\(conv.messageCount) 条消息)\n"
                if let topics = conv.topics, !topics.isEmpty {
                    md += "话题: \(topics.joined(separator: ", "))\n"
                }
                md += "\n"
                for msg in conv.messages {
                    let roleLabel = msg.role == "user" ? "👤 用户" : "🤖 AI"
                    md += "**\(roleLabel)**: \(msg.content)\n\n"
                }
            }
        }
        
        // Questions
        if !package.questions.isEmpty {
            md += "## ❓ 问题表\n\n"
            md += "| 问题 | 创建日期 | 间隔天数 | 交付日期 |\n"
            md += "|------|----------|----------|----------|\n"
            for question in package.questions {
                let prompt = question.systemPrompt ?? "-"
                md += "| \(prompt) | \(question.createdAt) | \(question.intervalDays) | \(question.deliveryDate) |\n"
            }
            md += "\n"
        }
        
        return md
    }
    
    // MARK: - Format to API Request Body
    
    /// 格式化为 API 请求体（第一轮：快速分析）
    public func formatForQuickAnalysis(_ package: DailyExtractionPackage) -> String {
        let requestBody: [String: Any] = [
            "dayId": package.dayId,
            "extractedAt": formatDateISO(package.extractedAt),
            "data": [
                "journalEntries": package.journalEntries.map { entryToDict($0) },
                "trackerRecord": package.trackerRecord.map { trackerToDict($0) } as Any,
                "loveLogs": package.loveLogs.map { loveLogToDict($0) },
                "aiConversations": package.aiConversations.map { convToDict($0) },
                "questions": package.questions.map { questionToDict($0) }
            ]
        ]
        
        return dictToJSON(requestBody)
    }
    
    // MARK: - Private Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatDateISO(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    private func entryToDict(_ entry: SanitizedJournalEntry) -> [String: Any] {
        var dict: [String: Any] = [
            "timestamp": entry.timestamp,
            "type": entry.type,
            "chronology": entry.chronology
        ]
        if let category = entry.category { dict["category"] = category }
        if let content = entry.content { dict["content"] = content }
        if let sender = entry.sender { dict["sender"] = sender }
        if let targetDate = entry.targetDate { dict["targetDate"] = targetDate }
        return dict
    }
    
    private func trackerToDict(_ tracker: SanitizedTrackerRecord) -> [String: Any] {
        return [
            "bodyEnergy": tracker.bodyEnergy,
            "moodWeather": tracker.moodWeather,
            "activities": tracker.activities.map { activityToDict($0) }
        ]
    }
    
    private func activityToDict(_ activity: SanitizedActivity) -> [String: Any] {
        var dict: [String: Any] = [
            "activityType": activity.activityType,
            "companions": activity.companions,
            "companionRefs": activity.companionRefs,
            "tags": activity.tags
        ]
        if let details = activity.details { dict["details"] = details }
        return dict
    }
    
    private func loveLogToDict(_ log: SanitizedLoveLog) -> [String: Any] {
        return [
            "timestamp": log.timestamp,
            "senderRef": log.senderRef,
            "receiverRef": log.receiverRef,
            "content": log.content
        ]
    }
    
    private func convToDict(_ conv: AIConversationSummary) -> [String: Any] {
        var dict: [String: Any] = [
            "timestamp": conv.timestamp,
            "messageCount": conv.messageCount,
            "messages": conv.messages.map { ["role": $0.role, "content": $0.content] }
        ]
        if let topics = conv.topics { dict["topics"] = topics }
        return dict
    }
    
    private func questionToDict(_ question: SanitizedQuestion) -> [String: Any] {
        var dict: [String: Any] = [
            "createdAt": question.createdAt,
            "dayId": question.dayId,
            "intervalDays": question.intervalDays,
            "deliveryDate": question.deliveryDate
        ]
        if let prompt = question.systemPrompt { dict["systemPrompt"] = prompt }
        return dict
    }
    
    private func dictToJSON(_ dict: [String: Any]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{ \"error\": \"\(error.localizedDescription)\" }"
        }
    }
}

// MARK: - Convenience Extensions

extension DailyExtractionPackage {
    
    /// 导出为 JSON 字符串
    public func toJSON(prettyPrint: Bool = true) -> String {
        return DailyPackageFormatter.shared.formatToJSON(self, prettyPrint: prettyPrint)
    }
    
    /// 导出为 Markdown 文本
    public func toMarkdown() -> String {
        return DailyPackageFormatter.shared.formatToMarkdown(self)
    }
    
    /// 导出为 API 请求体
    public func toAPIRequestBody() -> String {
        return DailyPackageFormatter.shared.formatForQuickAnalysis(self)
    }
}
