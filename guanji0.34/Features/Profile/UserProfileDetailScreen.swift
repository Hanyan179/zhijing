import SwiftUI

/// User Profile Detail Screen with tab navigation for Kernel and State data
/// Requirements: Epic 1-5
public struct UserProfileDetailScreen: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @StateObject private var relationshipViewModel = RelationshipProfileViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: ProfileTab = .kernel
    @State private var showComingSoonAlert = false
    @State private var selectedRelationship: RelationshipProfile?
    
    enum ProfileTab: String, CaseIterable {
        case kernel
        case state
        
        var title: String {
            switch self {
            case .kernel: return Localization.tr("profileKernel")
            case .state: return Localization.tr("profileState")
            }
        }
        
        var accessibilityLabel: String {
            switch self {
            case .kernel: return Localization.tr("profileKernel")
            case .state: return Localization.tr("profileState")
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab Picker with accessibility
            Picker(Localization.tr("myProfile"), selection: $selectedTab) {
                ForEach(ProfileTab.allCases, id: \.self) { tab in
                    Text(tab.title)
                        .tag(tab)
                        .accessibilityLabel(tab.accessibilityLabel)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .accessibilityIdentifier("profileTabPicker")
            
            // Content based on selected tab
            if selectedTab == .kernel {
                kernelContent
            } else {
                stateContent
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Localization.tr("myProfile"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if selectedTab == .kernel {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Future: UserProfileEditScreen for Kernel editing
                    Button(Localization.tr("edit")) {
                        showComingSoonAlert = true
                    }
                    .disabled(true)
                    .accessibilityLabel(Localization.tr("edit"))
                    .accessibilityHint(Localization.tr("comingSoon"))
                }
            }
        }
        .alert(Localization.tr("comingSoon"), isPresented: $showComingSoonAlert) {
            Button(Localization.tr("ok"), role: .cancel) {}
        }
        .id(appState.lang.rawValue)
    }
    
    // MARK: - Kernel Content (Long-term stable data)
    
    private var kernelContent: some View {
        List {
            // 1. Identity Dimension
            identityKernelSection
            
            // 2. Personality Dimension
            personalityKernelSection
            
            // 3. Social Dimension
            socialKernelSection
            
            // 4. Competence Dimension
            competenceKernelSection
            
            // 5. Lifestyle Dimension
            lifestyleKernelSection
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - State Content (Short-term changing data)
    
    private var stateContent: some View {
        List {
            // 1. Identity State
            identityStateSection
            
            // 2. Personality State
            personalityStateSection
            
            // 3. Social State
            socialStateSection
            
            // 4. Competence State
            competenceStateSection
            
            // 5. Lifestyle State
            lifestyleStateSection
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Kernel Sections

extension UserProfileDetailScreen {
    
    private var identityKernelSection: some View {
        Section {
            let kernel = viewModel.identityKernel
            
            ProfileRow(label: "field_gender", value: kernel.gender?.localizedValue ?? Localization.tr("notSet"))
            ProfileRow(label: "field_birthDate", value: viewModel.displayValue(kernel.birthDate))
            ProfileRow(label: "field_height", value: viewModel.displayValue(kernel.height, unit: "unit_cm"))
            ProfileRow(label: "field_weight", value: viewModel.displayValue(kernel.weight, unit: "unit_kg"))
            ProfileRow(label: "field_bloodType", value: kernel.bloodType?.localizedValue ?? Localization.tr("notSet"))
            ProfileRow(label: "field_chronicConditions", value: viewModel.displayValue(kernel.chronicConditions))
            ProfileRow(label: "field_basePhysicalCondition", value: kernel.basePhysicalCondition.localizedValue)
            ProfileRow(label: "field_geneticTraits", value: viewModel.displayValue(kernel.geneticTraits ?? []))
            ProfileRow(label: "field_hometown", value: viewModel.displayValue(kernel.hometown))
            ProfileRow(label: "field_currentCity", value: viewModel.displayValue(kernel.currentCity))
            ProfileRow(label: "field_education", value: kernel.education?.localizedValue ?? Localization.tr("notSet"))
            ProfileRow(label: "field_maritalStatus", value: kernel.maritalStatus?.localizedValue ?? Localization.tr("notSet"))
        } header: {
            DimensionHeader(icon: "figure.stand", title: "dim_identity")
        }
    }
    
    private var personalityKernelSection: some View {
        Section {
            let kernel = viewModel.personalityKernel
            
            ProfileRow(label: "field_mbtiType", value: viewModel.displayValue(kernel.mbtiType))
            
            if let bigFive = kernel.bigFive {
                BigFiveRow(scores: bigFive)
            } else {
                ProfileRow(label: "field_bigFive", value: Localization.tr("notSet"))
            }
            
            if !kernel.valuePriorities.isEmpty {
                CoreValuesRow(values: kernel.valuePriorities)
            } else {
                ProfileRow(label: "field_valuePriorities", value: Localization.tr("notSet"))
            }
            
            ProfileRow(label: "field_decisionMode", value: kernel.decisionMode.localizedValue)
            ProfileRow(label: "field_riskPreference", value: kernel.riskPreference.localizedValue)
        } header: {
            DimensionHeader(icon: "brain.head.profile", title: "dim_personality")
        }
    }
    
    private var socialKernelSection: some View {
        Section {
            let kernel = viewModel.socialKernel
            
            // Core relationships - tappable rows
            // Requirements: Story 3.1
            if !kernel.coreRelationshipIDs.isEmpty {
                ForEach(kernel.coreRelationshipIDs, id: \.self) { relationshipID in
                    if let profile = relationshipViewModel.getProfile(id: relationshipID) {
                        NavigationLink {
                            RelationshipDetailScreen(profile: profile, viewModel: relationshipViewModel)
                        } label: {
                            CoreRelationshipRow(profile: profile)
                        }
                    }
                }
            } else {
                ProfileRow(label: "field_coreRelationships", value: Localization.tr("notSet"))
            }
            
            ProfileRow(label: "field_socialType", value: kernel.socialType.localizedValue)
            ProfileRow(label: "field_socialEnergy", value: kernel.socialEnergy.localizedValue)
            ProfileRow(label: "field_familyStructure", value: kernel.familyStructure.localizedValue)
        } header: {
            DimensionHeader(icon: "person.2", title: "dim_social")
        }
    }
    
    private var competenceKernelSection: some View {
        Section {
            let kernel = viewModel.competenceKernel
            
            ProfileRow(label: "field_occupation", value: viewModel.displayValue(kernel.occupation))
            ProfileRow(label: "field_industry", value: viewModel.displayValue(kernel.industry))
            ProfileRow(label: "field_employmentStatus", value: kernel.employmentStatus.localizedValue)
            ProfileRow(label: "field_skills", value: viewModel.displayValue(kernel.skills))
            ProfileRow(label: "field_expertise", value: viewModel.displayValue(kernel.expertise))
            ProfileRow(label: "field_consumptionLevel", value: kernel.consumptionLevel.localizedValue)
            ProfileRow(label: "field_debtStatus", value: kernel.debtStatus.localizedValue)
        } header: {
            DimensionHeader(icon: "briefcase", title: "dim_competence")
        }
    }
    
    private var lifestyleKernelSection: some View {
        Section {
            let kernel = viewModel.lifestyleKernel
            
            ProfileRow(label: "field_chronoType", value: kernel.chronoType.localizedValue)
            ProfileRow(label: "field_averageSleepHours", value: viewModel.displayValue(kernel.averageSleepHours, unit: "unit_hours"))
            ProfileRow(label: "field_longTermHobbies", value: viewModel.displayValue(kernel.longTermHobbies))
            ProfileRow(label: "field_hobbyIntensity", value: kernel.hobbyIntensity.localizedValue)
            ProfileRow(label: "field_tastePreferences", value: viewModel.displayValue(kernel.tastePreferences))
            ProfileRow(label: "field_dietType", value: kernel.dietType.localizedValue)
            ProfileRow(label: "field_foodRestrictions", value: viewModel.displayValue(kernel.foodRestrictions))
        } header: {
            DimensionHeader(icon: "heart.text.square", title: "dim_lifestyle")
        }
    }
}

// MARK: - State Sections

extension UserProfileDetailScreen {
    
    private var identityStateSection: some View {
        Section {
            let state = viewModel.identityState
            
            ProfileRow(label: "field_isSick", value: state.isSick ? Localization.tr("bool_yes") : Localization.tr("bool_no"))
            if state.isSick {
                ProfileRow(label: "field_sicknessType", value: viewModel.displayValue(state.sicknessType))
                ProfileRow(label: "field_painLocation", value: viewModel.displayValue(state.painLocation))
            }
            ProfileRow(label: "field_bodyEnergy", value: viewModel.displayEnergyLevel(state.bodyEnergy))
            ProfileRow(label: "field_sleepQuality", value: state.sleepQuality.localizedValue)
            ProfileRow(label: "field_exerciseLevel", value: state.exerciseLevel.localizedValue)
            ProfileRow(label: "field_hungerLevel", value: viewModel.displayScale5(state.hungerLevel))
            ProfileRow(label: "field_thirstLevel", value: viewModel.displayScale5(state.thirstLevel))
            ProfileRow(label: "field_fatigueLevel", value: viewModel.displayScale5(state.fatigueLevel))
            
            LastUpdatedRow(date: state.lastUpdatedAt)
        } header: {
            DimensionHeader(icon: "figure.stand", title: "dim_identity")
        }
    }
    
    private var personalityStateSection: some View {
        Section {
            let state = viewModel.personalityState
            
            ProfileRow(label: "field_happiness", value: viewModel.displayScale(state.happiness))
            ProfileRow(label: "field_anxiety", value: viewModel.displayScale(state.anxiety))
            ProfileRow(label: "field_anger", value: viewModel.displayScale(state.anger))
            ProfileRow(label: "field_calmness", value: viewModel.displayScale(state.calmness))
            ProfileRow(label: "field_moodWeather", value: viewModel.displayEnergyLevel(state.moodWeather))
            ProfileRow(label: "field_moodDescription", value: state.moodDescription.localizedValue)
            ProfileRow(label: "field_currentStressors", value: viewModel.displayValue(state.currentStressors))
            ProfileRow(label: "field_stressLevel", value: viewModel.displayScale(state.stressLevel))
            
            LastUpdatedRow(date: state.lastUpdatedAt)
        } header: {
            DimensionHeader(icon: "brain.head.profile", title: "dim_personality")
        }
    }
    
    private var socialStateSection: some View {
        Section {
            let state = viewModel.socialState
            
            ProfileRow(label: "field_recentSocialFrequency", value: state.recentSocialFrequency.localizedValue)
            ProfileRow(label: "field_socialSatisfaction", value: viewModel.displayScale(state.socialSatisfaction))
            ProfileRow(label: "field_relationshipsImproving", value: "\(state.relationshipsImproving.count) \(Localization.tr("unit_people"))")
            ProfileRow(label: "field_relationshipsTense", value: "\(state.relationshipsTense.count) \(Localization.tr("unit_people"))")
            ProfileRow(label: "field_companionshipNeed", value: state.companionshipNeed.localizedValue)
            
            LastUpdatedRow(date: state.lastUpdatedAt)
        } header: {
            DimensionHeader(icon: "person.2", title: "dim_social")
        }
    }
    
    private var competenceStateSection: some View {
        Section {
            let state = viewModel.competenceState
            
            ProfileRow(label: "field_workIntensity", value: state.workIntensity.localizedValue)
            ProfileRow(label: "field_workStatus", value: state.workStatus.localizedValue)
            ProfileRow(label: "field_currentTasks", value: viewModel.displayValue(state.currentTasks))
            ProfileRow(label: "field_taskPressure", value: viewModel.displayScale(state.taskPressure))
            ProfileRow(label: "field_achievementStatus", value: state.achievementStatus.localizedValue)
            ProfileRow(label: "field_careerSatisfaction", value: viewModel.displayScale(state.careerSatisfaction))
            
            LastUpdatedRow(date: state.lastUpdatedAt)
        } header: {
            DimensionHeader(icon: "briefcase", title: "dim_competence")
        }
    }
    
    private var lifestyleStateSection: some View {
        Section {
            let state = viewModel.lifestyleState
            
            ProfileRow(label: "field_currentInterests", value: viewModel.displayValue(state.currentInterests))
            ProfileRow(label: "field_interestDuration", value: viewModel.displayValue(state.interestDuration, unit: "unit_days"))
            ProfileRow(label: "field_recentEvents", value: viewModel.displayValue(state.recentEvents))
            ProfileRow(label: "field_eventImpact", value: state.eventImpact.localizedValue)
            ProfileRow(label: "field_planCompletionRate", value: viewModel.displayScale(state.planCompletionRate))
            ProfileRow(label: "field_procrastinationLevel", value: viewModel.displayScale(state.procrastinationLevel))
            
            LastUpdatedRow(date: state.lastUpdatedAt)
        } header: {
            DimensionHeader(icon: "heart.text.square", title: "dim_lifestyle")
        }
    }
}

// MARK: - Helper Views

private struct DimensionHeader: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Colors.indigo)
                .imageScale(.medium)
                .accessibilityHidden(true)
            Text(Localization.tr(title))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localization.tr(title))
    }
}

private struct ProfileRow: View {
    let label: String
    let value: String
    
    private var isNotSet: Bool {
        value == Localization.tr("notSet")
    }
    
    var body: some View {
        HStack {
            Text(Localization.tr(label))
                .font(.body)
                .foregroundStyle(.secondary)
                .layoutPriority(1)
            Spacer(minLength: 16)
            Text(value)
                .font(.body)
                .foregroundStyle(isNotSet ? .tertiary : .primary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Localization.tr(label)): \(value)")
    }
}

private struct LastUpdatedRow: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(Localization.tr("lastUpdated"))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatDate(date))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Localization.tr("lastUpdated")): \(formatDate(date))")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Row for displaying a core relationship with avatar and name
/// Requirements: Story 3.1
private struct CoreRelationshipRow: View {
    let profile: RelationshipProfile
    
    var body: some View {
        HStack(spacing: 12) {   
            // Avatar
            Text(profile.avatar ?? "👤")
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            // Name and type
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: profile.type.iconName)
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text(Localization.tr(profile.type.localizedKey))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Intimacy indicator
            IntimacyIndicator(level: profile.intimacyLevel)
                .accessibilityLabel("\(Localization.tr("intimacyLevel")): \(profile.intimacyLevel)/10")
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.displayName), \(Localization.tr(profile.type.localizedKey)), \(Localization.tr("intimacyLevel")) \(profile.intimacyLevel)/10")
        .accessibilityHint(Localization.tr("tapToJump"))
    }
}

// Note: IntimacyIndicator is defined in RelationshipManagementScreen.swift and reused here

private struct BigFiveRow: View {
    let scores: BigFiveScores
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("field_bigFive"))
                .font(.body)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                BigFiveItem(label: "bigFive_openness", value: scores.openness)
                BigFiveItem(label: "bigFive_conscientiousness", value: scores.conscientiousness)
                BigFiveItem(label: "bigFive_extraversion", value: scores.extraversion)
                BigFiveItem(label: "bigFive_agreeableness", value: scores.agreeableness)
                BigFiveItem(label: "bigFive_neuroticism", value: scores.neuroticism)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Localization.tr("field_bigFive"))
    }
}

private struct BigFiveItem: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Text(Localization.tr(label))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, alignment: .leading)
            
            ProgressView(value: Double(value), total: 10)
                .progressViewStyle(.linear)
                .tint(Colors.indigo)
                .frame(maxWidth: .infinity)
            
            Text("\(value)")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(width: 24, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Localization.tr(label)): \(value)/10")
        .accessibilityValue("\(value * 10)%")
    }
}

private struct CoreValuesRow: View {
    let values: [CoreValue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.tr("field_valuePriorities"))
                .font(.body)
                .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    HStack(spacing: 4) {
                        Text("\(index + 1).")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.tertiary)
                        Text(value.localizedValue)
                            .font(.footnote)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Colors.indigo.opacity(0.1))
                    .clipShape(Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(index + 1). \(value.localizedValue)")
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Localization.tr("field_valuePriorities"))
    }
}

// Simple flow layout for tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Enum Extensions for Localization

extension Gender {
    var localizedValue: String {
        Localization.tr("enum_gender_\(rawValue)")
    }
}

extension BloodType {
    var localizedValue: String {
        Localization.tr("enum_bloodType_\(rawValue)")
    }
}

extension PhysicalCondition {
    var localizedValue: String {
        Localization.tr("enum_physicalCondition_\(rawValue)")
    }
}

extension Education {
    var localizedValue: String {
        Localization.tr("enum_education_\(rawValue)")
    }
}

extension MaritalStatus {
    var localizedValue: String {
        Localization.tr("enum_maritalStatus_\(rawValue)")
    }
}

extension SleepQuality {
    var localizedValue: String {
        Localization.tr("enum_sleepQuality_\(rawValue)")
    }
}

extension ExerciseLevel {
    var localizedValue: String {
        Localization.tr("enum_exerciseLevel_\(rawValue)")
    }
}

extension DecisionMode {
    var localizedValue: String {
        Localization.tr("enum_decisionMode_\(rawValue)")
    }
}

extension RiskPreference {
    var localizedValue: String {
        Localization.tr("enum_riskPreference_\(rawValue)")
    }
}

extension MoodDescription {
    var localizedValue: String {
        Localization.tr("enum_moodDescription_\(rawValue)")
    }
}

extension SocialType {
    var localizedValue: String {
        Localization.tr("enum_socialType_\(rawValue)")
    }
}

extension SocialEnergy {
    var localizedValue: String {
        Localization.tr("enum_socialEnergy_\(rawValue)")
    }
}

extension FamilyStructure {
    var localizedValue: String {
        Localization.tr("enum_familyStructure_\(rawValue)")
    }
}

extension SocialFrequency {
    var localizedValue: String {
        Localization.tr("enum_socialFrequency_\(rawValue)")
    }
}

extension CompanionshipNeed {
    var localizedValue: String {
        Localization.tr("enum_companionshipNeed_\(rawValue)")
    }
}

extension EmploymentStatus {
    var localizedValue: String {
        Localization.tr("enum_employmentStatus_\(rawValue)")
    }
}

extension ConsumptionLevel {
    var localizedValue: String {
        Localization.tr("enum_consumptionLevel_\(rawValue)")
    }
}

extension DebtStatus {
    var localizedValue: String {
        Localization.tr("enum_debtStatus_\(rawValue)")
    }
}

extension WorkIntensity {
    var localizedValue: String {
        Localization.tr("enum_workIntensity_\(rawValue)")
    }
}

extension WorkStatus {
    var localizedValue: String {
        Localization.tr("enum_workStatus_\(rawValue)")
    }
}

extension CareerAchievementStatus {
    var localizedValue: String {
        Localization.tr("enum_achievementStatus_\(rawValue)")
    }
}

extension ChronoType {
    var localizedValue: String {
        Localization.tr("enum_chronoType_\(rawValue)")
    }
}

extension HobbyIntensity {
    var localizedValue: String {
        Localization.tr("enum_hobbyIntensity_\(rawValue)")
    }
}

extension DietType {
    var localizedValue: String {
        Localization.tr("enum_dietType_\(rawValue)")
    }
}

extension EventImpact {
    var localizedValue: String {
        Localization.tr("enum_eventImpact_\(rawValue)")
    }
}

extension CoreValue {
    var localizedValue: String {
        Localization.tr("enum_coreValue_\(rawValue)")
    }
}
