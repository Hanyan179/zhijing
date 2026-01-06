import SwiftUI

/// 外观设置页面
/// Requirements: 5.5 - WHEN the user taps "外观", THE Profile_Screen SHALL show appearance settings (light/dark/system)
public struct AppearanceSettingsScreen: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    public init() {}
    
    public var body: some View {
        List {
            Section {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button(action: {
                        appearanceMode = mode
                        applyAppearance(mode)
                    }) {
                        HStack {
                            Label {
                                Text(mode.displayName)
                            } icon: {
                                Image(systemName: mode.iconName)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Colors.indigo)
                            }
                            
                            Spacer()
                            
                            if appearanceMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Colors.indigo)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localization.tr("Appearance.Title"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func applyAppearance(_ mode: AppearanceMode) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        UIView.animate(withDuration: 0.3) {
            window.overrideUserInterfaceStyle = mode.userInterfaceStyle
        }
    }
}

/// 外观模式枚举
public enum AppearanceMode: String, CaseIterable {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light: return Localization.tr("Appearance.Light")
        case .dark: return Localization.tr("Appearance.Dark")
        case .system: return Localization.tr("Appearance.System")
        }
    }
    
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsScreen()
    }
}
