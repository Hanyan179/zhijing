import SwiftUI

/// Narrative User Profile Screen - simplified profile without scores
/// Uses NarrativeUserProfile model with static core and recent portrait
public struct NarrativeUserProfileScreen: View {
    @StateObject private var viewModel = NarrativeUserProfileViewModel()
    @StateObject private var relationshipViewModel = NarrativeRelationshipViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showEditSheet = false
    @State private var showAddTagSheet = false
    @State private var newTag = ""
    
    public init() {}
    
    public var body: some View {
        List {
            // Static Core Section
            staticCoreSection
            
            // Self Tags Section
            selfTagsSection
            
            // Relationship Constellation Section
            relationshipSection
            
            // Recent Portrait Section (placeholder)
            recentPortraitSection
        }
        .listStyle(.insetGrouped)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Localization.tr("myProfile"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.tr("edit")) {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NarrativeProfileEditSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddTagSheet(newTag: $newTag) {
                if !newTag.isEmpty {
                    viewModel.addSelfTag(newTag)
                    newTag = ""
                }
                showAddTagSheet = false
            }
        }
        .id(appState.lang.rawValue)
    }
    
    // MARK: - Static Core Section
    
    private var staticCoreSection: some View {
        Section {
            let core = viewModel.staticCore
            
            ProfileRow(
                label: "field_gender",
                value: core.gender?.localizedValue ?? Localization.tr("Profile.NotSet")
            )
            ProfileRow(
                label: "field_birthDate",
                value: viewModel.displayValue(core.birthYearMonth)
            )
            ProfileRow(
                label: "field_hometown",
                value: viewModel.displayValue(core.hometown)
            )
            ProfileRow(
                label: "field_currentCity",
                value: viewModel.displayValue(core.currentCity)
            )
            ProfileRow(
                label: "field_occupation",
                value: viewModel.displayValue(core.occupation)
            )
            ProfileRow(
                label: "field_industry",
                value: viewModel.displayValue(core.industry)
            )
            ProfileRow(
                label: "field_education",
                value: core.education?.localizedValue ?? Localization.tr("Profile.NotSet")
            )
        } header: {
            ProfileSectionHeader(icon: "person.fill", title: "Profile.StaticCore")
        }
    }
    
    // MARK: - Self Tags Section
    
    private var selfTagsSection: some View {
        Section {
            if viewModel.staticCore.selfTags.isEmpty {
                Text(Localization.tr("Profile.NoTags"))
                    .foregroundStyle(.secondary)
                    .font(.body)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.staticCore.selfTags, id: \.self) { tag in
                        ProfileTagChip(tag: tag) {
                            viewModel.removeSelfTag(tag)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            Button {
                showAddTagSheet = true
            } label: {
                Label(Localization.tr("Profile.AddTag"), systemImage: "plus.circle")
            }
        } header: {
            ProfileSectionHeader(icon: "tag.fill", title: "Profile.SelfTags")
        }
    }
    
    // MARK: - Relationship Section
    
    private var relationshipSection: some View {
        Section {
            if relationshipViewModel.relationships.isEmpty {
                Text(Localization.tr("noProfiles"))
                    .foregroundStyle(.secondary)
                    .font(.body)
            } else {
                ForEach(relationshipViewModel.relationships.prefix(5)) { relationship in
                    NavigationLink {
                        NarrativeRelationshipDetailScreen(
                            relationship: relationship,
                            viewModel: relationshipViewModel
                        )
                    } label: {
                        RelationshipRow(relationship: relationship)
                    }
                }
                
                if relationshipViewModel.relationships.count > 5 {
                    NavigationLink {
                        RelationshipManagementScreen()
                    } label: {
                        Text("\(Localization.tr("all")) (\(relationshipViewModel.relationships.count))")
                            .foregroundStyle(Colors.indigo)
                    }
                }
            }
        } header: {
            HStack {
                ProfileSectionHeader(icon: "person.2.fill", title: "peopleManagement")
                Spacer()
                NavigationLink {
                    RelationshipManagementScreen()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Recent Portrait Section
    
    private var recentPortraitSection: some View {
        Section {
            if let portrait = viewModel.recentPortrait {
                VStack(alignment: .leading, spacing: 12) {
                    Text(portrait.overallNarrative)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if !portrait.focusTopics.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Localization.tr("recentFocus"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            FlowLayout(spacing: 6) {
                                ForEach(portrait.focusTopics, id: \.self) { topic in
                                    Text(topic)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Colors.indigo.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    Text("\(Localization.tr("lastUpdated")): \(formatDate(portrait.generatedAt))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Localization.tr("comingSoon"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("AI will generate your portrait based on diary entries and daily records.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            ProfileSectionHeader(icon: "sparkles", title: "Profile.RecentPortrait")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views

private struct ProfileSectionHeader: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Colors.indigo)
                .imageScale(.medium)
            Text(Localization.tr(title))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

private struct ProfileRow: View {
    let label: String
    let value: String
    
    private var isNotSet: Bool {
        value == Localization.tr("Profile.NotSet") || value == Localization.tr("notSet")
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
    }
}

private struct ProfileTagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.footnote)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Colors.indigo.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct RelationshipRow: View {
    let relationship: NarrativeRelationship
    
    var body: some View {
        HStack(spacing: 12) {
            Text(relationship.avatar ?? "👤")
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(relationship.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: relationship.type.iconName)
                        .font(.caption2)
                    Text(Localization.tr(relationship.type.localizedKey))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Mention count instead of intimacy score
            if relationship.mentionCount > 0 {
                Text("\(relationship.mentionCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddTagSheet: View {
    @Binding var newTag: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                TextField(Localization.tr("Profile.AddTag"), text: $newTag)
            }
            .navigationTitle(Localization.tr("Profile.AddTag"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.tr("save")) {
                        onSave()
                    }
                    .disabled(newTag.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Profile Edit Sheet

private struct NarrativeProfileEditSheet: View {
    @ObservedObject var viewModel: NarrativeUserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var gender: Gender?
    @State private var birthYearMonth: String = ""
    @State private var hometown: String = ""
    @State private var currentCity: String = ""
    @State private var occupation: String = ""
    @State private var industry: String = ""
    @State private var education: Education?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(Localization.tr("Profile.StaticCore")) {
                    Picker(Localization.tr("field_gender"), selection: $gender) {
                        Text(Localization.tr("Profile.NotSet")).tag(nil as Gender?)
                        ForEach([Gender.male, .female, .other], id: \.self) { g in
                            Text(g.localizedValue).tag(g as Gender?)
                        }
                    }
                    
                    TextField(Localization.tr("field_birthDate"), text: $birthYearMonth)
                        .keyboardType(.numbersAndPunctuation)
                    
                    TextField(Localization.tr("field_hometown"), text: $hometown)
                    
                    TextField(Localization.tr("field_currentCity"), text: $currentCity)
                    
                    TextField(Localization.tr("field_occupation"), text: $occupation)
                    
                    TextField(Localization.tr("field_industry"), text: $industry)
                    
                    Picker(Localization.tr("field_education"), selection: $education) {
                        Text(Localization.tr("Profile.NotSet")).tag(nil as Education?)
                        ForEach([Education.highSchool, .bachelor, .master, .phd], id: \.self) { e in
                            Text(e.localizedValue).tag(e as Education?)
                        }
                    }
                }
            }
            .navigationTitle(Localization.tr("edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.tr("save")) {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }
    
    private func loadCurrentValues() {
        let core = viewModel.staticCore
        gender = core.gender
        birthYearMonth = core.birthYearMonth ?? ""
        hometown = core.hometown ?? ""
        currentCity = core.currentCity ?? ""
        occupation = core.occupation ?? ""
        industry = core.industry ?? ""
        education = core.education
    }
    
    private func saveChanges() {
        let core = viewModel.staticCore
        
        if gender != core.gender {
            viewModel.updateGender(gender)
        }
        if birthYearMonth != (core.birthYearMonth ?? "") {
            viewModel.updateBirthYearMonth(birthYearMonth.isEmpty ? nil : birthYearMonth)
        }
        if hometown != (core.hometown ?? "") {
            viewModel.updateHometown(hometown.isEmpty ? nil : hometown)
        }
        if currentCity != (core.currentCity ?? "") {
            viewModel.updateCurrentCity(currentCity.isEmpty ? nil : currentCity)
        }
        if occupation != (core.occupation ?? "") {
            viewModel.updateOccupation(occupation.isEmpty ? nil : occupation)
        }
        if industry != (core.industry ?? "") {
            viewModel.updateIndustry(industry.isEmpty ? nil : industry)
        }
        if education != core.education {
            viewModel.updateEducation(education)
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
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
