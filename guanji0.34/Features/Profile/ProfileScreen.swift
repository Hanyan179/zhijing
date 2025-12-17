import SwiftUI
import Foundation

public struct ProfileScreen: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var showInsight = false
    @State private var showLangPicker = false
    @State private var showAISettings = false
    @EnvironmentObject private var appState: AppState
    public init() {}
    public var body: some View {
        NavigationStack {
            List {
                Section(Localization.tr("osModules")) {
                    NavigationLink(destination: NotificationsScreen(vm: vm)) {
                        Label(Localization.tr("notifications"), systemImage: "bell.badge.fill")
                    }
                    NavigationLink(destination: DataMaintenanceScreen(vm: vm)) {
                        Label(Localization.tr("dataMaintenance"), systemImage: "externaldrive.fill")
                    }
                }
                
                Section(Localization.tr("lifeInsight")) {
                    NavigationLink(destination: MembershipScreen(vm: vm)) {
                        HStack {
                            Label(Localization.tr("insightPlan"), systemImage: "crown.fill")
                            Spacer()
                            Text(vm.userPlan)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink(destination: ComponentGalleryScreen()) {
                        Label(Localization.tr("componentLibrary"), systemImage: "square.stack.3d.up.fill")
                    }
                }
                
                // AI Settings Section - Requirements 5.1, 5.2
                Section(Localization.tr("AI.Settings.Section")) {
                    Button(action: { showAISettings = true }) {
                        HStack {
                            Label(Localization.tr("AI.Settings.Title"), systemImage: "sparkles")
                            Spacer()
                            Text(AISettingsRepository.shared.isAPIKeyConfigured ? Localization.tr("AI.Configured") : Localization.tr("AI.NotConfigured"))
                                .font(.caption)
                                .foregroundStyle(AISettingsRepository.shared.isAPIKeyConfigured ? Colors.green : .secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    // Default Mode Setting - Requirements 5.1, 5.2
                    HStack {
                        Label(Localization.tr("AI.DefaultMode"), systemImage: "rectangle.stack")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { UserPreferencesRepository.shared.defaultMode },
                            set: { UserPreferencesRepository.shared.defaultMode = $0 }
                        )) {
                            Text(Localization.tr("AI.Mode.Journal")).tag(AppMode.journal)
                            Text(Localization.tr("AI.Mode.AI")).tag(AppMode.ai)
                        }
                        .pickerStyle(.menu)
                        .tint(Colors.indigo)
                    }
                }
                
                Section(Localization.tr("system")) {
                    Button(action: { showLangPicker = true }) {
                        HStack {
                            Label(Localization.tr("language"), systemImage: "globe")
                            Spacer()
                            Text(Localization.displayName(appState.lang))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    HStack {
                        Label(Localization.tr("dataSync"), systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        Text("On")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    NavigationLink(destination: AboutScreen()) {
                        Label(Localization.tr("about"), systemImage: "info.circle")
                    }
                    NavigationLink(destination: SubscriptionInfoScreen(vm: vm)) {
                        Label(Localization.tr("subscriptionInfo"), systemImage: "doc.text.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .tint(Colors.indigo)
            .navigationTitle(Localization.tr("profileTitle"))
            .onAppear { vm.loadAddresses() }
        }
        .sheet(isPresented: $showInsight) { InsightSheet() }
        .sheet(isPresented: $showLangPicker) { LanguagePickerSheet(selected: $appState.lang) }
        .sheet(isPresented: $showAISettings) { AISettingsScreen() }
    }
}

struct ProfileDetailContainer: View { var body: some View { EmptyView() } }

struct LanguagePickerSheet: View {
    @Binding var selected: Lang
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Localization.supported, id: \.self) { l in
                    Button(action: {
                        selected = l
                        Localization.set(l)
                        dismiss()
                    }) {
                        HStack {
                            Text(Localization.displayName(l))
                                .foregroundStyle(.primary)
                            if l == selected {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Colors.indigo)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Localization.tr("language"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
