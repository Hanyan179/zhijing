import SwiftUI
import Foundation
import StoreKit

public struct ProfileScreen: View {
    @StateObject private var vm = ProfileViewModel()
    /// 认证服务
    /// - Requirements: 10.1
    @StateObject private var authService = AuthService.shared
    @State private var showInsight = false
    @State private var showLangPicker = false
    @State private var showAISettings = false
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    @EnvironmentObject private var appState: AppState
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Section 1: 用户信息 (无标题)
                // Requirements: 1.1, 1.2, 1.3, 1.4
                Section {
                    NavigationLink(destination: ProfileEditScreen()) {
                        UserHeaderRow()
                    }
                }
                
                // MARK: - Section 2: 功能与服务
                // Requirements: 2.2
                Section(Localization.tr("Profile.Section.Features")) {
                    // 人生回顾
                    NavigationLink(destination: LifeReviewScreen()) {
                        Label {
                            Text(Localization.tr("Profile.LifeReview"))
                        } icon: {
                            Image(systemName: "brain.head.profile")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                    
                    // 我的羁绊（人员管理）
                    NavigationLink(destination: NarrativeRelationshipListScreen(viewModel: NarrativeRelationshipViewModel())) {
                        Label {
                            Text(Localization.tr("Profile.MyBonds"))
                        } icon: {
                            Image(systemName: "person.2.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                    
                    // 地点管理
                    NavigationLink(destination: LocationListScreen(vm: vm)) {
                        Label {
                            Text(Localization.tr("locationManagement"))
                        } icon: {
                            Image(systemName: "map")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                    
                    // 数据统计
                    Button(action: { showInsight = true }) {
                        HStack {
                            Label {
                                Text(Localization.tr("Profile.DataStats"))
                            } icon: {
                                Image(systemName: "chart.bar.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Colors.indigo)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    // 会员计划
                    NavigationLink(destination: MembershipScreen(vm: vm)) {
                        HStack {
                            Label {
                                Text(Localization.tr("insightPlan"))
                            } icon: {
                                Image(systemName: "crown.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Colors.indigo)
                            }
                            Spacer()
                            Text(vm.userPlan)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - Section 3: 偏好设置
                // Requirements: 2.3
                Section(Localization.tr("Profile.Section.Preferences")) {
                    // AI设置
                    Button(action: { showAISettings = true }) {
                        HStack {
                            Label {
                                Text(Localization.tr("AI.Settings.Title"))
                            } icon: {
                                Image(systemName: "sparkles")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Colors.indigo)
                            }
                            Spacer()
                            Text(authService.isAuthenticated ? Localization.tr("AI.Configured") : Localization.tr("AI.NotConfigured"))
                                .font(.caption)
                                .foregroundStyle(authService.isAuthenticated ? Colors.green : .secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    // 默认模式
                    HStack {
                        Label {
                            Text(Localization.tr("AI.DefaultMode"))
                        } icon: {
                            Image(systemName: "rectangle.stack")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
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
                    
                    // 通知
                    NavigationLink(destination: NotificationsScreen(vm: vm)) {
                        Label {
                            Text(Localization.tr("notifications"))
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                    
                    // 语言
                    Button(action: { showLangPicker = true }) {
                        HStack {
                            Label {
                                Text(Localization.tr("language"))
                            } icon: {
                                Image(systemName: "globe")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Colors.indigo)
                            }
                            Spacer()
                            Text(Localization.displayName(appState.lang))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    // 外观
                    NavigationLink(destination: AppearanceSettingsScreen()) {
                        Label {
                            Text(Localization.tr("Profile.Appearance"))
                        } icon: {
                            Image(systemName: "circle.lefthalf.filled")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                }
                
                // MARK: - Section 4: 隐私与安全
                // Requirements: 2.4
                Section(Localization.tr("Profile.Section.Privacy")) {
                    // 数据同步
                    HStack {
                        Label {
                            Text(Localization.tr("dataSync"))
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                        Spacer()
                        Text("On")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // 数据维护
                    NavigationLink(destination: DataMaintenanceScreen(vm: vm)) {
                        Label {
                            Text(Localization.tr("dataMaintenance"))
                        } icon: {
                            Image(systemName: "externaldrive.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                    
                    // 隐私政策
                    NavigationLink(destination: PrivacyPolicyScreen()) {
                        Label {
                            Text(Localization.tr("Profile.PrivacyPolicy"))
                        } icon: {
                            Image(systemName: "hand.raised.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                }
                
                // MARK: - Section 5: 支持与反馈
                // Requirements: 2.5
                Section(Localization.tr("Profile.Section.Support")) {
                    // 帮助中心
                    NavigationLink(destination: HelpCenterScreen()) {
                        Label {
                            Text(Localization.tr("Profile.HelpCenter"))
                        } icon: {
                            Image(systemName: "questionmark.circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                    
                    // 意见反馈
                    NavigationLink(destination: FeedbackScreen()) {
                        Label {
                            Text(Localization.tr("Profile.Feedback"))
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                    
                    // 给我们评分
                    Button(action: requestAppStoreReview) {
                        HStack {
                            Label {
                                Text(Localization.tr("Profile.RateUs"))
                            } icon: {
                                Image(systemName: "star.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Colors.indigo)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                // MARK: - Section 6: 关于
                // Requirements: 2.6
                Section(Localization.tr("Profile.Section.About")) {
                    // 关于
                    NavigationLink(destination: AboutScreen()) {
                        Label {
                            Text(Localization.tr("about"))
                        } icon: {
                            Image(systemName: "info.circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                    
                    // 订阅信息
                    NavigationLink(destination: SubscriptionInfoScreen(vm: vm)) {
                        Label {
                            Text(Localization.tr("subscriptionInfo"))
                        } icon: {
                            Image(systemName: "doc.text.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Colors.indigo)
                        }
                    }
                }
                
                // MARK: - Section 7: 账户
                // Requirements: 5.1, 11.5
                if authService.isAuthenticated {
                    Section {
                        // 登出按钮
                        // - Requirements: 5.1, 11.5
                        Button(action: { showLogoutConfirmation = true }) {
                            HStack {
                                Label {
                                    Text(Localization.tr("auth.signOut"))
                                } icon: {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(Colors.red)
                                }
                                Spacer()
                                if isLoggingOut {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .foregroundStyle(Colors.red)
                        .disabled(isLoggingOut)
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
        .alert(Localization.tr("auth.signOut.confirm.title"), isPresented: $showLogoutConfirmation) {
            Button(Localization.tr("cancel"), role: .cancel) { }
            Button(Localization.tr("auth.signOut"), role: .destructive) {
                performLogout()
            }
        } message: {
            Text(Localization.tr("auth.signOut.confirm.message"))
        }
    }
    
    // MARK: - Logout
    // Requirements: 5.1, 11.5, 10.1
    private func performLogout() {
        isLoggingOut = true
        Task {
            do {
                try await authService.logout()
            } catch {
                // Error is handled by authService, local data is still cleared
                print("[ProfileScreen] Logout error: \(error.localizedDescription)")
            }
            await MainActor.run {
                isLoggingOut = false
            }
        }
    }
    
    // MARK: - App Store Review
    // Requirements: 5.4
    private func requestAppStoreReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
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
            .listStyle(.insetGrouped)
            .tint(Colors.indigo)
            .navigationTitle(Localization.tr("language"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
