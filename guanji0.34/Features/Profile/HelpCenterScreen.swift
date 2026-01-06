import SwiftUI

/// 帮助中心占位页面
/// Requirements: 5.2 - WHEN the user taps "帮助中心", THE Profile_Screen SHALL navigate to a help center screen (placeholder)
public struct HelpCenterScreen: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 60))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Colors.indigo)
            
            Text(Localization.tr("Profile.HelpCenter"))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(Localization.tr("Profile.FeatureInDevelopment"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Localization.tr("Profile.HelpCenter"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HelpCenterScreen()
    }
}
