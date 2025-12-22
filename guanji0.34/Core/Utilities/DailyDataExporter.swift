import Foundation

/// Daily data exporter - exports all data for a specific day as plain text
public enum DailyDataExporter {
    
    // MARK: - Public API
    
    /// Export all data for a specific day as plain text
    /// - Parameter dayId: Date string in yyyy.MM.dd format
    /// - Returns: Plain text export of all day's data
    public static func exportDay(_ dayId: String) -> String {
        var output = ""
        
        // Header
        output += String(repeating: "=", count: 60) + "\n"
        output += "观己 Guanji - 每日数据导出\n"
        output += "Daily Data Export\n"
        output += String(repeating: "=", count: 60) + "\n"
        output += "日期 Date: \(dayId)\n"
        output += "导出时间 Exported: \(formatDateTime(Date()))\n"
        output += String(repeating: "=", count: 60) + "\n\n"
        
        var hasData = false
        
        // 1. Timeline Data
        let timeline = TimelineRepository.shared.getDailyTimeline(for: dayId)
        if !timeline.items.isEmpty || timeline.title != nil || timeline.weather != nil {
            output += exportTimeline(timeline)
            hasData = true
        }
        
        // 2. AI Conversations
        let conversations = AIConversationRepository.shared.getConversations(for: dayId)
        if !conversations.isEmpty {
            output += exportConversations(conversations)
            hasData = true
        }
        
        // 3. Questions
        let questions = QuestionRepository.shared.getAll().filter { $0.dayId == dayId }
        if !questions.isEmpty {
            output += exportQuestions(questions)
            hasData = true
        }
        
        // 4. Mind State
        let mindStates = MindStateRepository().load(for: dayId)
        if !mindStates.isEmpty {
            output += exportMindStates(mindStates)
            hasData = true
        }
        
        // 5. Daily Tracker
        if let tracker = DailyTrackerRepository.shared.load(for: dayId) {
            output += exportTracker(tracker)
            hasData = true
        }
        
        // Footer
        if !hasData {
            output += "📭 当日无数据记录\n"
            output += "📭 No data recorded for this day\n\n"
        }
        
        output += String(repeating: "=", count: 60) + "\n"
        output += "导出完成 Export Complete\n"
        output += String(repeating: "=", count: 60) + "\n"
        
        return output
    }
    
    // MARK: - Timeline Export
    
    private static func exportTimeline(_ timeline: DailyTimeline) -> String {
        var output = "## 📅 时间轴 Timeline\n\n"
        
        if let title = timeline.title {
            output += "**标题 Title**: \(title)\n"
        }
        
        if let weather = timeline.weather {
            output += "**天气 Weather**: \(weather)\n"
        }
        
        if !timeline.tags.isEmpty {
            let tagNames = timeline.tags.map { $0.rawValue }.joined(separator: ", ")
            output += "**标签 Tags**: \(tagNames)\n"
        }
        
        output += "\n"
        
        for item in timeline.items {
            switch item {
            case .scene(let scene):
                output += exportScene(scene)
            case .journey(let journey):
                output += exportJourney(journey)
            }
        }
        
        output += "\n"
        return output
    }
    
    private static func exportScene(_ scene: SceneGroup) -> String {
        var output = "### 📍 场景 Scene: \(scene.location.displayText)\n"
        output += "**时间 Time**: \(scene.timeRange)\n"
        
        if let icon = scene.location.icon {
            output += "**图标 Icon**: \(icon)\n"
        }
        
        output += "\n"
        
        for entry in scene.entries {
            output += exportJournalEntry(entry)
        }
        
        output += "\n"
        return output
    }
    
    private static func exportJourney(_ journey: JourneyBlock) -> String {
        var output = "### 🚗 旅程 Journey\n"
        output += "**起点 From**: \(journey.origin.displayText)\n"
        output += "**终点 To**: \(journey.destination.displayText)\n"
        output += "**方式 Mode**: \(journey.mode.rawValue)\n"
        // Duration field removed in v0.34.1
        output += "\n"
        
        for entry in journey.entries {
            output += exportJournalEntry(entry)
        }
        
        output += "\n"
        return output
    }
    
    private static func exportJournalEntry(_ entry: JournalEntry) -> String {
        var output = "[\(entry.timestamp)] "
        
        // Category
        if let category = entry.category {
            output += "[\(category.rawValue)] "
        }
        
        // Chronology
        switch entry.chronology {
        case .past:
            output += "[过去 Past] "
        case .present:
            output += "[现在 Present] "
        case .future:
            output += "[未来 Future] "
        }
        
        // Content
        if let content = entry.content {
            output += content
        } else {
            // Media types
            switch entry.type {
            case .image:
                output += "[图片 Image]"
            case .video:
                output += "[视频 Video]"
            case .audio:
                output += "[音频 Audio]"
            case .file:
                output += "[文件 File]"
            case .mixed:
                output += "[混合内容 Mixed Content]"
            case .text:
                output += "[文本 Text]"
            }
        }
        
        output += "\n"
        return output
    }
    
    // MARK: - AI Conversations Export
    
    private static func exportConversations(_ conversations: [AIConversation]) -> String {
        var output = "## 💬 AI 对话 AI Conversations\n\n"
        
        for conv in conversations {
            if let title = conv.title {
                output += "### 对话 Conversation: \(title)\n\n"
            } else {
                output += "### 对话 Conversation\n\n"
            }
            
            for message in conv.sortedMessages {
                let role = message.role == .user ? "👤 我 Me" : "🤖 AI"
                output += "**\(role)** [\(formatTime(message.timestamp))]\n"
                output += message.content + "\n\n"
                
                if let reasoning = message.reasoningContent {
                    output += "_💭 思考过程 Thinking: \(reasoning)_\n\n"
                }
            }
            
            output += String(repeating: "-", count: 40) + "\n\n"
        }
        
        return output
    }
    
    // MARK: - Questions Export
    
    private static func exportQuestions(_ questions: [QuestionEntry]) -> String {
        var output = "## ❓ 问题与思考 Questions & Reflections\n\n"
        
        for question in questions {
            if let prompt = question.system_prompt {
                output += "**问题 Question**: \(prompt)\n"
            }
            output += "**创建时间 Created**: \(question.created_at)\n"
            output += "**交付日期 Delivery**: \(question.delivery_date)\n"
            output += "**间隔天数 Interval**: \(question.interval_days) 天 days\n\n"
        }
        
        output += "\n"
        return output
    }
    
    // MARK: - Mind State Export
    
    private static func exportMindStates(_ mindStates: [MindStateRecord]) -> String {
        var output = "## 🧠 心境记录 Mind State Records\n\n"
        
        for state in mindStates {
            output += "**情绪值 Valence**: \(state.valenceValue)\n"
            
            if !state.labels.isEmpty {
                output += "**标签 Labels**: \(state.labels.joined(separator: ", "))\n"
            }
            
            if !state.influences.isEmpty {
                output += "**影响因素 Influences**: \(state.influences.joined(separator: ", "))\n"
            }
            
            output += "**记录时间 Recorded**: \(formatDateTime(state.createdAt))\n\n"
        }
        
        output += "\n"
        return output
    }
    
    // MARK: - Daily Tracker Export
    
    private static func exportTracker(_ tracker: DailyTrackerRecord) -> String {
        var output = "## 📊 每日追踪 Daily Tracker\n\n"
        
        // Body Energy
        let bodyLevel = BodyEnergyLevel.from(tracker.bodyEnergy)
        output += "**身体能量 Body Energy**: \(tracker.bodyEnergy)/100\n"
        output += "  Level: \(bodyLevel.titleKey)\n\n"
        
        // Mood Weather
        output += "**心情天气 Mood Weather**: \(tracker.moodWeather)/100\n\n"
        
        // Activities
        if !tracker.activities.isEmpty {
            output += "**活动记录 Activities**:\n\n"
            for activity in tracker.activities {
                output += "- **\(activity.activityType.localizedKey)**\n"
                
                if !activity.companions.isEmpty {
                    let companionNames = activity.companions.map { $0.localizedKey }.joined(separator: ", ")
                    output += "  陪伴 Companions: \(companionNames)\n"
                }
                
                if let details = activity.details, !details.isEmpty {
                    output += "  详情 Details: \(details)\n"
                }
                
                if !activity.tags.isEmpty {
                    output += "  标签 Tags: \(activity.tags.count) 个 items\n"
                }
                
                output += "\n"
            }
        }
        
        output += "\n"
        return output
    }
    
    // MARK: - Helper Functions
    
    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
