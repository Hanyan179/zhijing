import SwiftUI

// MARK: - Relationship Edit Sheet

/// Sheet for creating or editing a relationship profile
/// Requirements: Story 6.2, 6.4
public struct RelationshipEditSheet: View {
    let profile: RelationshipProfile?
    let onSave: (RelationshipProfile) -> Void
    let onCancel: () -> Void
    
    // Basic fields
    @State private var displayName: String = ""
    @State private var avatar: String = "👤"
    @State private var type: CompanionType = .friends
    @State private var realName: String = ""
    
    // Relationship fields
    @State private var intimacyLevel: Double = 5
    @State private var emotionalConnection: Double = 5
    
    // Notes
    @State private var notes: String = ""
    @State private var tagsText: String = ""
    
    // Type-specific fields
    // Partner
    @State private var partnerStatus: String = "dating"
    @State private var anniversaryMet: String = ""
    @State private var anniversaryDating: String = ""
    @State private var anniversaryMarried: String = ""
    
    // Family
    @State private var familyRole: String = "parent"
    @State private var livingTogether: Bool = false
    
    // Friends
    @State private var friendIntimacy: String = "friend"
    @State private var yearsKnown: String = ""
    
    // Colleagues
    @State private var workRelationship: String = "peer"
    @State private var company: String = ""
    @State private var department: String = ""
    
    // Online Friends
    @State private var platform: String = ""
    @State private var hasMetInPerson: Bool = false
    
    // Pet
    @State private var petType: String = "cat"
    @State private var petAge: String = ""
    @State private var petBreed: String = ""
    
    // UI State
    @State private var showingEmojiPicker = false
    
    private var isEditing: Bool { profile != nil }
    
    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    public init(
        profile: RelationshipProfile?,
        onSave: @escaping (RelationshipProfile) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.profile = profile
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Basic Section
                basicSection
                
                // Relationship Section
                relationshipSection
                
                // Type-Specific Section
                typeSpecificSection
                
                // Notes Section
                notesSection
                
                // Privacy Warning for Real Name
                if !realName.isEmpty {
                    Section {
                        Label(Localization.tr("privacyWarning"), systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(isEditing ? Localization.tr("editRelationship") : Localization.tr("newRelationship"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel")) {
                        onCancel()
                    }
                    .accessibilityLabel(Localization.tr("cancel"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.tr("save")) {
                        saveProfile()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                    .accessibilityLabel(Localization.tr("save"))
                    .accessibilityHint(canSave ? "" : Localization.tr("displayNamePlaceholder"))
                }
            }
            .onAppear {
                loadProfileData()
            }
            .interactiveDismissDisabled(canSave && isEditing)
        }
    }
    
    // MARK: - Basic Section
    
    private var basicSection: some View {
        Section(header: Text(Localization.tr("basicInfo"))) {
            // Display Name
            HStack {
                Text(Localization.tr("displayName"))
                    .foregroundStyle(.primary)
                Spacer()
                TextField(Localization.tr("displayNamePlaceholder"), text: $displayName)
                    .multilineTextAlignment(.trailing)
                    .accessibilityLabel(Localization.tr("displayName"))
            }
            
            // Avatar
            HStack {
                Text(Localization.tr("avatar"))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: { showingEmojiPicker = true }) {
                    Text(avatar)
                        .font(.title)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.tr("avatar"))
                .accessibilityHint(Localization.tr("selectEmoji"))
                .sheet(isPresented: $showingEmojiPicker) {
                    EmojiPickerSheet(selectedEmoji: $avatar, isPresented: $showingEmojiPicker)
                }
            }
            
            // Type
            Picker(Localization.tr("relationshipType"), selection: $type) {
                ForEach(CompanionType.allCases) { companionType in
                    HStack(spacing: 8) {
                        Image(systemName: companionType.iconName)
                            .imageScale(.small)
                        Text(Localization.tr(companionType.localizedKey))
                    }
                    .tag(companionType)
                }
            }
            .accessibilityLabel(Localization.tr("relationshipType"))
            
            // Real Name (Optional)
            HStack {
                Text(Localization.tr("realName"))
                    .foregroundStyle(.primary)
                Spacer()
                TextField(Localization.tr("optional"), text: $realName)
                    .multilineTextAlignment(.trailing)
                    .accessibilityLabel(Localization.tr("realName"))
            }
        }
    }
    
    // MARK: - Relationship Section
    
    private var relationshipSection: some View {
        Section(header: Text(Localization.tr("relationshipInfo"))) {
            // Intimacy Level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Localization.tr("intimacyLevel"))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(Int(intimacyLevel))/10")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $intimacyLevel, in: 1...10, step: 1)
                    .tint(Color(.systemPink))
                    .accessibilityLabel(Localization.tr("intimacyLevel"))
                    .accessibilityValue("\(Int(intimacyLevel))/10")
            }
            .padding(.vertical, 4)
            
            // Emotional Connection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Localization.tr("emotionalConnection"))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(Int(emotionalConnection))/10")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $emotionalConnection, in: 1...10, step: 1)
                    .tint(Colors.indigo)
                    .accessibilityLabel(Localization.tr("emotionalConnection"))
                    .accessibilityValue("\(Int(emotionalConnection))/10")
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Type-Specific Section
    
    @ViewBuilder
    private var typeSpecificSection: some View {
        switch type {
        case .partner:
            partnerSection
        case .family:
            familySection
        case .friends:
            friendsSection
        case .colleagues:
            colleaguesSection
        case .onlineFriends:
            onlineFriendsSection
        case .pet:
            petSection
        case .alone:
            EmptyView()
        }
    }
    
    private var partnerSection: some View {
        Section(header: Text(Localization.tr("partnerInfo"))) {
            Picker(Localization.tr("partnerStatus"), selection: $partnerStatus) {
                Text(Localization.tr("partnerStatus_dating")).tag("dating")
                Text(Localization.tr("partnerStatus_married")).tag("married")
                Text(Localization.tr("partnerStatus_separated")).tag("separated")
            }
            
            HStack {
                Text(Localization.tr("anniversaryMet"))
                Spacer()
                TextField("MM-DD", text: $anniversaryMet)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numbersAndPunctuation)
            }
            
            HStack {
                Text(Localization.tr("anniversaryDating"))
                Spacer()
                TextField("MM-DD", text: $anniversaryDating)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numbersAndPunctuation)
            }
            
            HStack {
                Text(Localization.tr("anniversaryMarried"))
                Spacer()
                TextField("MM-DD", text: $anniversaryMarried)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numbersAndPunctuation)
            }
        }
    }
    
    private var familySection: some View {
        Section(header: Text(Localization.tr("familyInfo"))) {
            Picker(Localization.tr("familyRole"), selection: $familyRole) {
                Text(Localization.tr("familyRole_parent")).tag("parent")
                Text(Localization.tr("familyRole_child")).tag("child")
                Text(Localization.tr("familyRole_sibling")).tag("sibling")
                Text(Localization.tr("familyRole_other")).tag("other")
            }
            
            Toggle(Localization.tr("livingTogether"), isOn: $livingTogether)
        }
    }
    
    private var friendsSection: some View {
        Section(header: Text(Localization.tr("friendInfo"))) {
            Picker(Localization.tr("friendIntimacy"), selection: $friendIntimacy) {
                Text(Localization.tr("friendIntimacy_acquaintance")).tag("acquaintance")
                Text(Localization.tr("friendIntimacy_friend")).tag("friend")
                Text(Localization.tr("friendIntimacy_closeFriend")).tag("closeFriend")
                Text(Localization.tr("friendIntimacy_bestFriend")).tag("bestFriend")
            }
            
            HStack {
                Text(Localization.tr("yearsKnown"))
                Spacer()
                TextField("0", text: $yearsKnown)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                Text(Localization.tr("unit_years"))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var colleaguesSection: some View {
        Section(header: Text(Localization.tr("colleagueInfo"))) {
            Picker(Localization.tr("workRelationship"), selection: $workRelationship) {
                Text(Localization.tr("workRelationship_superior")).tag("superior")
                Text(Localization.tr("workRelationship_subordinate")).tag("subordinate")
                Text(Localization.tr("workRelationship_peer")).tag("peer")
                Text(Localization.tr("workRelationship_partner")).tag("partner")
            }
            
            HStack {
                Text(Localization.tr("company"))
                Spacer()
                TextField(Localization.tr("optional"), text: $company)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text(Localization.tr("department"))
                Spacer()
                TextField(Localization.tr("optional"), text: $department)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var onlineFriendsSection: some View {
        Section(header: Text(Localization.tr("onlineFriendInfo"))) {
            HStack {
                Text(Localization.tr("platform"))
                Spacer()
                TextField(Localization.tr("platformPlaceholder"), text: $platform)
                    .multilineTextAlignment(.trailing)
            }
            
            Toggle(Localization.tr("hasMetInPerson"), isOn: $hasMetInPerson)
        }
    }
    
    private var petSection: some View {
        Section(header: Text(Localization.tr("petInfo"))) {
            Picker(Localization.tr("petType"), selection: $petType) {
                Text(Localization.tr("petType_cat")).tag("cat")
                Text(Localization.tr("petType_dog")).tag("dog")
                Text(Localization.tr("petType_bird")).tag("bird")
                Text(Localization.tr("petType_fish")).tag("fish")
                Text(Localization.tr("petType_other")).tag("other")
            }
            
            HStack {
                Text(Localization.tr("petAge"))
                Spacer()
                TextField("0", text: $petAge)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                Text(Localization.tr("unit_years"))
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text(Localization.tr("petBreed"))
                Spacer()
                TextField(Localization.tr("optional"), text: $petBreed)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        Section(header: Text(Localization.tr("notesAndTags"))) {
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.tr("notes"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel(Localization.tr("notes"))
            }
            .padding(.vertical, 4)
            
            // Tags
            HStack {
                Text(Localization.tr("tags"))
                    .foregroundStyle(.primary)
                Spacer()
                TextField(Localization.tr("tagsPlaceholder"), text: $tagsText)
                    .multilineTextAlignment(.trailing)
                    .accessibilityLabel(Localization.tr("tags"))
                    .accessibilityHint(Localization.tr("tagsPlaceholder"))
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadProfileData() {
        guard let profile = profile else { return }
        
        displayName = profile.displayName
        avatar = profile.avatar ?? "👤"
        type = profile.type
        realName = profile.realName ?? ""
        intimacyLevel = Double(profile.intimacyLevel)
        emotionalConnection = Double(profile.emotionalConnection)
        notes = profile.notes ?? ""
        tagsText = profile.tags.joined(separator: ", ")
        
        // Load type-specific data
        switch profile.type {
        case .partner:
            partnerStatus = profile.partnerStatus ?? "dating"
            anniversaryMet = profile.anniversaryMet ?? ""
            anniversaryDating = profile.anniversaryDating ?? ""
            anniversaryMarried = profile.anniversaryMarried ?? ""
        case .family:
            familyRole = profile.familyRole ?? "parent"
            livingTogether = profile.livingTogether
        case .friends:
            friendIntimacy = profile.friendIntimacy ?? "friend"
            yearsKnown = profile.yearsKnown.map { String($0) } ?? ""
        case .colleagues:
            workRelationship = profile.workRelationship ?? "peer"
            company = profile.company ?? ""
            department = profile.department ?? ""
        case .onlineFriends:
            platform = profile.platform ?? ""
            hasMetInPerson = profile.hasMetInPerson
        case .pet:
            petType = profile.petType ?? "cat"
            petAge = profile.petAge.map { String($0) } ?? ""
            petBreed = profile.petBreed ?? ""
        case .alone:
            break
        }
    }
    
    // MARK: - Save
    
    private func saveProfile() {
        var newProfile = RelationshipProfile(
            id: profile?.id ?? UUID().uuidString,
            createdAt: profile?.createdAt ?? Date(),
            updatedAt: Date(),
            type: type,
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            realName: realName.isEmpty ? nil : realName,
            avatar: avatar,
            intimacyLevel: Int(intimacyLevel),
            interactionFrequency: profile?.interactionFrequency ?? .occasional,
            emotionalConnection: Int(emotionalConnection),
            totalInteractions: profile?.totalInteractions ?? 0,
            lastInteractionDate: profile?.lastInteractionDate,
            recentInteractionDates: profile?.recentInteractionDates ?? [],
            metadata: [:],
            notes: notes.isEmpty ? nil : notes,
            tags: tagsText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        )
        
        // Set type-specific metadata
        switch type {
        case .partner:
            newProfile.partnerStatus = partnerStatus
            if !anniversaryMet.isEmpty { newProfile.anniversaryMet = anniversaryMet }
            if !anniversaryDating.isEmpty { newProfile.anniversaryDating = anniversaryDating }
            if !anniversaryMarried.isEmpty { newProfile.anniversaryMarried = anniversaryMarried }
        case .family:
            newProfile.familyRole = familyRole
            newProfile.livingTogether = livingTogether
        case .friends:
            newProfile.friendIntimacy = friendIntimacy
            if let years = Int(yearsKnown) { newProfile.yearsKnown = years }
        case .colleagues:
            newProfile.workRelationship = workRelationship
            if !company.isEmpty { newProfile.company = company }
            if !department.isEmpty { newProfile.department = department }
        case .onlineFriends:
            if !platform.isEmpty { newProfile.platform = platform }
            newProfile.hasMetInPerson = hasMetInPerson
        case .pet:
            newProfile.petType = petType
            if let age = Int(petAge) { newProfile.petAge = age }
            if !petBreed.isEmpty { newProfile.petBreed = petBreed }
        case .alone:
            break
        }
        
        onSave(newProfile)
    }
}

// MARK: - Emoji Picker Sheet

struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String
    @Binding var isPresented: Bool
    
    private let emojis = [
        "👤", "👩", "👨", "👧", "👦", "👶", "👵", "👴",
        "❤️", "💕", "💔", "💖", "💗", "💘", "💝", "💞",
        "👨‍👩‍👧", "👨‍👩‍👦", "👨‍👩‍👧‍👦", "👪", "👨‍👧", "👩‍👦",
        "🐱", "🐶", "🐰", "🐹", "🐠", "🐦", "🐢", "🦎",
        "👔", "💼", "🎓", "💻", "📱", "🎨", "🎸", "📚",
        "🏃", "🧘", "🎮", "☕", "🍺", "🎬", "✈️", "🏠",
        "😊", "😎", "🤓", "🥰", "😇", "🤗", "🙂", "😌"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 12) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            isPresented = false
                        }) {
                            Text(emoji)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(selectedEmoji == emoji ? Color(.systemBlue).opacity(0.2) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(emoji)
                        .accessibilityAddTraits(selectedEmoji == emoji ? .isSelected : [])
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Localization.tr("selectEmoji"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.tr("cancel")) {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    RelationshipEditSheet(
        profile: nil,
        onSave: { _ in },
        onCancel: { }
    )
}
