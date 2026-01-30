import SwiftUI

/// Typography - 使用 iOS Dynamic Type 支持系统字体大小设置
/// 
/// 所有字体都会跟随用户在「设置 > 辅助功能 > 显示与文字大小」中的设置
public enum Typography {
    // MARK: - 标题 (Titles)
    /// 大标题 - 用于页面主标题 (默认 34pt)
    public static let largeTitle = Font.largeTitle
    /// 标题 - 用于重要标题 (默认 28pt)
    public static let title = Font.title
    /// 二级标题 (默认 22pt)
    public static let title2 = Font.title2
    /// 三级标题 (默认 20pt)
    public static let title3 = Font.title3
    
    // MARK: - 正文 (Body)
    /// 强调文字 - 用于列表标题、按钮等 (默认 17pt semibold)
    public static let headline = Font.headline
    /// 正文 - 主要内容文字 (默认 17pt)
    public static let body = Font.body
    /// 说明文字 (默认 16pt)
    public static let callout = Font.callout
    /// 副标题 - 次要内容 (默认 15pt)
    public static let subheadline = Font.subheadline
    
    // MARK: - 小字 (Small)
    /// 脚注 (默认 13pt)
    public static let footnote = Font.footnote
    /// 标签 (默认 12pt)
    public static let caption = Font.caption
    /// 更小标签 (默认 11pt)
    public static let caption2 = Font.caption2
    
    // MARK: - 特殊样式 (保留向后兼容)
    /// @deprecated 使用 .caption2 代替
    public static let fontEngraved = Font.caption2.weight(.semibold)
    /// 衬线字体 - 用于特殊排版
    public static let fontSerif = Font.system(.body, design: .serif)
    /// @deprecated 使用 .title3 代替
    public static let header = Font.title3.weight(.semibold)
}
