import SwiftUI

// MARK: - Relationship Management Screen

/// Main screen for managing relationship profiles
/// Requirements: Epic 6, Story 6.1, 6.2
public struct RelationshipManagementScreen: View {
    @StateObject private var viewModel = RelationshipProfileViewModel()
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var showingDetail = false
    @State private var selectedProfile: RelationshipProfile?
    
    public init() {}
    
    private var hasAnyProfiles: Bool {
        CompanionType.allCases.contains { type in
            !viewModel.profilesForType(type, searchText: "").isEmpty
        }
    }
    
    public var body: some View {
        Group {
            if !hasAnyProfiles && searchText.isEmpty {
                // Empty state
                emptyStateView
            } else {
                List {
                    ForEach(CompanionType.allCases) { type in
                        let profiles = viewModel.profilesForType(type, searchText: searchText)
                        if !profiles.isEmpty || searchText.isEmpty {
                            RelationshipTypeSection(
                                type: type,
                                profiles: profiles,
                                onSelect: { profile in
                                    selectedProfile = profile
                                    showingDetail = true
                                }
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText, prompt: Text(Localization.tr("searchPeople")))
        .navigationTitle(Localization.tr("peopleManagement"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Localization.tr("newRelationship"))
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            RelationshipEditSheet(
                profile: nil,
                onSave: { newProfile in
                    viewModel.create(newProfile)
                    showingAddSheet = false
                },
                onCancel: { showingAddSheet = false }
            )
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let profile = selectedProfile {
                        RelationshipDetailScreen(
                            profile: profile,
                            viewModel: viewModel
                        )
                    }
                },
                isActive: $showingDetail
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            
            Text(Localization.tr("noProfiles"))
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Button(action: { showingAddSheet = true }) {
                Label(Localization.tr("newRelationship"), systemImage: "plus.circle.fill")
                    .font(.body)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Relationship Type Section

/// Collapsible section for each relationship type
/// Requirements: Story 6.1
struct RelationshipTypeSection: View {
    let type: CompanionType
    let profiles: [RelationshipProfile]
    let onSelect: (RelationshipProfile) -> Void
    
    var body: some View {
        Section {
            if profiles.isEmpty {
                Text(Localization.tr("noProfiles"))
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(profiles) { profile in
                    RelationshipRowView(profile: profile)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(profile)
                        }
                        .accessibilityAddTraits(.isButton)
                }
            }
        } header: {
            HStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .foregroundStyle(colorForType(type))
                    .imageScale(.medium)
                    .accessibilityHidden(true)
                Text(Localization.tr(type.localizedKey))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(profiles.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Localization.tr(type.localizedKey)), \(profiles.count) \(Localization.tr("unit_people"))")
        }
    }
    
    private func colorForType(_ type: CompanionType) -> Color {
        switch type {
        case .alone: return Color(.systemGray)
        case .partner: return Color(.systemPink)
        case .family: return Color(.systemOrange)
        case .friends: return Color(.systemBlue)
        case .colleagues: return Color(.systemPurple)
        case .onlineFriends: return Color(.systemCyan)
        case .pet: return Color(.systemBrown)
        }
    }
}

// MARK: - Relationship Row View

/// Row view for displaying a single relationship profile
/// Requirements: Story 6.2
struct RelationshipRowView: View {
    let profile: RelationshipProfile
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Text(profile.avatar ?? "👤")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            // Name and info
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(Localization.tr(profile.interactionFrequency.localizedKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Intimacy indicator
            IntimacyIndicator(level: profile.intimacyLevel)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.displayName), \(Localization.tr(profile.interactionFrequency.localizedKey)), \(Localization.tr("intimacyLevel")) \(profile.intimacyLevel)/10")
    }
}

// MARK: - Intimacy Indicator

/// Visual indicator for intimacy level (1-10)
struct IntimacyIndicator: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < (level + 1) / 2 ? Color(.systemPink) : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        RelationshipManagementScreen()
    }
}
