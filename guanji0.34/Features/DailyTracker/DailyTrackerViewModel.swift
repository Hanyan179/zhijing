import Foundation
import SwiftUI
import Combine

/// ViewModel for Daily Tracker three-step flow
public final class DailyTrackerViewModel: ObservableObject {
    
    // MARK: - Flow State
    
    @Published public var step: Int = 1
    
    // MARK: - Step 1: Daily Status (0-100 continuous scale)
    
    @Published public var bodyEnergy: Int = 50     // 0-100 (50 = normal)
    @Published public var moodWeather: Int = 50    // 0-100 (50 = neutral)
    
    // MARK: - Step 2: Activities
    
    @Published public var selectedActivities: Set<ActivityType> = []
    
    // MARK: - Step 3: Context
    
    @Published public var activityContexts: [ActivityType: ActivityContext] = [:]
    
    // MARK: - Editing State
    
    @Published public var editingActivity: ActivityType? = nil
    
    // MARK: - Computed Properties
    
    public var bodyEnergyLevel: BodyEnergyLevel {
        BodyEnergyLevel.from(bodyEnergy)
    }
    
    public var moodWeatherLevel: MindValence {
        MindValence.from(moodWeather)
    }
    
    public var canProceedToStep2: Bool { true }
    
    public var canProceedToStep3: Bool { !selectedActivities.isEmpty }
    
    public var canSaveFromStep2: Bool { true }
    
    public var canSave: Bool { true }
    
    /// Get sorted activities for display
    public var sortedSelectedActivities: [ActivityType] {
        selectedActivities.sorted { $0.rawValue < $1.rawValue }
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    /// Initialize for editing an existing record
    public init(record: DailyTrackerRecord) {
        self.bodyEnergy = record.bodyEnergy
        self.moodWeather = record.moodWeather
        
        for context in record.activities {
            self.selectedActivities.insert(context.activityType)
            self.activityContexts[context.activityType] = context
        }
    }
    
    // MARK: - Step Navigation
    
    public func goToStep(_ step: Int) {
        guard step >= 1 && step <= 3 else { return }
        
        // Initialize contexts when entering Step 3
        if step == 3 {
            initializeContexts()
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.step = step
        }
    }
    
    public func goBack() {
        if step > 1 {
            goToStep(step - 1)
        }
    }
    
    public func goNext() {
        if step < 3 {
            goToStep(step + 1)
        }
    }
    
    // MARK: - Step 2: Activity Selection
    
    public func toggleActivity(_ type: ActivityType) {
        if selectedActivities.contains(type) {
            selectedActivities.remove(type)
            activityContexts.removeValue(forKey: type)
        } else {
            selectedActivities.insert(type)
        }
        
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    
    public func isActivitySelected(_ type: ActivityType) -> Bool {
        selectedActivities.contains(type)
    }
    
    // MARK: - Step 3: Context Management
    
    /// Initialize contexts with default values for selected activities
    public func initializeContexts() {
        for activity in selectedActivities {
            if activityContexts[activity] == nil {
                activityContexts[activity] = ActivityContext(
                    activityType: activity,
                    companions: activity.defaultCompanions
                )
            }
        }
    }
    
    /// Get context for an activity (creates default if not exists)
    public func getContext(for activity: ActivityType) -> ActivityContext {
        if let context = activityContexts[activity] {
            return context
        }
        let newContext = ActivityContext(
            activityType: activity,
            companions: activity.defaultCompanions
        )
        activityContexts[activity] = newContext
        return newContext
    }
    
    /// Update context for an activity
    public func updateContext(
        for activity: ActivityType,
        companions: [CompanionType]? = nil,
        companionDetails: [String]? = nil,
        details: String? = nil,
        tags: [String]? = nil
    ) {
        var context = getContext(for: activity)
        
        if let companions = companions {
            context.companions = companions
        }
        if let companionDetails = companionDetails {
            context.companionDetails = companionDetails
        }
        if let details = details {
            context.details = details
        }
        if let tags = tags {
            context.tags = tags
        }
        
        activityContexts[activity] = context
    }
    
    /// Toggle companion type for an activity
    public func toggleCompanion(_ companion: CompanionType, for activity: ActivityType) {
        var context = getContext(for: activity)
        
        if context.companions.contains(companion) {
            context.companions.removeAll { $0 == companion }
        } else {
            context.companions.append(companion)
        }
        
        activityContexts[activity] = context
    }
    
    /// Toggle tag for an activity
    public func toggleTag(_ tagId: String, for activity: ActivityType) {
        var context = getContext(for: activity)
        
        if context.tags.contains(tagId) {
            context.tags.removeAll { $0 == tagId }
        } else {
            context.tags.append(tagId)
        }
        
        activityContexts[activity] = context
    }
    
    /// Create and add a new tag
    public func createTag(text: String, for activity: ActivityType) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Check if tag already exists
        if ActivityTagRepository.shared.tagExists(text: trimmed, for: activity) {
            return
        }
        
        let tag = ActivityTagRepository.shared.createTag(text: trimmed, for: activity)
        
        // Add to current context
        var context = getContext(for: activity)
        context.tags.append(tag.id)
        activityContexts[activity] = context
    }
    
    // MARK: - Save
    
    /// Finalize and create the record
    public func finalize() -> DailyTrackerRecord {
        // Build activity contexts array
        var activities: [ActivityContext] = []
        for activity in sortedSelectedActivities {
            if let context = activityContexts[activity] {
                activities.append(context)
            } else {
                // Create default context
                activities.append(ActivityContext(
                    activityType: activity,
                    companions: activity.defaultCompanions
                ))
            }
        }
        
        return DailyTrackerRecord(
            date: DateUtilities.today,
            bodyEnergy: bodyEnergy,
            moodWeather: moodWeather,
            activities: activities
        )
    }
    
    /// Save the record
    public func save() {
        let record = finalize()
        DailyTrackerRepository.shared.save(record)
        
        // Update tag usage counts
        for context in record.activities {
            ActivityTagRepository.shared.incrementUsage(tagIds: context.tags)
        }
        
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    /// Save from Step 2 (skip Step 3)
    public func saveFromStep2() {
        // Initialize contexts with defaults before saving
        initializeContexts()
        save()
    }
}
