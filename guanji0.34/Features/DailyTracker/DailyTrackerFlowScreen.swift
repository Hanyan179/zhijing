import SwiftUI

/// Main screen for Daily Tracker three-step flow
public struct DailyTrackerFlowScreen: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: DailyTrackerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    public let onClose: () -> Void
    
    @State private var editingActivity: ActivityType? = nil
    
    private var robotTheme: RobotMoodTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    /// Initialize for new record
    public init(onClose: @escaping () -> Void) {
        self._vm = StateObject(wrappedValue: DailyTrackerViewModel())
        self.onClose = onClose
    }
    
    /// Initialize for editing existing record
    public init(record: DailyTrackerRecord, onClose: @escaping () -> Void) {
        self._vm = StateObject(wrappedValue: DailyTrackerViewModel(record: record))
        self.onClose = onClose
    }
    
    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(navTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if vm.step == 1 {
                            Button(Localization.tr("cancel")) {
                                onClose()
                            }
                        } else {
                            Button(action: { vm.goBack() }) {
                                Image(systemName: "chevron.left")
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        confirmButton
                    }
                }
        }
        .sheet(item: $editingActivity) { activity in
            if let context = vm.activityContexts[activity] {
                ContextDetailSheet(
                    activity: activity,
                    context: Binding(
                        get: { vm.activityContexts[activity] ?? context },
                        set: { vm.activityContexts[activity] = $0 }
                    )
                ) {
                    editingActivity = nil
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Navigation Title
    
    private var navTitle: String {
        switch vm.step {
        case 1: return Localization.tr("tracker_status")
        case 2: return Localization.tr("tracker_activities")
        case 3: return Localization.tr("tracker_details")
        default: return ""
        }
    }
    
    // MARK: - Confirm Button
    
    @ViewBuilder
    private var confirmButton: some View {
        switch vm.step {
        case 1:
            Button(Localization.tr("next")) {
                vm.goNext()
            }
        case 2:
            // Dual button: Save or Add Details
            Menu {
                Button(Localization.tr("save")) {
                    vm.saveFromStep2()
                    appState.homeValence = vm.moodWeatherLevel
                    // 更新机器人状态
                    appState.updateRobotState(mindValence: vm.moodWeather, bodyEnergy: vm.bodyEnergy)
                    onClose()
                }
                Button(Localization.tr("tracker_add_details")) {
                    vm.goNext()
                }
            } label: {
                Text(Localization.tr("next"))
            }
        case 3:
            Button(Localization.tr("save")) {
                vm.save()
                appState.homeValence = vm.moodWeatherLevel
                // 更新机器人状态
                appState.updateRobotState(mindValence: vm.moodWeather, bodyEnergy: vm.bodyEnergy)
                onClose()
            }
        default:
            EmptyView()
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        switch vm.step {
        case 1:
            step1Content
        case 2:
            step2Content
        case 3:
            step3Content
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 1: Daily Status
    
    private var step1Content: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 机器人预览
                RobotAvatarMood(
                    mindValence: vm.moodWeather,
                    bodyEnergy: vm.bodyEnergy,
                    theme: robotTheme,
                    size: 200
                )
                .padding(.top, 16)
                
                // 身体能量滑块
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(vm.bodyEnergyLevel.color)
                        Text(Localization.tr("body_energy"))
                            .font(.headline)
                    }
                    
                    RobotSliderCard(
                        value: $vm.bodyEnergy,
                        label: Localization.tr(vm.bodyEnergyLevel.titleKey),
                        leftText: Localization.tr("body_collapsed"),
                        rightText: Localization.tr("body_unstoppable"),
                        color: vm.bodyEnergyLevel.color
                    )
                }
                .padding(.horizontal)
                
                // 心情天气滑块
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(moodWeatherColor)
                        Text(Localization.tr("mood_weather"))
                            .font(.headline)
                    }
                    
                    RobotSliderCard(
                        value: $vm.moodWeather,
                        label: Localization.tr(vm.moodWeatherLevel.titleKey),
                        leftText: Localization.tr("mind_very_unpleasant"),
                        rightText: Localization.tr("mind_very_pleasant"),
                        color: moodWeatherColor
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Robot Slider Card
    
    private struct RobotSliderCard: View {
        @Binding var value: Int
        let label: String
        let leftText: String
        let rightText: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 16) {
                Text(label)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                ThickSlider(
                    value: Binding(
                        get: { Double(value) },
                        set: { value = Int(round($0)) }
                    ),
                    range: 0...100,
                    step: 1,
                    leftText: leftText,
                    rightText: rightText,
                    accent: color
                )
                .frame(height: 44)
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    /// Convert MindValence to Color for background
    private var moodWeatherColor: Color {
        switch vm.moodWeatherLevel {
        case .veryUnpleasant, .unpleasant:
            return Color(red: 0.90, green: 0.50, blue: 0.55)
        case .slightlyUnpleasant:
            return Color(red: 0.94, green: 0.60, blue: 0.64)
        case .neutral:
            return Colors.systemGray
        case .slightlyPleasant:
            return Color(red: 0.38, green: 0.74, blue: 0.52)
        case .pleasant, .veryPleasant:
            return Color(red: 0.32, green: 0.68, blue: 0.50)
        }
    }
    
    // MARK: - Step 2: Activity Selection
    
    private var step2Content: some View {
        ScrollView {
            ActivitySelectionView(
                selectedActivities: $vm.selectedActivities,
                onToggle: { vm.toggleActivity($0) }
            )
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Step 3: Context Details
    
    private var step3Content: some View {
        ScrollView {
            ContextCardList(
                activities: vm.sortedSelectedActivities,
                contexts: vm.activityContexts,
                onSelectActivity: { activity in
                    // Ensure context exists before editing
                    if vm.activityContexts[activity] == nil {
                        vm.activityContexts[activity] = ActivityContext(
                            activityType: activity,
                            companions: activity.defaultCompanions
                        )
                    }
                    editingActivity = activity
                }
            )
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            vm.initializeContexts()
        }
    }
}

// Note: ActivityType already conforms to Identifiable in DailyTrackerModels.swift
