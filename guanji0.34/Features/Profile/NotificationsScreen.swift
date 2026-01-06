import SwiftUI
import Foundation

public struct NotificationsScreen: View {
    @ObservedObject public var vm: ProfileViewModel
    @EnvironmentObject private var appState: AppState
    public init(vm: ProfileViewModel) { self.vm = vm }
    private let slots: [String] = ["08:00", "12:00", "20:00"]
    public var body: some View {
        List {
            Section {
                Toggle(isOn: $vm.pushEnabled) {
                    Label(Localization.tr("pushNotifications"), systemImage: "bell.badge.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Colors.indigo)
                }
                
                Toggle(isOn: $vm.soundEnabled) {
                    Label(Localization.tr("sounds"), systemImage: "speaker.wave.2.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Colors.indigo)
                }
                
                Toggle(isOn: $vm.badgeEnabled) {
                    Label(Localization.tr("badges"), systemImage: "app.badge.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Colors.indigo)
                }
                
                Toggle(isOn: $vm.dailyReminderEnabled) {
                    Label(Localization.tr("dailyReminder"), systemImage: "calendar.badge.clock")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Colors.indigo)
                }
                
                if vm.dailyReminderEnabled {
                    Picker(selection: $vm.reminderTime) {
                        ForEach(slots, id: \.self) { s in Text(s).tag(s) }
                    } label: {
                        Label(Localization.tr("reminderTime"), systemImage: "clock.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Colors.indigo)
                    }
                    .pickerStyle(.menu)
                    .tint(Colors.indigo)
                }
            }
        }
        .listStyle(.insetGrouped)
        .tint(Colors.indigo)
        .navigationTitle(Localization.tr("notifications"))
        .id(appState.lang.rawValue)
    }
}
