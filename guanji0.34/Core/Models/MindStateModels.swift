import Foundation

public enum MindValence: Int, CaseIterable, Identifiable {
    case veryUnpleasant = 0
    case unpleasant = 1
    case slightlyUnpleasant = 2
    case neutral = 3
    case slightlyPleasant = 4
    case pleasant = 5
    case veryPleasant = 6
    public var id: Int { rawValue }
    public var titleKey: String {
        switch self {
        case .veryUnpleasant: return "mind_very_unpleasant"
        case .unpleasant: return "mind_unpleasant"
        case .slightlyUnpleasant: return "mind_slightly_unpleasant"
        case .neutral: return "mind_neutral"
        case .slightlyPleasant: return "mind_slightly_pleasant"
        case .pleasant: return "mind_pleasant"
        case .veryPleasant: return "mind_very_pleasant"
        }
    }
    
    public var iconName: String {
        switch self {
        case .veryUnpleasant: return "cloud.heavyrain.fill"
        case .unpleasant: return "cloud.rain.fill"
        case .slightlyUnpleasant: return "cloud.drizzle.fill"
        case .neutral: return "cloud.fill"
        case .slightlyPleasant: return "cloud.sun.fill"
        case .pleasant: return "sun.min.fill"
        case .veryPleasant: return "sun.max.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .veryUnpleasant: return "slateDark" // Dark/Stormy
        case .unpleasant: return "indigo" // Cool/Rainy
        case .slightlyUnpleasant: return "sky" // Overcast
        case .neutral: return "slateLight" // Neutral gray
        case .slightlyPleasant: return "teal" // Fresh
        case .pleasant: return "orange" // Warm
        case .veryPleasant: return "amber" // Bright
        }
    }
}

public struct MindLabel: Hashable, Identifiable {
    public let id: String
    public let key: String
    public let group: MindValenceGroup
    public init(id: String, key: String, group: MindValenceGroup) { self.id = id; self.key = key; self.group = group }
}

public enum MindValenceGroup: String, CaseIterable {
    case unpleasant
    case neutral
    case pleasant
}

public enum MindInfluence: String, CaseIterable, Identifiable {
    case work
    case family
    case money
    case health
    case spirituality
    case tasks
    case weather
    case dating
    case community
    case education
    case friends
    case relationships
    case identity
    case partner
    case social
    case home
    case fitness
    public var id: String { rawValue }
    public var key: String { "mind_dim_" + rawValue }
}

public enum MindCatalog {
    public static let labels: [MindLabel] = {
        var set: [MindLabel] = []
        func add(_ id: String, _ g: MindValenceGroup) { set.append(MindLabel(id: id, key: "mind_" + id, group: g)) }
        let pairs: [(String, MindValenceGroup)] = [
            ("angry", MindValenceGroup.unpleasant), ("anxious", MindValenceGroup.unpleasant), ("ashamed", MindValenceGroup.unpleasant), ("disappointed", MindValenceGroup.unpleasant), ("discouraged", MindValenceGroup.unpleasant), ("disgusted", MindValenceGroup.unpleasant), ("embarrassed", MindValenceGroup.unpleasant), ("frustrated", MindValenceGroup.unpleasant), ("guilty", MindValenceGroup.unpleasant), ("hopeless", MindValenceGroup.unpleasant), ("irritated", MindValenceGroup.unpleasant), ("jealous", MindValenceGroup.unpleasant), ("lonely", MindValenceGroup.unpleasant), ("sad", MindValenceGroup.unpleasant), ("scared", MindValenceGroup.unpleasant), ("stressed", MindValenceGroup.unpleasant), ("worried", MindValenceGroup.unpleasant), ("annoyed", MindValenceGroup.unpleasant), ("drained", MindValenceGroup.unpleasant), ("overwhelmed", MindValenceGroup.unpleasant), ("disgusted", MindValenceGroup.unpleasant),
            ("calm", MindValenceGroup.neutral), ("content", MindValenceGroup.neutral), ("indifferent", MindValenceGroup.neutral), ("peaceful", MindValenceGroup.neutral), ("satisfied", MindValenceGroup.neutral),
            ("amazed", MindValenceGroup.pleasant), ("amused", MindValenceGroup.pleasant), ("brave", MindValenceGroup.pleasant), ("confident", MindValenceGroup.pleasant), ("excited", MindValenceGroup.pleasant), ("grateful", MindValenceGroup.pleasant), ("happy", MindValenceGroup.pleasant), ("hopeful", MindValenceGroup.pleasant), ("joyful", MindValenceGroup.pleasant), ("passionate", MindValenceGroup.pleasant), ("proud", MindValenceGroup.pleasant), ("relieved", MindValenceGroup.pleasant), ("satisfied", MindValenceGroup.pleasant), ("surprised", MindValenceGroup.pleasant), ("amazed", MindValenceGroup.pleasant), ("joyful", MindValenceGroup.pleasant), ("hopeful", MindValenceGroup.pleasant)
        ]
        pairs.forEach { add($0.0, $0.1) }
        return set
    }()
}
