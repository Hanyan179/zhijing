import SwiftUI

public enum AchievementRarity { case common, rare, legendary }

public struct AchievementCard: View {
    public let achievement: UserAchievement
    public init(achievement: UserAchievement) { self.achievement = achievement }

    private var rarity: AchievementRarity {
        switch achievement.definitionId {
        case "def_winter_sea", "def_time_traveler": return .legendary
        case "def_digital_spark", "def_lucid_dreamer", "def_old_soul": return .rare
        default: return .common
        }
    }

    private var containerStyle: (bg: AnyShapeStyle, border: Color, text: Color) {
        switch rarity {
        case .common:
            return (AnyShapeStyle(Colors.slateLight), Colors.slateLight, Color(.sRGB, red: 71/255, green: 85/255, blue: 105/255, opacity: 1))
        case .rare:
            return (AnyShapeStyle(.ultraThinMaterial), Color.white.opacity(0.6), Color(.sRGB, red: 30/255, green: 41/255, blue: 59/255, opacity: 1))
        case .legendary:
            return (AnyShapeStyle(LinearGradient(colors: [Color(.sRGB, red: 2/255, green: 6/255, blue: 23/255, opacity: 1), Color(.sRGB, red: 11/255, green: 13/255, blue: 18/255, opacity: 1)], startPoint: .topLeading, endPoint: .bottomTrailing)), Color.orange.opacity(0.3), Color(.sRGB, red: 250/255, green: 250/255, blue: 250/255, opacity: 1))
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(achievement.aiGeneratedTitle?.zh ?? achievement.aiGeneratedTitle?.en ?? "").font(.headline).foregroundColor(containerStyle.text)
            if let desc = achievement.aiPoeticDescription?.zh ?? achievement.aiPoeticDescription?.en { Text(desc).font(.subheadline).foregroundColor(containerStyle.text.opacity(0.8)) }
            HStack(spacing: 8) {
                Text(NSLocalizedString("current", comment: "")).font(Typography.fontEngraved).foregroundColor(containerStyle.text.opacity(0.7))
                Text(String(format: "%.0f", achievement.progressValue)).font(Typography.fontEngraved).foregroundColor(containerStyle.text.opacity(0.7))
                Text(NSLocalizedString("target", comment: "")).font(Typography.fontEngraved).foregroundColor(containerStyle.text.opacity(0.7))
                Text(String(format: "%.0f", achievement.targetValue)).font(Typography.fontEngraved).foregroundColor(containerStyle.text.opacity(0.7))
                Spacer()
                if achievement.status == .unlocked { Image(systemName: "trophy.fill").foregroundColor(rarity == .legendary ? .orange : .yellow) }
            }
        }
        .padding(16)
        .modifier(Materials.card())
    }
}
