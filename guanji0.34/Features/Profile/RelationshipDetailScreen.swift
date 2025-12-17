import SwiftUI

// MARK: - Relationship Detail Screen

/// Detail screen for viewing a relationship profile
/// Requirements: Story 6.2, 6.3, 6.4
public struct RelationshipDetailScreen: View {
    let profile: RelationshipProfile
    @ObservedObject var viewModel: RelationshipProfileViewModel
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    public init(profile: RelationshipProfile, viewModel: RelationshipProfileViewModel) {
        self.profile = profile
        self.viewModel = viewModel
    }
    
    // Get the latest profile from viewModel
    private var currentProfile: RelationshipProfile {
        viewModel.getProfile(id: profile.id) ?? profile
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                profileHeader
                
                // Basic Info Section
                basicInfoSection
                
                // Interaction Stats Section
                interactionStatsSection
                
                // Type-Specific Section
                typeSpecificSection
                
                // Notes Section
                notesSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentProfile.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label(Localization.tr("edit"), systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label(Localization.tr("delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(Localization.tr("moreAction"))
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            RelationshipEditSheet(
                profile: currentProfile,
                onSave: { updatedProfile in
                    viewModel.update(updatedProfile)
                    showingEditSheet = false
                },
                onCancel: { showingEditSheet = false }
            )
        }
        .alert(Localization.tr("deleteConfirmTitle"), isPresented: $showingDeleteAlert) {
            Button(Localization.tr("cancel"), role: .cancel) {}
            Button(Localization.tr("delete"), role: .destructive) {
                viewModel.delete(currentProfile)
                dismiss()
            }
        } message: {
            Text(Localization.tr("deleteConfirmMessage"))
        }
    }
    
    // MARK: - Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Large Avatar
            Text(currentProfile.avatar ?? "👤")
                .font(.system(size: 64))
                .frame(width: 100, height: 100)
                .background(Color(.systemGray6))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .accessibilityHidden(true)
            
            // Display Name
            Text(currentProfile.displayName)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Type Badge
            HStack(spacing: 6) {
                Image(systemName: currentProfile.type.iconName)
                    .imageScale(.small)
                Text(Localization.tr(currentProfile.type.localizedKey))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentProfile.displayName), \(Localization.tr(currentProfile.type.localizedKey))")
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: Localization.tr("basicInfo"))
            
            VStack(spacing: 0) {
                DetailRow(
                    label: Localization.tr("intimacyLevel"),
                    value: "\(currentProfile.intimacyLevel)/10"
                )
                Divider().padding(.leading, 16)
                DetailRow(
                    label: Localization.tr("emotionalConnection"),
                    value: "\(currentProfile.emotionalConnection)/10"
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Interaction Stats Section
    
    private var interactionStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: Localization.tr("interactionStats"))
            
            VStack(spacing: 0) {
                DetailRow(
                    label: Localization.tr("totalInteractions"),
                    value: "\(currentProfile.totalInteractions)"
                )
                Divider().padding(.leading, 16)
                DetailRow(
                    label: Localization.tr("lastInteraction"),
                    value: formatDate(currentProfile.lastInteractionDate)
                )
                Divider().padding(.leading, 16)
                DetailRow(
                    label: Localization.tr("interactionFrequency"),
                    value: Localization.tr(currentProfile.interactionFrequency.localizedKey)
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Type-Specific Section
    
    @ViewBuilder
    private var typeSpecificSection: some View {
        let fields = typeSpecificFields
        if !fields.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: Localization.tr("typeSpecificInfo"))
                
                VStack(spacing: 0) {
                    ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                        if index > 0 {
                            Divider().padding(.leading, 16)
                        }
                        DetailRow(label: field.label, value: field.value)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var typeSpecificFields: [(label: String, value: String)] {
        var fields: [(String, String)] = []
        
        switch currentProfile.type {
        case .partner:
            if let status = currentProfile.partnerStatus {
                fields.append((Localization.tr("partnerStatus"), Localization.tr("partnerStatus_\(status)")))
            }
            if let date = currentProfile.anniversaryMet {
                fields.append((Localization.tr("anniversaryMet"), date))
            }
            if let date = currentProfile.anniversaryDating {
                fields.append((Localization.tr("anniversaryDating"), date))
            }
            if let date = currentProfile.anniversaryMarried {
                fields.append((Localization.tr("anniversaryMarried"), date))
            }
            
        case .family:
            if let role = currentProfile.familyRole {
                fields.append((Localization.tr("familyRole"), Localization.tr("familyRole_\(role)")))
            }
            fields.append((Localization.tr("livingTogether"), currentProfile.livingTogether ? Localization.tr("bool_yes") : Localization.tr("bool_no")))
            
        case .friends:
            if let intimacy = currentProfile.friendIntimacy {
                fields.append((Localization.tr("friendIntimacy"), Localization.tr("friendIntimacy_\(intimacy)")))
            }
            if let years = currentProfile.yearsKnown {
                fields.append((Localization.tr("yearsKnown"), "\(years) \(Localization.tr("unit_years"))"))
            }
            
        case .colleagues:
            if let relationship = currentProfile.workRelationship {
                fields.append((Localization.tr("workRelationship"), Localization.tr("workRelationship_\(relationship)")))
            }
            if let company = currentProfile.company {
                fields.append((Localization.tr("company"), company))
            }
            if let department = currentProfile.department {
                fields.append((Localization.tr("department"), department))
            }
            
        case .onlineFriends:
            if let platform = currentProfile.platform {
                fields.append((Localization.tr("platform"), platform))
            }
            fields.append((Localization.tr("hasMetInPerson"), currentProfile.hasMetInPerson ? Localization.tr("bool_yes") : Localization.tr("bool_no")))
            
        case .pet:
            if let petType = currentProfile.petType {
                fields.append((Localization.tr("petType"), Localization.tr("petType_\(petType)")))
            }
            if let age = currentProfile.petAge {
                fields.append((Localization.tr("petAge"), "\(age) \(Localization.tr("unit_years"))"))
            }
            if let breed = currentProfile.petBreed {
                fields.append((Localization.tr("petBreed"), breed))
            }
            
        case .alone:
            break
        }
        
        return fields
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: Localization.tr("notesAndTags"))
            
            VStack(alignment: .leading, spacing: 16) {
                // Notes
                if let notes = currentProfile.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(Localization.tr("noNotes"))
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
                
                // Tags
                if !currentProfile.tags.isEmpty {
                    Divider()
                    TagsFlowView(tags: currentProfile.tags)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else {
            return Localization.tr("notSet")
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .accessibilityAddTraits(.isHeader)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
                .layoutPriority(1)
            Spacer(minLength: 16)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Tags Flow View

/// Simple horizontal wrapping view for tags (iOS 16 compatible)
struct TagsFlowView: View {
    let tags: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], alignment: .leading, spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                    .accessibilityLabel(tag)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Localization.tr("tags"))
    }
}

#Preview {
    NavigationStack {
        RelationshipDetailScreen(
            profile: MockDataService.relationshipProfiles.first!,
            viewModel: RelationshipProfileViewModel()
        )
    }
}
