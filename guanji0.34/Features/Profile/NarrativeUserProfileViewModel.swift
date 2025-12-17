import SwiftUI
import Combine
import Foundation

/// ViewModel for NarrativeUserProfile display (no scores)
/// Replaces UserProfileViewModel with narrative-based approach
public final class NarrativeUserProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var profile: NarrativeUserProfile
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let repository = NarrativeUserProfileRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        self.profile = repository.load()
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: Notification.Name("gj_user_profile_updated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Static Core Access
    
    public var staticCore: StaticCore {
        profile.staticCore
    }
    
    public var recentPortrait: RecentPortrait? {
        profile.recentPortrait
    }
    
    // MARK: - Static Core Field Updates
    
    public func updateGender(_ gender: Gender?) {
        let oldValue = staticCore.gender?.rawValue
        let newValue = gender?.rawValue
        
        repository.updateStaticCoreField(
            fieldName: "gender",
            oldValue: oldValue,
            newValue: newValue
        ) { core in
            core.gender = gender
        }
        reload()
    }
    
    public func updateBirthYearMonth(_ value: String?) {
        let oldValue = staticCore.birthYearMonth
        
        repository.updateStaticCoreField(
            fieldName: "birthYearMonth",
            oldValue: oldValue,
            newValue: value
        ) { core in
            core.birthYearMonth = value
        }
        reload()
    }
    
    public func updateHometown(_ value: String?) {
        let oldValue = staticCore.hometown
        
        repository.updateStaticCoreField(
            fieldName: "hometown",
            oldValue: oldValue,
            newValue: value
        ) { core in
            core.hometown = value
        }
        reload()
    }
    
    public func updateCurrentCity(_ value: String?) {
        let oldValue = staticCore.currentCity
        
        repository.updateStaticCoreField(
            fieldName: "currentCity",
            oldValue: oldValue,
            newValue: value
        ) { core in
            core.currentCity = value
        }
        reload()
    }
    
    public func updateOccupation(_ value: String?) {
        let oldValue = staticCore.occupation
        
        repository.updateStaticCoreField(
            fieldName: "occupation",
            oldValue: oldValue,
            newValue: value
        ) { core in
            core.occupation = value
        }
        reload()
    }
    
    public func updateIndustry(_ value: String?) {
        let oldValue = staticCore.industry
        
        repository.updateStaticCoreField(
            fieldName: "industry",
            oldValue: oldValue,
            newValue: value
        ) { core in
            core.industry = value
        }
        reload()
    }
    
    public func updateEducation(_ education: Education?) {
        let oldValue = staticCore.education?.rawValue
        let newValue = education?.rawValue
        
        repository.updateStaticCoreField(
            fieldName: "education",
            oldValue: oldValue,
            newValue: newValue
        ) { core in
            core.education = education
        }
        reload()
    }
    
    // MARK: - Self Tags Management
    
    public func addSelfTag(_ tag: String) {
        guard !tag.isEmpty, !staticCore.selfTags.contains(tag) else { return }
        
        var updatedProfile = profile
        updatedProfile.staticCore.selfTags.append(tag)
        repository.save(updatedProfile)
        reload()
    }
    
    public func removeSelfTag(_ tag: String) {
        var updatedProfile = profile
        updatedProfile.staticCore.selfTags.removeAll { $0 == tag }
        repository.save(updatedProfile)
        reload()
    }
    
    // MARK: - Display Helpers
    
    public func displayValue(_ value: String?) -> String {
        value ?? Localization.tr("Profile.NotSet")
    }
    
    public func displayTags(_ tags: [String]) -> String {
        tags.isEmpty ? Localization.tr("Profile.NoTags") : tags.joined(separator: ", ")
    }
    
    public var hasAnyStaticCoreData: Bool {
        staticCore.gender != nil ||
        staticCore.birthYearMonth != nil ||
        staticCore.hometown != nil ||
        staticCore.currentCity != nil ||
        staticCore.occupation != nil ||
        staticCore.industry != nil ||
        staticCore.education != nil ||
        !staticCore.selfTags.isEmpty
    }
    
    // MARK: - Update History
    
    public var updateHistory: [ProfileUpdateRecord] {
        staticCore.updateHistory.sorted { $0.timestamp > $1.timestamp }
    }
    
    public var recentUpdates: [ProfileUpdateRecord] {
        Array(updateHistory.prefix(5))
    }
    
    // MARK: - Private Methods
    
    private func reload() {
        profile = repository.load()
    }
}
