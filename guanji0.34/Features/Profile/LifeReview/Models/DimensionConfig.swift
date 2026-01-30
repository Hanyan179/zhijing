import SwiftUI

// MARK: - DimensionColors

/// 维度颜色配置
/// 为 5 个核心 L1 维度提供主题色配置
///
/// 设计原则：
/// - 使用温暖、个人化的颜色
/// - 支持 Light/Dark Mode
/// - 颜色具有语义关联性
public struct DimensionColors {
    
    // MARK: - Color Mapping
    
    /// Level 1 维度颜色映射
    public static let colors: [DimensionHierarchy.Level1: Color] = [
        .self_: Color.indigo,           // 本体 - 深邃的靛蓝色，代表内在自我
        .material: Color.green,          // 物质 - 绿色，代表财富与成长
        .achievements: Color.orange,     // 成就 - 橙色，代表活力与成功
        .experiences: Color.blue,        // 阅历 - 蓝色，代表探索与广阔
        .spirit: Color.purple            // 精神 - 紫色，代表智慧与精神
    ]
    
    /// 预留维度颜色（暂不使用）
    public static let reservedColors: [DimensionHierarchy.Level1: Color] = [
        .relationships: Color.pink,      // 关系 - 粉色，代表情感连接
        .aiPreferences: Color.cyan       // AI偏好 - 青色，代表科技与智能
    ]
    
    // MARK: - Public Methods
    
    /// 获取指定 Level 1 维度的颜色
    /// - Parameter level1: Level 1 维度
    /// - Returns: 对应的主题色，如果未配置则返回灰色
    public static func color(for level1: DimensionHierarchy.Level1) -> Color {
        colors[level1] ?? reservedColors[level1] ?? .gray
    }
    
    /// 获取指定 Level 1 维度的浅色背景色
    /// - Parameter level1: Level 1 维度
    /// - Returns: 带透明度的浅色背景
    public static func backgroundColor(for level1: DimensionHierarchy.Level1) -> Color {
        color(for: level1).opacity(0.1)
    }
    
    /// 获取指定 Level 1 维度的边框色
    /// - Parameter level1: Level 1 维度
    /// - Returns: 带透明度的边框色
    public static func borderColor(for level1: DimensionHierarchy.Level1) -> Color {
        color(for: level1).opacity(0.3)
    }
    
    /// 获取所有核心维度的颜色列表
    public static var coreColors: [Color] {
        DimensionHierarchy.coreDimensions.map { color(for: $0) }
    }
}

// MARK: - DimensionIcons

/// 维度图标配置
/// 为 5 个核心 L1 维度提供 SF Symbol 图标配置
///
/// 设计原则：
/// - 使用 SF Symbols 确保原生体验
/// - 图标具有语义关联性
/// - 支持 filled 和 outline 两种风格
public struct DimensionIcons {
    
    // MARK: - Icon Mapping
    
    /// Level 1 维度图标映射（filled 风格）
    public static let icons: [DimensionHierarchy.Level1: String] = [
        .self_: "person.fill",                    // 本体 - 人物图标
        .material: "dollarsign.circle.fill",      // 物质 - 货币图标
        .achievements: "star.fill",               // 成就 - 星星图标
        .experiences: "airplane",                 // 阅历 - 飞机图标
        .spirit: "brain.head.profile"             // 精神 - 大脑图标
    ]
    
    /// Level 1 维度图标映射（outline 风格）
    public static let outlineIcons: [DimensionHierarchy.Level1: String] = [
        .self_: "person",
        .material: "dollarsign.circle",
        .achievements: "star",
        .experiences: "airplane",
        .spirit: "brain.head.profile"
    ]
    
    /// 预留维度图标（暂不使用）
    public static let reservedIcons: [DimensionHierarchy.Level1: String] = [
        .relationships: "person.2.fill",          // 关系 - 双人图标
        .aiPreferences: "cpu.fill"                // AI偏好 - CPU图标
    ]
    
    // MARK: - Public Methods
    
    /// 获取指定 Level 1 维度的图标名称（filled 风格）
    /// - Parameter level1: Level 1 维度
    /// - Returns: SF Symbol 名称，如果未配置则返回默认文件夹图标
    public static func icon(for level1: DimensionHierarchy.Level1) -> String {
        icons[level1] ?? reservedIcons[level1] ?? "folder.fill"
    }
    
    /// 获取指定 Level 1 维度的图标名称（outline 风格）
    /// - Parameter level1: Level 1 维度
    /// - Returns: SF Symbol 名称
    public static func outlineIcon(for level1: DimensionHierarchy.Level1) -> String {
        outlineIcons[level1] ?? "folder"
    }
    
    /// 获取所有核心维度的图标列表
    public static var coreIcons: [String] {
        DimensionHierarchy.coreDimensions.map { icon(for: $0) }
    }
}

// MARK: - DimensionConfig

/// 维度配置聚合
/// 提供统一的维度配置访问接口
public struct DimensionConfig {
    
    /// 获取指定 Level 1 维度的完整配置
    /// - Parameter level1: Level 1 维度
    /// - Returns: 包含颜色和图标的元组
    public static func config(for level1: DimensionHierarchy.Level1) -> (color: Color, icon: String) {
        (
            color: DimensionColors.color(for: level1),
            icon: DimensionIcons.icon(for: level1)
        )
    }
    
    /// 获取所有核心维度的配置
    public static var coreConfigs: [(level1: DimensionHierarchy.Level1, color: Color, icon: String)] {
        DimensionHierarchy.coreDimensions.map { level1 in
            (level1: level1, color: DimensionColors.color(for: level1), icon: DimensionIcons.icon(for: level1))
        }
    }
}

// MARK: - ContentType Icons

/// 节点内容类型图标配置
public struct ContentTypeIcons {
    
    /// 内容类型图标映射
    public static let icons: [NodeContentType: String] = [
        .aiTag: "tag.fill",
        .subsystem: "square.grid.2x2.fill",
        .entityRef: "person.crop.circle.fill",
        .nestedList: "list.bullet.indent"
    ]
    
    /// 获取内容类型图标
    public static func icon(for contentType: NodeContentType) -> String {
        icons[contentType] ?? "doc.fill"
    }
}

// MARK: - Confidence Colors

/// 置信度颜色配置
public struct ConfidenceColors {
    
    /// 根据置信度获取颜色
    /// - Parameter confidence: 置信度值 (0.0 ~ 1.0)
    /// - Returns: 对应的颜色
    public static func color(for confidence: Double) -> Color {
        switch confidence {
        case 0.9...1.0:
            return .green           // 高置信度 - 绿色
        case 0.7..<0.9:
            return .blue            // 中高置信度 - 蓝色
        case 0.5..<0.7:
            return .orange          // 中置信度 - 橙色
        default:
            return .red             // 低置信度 - 红色
        }
    }
    
    /// 根据置信度获取显示文本
    /// - Parameter confidence: 置信度值 (0.0 ~ 1.0)
    /// - Returns: 显示文本
    public static func label(for confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0:
            return "高置信度"
        case 0.7..<0.9:
            return "AI推测"
        case 0.5..<0.7:
            return "待确认"
        default:
            return "低置信度"
        }
    }
    
    /// 根据置信度获取图标
    /// - Parameter confidence: 置信度值 (0.0 ~ 1.0)
    /// - Returns: SF Symbol 名称
    public static func icon(for confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0:
            return "checkmark.circle.fill"
        case 0.7..<0.9:
            return "questionmark.circle.fill"
        case 0.5..<0.7:
            return "exclamationmark.circle.fill"
        default:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Source Type Icons

/// 来源类型图标配置
public struct SourceTypeIcons {
    
    /// 来源类型图标映射
    public static let icons: [SourceType: String] = [
        .userInput: "person.fill.checkmark",
        .aiExtracted: "cpu.fill",
        .aiInferred: "sparkles"
    ]
    
    /// 来源类型显示名称
    public static let displayNames: [SourceType: String] = [
        .userInput: "用户输入",
        .aiExtracted: "AI提取",
        .aiInferred: "AI推断"
    ]
    
    /// 获取来源类型图标
    public static func icon(for sourceType: SourceType) -> String {
        icons[sourceType] ?? "doc.fill"
    }
    
    /// 获取来源类型显示名称
    public static func displayName(for sourceType: SourceType) -> String {
        displayNames[sourceType] ?? sourceType.rawValue
    }
}
