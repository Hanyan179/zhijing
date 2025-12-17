import SwiftUI
import Combine
import Foundation

/// ViewModel for UserProfile display
/// Requirements: Epic 1-5
public final class UserProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var userProfile: UserProfile
    
    // MARK: - Initialization
    
    public init() {
        // Load mock data initially
        self.userProfile = MockDataService.userProfile
    }
    
    // MARK: - Computed Properties for Kernel Data
    
    public var identityKernel: IdentityKernel {
        userProfile.identity.kernel
    }
    
    public var personalityKernel: PersonalityKernel {
        userProfile.personality.kernel
    }
    
    public var socialKernel: SocialKernel {
        userProfile.social.kernel
    }
    
    public var competenceKernel: CompetenceKernel {
        userProfile.competence.kernel
    }
    
    public var lifestyleKernel: LifestyleKernel {
        userProfile.lifestyle.kernel
    }
    
    // MARK: - Computed Properties for State Data
    
    public var identityState: IdentityState {
        userProfile.identity.state
    }
    
    public var personalityState: PersonalityState {
        userProfile.personality.state
    }
    
    public var socialState: SocialState {
        userProfile.social.state
    }
    
    public var competenceState: CompetenceState {
        userProfile.competence.state
    }
    
    public var lifestyleState: LifestyleState {
        userProfile.lifestyle.state
    }
    
    // MARK: - Helper Methods for Display
    
    /// Format optional string value for display
    public func displayValue(_ value: String?) -> String {
        value ?? Localization.tr("notSet")
    }
    
    /// Format optional int value for display
    public func displayValue(_ value: Int?, unit: String? = nil) -> String {
        guard let v = value else { return Localization.tr("notSet") }
        if let u = unit {
            return "\(v) \(Localization.tr(u))"
        }
        return "\(v)"
    }
    
    /// Format optional double value for display
    public func displayValue(_ value: Double?, unit: String? = nil) -> String {
        guard let v = value else { return Localization.tr("notSet") }
        if let u = unit {
            return String(format: "%.1f \(Localization.tr(u))", v)
        }
        return String(format: "%.1f", v)
    }
    
    /// Format array value for display
    public func displayValue(_ values: [String]) -> String {
        values.isEmpty ? Localization.tr("notSet") : values.joined(separator: ", ")
    }
    
    /// Format date for display
    public func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Format energy level (-3 to +3) for display
    public func displayEnergyLevel(_ level: Int) -> String {
        switch level {
        case -3: return "😫 -3"
        case -2: return "😔 -2"
        case -1: return "😐 -1"
        case 0: return "😊 0"
        case 1: return "🙂 +1"
        case 2: return "😄 +2"
        case 3: return "🤩 +3"
        default: return "\(level)"
        }
    }
    
    /// Format 1-10 scale for display
    public func displayScale(_ value: Int) -> String {
        "\(value)/10"
    }
    
    /// Format 1-5 scale for display
    public func displayScale5(_ value: Int?) -> String {
        guard let v = value else { return Localization.tr("notSet") }
        return "\(v)/5"
    }
}
