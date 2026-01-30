import Foundation

// MARK: - TestDataGenerator

/// 测试数据生成器 - 生成覆盖所有维度和 ContentType 的测试数据
///
/// 用于快速验证 UI 效果，仅在 DEBUG 模式下使用。
/// 数据基于用户真实画像定制（郑州/梦创双杨/4年经验），已隐去特定敏感信息。
///
/// - Requirements: REQ-6
public struct TestDataGenerator {
    
    // MARK: - Public Methods
    
    /// 生成完整测试数据集
    public static func generateTestProfile() -> NarrativeUserProfile {
        var profile = NarrativeUserProfile()
        profile.staticCore = generateTestStaticCore()
        profile.knowledgeNodes = generateTestNodes()
        return profile
    }
    
    /// 生成测试知识节点列表
    public static func generateTestNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(contentsOf: generateSelfDimensionNodes())
        nodes.append(contentsOf: generateMaterialDimensionNodes())
        nodes.append(contentsOf: generateAchievementsDimensionNodes())
        nodes.append(contentsOf: generateExperiencesDimensionNodes())
        nodes.append(contentsOf: generateSpiritDimensionNodes())
        
        return nodes
    }
    
    /// 生成测试 StaticCore
    public static func generateTestStaticCore() -> StaticCore {
        StaticCore(
            nickname: "独立开发者",
            gender: .male,
            birthYearMonth: "2000-06",
            hometown: "郑州",
            currentCity: "郑州",
            occupation: "Java后端开发",
            industry: "政务软件/互联网",
            education: .bachelor
        )
    }
}


// MARK: - Self Dimension (本体)

extension TestDataGenerator {
    
    static func generateSelfDimensionNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        nodes.append(contentsOf: generateIdentityNodes())
        nodes.append(contentsOf: generatePhysicalNodes())
        nodes.append(contentsOf: generatePersonalityNodes())
        return nodes
    }
    
    private static func generateIdentityNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "self.identity.professional_identity",
            name: "全栈探索者",
            description: "主业Java后端，副业独立开发iOS App，热衷于AI落地",
            confidence: 0.95,
            sourceSnippet: "虽然工作是写Java，但我更想用Python和Swift做自己的产品。"
        ))
        
        nodes.append(createAITagNode(
            nodeType: "self.identity.social_roles",
            name: "弟弟",
            description: "有一个大十岁的哥哥",
            confidence: 1.0,
            sourceSnippet: "我哥比我大十岁，有时候代沟还挺明显的。"
        ))
        
        nodes.append(createSubsystemNode(
            nodeType: "self.identity.personal_info",
            name: "个人基础信息",
            attributes: [
                "MBTI": .string("INTJ"),
                "年龄": .int(25),
                "编程风格": .string("Clean Code")
            ]
        ))
        
        return nodes
    }
    
    private static func generatePhysicalNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "self.physical.dietary_habits",
            name: "胶质食物爱好者",
            description: "喜欢猪蹄、鸡爪等口感",
            confidence: 1.0,
            sourceSnippet: "晚上加餐点了份烤猪蹄，就好这一口糯叽叽的感觉。"
        ))
        
        nodes.append(createAITagNode(
            nodeType: "self.physical.dietary_habits",
            name: "无糖茶饮",
            description: "不喜欢白开水，常喝无糖茶饮料",
            confidence: 0.9
        ))
        
        nodes.append(createAITagNode(
            nodeType: "self.physical.sleep_quality",
            name: "严重失眠",
            description: "曾有连续48小时未眠的经历，可能与营养补剂有关",
            confidence: 0.8,
            sourceSnippet: "吃了那个补剂之后整整两天没睡着，太折磨了。"
        ))
        
        return nodes
    }
    
    private static func generatePersonalityNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "self.personality.cognitive_style",
            name: "绝对理性",
            description: "厌恶情绪化安慰，追求客观事实和冷血反馈",
            confidence: 1.0,
            sourceSnippet: "不需要同理心，只需要告诉我解决方案，哪怕听起来很冷血。"
        ))
        
        nodes.append(createAITagNode(
            nodeType: "self.personality.self_assessment",
            name: "内省",
            description: "习惯通过软件工具记录和分析自我",
            confidence: 0.9
        ))
        
        return nodes
    }
}


// MARK: - Material Dimension (物质)

extension TestDataGenerator {
    
    static func generateMaterialDimensionNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        nodes.append(contentsOf: generateEconomyNodes())
        nodes.append(contentsOf: generateObjectsSpaceNodes())
        return nodes
    }
    
    private static func generateEconomyNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "material.economy.income_sources",
            name: "稳定薪资",
            description: "梦创双杨全职工作收入",
            confidence: 1.0
        ))
        
        nodes.append(createAITagNode(
            nodeType: "material.economy.visions",
            name: "创业筹备",
            description: "计划成立 Prisma AI Inc. 申请云资源",
            confidence: 0.8,
            sourceSnippet: "注册个公司弄个身份，好去申请那些云厂商的免费额度。"
        ))
        
        return nodes
    }
    
    private static func generateObjectsSpaceNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "material.objects_space.possessions",
            name: "开发设备",
            description: "高性能 PC 用于游戏和开发，MacBook 用于 iOS 开发",
            confidence: 0.9
        ))
        
        return nodes
    }
}

// MARK: - Achievements Dimension (成就)

extension TestDataGenerator {
    
    static func generateAchievementsDimensionNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        nodes.append(contentsOf: generateCareerNodes())
        nodes.append(contentsOf: generateCompetenciesNodes())
        nodes.append(contentsOf: generateOutcomesNodes())
        return nodes
    }
    
    private static func generateCareerNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "achievements.career.work_experience",
            name: "梦创双杨",
            description: "2022年至今 | Java后端开发 | 郑州/上海",
            confidence: 1.0,
            sourceSnippet: "目前在做政务文档处理相关的项目，代码量很大。"
        ))
        
        nodes.append(createAITagNode(
            nodeType: "achievements.career.industry_expertise",
            name: "政务数字化",
            description: "熟悉政务公文处理业务流程与后端架构",
            confidence: 0.9
        ))
        
        nodes.append(createAITagNode(
            nodeType: "achievements.career.milestones",
            name: "从业4年",
            description: "从2022年开始进入软件开发行业",
            confidence: 1.0
        ))
        
        return nodes
    }
    
    private static func generateCompetenciesNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "achievements.competencies.professional_skills",
            name: "Java Ecosystem",
            description: "熟练掌握 Java 后端开发，处理大型遗留代码库",
            confidence: 1.0
        ))
        
        nodes.append(createAITagNode(
            nodeType: "achievements.competencies.professional_skills",
            name: "Python & AI",
            description: "FastAPI, Prompt Engineering, Knowledge Graphs",
            confidence: 0.9,
            sourceSnippet: "最近在研究怎么优化知识图谱抽取的提示词，FastAPI写起来比Java轻快多了。"
        ))
        
        nodes.append(createAITagNode(
            nodeType: "achievements.competencies.professional_skills",
            name: "iOS Development",
            description: "SwiftUI 开发，正在构建个人App",
            confidence: 0.8
        ))
        
        return nodes
    }
    
    private static func generateOutcomesNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "achievements.outcomes.personal_creations",
            name: "Project Ode (智镜)",
            description: "一款用于记忆保存与自我分析的 iOS 应用",
            confidence: 1.0,
            sourceSnippet: "我想开发的智镜，核心就是为了记着记忆，后端打算用 Python 写。"
        ))
        
        nodes.append(createAITagNode(
            nodeType: "achievements.outcomes.dev_sessions",
            name: "高强度开发",
            description: "曾有连续工作至凌晨4点的开发经历",
            confidence: 0.8
        ))
        
        return nodes
    }
}


// MARK: - Experiences Dimension (阅历)

extension TestDataGenerator {
    
    static func generateExperiencesDimensionNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        nodes.append(contentsOf: generateCultureEntertainmentNodes())
        nodes.append(contentsOf: generateExplorationNodes())
        nodes.append(contentsOf: generateHistoryNodes())
        return nodes
    }
    
    private static func generateExplorationNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "experiences.exploration.travel_stories",
            name: "西安之旅",
            description: "2024年国庆期间的古都探访",
            confidence: 0.9,
            sourceSnippet: "去西安看了兵马俑，历史的厚重感扑面而来。"
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.exploration.travel_stories",
            name: "上海出差",
            description: "工作期间的城市体验",
            confidence: 0.85
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.exploration.lifestyle_exploration",
            name: "郑州美食探索",
            description: "本地特色餐厅打卡",
            confidence: 0.8
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.exploration.local_discoveries",
            name: "郑州咖啡馆",
            description: "适合写代码的安静角落",
            confidence: 0.75
        ))
        
        return nodes
    }
    
    private static func generateCultureEntertainmentNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "experiences.culture_entertainment.gaming",
            name: "资深玩家",
            description: "25岁前积累约5000小时游戏时长",
            confidence: 1.0,
            sourceSnippet: "算了一下，从小到大玩游戏的时间得有5000个小时了。"
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.culture_entertainment.gaming",
            name: "暴雪全家桶",
            description: "星际争霸II、炉石传说玩家",
            confidence: 0.9
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.culture_entertainment.gaming",
            name: "Fallout Series",
            description: "辐射系列粉丝，喜爱废土风格",
            confidence: 0.9
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.culture_entertainment.reading",
            name: "诡秘之主",
            description: "追读小说及相关动漫",
            confidence: 0.8
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.culture_entertainment.reading",
            name: "终末的女武神",
            description: "关注漫画剧情发展",
            confidence: 0.7
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.culture_entertainment.movies_music",
            name: "美剧爱好者",
            description: "绝命毒师, 惩罚者, 怪奇物语, 行尸走肉",
            confidence: 0.9
        ))
        
        return nodes
    }
    
    private static func generateHistoryNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "experiences.history.milestones",
            name: "大学毕业",
            description: "约2022年本科毕业，开始职业生涯",
            confidence: 0.9
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.history.milestones",
            name: "入职梦创双杨",
            description: "2022年开始Java后端开发工作",
            confidence: 1.0
        ))
        
        nodes.append(createAITagNode(
            nodeType: "experiences.history.memories",
            name: "第一次独立开发",
            description: "完成第一个独立iOS项目的成就感",
            confidence: 0.85
        ))
        
        nodes.append(createSubsystemNode(
            nodeType: "experiences.history.anniversaries",
            name: "重要纪念日",
            attributes: [
                "生日": .string("2000-06-15"),
                "入职纪念日": .string("2022-07-01"),
                "毕业日期": .string("2022-06-30"),
                "结婚纪念日": .string("2020-05-20")
            ]
        ))
        
        return nodes
    }
}


// MARK: - Spirit Dimension (精神)

extension TestDataGenerator {
    
    static func generateSpiritDimensionNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        nodes.append(contentsOf: generateIdeologyNodes())
        nodes.append(contentsOf: generateWisdomNodes())
        return nodes
    }
    
    private static func generateIdeologyNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "spirit.ideology.beliefs",
            name: "虚无主义与存在主义",
            description: "对生命意义、虚无等议题有深入思考",
            confidence: 0.9,
            sourceSnippet: "最近在思考悲伤的机制，感觉一切终将归于虚无。"
        ))
        
        return nodes
    }
    
    private static func generateWisdomNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        nodes.append(createAITagNode(
            nodeType: "spirit.wisdom.reflections",
            name: "记忆的价值",
            description: "认为人的本质在于记忆，致力于保存记忆",
            confidence: 0.95,
            sourceSnippet: "如果失去了记忆，我们还是我们吗？所以我才要做这个App。"
        ))
        
        return nodes
    }
}

// MARK: - Helper Methods

extension TestDataGenerator {
    
    private static func createAITagNode(
        nodeType: String,
        name: String,
        description: String,
        confidence: Double,
        sourceSnippet: String? = nil
    ) -> KnowledgeNode {
        var sourceLinks: [SourceLink] = []
        
        if let snippet = sourceSnippet {
            sourceLinks.append(SourceLink(
                sourceType: "diary",
                sourceId: UUID().uuidString,
                dayId: generateRandomDayId(),
                snippet: snippet,
                relevanceScore: 0.85
            ))
        }
        
        let sourceType: SourceType = confidence >= 1.0 ? .userInput : .aiExtracted
        let needsReview = confidence < 0.8
        
        return KnowledgeNode(
            nodeType: nodeType,
            contentType: .aiTag,
            nodeCategory: .common,
            name: name,
            description: description,
            sourceLinks: sourceLinks,
            tracking: NodeTracking(
                source: NodeSource(type: sourceType, confidence: confidence),
                verification: NodeVerification(
                    confirmedByUser: confidence >= 1.0,
                    needsReview: needsReview
                )
            )
        )
    }
    
    private static func createSubsystemNode(
        nodeType: String,
        name: String,
        attributes: [String: AttributeValue]
    ) -> KnowledgeNode {
        KnowledgeNode(
            nodeType: nodeType,
            contentType: .subsystem,
            nodeCategory: .common,
            name: name,
            attributes: attributes,
            tracking: NodeTracking(
                source: NodeSource(type: .userInput, confidence: 1.0),
                verification: NodeVerification(confirmedByUser: true)
            )
        )
    }
    
    private static func generateRandomDayId() -> String {
        let calendar = Calendar.current
        let today = Date()
        let daysAgo = Int.random(in: 1...365)
        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        return "2025-01-01"
    }
}
