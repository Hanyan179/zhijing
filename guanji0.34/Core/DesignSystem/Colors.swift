import SwiftUI
import UIKit

public enum Colors {
    public static let background = Color(uiColor: .systemBackground)
    public static let text = Color.primary
    public static let systemGray = Color(uiColor: .systemGray)
    
    public static let slateDark = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .black : .label })
    public static let slatePrimary = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .secondaryLabel })
    public static let slateText = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .white : .label })
    public static let slate600 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .lightGray : .secondaryLabel })
    public static let slate500 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .systemGray : .tertiaryLabel })
    public static let slateLight = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .tertiarySystemBackground : .secondarySystemBackground })
    
    public static let cardBackground = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .secondarySystemBackground : .white })

    // 主题色：纯黑白（亮色模式纯黑，暗色模式纯白）
    public static let indigo = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .white : .black })
    public static let amber = Color(.sRGB, red: 245/255, green: 158/255, blue: 11/255, opacity: 1)
    public static let rose = Color(.sRGB, red: 244/255, green: 63/255, blue: 94/255, opacity: 1)
    public static let emerald = Color(.sRGB, red: 16/255, green: 185/255, blue: 129/255, opacity: 1)
    public static let sky = Color(.sRGB, red: 14/255, green: 165/255, blue: 233/255, opacity: 1)
    public static let violet = Color(.sRGB, red: 139/255, green: 92/255, blue: 246/255, opacity: 1)
    public static let teal = Color(.sRGB, red: 20/255, green: 184/255, blue: 166/255, opacity: 1)
    public static let orange = Color(.sRGB, red: 234/255, green: 88/255, blue: 12/255, opacity: 1)
    public static let pink = Color(.sRGB, red: 236/255, green: 72/255, blue: 153/255, opacity: 1)
    public static let blue = Color(.sRGB, red: 59/255, green: 130/255, blue: 246/255, opacity: 1)
    public static let green = Color(.sRGB, red: 34/255, green: 197/255, blue: 94/255, opacity: 1)
    public static let red = Color(.sRGB, red: 239/255, green: 68/255, blue: 68/255, opacity: 1)
}
