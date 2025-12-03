import SwiftUI
import Foundation

public struct NotificationsScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    private let slots: [String] = ["08:00", "12:00", "20:00"]
    public var body: some View {
        VStack(spacing: 12) {
            GroupLabel(label: Localization.tr("notifications"))
            ListGroup {
                HStack {
                    HStack(spacing: 12) { Image(systemName: "bell.badge").foregroundColor(Color(.systemGray)); Text(Localization.tr("pushNotifications")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                    Spacer()
                    ToggleSwitch(checked: $vm.pushEnabled)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                HStack {
                    HStack(spacing: 12) { Image(systemName: "speaker.wave.2").foregroundColor(Color(.systemGray)); Text(Localization.tr("sounds")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                    Spacer()
                    ToggleSwitch(checked: $vm.soundEnabled)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                HStack {
                    HStack(spacing: 12) { Image(systemName: "app.badge").foregroundColor(Color(.systemGray)); Text(Localization.tr("badges")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                    Spacer()
                    ToggleSwitch(checked: $vm.badgeEnabled)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                HStack {
                    HStack(spacing: 12) { Image(systemName: "calendar.badge.clock").foregroundColor(Color(.systemGray)); Text(Localization.tr("dailyReminder")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                    Spacer()
                    ToggleSwitch(checked: $vm.dailyReminderEnabled)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.2)), alignment: .bottom)

                if vm.dailyReminderEnabled {
                    HStack {
                        HStack(spacing: 12) { Image(systemName: "clock").foregroundColor(Colors.systemGray); Text(Localization.tr("reminderTime")).font(.system(size: 14, weight: .medium)).foregroundColor(Colors.slateText) }
                        Spacer()
                        Picker("", selection: $vm.reminderTime) {
                            ForEach(slots, id: \.self) { s in Text(s).tag(s) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
        .id(appState.lang.rawValue)
    }
}
