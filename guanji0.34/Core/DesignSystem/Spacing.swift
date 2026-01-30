import SwiftUI

/// Spacing - 标准间距常量
///
/// 使用 4pt 基础网格系统，所有间距都是 4 的倍数
public enum Spacing {
    // MARK: - 基础间距
    /// 最小间距 (4pt)
    public static let xxs: CGFloat = 4
    /// 超小间距 (6pt)
    public static let xs: CGFloat = 6
    /// 小间距 (8pt)
    public static let sm: CGFloat = 8
    /// 中间距 (12pt)
    public static let md: CGFloat = 12
    /// 默认间距 (16pt)
    public static let base: CGFloat = 16
    /// 大间距 (20pt)
    public static let lg: CGFloat = 20
    /// 超大间距 (24pt)
    public static let xl: CGFloat = 24
    /// 最大间距 (32pt)
    public static let xxl: CGFloat = 32
    
    // MARK: - 语义化间距
    /// 组件内部间距
    public static let inset: CGFloat = 12
    /// 卡片内边距
    public static let cardPadding: CGFloat = 16
    /// 列表项间距
    public static let listItemSpacing: CGFloat = 12
    /// 区块间距
    public static let sectionSpacing: CGFloat = 24
    /// 页面边距
    public static let pageMargin: CGFloat = 16
}

/// CornerRadius - 标准圆角常量
public enum CornerRadius {
    /// 小圆角 (4pt) - 用于小标签、badge
    public static let xs: CGFloat = 4
    /// 默认圆角 (8pt) - 用于按钮、输入框
    public static let sm: CGFloat = 8
    /// 中圆角 (10pt)
    public static let md: CGFloat = 10
    /// 大圆角 (12pt) - 用于卡片
    public static let lg: CGFloat = 12
    /// 超大圆角 (16pt) - 用于模态框
    public static let xl: CGFloat = 16
    /// 最大圆角 (20pt)
    public static let xxl: CGFloat = 20
    /// 圆形 (用于头像等)
    public static let full: CGFloat = 9999
}

/// IconSize - 标准图标尺寸
public enum IconSize {
    /// 超小图标 (12pt)
    public static let xs: CGFloat = 12
    /// 小图标 (14pt)
    public static let sm: CGFloat = 14
    /// 默认图标 (16pt)
    public static let md: CGFloat = 16
    /// 大图标 (18pt)
    public static let lg: CGFloat = 18
    /// 超大图标 (20pt)
    public static let xl: CGFloat = 20
    /// 巨大图标 (24pt)
    public static let xxl: CGFloat = 24
    /// 展示图标 (32pt)
    public static let display: CGFloat = 32
    /// 特大展示图标 (48pt)
    public static let hero: CGFloat = 48
}

/// ButtonSize - 标准按钮尺寸
public enum ButtonSize {
    /// 小按钮 (32pt)
    public static let sm: CGFloat = 32
    /// 默认按钮 (44pt) - iOS 推荐最小触摸目标
    public static let md: CGFloat = 44
    /// 大按钮 (50pt)
    public static let lg: CGFloat = 50
    /// 超大按钮 (56pt)
    public static let xl: CGFloat = 56
}

/// AvatarSize - 标准头像尺寸
public enum AvatarSize {
    /// 超小头像 (28pt)
    public static let xs: CGFloat = 28
    /// 小头像 (32pt)
    public static let sm: CGFloat = 32
    /// 默认头像 (40pt)
    public static let md: CGFloat = 40
    /// 大头像 (44pt)
    public static let lg: CGFloat = 44
    /// 超大头像 (60pt)
    public static let xl: CGFloat = 60
    /// 展示头像 (80pt)
    public static let display: CGFloat = 80
}
