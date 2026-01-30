import SwiftUI

/// 隐私政策占位页面
/// Requirements: 5.1 - WHEN the user taps "隐私政策", THE Profile_Screen SHALL navigate to a privacy policy screen (placeholder)
public struct PrivacyPolicyScreen: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Colors.indigo)
            
            Text(Localization.tr("Profile.PrivacyPolicy"))
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
        .navigationTitle(Localization.tr("Profile.PrivacyPolicy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyScreen()
    }
}
