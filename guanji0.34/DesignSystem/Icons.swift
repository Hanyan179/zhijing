import SwiftUI

public enum Icons {
    public static func categoryIconName(_ category: EntryCategory?) -> String {
        guard let c = category else { return "sparkles" }
        switch c {
        case .dream: return "moon"
        case .idea: return "lightbulb"
        case .emotion: return "heart.fill"
        case .work: return "briefcase"
        case .social: return "person.2"
        case .media: return "photo"
        }
    }

    public static func categoryLabelKey(_ category: EntryCategory?) -> String {
        guard let c = category else { return "record" }
        switch c {
        case .dream: return "dream"
        case .idea: return "idea"
        case .emotion: return "emotion"
        case .work: return "work"
        case .social: return "social"
        case .media: return "media"
        }
    }

    public static func categoryLabel(_ category: EntryCategory?) -> String {
        NSLocalizedString(categoryLabelKey(category), comment: "")
    }

    public static func transportIconName(_ mode: TransportMode) -> String {
        switch mode {
        case .car: return "car.fill"
        case .walk: return "figure.walk"
        case .subway: return "tram.fill"
        case .bicycle: return "bicycle"
        }
    }
}
