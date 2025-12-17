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
                }
                
                Toggle(isOn: $vm.soundEnabled) {
                    Label(Localization.tr("sounds"), systemImage: "speaker.wave.2.fill")
                }
                
                Toggle(isOn: $vm.badgeEnabled) {
                    Label(Localization.tr("badges"), systemImage: "app.badge.fill")
                }
                
                Toggle(isOn: $vm.dailyReminderEnabled) {
                    Label(Localization.tr("dailyReminder"), systemImage: "calendar.badge.clock")
                }
                
                if vm.dailyReminderEnabled {
                    Picker(selection: $vm.reminderTime) {
                        ForEach(slots, id: \.self) { s in Text(s).tag(s) }
                    } label: {
                        Label(Localization.tr("reminderTime"), systemImage: "clock.fill")
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localization.tr("notifications"))
        .id(appState.lang.rawValue)
    }
}
