import SwiftUI

/// 意见反馈占位页面
/// Requirements: 5.3 - WHEN the user taps "意见反馈", THE Profile_Screen SHALL navigate to a feedback screen (placeholder)
public struct FeedbackScreen: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "envelope.fill")
                .font(.system(size: 60))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Colors.indigo)
            
            Text(Localization.tr("Profile.Feedback"))
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
        .navigationTitle(Localization.tr("Profile.Feedback"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FeedbackScreen()
    }
}
