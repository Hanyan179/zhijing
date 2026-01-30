import SwiftUI

/// Narrative Relationship List Screen - shows all relationships
public struct NarrativeRelationshipListScreen: View {
    @ObservedObject var viewModel: NarrativeRelationshipViewModel
    @State private var showAddSheet = false
    @State private var searchText = ""
    
    public init(viewModel: NarrativeRelationshipViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        List {
            ForEach(filteredRelationships) { relationship in
                NavigationLink {
                    NarrativeRelationshipDetailScreen(
                        relationship: relationship,
                        viewModel: viewModel
                    )
                } label: {
                    RelationshipRow(relationship: relationship)
                }
            }
            .onDelete(perform: deleteRelationships)
        }
        .searchable(text: $searchText, prompt: Localization.tr("search"))
        .navigationTitle(Localization.tr("peopleManagement"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                NarrativeRelationshipEditSheet(
                    relationship: nil,
                    viewModel: viewModel,
                    onSave: { _ in showAddSheet = false }
                )
            }
        }
    }
    
    private var filteredRelationships: [NarrativeRelationship] {
        if searchText.isEmpty {
            return viewModel.relationships
        } else {
            return viewModel.relationships.filter { relationship in
                relationship.displayName.localizedCaseInsensitiveContains(searchText) ||
                (relationship.realName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                relationship.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private func deleteRelationships(at offsets: IndexSet) {
        for index in offsets {
            let relationship = filteredRelationships[index]
            viewModel.delete(id: relationship.id)
        }
    }
}

// MARK: - Relationship Row

struct RelationshipRow: View {
    let relationship: NarrativeRelationship
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatar = relationship.avatar, !avatar.isEmpty {
                Text(avatar)
                    .font(.title2)
            } else {
                Image(systemName: relationship.type.iconName)
                    .font(.title3)
                    .foregroundStyle(Colors.indigo)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(relationship.displayName)
                    .font(.body)
                
                HStack(spacing: 8) {
                    // Type badge
                    Text(Localization.tr(relationship.type.localizedKey))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Mention count
                    if !relationship.mentions.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("\(relationship.mentions.count) \(Localization.tr("mentions"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
