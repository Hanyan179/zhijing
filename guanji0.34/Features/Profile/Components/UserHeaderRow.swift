import SwiftUI

/// 用户头部组件 - 显示头像占位、昵称
/// Requirements: 1.1, 1.2, 1.3
struct UserHeaderRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // 头像占位圆形
            Circle()
                .fill(Colors.slateLight)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(Colors.indigo)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.tr("Profile.SetNickname"))
                    .font(.headline)
                Text(Localization.tr("Profile.TapToEdit"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        Section {
            NavigationLink(destination: EmptyView()) {
                UserHeaderRow()
            }
        }
    }
    .listStyle(.insetGrouped)
}
