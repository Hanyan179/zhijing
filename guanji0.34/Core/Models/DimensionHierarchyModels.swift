import Foundation

// MARK: - L4 Layer: Dimension Hierarchy (维度层级体系)
// Three-level dimension architecture for Life OS
// Level 1 & 2: Fixed, covering major life aspects
// Level 3: Dynamic, AI-maintained subdivisions

// MARK: - Node Content Type

/// 节点内容类型 - 支持 L3 层的特异性与无限扩展
/// Defines the type of content stored in a KnowledgeNode
public enum NodeContentType: String, Codable, CaseIterable {
    /// AI生成的标签 - 只有 name + description + sourceLinks
    case aiTag = "ai_tag"
    
    /// 独立小系统 - 有固定 schema（如个人信息：血型、姓名等）
    case subsystem = "subsystem"
    
    /// 实体引用 - 指向关系表中的人物
    case entityRef = "entity_ref"
    
    /// 嵌套列表 - 下面还有子节点列表
    case nestedList = "nested_list"
    
    // MARK: - Display Properties
    
    /// 中文显示名称
    public var displayName: String {
        switch self {
        case .aiTag: return "AI标签"
        case .subsystem: return "独立子系统"
        case .entityRef: return "实体引用"
        case .nestedList: return "嵌套列表"
        }
    }
    
    /// 英文描述
    public var description: String {
        switch self {
        case .aiTag: return "AI-generated tag with name, description, and source links"
        case .subsystem: return "Independent subsystem with fixed schema"
        case .entityRef: return "Reference to entity in relationship table"
        case .nestedList: return "Nested list with child nodes"
        }
    }
}

// MARK: - Dimension Hierarchy

/// 维度层级定义 - Life OS 三层维度体系
/// Level 1: 7 first-level dimensions (fixed)
/// Level 2: 15 second-level dimensions (fixed)
/// Level 3: AI-maintained subdivisions (dynamic)
public struct DimensionHierarchy {
    
    // MARK: - Level 1 Dimensions
    
    /// Level 1 维度枚举 - 7个一级维度
    public enum Level1: String, CaseIterable, Codable {
        case self_ = "self"                       // 本体
        case material = "material"                 // 物质
        case achievements = "achievements"         // 成就
        case experiences = "experiences"           // 阅历
        case spirit = "spirit"                     // 精神
        case relationships = "relationships"       // 关系 [预留]
        case aiPreferences = "ai_preferences"      // AI偏好 [预留]
        
        /// 是否为预留维度（暂不实现）
        public var isReserved: Bool {
            self == .relationships || self == .aiPreferences
        }
        
        /// 中文显示名称
        public var displayName: String {
            switch self {
            case .self_: return "本体"
            case .material: return "物质"
            case .achievements: return "成就"
            case .experiences: return "阅历"
            case .spirit: return "精神"
            case .relationships: return "关系"
            case .aiPreferences: return "AI偏好"
            }
        }
        
        /// 英文显示名称
        public var englishName: String {
            switch self {
            case .self_: return "Self"
            case .material: return "Material"
            case .achievements: return "Achievements"
            case .experiences: return "Experiences"
            case .spirit: return "Spirit"
            case .relationships: return "Relationships"
            case .aiPreferences: return "AI Preferences"
            }
        }
        
        /// 维度描述
        public var dimensionDescription: String {
            switch self {
            case .self_: return "身份认同、身体状态、性格特质"
            case .material: return "经济状况、物品与环境、生活保障"
            case .achievements: return "事业发展、个人能力、成果展示"
            case .experiences: return "文化娱乐、探索足迹、人生历程"
            case .spirit: return "意识形态、心理状态、思考感悟"
            case .relationships: return "人际关系管理（预留）"
            case .aiPreferences: return "AI交互偏好设置（预留）"
            }
        }
    }
    
    // MARK: - Level 2 Dimensions
    
    /// Level 2 维度定义 - 15个二级维度（5个核心维度各3个）
    public static let level2Dimensions: [Level1: [String]] = [
        .self_: ["identity", "physical", "personality"],
        .material: ["economy", "objects_space", "security"],
        .achievements: ["career", "competencies", "outcomes"],
        .experiences: ["culture_entertainment", "exploration", "history"],
        .spirit: ["ideology", "mental_state", "wisdom"]
        // relationships 和 aiPreferences 为预留维度，暂不定义 Level 2
    ]
    
    /// Level 2 维度中文名称映射
    public static let level2DisplayNames: [String: String] = [
        // 本体
        "identity": "身份认同",
        "physical": "身体状态",
        "personality": "性格特质",
        // 物质
        "economy": "经济状况",
        "objects_space": "物品与环境",
        "security": "生活保障",
        // 成就
        "career": "事业发展",
        "competencies": "个人能力",
        "outcomes": "成果展示",
        // 阅历
        "culture_entertainment": "文化娱乐",
        "exploration": "探索足迹",
        "history": "人生历程",
        // 精神
        "ideology": "意识形态",
        "mental_state": "心理状态",
        "wisdom": "思考感悟"
    ]
    
    // MARK: - Level 3 Presets
    
    /// Level 3 预设维度（可由AI动态扩展）
    /// Key format: "level1.level2"
    /// 
    /// 每个三级维度包含：
    /// - 范畴界定 (Scope): 该维度涵盖的内容边界
    /// - 常见举例 (Examples): 典型的知识节点示例
    /// - 内容类型 (ContentType): 推荐使用的节点类型
    public static let level3Presets: [String: [String]] = [
        // ===== 本体维度 (self) =====
        // 本体 > 身份认同
        "self.identity": [
            "social_roles",           // 社会角色: 父亲、丈夫、儿子、朋友、志愿者
            "professional_identity",  // 职业身份: 软件工程师、产品经理、创业者
            "appearance_style",       // 外在形象: 商务风、休闲风、戴眼镜
            "personal_info",          // 个人信息: 血型、星座、MBTI (subsystem)
            "cultural_identity",      // 文化认同: 客家人、北方人、海归
            "online_identity"         // 网络身份: B站UP主、微博大V、知乎答主
        ],
        // 本体 > 身体状态
        "self.physical": [
            "health_condition",       // 健康状况: 轻度近视、花粉过敏、高血压
            "sleep_quality",          // 睡眠质量: 早睡早起、夜猫子、失眠困扰
            "dietary_habits",         // 饮食习惯: 素食主义、无辣不欢、海鲜过敏
            "exercise_habits",        // 运动习惯: 每周跑步3次、健身爱好者
            "body_metrics",           // 身体指标: 体重、BMI、血压 (subsystem)
            "medical_history"         // 病史记录: 手术史、长期服药
        ],
        // 本体 > 性格特质
        "self.personality": [
            "self_assessment",        // 自我评价: 内向、完美主义、乐观、敏感
            "behavioral_preferences", // 行为偏好: 喜欢独处、决策果断、注重细节
            "social_style",           // 社交风格: 社恐、社牛、慢热型、倾听者
            "emotional_patterns",     // 情绪模式: 容易焦虑、情绪稳定、易怒
            "cognitive_style"         // 思维方式: 逻辑思维强、直觉型、发散思维
        ],
        
        // ===== 物质维度 (material) =====
        // 物质 > 经济状况
        "material.economy": [
            "asset_status",           // 资产概况: 有一套自住房、有车、存款50万
            "consumption",            // 消费行为: 理性消费、月光族、品质优先
            "debt_pressure",          // 负债压力: 房贷200万、车贷、无负债
            "income_sources",         // 收入来源: 工资、副业、投资收益
            "financial_goals",        // 财务目标: 5年内买房、财务自由
            "investment_style"        // 投资风格: 保守型、激进型、定投党
        ],
        // 物质 > 物品与环境
        "material.objects_space": [
            "possessions",            // 常用物品: MacBook Pro、iPhone、相机
            "living_environment",     // 居住环境: 两室一厅、租房、学区房
            "collections",            // 收藏爱好: 手办、黑胶唱片、球鞋
            "vehicles",               // 交通工具: 特斯拉、电动自行车、无车
            "workspace",              // 工作空间: 独立书房、站立办公桌
            "digital_assets"          // 数字资产: 域名、NFT、游戏账号
        ],
        // 物质 > 生活保障
        "material.security": [
            "insurance_safety",       // 保险与风控: 重疾险、医疗险、意外险
            "emergency_fund",         // 应急储备: 6个月生活费储备
            "social_security"         // 社会保障: 五险一金、自由职业无社保
        ],
        
        // ===== 成就维度 (achievements) =====
        // 成就 > 事业发展
        "achievements.career": [
            "work_experience",        // 工作经历: 阿里巴巴P7、腾讯产品经理
            "business_activities",    // 商业活动: 天使投资人、淘宝店主
            "career_milestones",      // 职业里程碑: 首次晋升、转行成功
            "industry_expertise",     // 行业专长: 互联网、金融科技
            "professional_network"    // 职业人脉: 行业大佬、猎头 (entity_ref)
        ],
        // 成就 > 个人能力
        "achievements.competencies": [
            "professional_skills",    // 专业技能: Swift编程、产品设计、数据分析
            "education_learning",     // 学习进修: 清华本科、MBA在读、PMP认证
            "life_talents",           // 生活才艺: 钢琴十级、烹饪达人、摄影
            "soft_skills",            // 软技能: 沟通能力强、领导力、时间管理
            "languages",              // 语言能力: 英语流利、日语N1、粤语母语
            "certifications"          // 资质证书: 注册会计师、律师执照
        ],
        // 成就 > 成果展示
        "achievements.outcomes": [
            "personal_creations",     // 个人作品: 开源项目、出版书籍、原创音乐
            "recognition_awards",     // 荣誉认可: 优秀员工、行业奖项
            "publications",           // 发表作品: 学术论文、专栏文章、技术博客
            "portfolio"               // 作品集: 设计作品集、代码仓库 (nested_list)
        ],
        
        // ===== 阅历维度 (experiences) =====
        // 阅历 > 文化娱乐
        "experiences.culture_entertainment": [
            "reading",                // 阅读体验: 《三体》震撼、年读50本
            "movies_music",           // 视听欣赏: 诺兰粉丝、古典音乐爱好者
            "gaming",                 // 游戏娱乐: 王者荣耀、Steam玩家、桌游
            "sports_fitness",         // 运动健身: 跑步爱好者、健身房会员
            "arts_crafts",            // 艺术手工: 绘画、书法、手工皮具
            "social_activities"       // 社交活动: 读书会、行业沙龙
        ],
        // 阅历 > 探索足迹
        "experiences.exploration": [
            "travel_stories",         // 旅行见闻: 2023日本之旅、西藏自驾
            "lifestyle_exploration",  // 探店体验: 米其林餐厅、网红咖啡馆
            "local_discoveries",      // 本地发现: 隐藏小店、城市公园
            "adventure_activities",   // 冒险活动: 潜水、滑雪、攀岩
            "cultural_experiences"    // 文化体验: 茶道体验、博物馆参观
        ],
        // 阅历 > 人生历程
        "experiences.history": [
            "milestones",             // 重要节点: 毕业、结婚、生子、买房
            "memories",               // 往事回忆: 童年趣事、初恋回忆
            "anniversaries",          // 纪念日: 结婚纪念日、生日 (subsystem)
            "life_transitions",       // 人生转折: 转行、移民、离婚
            "family_history"          // 家族历史: 家族故事、祖辈经历
        ],
        
        // ===== 精神维度 (spirit) =====
        // 精神 > 意识形态
        "spirit.ideology": [
            "values",                 // 价值观: 家庭优先、诚信为本、追求自由
            "visions_dreams",         // 愿景梦想: 环游世界、财务自由、写一本书
            "beliefs",                // 信仰信念: 佛教徒、无神论、极简主义
            "principles",             // 行事原则: 不撒谎、守时、尊重他人
            "worldview"               // 世界观: 乐观主义、现实主义
        ],
        // 精神 > 心理状态
        "spirit.mental_state": [
            "emotions",               // 情绪感受: 最近很焦虑、心情愉悦
            "stressors",              // 压力来源: 工作压力、育儿焦虑、经济压力
            "mental_health",          // 心理健康: 轻度抑郁、焦虑症、状态良好
            "energy_level",           // 精力状态: 精力充沛、容易疲惫
            "satisfaction"            // 满意度: 工作满意、家庭幸福
        ],
        // 精神 > 思考感悟
        "spirit.wisdom": [
            "opinions",               // 观点看法: 对教育的看法、对婚姻的理解
            "reflections",            // 反思复盘: 慢即是快、选择比努力重要
            "learnings",              // 学习心得: 读书笔记、课程感悟
            "insights",               // 洞察发现: 行业洞察、人性观察
            "questions"               // 思考问题: 人生意义、职业方向
        ]
    ]
    
    /// Level 3 预设维度中文名称映射
    public static let level3DisplayNames: [String: String] = [
        // ===== 本体维度 (self) =====
        // 本体 > 身份认同
        "social_roles": "社会角色",
        "professional_identity": "职业身份",
        "appearance_style": "外在形象",
        "personal_info": "个人信息",
        "cultural_identity": "文化认同",
        "online_identity": "网络身份",
        // 本体 > 身体状态
        "health_condition": "健康状况",
        "sleep_quality": "睡眠质量",
        "dietary_habits": "饮食习惯",
        "exercise_habits": "运动习惯",
        "body_metrics": "身体指标",
        "medical_history": "病史记录",
        // 本体 > 性格特质
        "self_assessment": "自我评价",
        "behavioral_preferences": "行为偏好",
        "social_style": "社交风格",
        "emotional_patterns": "情绪模式",
        "cognitive_style": "思维方式",
        
        // ===== 物质维度 (material) =====
        // 物质 > 经济状况
        "asset_status": "资产概况",
        "consumption": "消费行为",
        "debt_pressure": "负债压力",
        "income_sources": "收入来源",
        "financial_goals": "财务目标",
        "investment_style": "投资风格",
        // 物质 > 物品与环境
        "possessions": "常用物品",
        "living_environment": "居住环境",
        "collections": "收藏爱好",
        "vehicles": "交通工具",
        "workspace": "工作空间",
        "digital_assets": "数字资产",
        // 物质 > 生活保障
        "insurance_safety": "保险与风控",
        "emergency_fund": "应急储备",
        "social_security": "社会保障",
        
        // ===== 成就维度 (achievements) =====
        // 成就 > 事业发展
        "work_experience": "工作经历",
        "business_activities": "商业活动",
        "career_milestones": "职业里程碑",
        "industry_expertise": "行业专长",
        "professional_network": "职业人脉",
        // 成就 > 个人能力
        "professional_skills": "专业技能",
        "education_learning": "学习进修",
        "life_talents": "生活才艺",
        "soft_skills": "软技能",
        "languages": "语言能力",
        "certifications": "资质证书",
        // 成就 > 成果展示
        "personal_creations": "个人作品",
        "recognition_awards": "荣誉认可",
        "publications": "发表作品",
        "portfolio": "作品集",
        
        // ===== 阅历维度 (experiences) =====
        // 阅历 > 文化娱乐
        "reading": "阅读体验",
        "movies_music": "视听欣赏",
        "gaming": "游戏娱乐",
        "sports_fitness": "运动健身",
        "arts_crafts": "艺术手工",
        "social_activities": "社交活动",
        // 阅历 > 探索足迹
        "travel_stories": "旅行见闻",
        "lifestyle_exploration": "探店体验",
        "local_discoveries": "本地发现",
        "adventure_activities": "冒险活动",
        "cultural_experiences": "文化体验",
        // 阅历 > 人生历程
        "milestones": "重要节点",
        "memories": "往事回忆",
        "anniversaries": "纪念日",
        "life_transitions": "人生转折",
        "family_history": "家族历史",
        
        // ===== 精神维度 (spirit) =====
        // 精神 > 意识形态
        "values": "价值观",
        "visions_dreams": "愿景梦想",
        "beliefs": "信仰信念",
        "principles": "行事原则",
        "worldview": "世界观",
        // 精神 > 心理状态
        "emotions": "情绪感受",
        "stressors": "压力来源",
        "mental_health": "心理健康",
        "energy_level": "精力状态",
        "satisfaction": "满意度",
        // 精神 > 思考感悟
        "opinions": "观点看法",
        "reflections": "反思复盘",
        "learnings": "学习心得",
        "insights": "洞察发现",
        "questions": "思考问题"
    ]
    
    // MARK: - Helper Methods
    
    /// 获取 Level 1 维度的所有 Level 2 维度
    public static func getLevel2Dimensions(for level1: Level1) -> [String] {
        level2Dimensions[level1] ?? []
    }
    
    /// 获取 Level 2 维度的所有 Level 3 预设
    public static func getLevel3Presets(level1: Level1, level2: String) -> [String] {
        let key = "\(level1.rawValue).\(level2)"
        return level3Presets[key] ?? []
    }
    
    /// 获取 Level 2 维度的中文显示名称
    public static func getLevel2DisplayName(_ level2: String) -> String {
        level2DisplayNames[level2] ?? level2
    }
    
    /// 获取 Level 3 维度的中文显示名称
    public static func getLevel3DisplayName(_ level3: String) -> String {
        level3DisplayNames[level3] ?? level3
    }
    
    /// 验证 Level 2 维度是否属于指定的 Level 1
    public static func isValidLevel2(_ level2: String, for level1: Level1) -> Bool {
        level2Dimensions[level1]?.contains(level2) ?? false
    }
    
    /// 验证 Level 3 维度是否为预设（非预设也允许，由AI动态创建）
    public static func isPresetLevel3(_ level3: String, level1: Level1, level2: String) -> Bool {
        let key = "\(level1.rawValue).\(level2)"
        return level3Presets[key]?.contains(level3) ?? false
    }
    
    /// 获取所有核心（非预留）Level 1 维度
    public static var coreDimensions: [Level1] {
        Level1.allCases.filter { !$0.isReserved }
    }
    
    /// 获取所有预留 Level 1 维度
    public static var reservedDimensions: [Level1] {
        Level1.allCases.filter { $0.isReserved }
    }
    
    /// 统计 Level 2 维度总数
    public static var totalLevel2Count: Int {
        level2Dimensions.values.reduce(0) { $0 + $1.count }
    }
    
    /// 统计 Level 3 预设维度总数
    public static var totalLevel3PresetCount: Int {
        level3Presets.values.reduce(0) { $0 + $1.count }
    }
}


// MARK: - NodeTypePath (路径解析工具)

/// nodeType 路径解析工具
/// 用于解析和验证 "level1.level2.level3" 格式的 nodeType 字符串
public struct NodeTypePath: Equatable, Hashable {
    
    /// Level 1 维度标识（必需）
    public let level1: String
    
    /// Level 2 维度标识（可选）
    public let level2: String?
    
    /// Level 3 维度标识（可选）
    public let level3: String?
    
    // MARK: - Initialization
    
    /// 从 nodeType 字符串解析路径
    /// - Parameter nodeType: 格式为 "level1.level2.level3" 的字符串
    /// - Returns: 解析成功返回 NodeTypePath，空字符串或无效格式返回 nil
    public init?(nodeType: String) {
        let trimmed = nodeType.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        let components = trimmed.split(separator: ".").map(String.init)
        guard !components.isEmpty else { return nil }
        
        self.level1 = components[0]
        self.level2 = components.count > 1 ? components[1] : nil
        self.level3 = components.count > 2 ? components[2] : nil
    }
    
    /// 直接初始化（用于测试或手动创建）
    public init(level1: String, level2: String? = nil, level3: String? = nil) {
        self.level1 = level1
        self.level2 = level2
        self.level3 = level3
    }
    
    // MARK: - Computed Properties
    
    /// 完整路径字符串
    /// 将 level1, level2, level3 用 "." 连接，忽略 nil 值
    public var fullPath: String {
        [level1, level2, level3].compactMap { $0 }.joined(separator: ".")
    }
    
    /// 获取 Level 1 维度枚举
    /// 如果 level1 字符串对应有效的 DimensionHierarchy.Level1 枚举值则返回，否则返回 nil
    public var level1Dimension: DimensionHierarchy.Level1? {
        DimensionHierarchy.Level1(rawValue: level1)
    }
    
    /// 路径深度（1-3）
    public var depth: Int {
        if level3 != nil { return 3 }
        if level2 != nil { return 2 }
        return 1
    }
    
    // MARK: - Validation
    
    /// 验证路径是否有效
    /// - Level 1 必须是有效的 DimensionHierarchy.Level1 枚举值
    /// - 如果有 Level 2，必须属于对应 Level 1 的有效二级维度
    /// - Level 3 不做强制验证（允许 AI 动态创建）
    public func isValid() -> Bool {
        // 验证 Level 1
        guard let l1 = DimensionHierarchy.Level1(rawValue: level1) else {
            return false
        }
        
        // 如果有 Level 2，验证是否属于该 Level 1
        if let l2 = level2 {
            guard DimensionHierarchy.level2Dimensions[l1]?.contains(l2) == true else {
                return false
            }
        }
        
        // Level 3 不做强制验证，允许 AI 动态创建新的细分领域
        return true
    }
    
    /// 检查是否为预留维度路径
    public var isReservedPath: Bool {
        level1Dimension?.isReserved ?? false
    }
    
    // MARK: - Display Names
    
    /// 获取 Level 1 的中文显示名称
    public var level1DisplayName: String? {
        level1Dimension?.displayName
    }
    
    /// 获取 Level 2 的中文显示名称
    public var level2DisplayName: String? {
        guard let l2 = level2 else { return nil }
        return DimensionHierarchy.level2DisplayNames[l2]
    }
    
    /// 获取 Level 3 的中文显示名称
    public var level3DisplayName: String? {
        guard let l3 = level3 else { return nil }
        return DimensionHierarchy.level3DisplayNames[l3]
    }
    
    /// 获取完整的中文显示路径
    public var fullDisplayPath: String {
        [level1DisplayName, level2DisplayName, level3DisplayName]
            .compactMap { $0 }
            .joined(separator: " > ")
    }
}

// MARK: - NodeTypePath CustomStringConvertible

extension NodeTypePath: CustomStringConvertible {
    public var description: String {
        fullPath
    }
}

// MARK: - NodeType Migration Map (迁移映射表)

/// 旧 nodeType 到新层级路径的映射表
/// 用于将扁平的 nodeType（如 "skill"）迁移到新的层级路径格式（如 "achievements.competencies.professional_skills"）
public let nodeTypeMigrationMap: [String: String] = [
    // ===== 用户画像维度 (10个) =====
    "skill": "achievements.competencies.professional_skills",
    "value": "spirit.ideology.values",
    "hobby": "experiences.culture_entertainment",
    "goal": "spirit.ideology.visions_dreams",
    "trait": "self.personality.self_assessment",
    "fear": "spirit.mental_state.stressors",
    "fact": "experiences.history.milestones",
    "lifestyle": "self.physical.dietary_habits",
    "belief": "spirit.ideology.values",
    "preference": "self.personality.behavioral_preferences",
    
    // ===== 关系画像维度 (6个) =====
    "relationship_status": "relationships.status",
    "interaction_pattern": "relationships.interaction",
    "emotional_connection": "relationships.emotional",
    "shared_memory": "relationships.memories",
    "health_status": "relationships.health",
    "life_event": "relationships.events"
]

/// 迁移旧 nodeType 到新格式
/// - Parameter oldType: 旧的扁平 nodeType 字符串
/// - Returns: 如果存在映射则返回新格式，否则返回原值
public func migrateNodeType(_ oldType: String) -> String {
    nodeTypeMigrationMap[oldType] ?? oldType
}

// MARK: - DimensionHierarchy Extension for Migration

extension DimensionHierarchy {
    
    /// 检查 nodeType 是否为旧格式（需要迁移）
    public static func isOldFormat(_ nodeType: String) -> Bool {
        nodeTypeMigrationMap.keys.contains(nodeType)
    }
    
    /// 获取迁移后的 nodeType
    public static func migratedNodeType(_ nodeType: String) -> String {
        migrateNodeType(nodeType)
    }
    
    /// 获取所有旧格式的 nodeType 列表
    public static var oldFormatNodeTypes: [String] {
        Array(nodeTypeMigrationMap.keys)
    }
    
    /// 获取所有新格式的 nodeType 列表
    public static var newFormatNodeTypes: [String] {
        Array(nodeTypeMigrationMap.values)
    }
}
