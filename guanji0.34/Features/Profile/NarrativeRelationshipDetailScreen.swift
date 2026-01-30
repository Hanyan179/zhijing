import SwiftUI

/// Narrative Relationship Detail Screen - shows relationship with narrative and fact anchors
/// No intimacy scores or interaction frequency metrics
public struct NarrativeRelationshipDetailScreen: View {
    let relationship: NarrativeRelationship
    @ObservedObject var viewModel: NarrativeRelationshipViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    public var body: some View {
        List {
            // Basic Info Section
            basicInfoSection
            
            // Narrative Section
            narrativeSection
            
            // Tags Section
            tagsSection
            
            // Fact Anchors Section
            factAnchorsSection
            
            // Mentions Section
            mentionsSection
            
            // Delete Section
            deleteSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(relationship.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.tr("edit")) {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NarrativeRelationshipEditSheet(
                relationship: relationship,
                viewModel: viewModel,
                onSave: { _ in showEditSheet = false }
            )
        }
        .alert(Localization.tr("deleteConfirmTitle"), isPresented: $showDeleteAlert) {
            Button(Localization.tr("cancel"), role: .cancel) {}
            Button(Localization.tr("delete"), role: .destructive) {
                viewModel.delete(relationship)
                dismiss()
            }
        } message: {
            Text(Localization.tr("deleteConfirmMessage"))
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        Section {
            HStack(spacing: 16) {
                Text(relationship.avatar ?? "👤")
                    .font(.system(size: 48))
                    .frame(width: 64, height: 64)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(relationship.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let realName = relationship.realName {
                        Text(realName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: relationship.type.iconName)
                            .font(.caption)
                        Text(Localization.tr(relationship.type.localizedKey))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        } header: {
            NarrativeSectionHeader(icon: "person.fill", title: "basicInfo")
        }
    }
    
    // MARK: - Narrative Section
    
    private var narrativeSection: some View {
        Section {
            if let narrative = relationship.narrative, !narrative.isEmpty {
                Text(narrative)
                    .font(.body)
                    .foregroundStyle(.primary)
            } else {
                Text(Localization.tr("Relationship.NarrativePlaceholder"))
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        } header: {
            NarrativeSectionHeader(icon: "text.quote", title: "Relationship.Narrative")
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        Section {
            if relationship.tags.isEmpty {
                Text(Localization.tr("Profile.NoTags"))
                    .foregroundStyle(.secondary)
            } else {
                RelationshipFlowLayout(spacing: 8) {
                    ForEach(relationship.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Colors.indigo.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            NarrativeSectionHeader(icon: "tag.fill", title: "tags")
        }
    }
    
    // MARK: - Fact Anchors Section
    
    private var factAnchorsSection: some View {
        Section {
            // First Meeting Date
            if let firstMeeting = relationship.factAnchors.firstMeetingDate {
                HStack {
                    Label(Localization.tr("Relationship.FirstMeeting"), systemImage: "calendar")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(firstMeeting)
                        .foregroundStyle(.primary)
                }
            }
            
            // Anniversaries
            if !relationship.factAnchors.anniversaries.isEmpty {
                ForEach(relationship.factAnchors.anniversaries) { anniversary in
                    HStack {
                        Label(anniversary.name, systemImage: "star.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(anniversary.date)
                                .foregroundStyle(.primary)
                            if let year = anniversary.year {
                                Text("\(year)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            
            // Shared Experiences
            if !relationship.factAnchors.sharedExperiences.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(Localization.tr("Relationship.SharedExperiences"), systemImage: "heart.fill")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    
                    ForEach(relationship.factAnchors.sharedExperiences, id: \.self) { experience in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(experience)
                                .font(.body)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            if !relationship.hasFactAnchors {
                Text(Localization.tr("Profile.NotSet"))
                    .foregroundStyle(.tertiary)
            }
        } header: {
            NarrativeSectionHeader(icon: "pin.fill", title: "Relationship.FactAnchors")
        }
    }
    
    // MARK: - Mentions Section
    
    private var mentionsSection: some View {
        Section {
            if relationship.mentions.isEmpty {
                Text(Localization.tr("Relationship.NoMentions"))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(relationship.mentions.prefix(10)) { mention in
                    MentionRow(mention: mention)
                }
                
                if relationship.mentions.count > 10 {
                    Text("\(relationship.mentions.count - 10) more...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            HStack {
                NarrativeSectionHeader(icon: "bubble.left.fill", title: "Relationship.Mentions")
                Spacer()
                Text("\(relationship.mentionCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Delete Section
    
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    Text(Localization.tr("delete"))
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Helper Views

private struct NarrativeSectionHeader: View {
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

private struct MentionRow: View {
    let mention: RelationshipMention
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: mention.sourceType.iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Localization.tr(mention.sourceType.localizedKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatDate(mention.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Text(mention.contextSnippet)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - MentionSource Extension

extension MentionSource {
    var iconName: String {
        switch self {
        case .diary: return "book.fill"
        case .dailyTracker: return "checkmark.circle.fill"
        case .aiConversation: return "bubble.left.and.bubble.right.fill"
        }
    }
}

// MARK: - Relationship Flow Layout

private struct RelationshipFlowLayout: Layout {
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
