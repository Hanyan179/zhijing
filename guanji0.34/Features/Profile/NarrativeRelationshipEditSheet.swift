import SwiftUI

/// Edit sheet for NarrativeRelationship - no score sliders
public struct NarrativeRelationshipEditSheet: View {
    let relationship: NarrativeRelationship?
    @ObservedObject var viewModel: NarrativeRelationshipViewModel
    let onSave: ((NarrativeRelationship) -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    private var isNewRelationship: Bool {
        relationship == nil
    }
    
    // Basic Info
    @State private var displayName: String = ""
    @State private var realName: String = ""
    @State private var avatar: String = ""
    @State private var type: CompanionType = .friends
    
    // Narrative
    @State private var narrative: String = ""
    @State private var tagsText: String = ""
    
    // Fact Anchors
    @State private var firstMeetingDate: String = ""
    @State private var showAddAnniversary = false
    @State private var newAnniversaryName: String = ""
    @State private var newAnniversaryDate: String = ""
    @State private var showAddExperience = false
    @State private var newExperience: String = ""
    
    public var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                basicInfoSection
                
                // Narrative Section
                narrativeSection
                
                // Tags Section
                tagsSection
                
                // Fact Anchors Section
                factAnchorsSection
            }
            .navigationTitle(Localization.tr("editRelationship"))
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
                    .disabled(displayName.isEmpty)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
            .sheet(isPresented: $showAddAnniversary) {
                AddAnniversarySheet(
                    name: $newAnniversaryName,
                    date: $newAnniversaryDate
                ) {
                    if let relationship = relationship,
                       !newAnniversaryName.isEmpty && !newAnniversaryDate.isEmpty {
                        viewModel.addAnniversary(
                            relationshipId: relationship.id,
                            name: newAnniversaryName,
                            date: newAnniversaryDate
                        )
                        newAnniversaryName = ""
                        newAnniversaryDate = ""
                    }
                    showAddAnniversary = false
                }
            }
            .sheet(isPresented: $showAddExperience) {
                AddExperienceSheet(experience: $newExperience) {
                    if let relationship = relationship,
                       !newExperience.isEmpty {
                        viewModel.addSharedExperience(
                            relationshipId: relationship.id,
                            experience: newExperience
                        )
                        newExperience = ""
                    }
                    showAddExperience = false
                }
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        Section(Localization.tr("basicInfo")) {
            TextField(Localization.tr("displayName"), text: $displayName)
            
            TextField(Localization.tr("realName") + " (\(Localization.tr("optional")))", text: $realName)
            
            HStack {
                Text(Localization.tr("avatar"))
                Spacer()
                TextField("👤", text: $avatar)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
            }
            
            Picker(Localization.tr("relationshipType"), selection: $type) {
                ForEach(CompanionType.allCases.filter { $0 != .alone }, id: \.self) { t in
                    Label(Localization.tr(t.localizedKey), systemImage: t.iconName)
                        .tag(t)
                }
            }
        }
    }
    
    // MARK: - Narrative Section
    
    private var narrativeSection: some View {
        Section(Localization.tr("Relationship.Narrative")) {
            TextEditor(text: $narrative)
                .frame(minHeight: 100)
                .overlay(
                    Group {
                        if narrative.isEmpty {
                            Text(Localization.tr("Relationship.NarrativePlaceholder"))
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        Section {
            TextField(Localization.tr("tagsPlaceholder"), text: $tagsText)
        } header: {
            Text(Localization.tr("tags"))
        } footer: {
            Text("Use commas to separate tags")
                .font(.caption)
        }
    }
    
    // MARK: - Fact Anchors Section
    
    private var factAnchorsSection: some View {
        Section(Localization.tr("Relationship.FactAnchors")) {
            // First Meeting Date
            HStack {
                Text(Localization.tr("Relationship.FirstMeeting"))
                Spacer()
                TextField("YYYY-MM-DD", text: $firstMeetingDate)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .keyboardType(.numbersAndPunctuation)
            }
            
            // Anniversaries
            if let relationship = relationship,
               let currentRelationship = viewModel.getRelationship(id: relationship.id) {
                ForEach(currentRelationship.factAnchors.anniversaries) { anniversary in
                    HStack {
                        Text(anniversary.name)
                        Spacer()
                        Text(anniversary.date)
                            .foregroundStyle(.secondary)
                        Button {
                            viewModel.removeAnniversary(
                                relationshipId: relationship.id,
                                anniversaryId: anniversary.id
                            )
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if relationship != nil {
                Button {
                    showAddAnniversary = true
                } label: {
                    Label(Localization.tr("Relationship.AddAnniversary"), systemImage: "plus.circle")
                }
            }
            
            // Shared Experiences
            if let relationship = relationship,
               let currentRelationship = viewModel.getRelationship(id: relationship.id) {
                ForEach(currentRelationship.factAnchors.sharedExperiences, id: \.self) { experience in
                    HStack {
                        Text(experience)
                            .lineLimit(2)
                        Spacer()
                        Button {
                            viewModel.removeSharedExperience(
                                relationshipId: relationship.id,
                                experience: experience
                            )
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if relationship != nil {
                Button {
                    showAddExperience = true
                } label: {
                    Label(Localization.tr("Relationship.AddExperience"), systemImage: "plus.circle")
                }
            }
        }
    }
    
    // MARK: - Data Loading & Saving
    
    private func loadCurrentValues() {
        guard let relationship = relationship else { return }
        displayName = relationship.displayName
        realName = relationship.realName ?? ""
        avatar = relationship.avatar ?? ""
        type = relationship.type
        narrative = relationship.narrative ?? ""
        tagsText = relationship.tags.joined(separator: ", ")
        firstMeetingDate = relationship.factAnchors.firstMeetingDate ?? ""
    }
    
    private func saveChanges() {
        if let existing = relationship {
            // Update existing relationship
            var updated = existing
            updated.displayName = displayName
            updated.realName = realName.isEmpty ? nil : realName
            updated.avatar = avatar.isEmpty ? nil : avatar
            updated.type = type
            updated.narrative = narrative.isEmpty ? nil : narrative
            updated.tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            updated.factAnchors.firstMeetingDate = firstMeetingDate.isEmpty ? nil : firstMeetingDate
            
            viewModel.update(updated)
            onSave?(updated)
        } else {
            // Create new relationship
            let newRelationship = NarrativeRelationship(
                id: UUID().uuidString,
                type: type,
                displayName: displayName,
                realName: realName.isEmpty ? nil : realName,
                avatar: avatar.isEmpty ? nil : avatar,
                narrative: narrative.isEmpty ? nil : narrative,
                tags: tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                factAnchors: RelationshipFactAnchors(
                    firstMeetingDate: firstMeetingDate.isEmpty ? nil : firstMeetingDate,
                    anniversaries: [],
                    sharedExperiences: []
                ),
                mentions: []
            )
            
            viewModel.create(newRelationship)
            onSave?(newRelationship)
        }
    }
}

// MARK: - Add Anniversary Sheet

private struct AddAnniversarySheet: View {
    @Binding var name: String
    @Binding var date: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                TextField(Localization.tr("Relationship.AnniversaryName"), text: $name)
                TextField(Localization.tr("Relationship.AnniversaryDate"), text: $date)
                    .keyboardType(.numbersAndPunctuation)
            }
            .navigationTitle(Localization.tr("Relationship.AddAnniversary"))
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
                    .disabled(name.isEmpty || date.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Add Experience Sheet

private struct AddExperienceSheet: View {
    @Binding var experience: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                TextEditor(text: $experience)
                    .frame(minHeight: 100)
                    .overlay(
                        Group {
                            if experience.isEmpty {
                                Text(Localization.tr("Relationship.ExperiencePlaceholder"))
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            .navigationTitle(Localization.tr("Relationship.AddExperience"))
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
                    .disabled(experience.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
