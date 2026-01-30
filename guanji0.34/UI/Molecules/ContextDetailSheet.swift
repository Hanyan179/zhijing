import SwiftUI

/// Detail sheet for editing activity context
/// Design: Only show people list, selecting a person auto-links their type
///         Support quick add new person with name + type
public struct ContextDetailSheet: View {
    let activity: ActivityType
    @Binding var context: ActivityContext
    let onDone: () -> Void
    
    @State private var newTagText: String = ""
    @State private var tags: [ActivityTag] = []
    @StateObject private var relationshipVM = NarrativeRelationshipViewModel()
    
    // Quick add person state
    @State private var showAddPerson = false
    @State private var newPersonName: String = ""
    @State private var newPersonType: CompanionType = .friends
    
    public init(
        activity: ActivityType,
        context: Binding<ActivityContext>,
        onDone: @escaping () -> Void
    ) {
        self.activity = activity
        self._context = context
        self.onDone = onDone
    }
    
    /// Default companion type based on activity
    private var defaultCompanionType: CompanionType {
        switch activity {
        case .date: return .partner
        case .walkPet: return .pet
        case .party: return .friends
        case .work, .study: return .colleagues
        case .internet, .gaming: return .onlineFriends
        default: return .friends
        }
    }
    
    public var body: some View {
        NavigationStack {
            List {
                // Section 1: Who - People selection (auto-links type)
                Section {
                    peopleSelectionView
                } header: {
                    Text(Localization.tr("context_who"))
                }
                
                // Section 2: Tags
                Section {
                    tagSelectionView
                } header: {
                    Text(Localization.tr("context_tags"))
                }
                
                // Section 3: Notes
                Section {
                    TextField(
                        Localization.tr("context_notes_placeholder"),
                        text: Binding(
                            get: { context.details ?? "" },
                            set: { context.details = $0.isEmpty ? nil : $0 }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                } header: {
                    Text(Localization.tr("context_notes"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Localization.tr(activity.localizedKey))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.tr("done")) {
                        onDone()
                    }
                }
            }
            .onAppear {
                loadTags()
                // Set default type based on activity
                newPersonType = defaultCompanionType
            }
            .sheet(isPresented: $showAddPerson) {
                addPersonSheet
            }
        }
    }
    
    // MARK: - People Selection (Only people, auto-link type)
    
    private var peopleSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Show all people, grouped by type
            let groupedProfiles = Dictionary(grouping: relationshipVM.relationships, by: { $0.type })
            
            // Show "Alone" option first
            AloneChip(
                isSelected: context.companions.contains(.alone),
                action: { toggleAlone() }
            )
            
            // Show people by type groups
            ForEach(CompanionType.allCases.filter { $0 != .alone }, id: \.self) { type in
                if let relationships = groupedProfiles[type], !relationships.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        // Type header
                        HStack {
                            Image(systemName: type.iconName)
                                .font(.caption)
                            Text(Localization.tr(type.localizedKey))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        // People chips
                        TrackerFlowLayout(spacing: 8) {
                            ForEach(relationships) { relationship in
                                PersonChip(
                                    relationship: relationship,
                                    isSelected: context.companionDetails?.contains(relationship.id) ?? false
                                ) {
                                    togglePerson(relationship)
                                }
                            }
                        }
                    }
                }
            }
            
            // Add new person button
            Button(action: { showAddPerson = true }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text(Localization.tr("context_add_person"))
                }
                .font(.subheadline)
                .foregroundColor(Colors.indigo)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    private func toggleAlone() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if context.companions.contains(.alone) {
                context.companions.removeAll { $0 == .alone }
            } else {
                // Clear other selections when choosing alone
                context.companions = [.alone]
                context.companionDetails = nil
            }
        }
    }
    
    private func togglePerson(_ relationship: NarrativeRelationship) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Remove "alone" if selecting a person
            context.companions.removeAll { $0 == .alone }
            
            if context.companionDetails == nil {
                context.companionDetails = []
            }
            
            if context.companionDetails?.contains(relationship.id) ?? false {
                // Deselect person
                context.companionDetails?.removeAll { $0 == relationship.id }
                // Remove type if no more people of this type selected
                let remainingOfType = context.companionDetails?.compactMap { id in
                    relationshipVM.relationships.first { $0.id == id }
                }.filter { $0.type == relationship.type } ?? []
                if remainingOfType.isEmpty {
                    context.companions.removeAll { $0 == relationship.type }
                }
            } else {
                // Select person and auto-add their type
                context.companionDetails?.append(relationship.id)
                if !context.companions.contains(relationship.type) {
                    context.companions.append(relationship.type)
                }
            }
        }
    }
    
    // MARK: - Add Person Sheet
    
    private var addPersonSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(Localization.tr("context_person_name"), text: $newPersonName)
                }
                
                Section {
                    Picker(Localization.tr("context_companion_type"), selection: $newPersonType) {
                        ForEach(CompanionType.allCases.filter { $0 != .alone }) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                Text(Localization.tr(type.localizedKey))
                            }
                            .tag(type)
                        }
                    }
                }
            }
            .navigationTitle(Localization.tr("context_add_person"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel")) {
                        showAddPerson = false
                        newPersonName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.tr("save")) {
                        addNewPerson()
                    }
                    .disabled(newPersonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func addNewPerson() {
        let trimmed = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Create new relationship
        let relationship = NarrativeRelationship(
            type: newPersonType,
            displayName: trimmed
        )
        
        // Add to VM (will persist later)
        relationshipVM.create(relationship)
        
        // Auto-select the new person
        if context.companionDetails == nil {
            context.companionDetails = []
        }
        context.companionDetails?.append(relationship.id)
        if !context.companions.contains(newPersonType) {
            context.companions.append(newPersonType)
        }
        context.companions.removeAll { $0 == .alone }
        
        // Reset and close
        newPersonName = ""
        showAddPerson = false
    }
    
    // MARK: - Tag Selection (Simplified)
    
    private var tagSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Existing tags first
            if !tags.isEmpty {
                TrackerFlowLayout(spacing: 8) {
                    ForEach(tags) { tag in
                        TagInputChip(
                            tag: tag,
                            isSelected: context.tags.contains(tag.id)
                        ) {
                            toggleTag(tag.id)
                        }
                    }
                }
            }
            
            // New tag input at bottom
            HStack {
                TextField(Localization.tr("context_new_tag"), text: $newTagText)
                    .textFieldStyle(.roundedBorder)
                
                if !newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: createNewTag) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Colors.indigo)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func loadTags() {
        tags = ActivityTagRepository.shared.getTags(for: activity)
    }
    
    private func toggleTag(_ tagId: String) {
        if context.tags.contains(tagId) {
            context.tags.removeAll { $0 == tagId }
        } else {
            context.tags.append(tagId)
        }
    }
    
    private func createNewTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Check if already exists
        if ActivityTagRepository.shared.tagExists(text: trimmed, for: activity) {
            newTagText = ""
            return
        }
        
        // Create and add tag
        let tag = ActivityTagRepository.shared.createTag(text: trimmed, for: activity)
        context.tags.append(tag.id)
        
        // Refresh tags list
        loadTags()
        newTagText = ""
    }
}

// MARK: - Alone Chip

/// Special chip for "Alone" option
struct AloneChip: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                Text(Localization.tr("companion_alone"))
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Colors.slateText : Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Person Chip

/// Chip for displaying a narrative relationship person
struct PersonChip: View {
    let relationship: NarrativeRelationship
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let avatar = relationship.avatar, !avatar.isEmpty {
                    Text(avatar)
                        .font(.system(size: 14))
                } else {
                    Image(systemName: relationship.type.iconName)
                        .font(.system(size: 12))
                }
                Text(relationship.displayName)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Colors.teal : Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

/// A simple flow layout for wrapping content (used in ContextDetailSheet)
struct TrackerFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
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
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
