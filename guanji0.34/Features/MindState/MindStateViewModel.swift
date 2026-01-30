import Foundation
import SwiftUI
import Combine

public final class MindStateViewModel: ObservableObject {
    @Published public var step: Int = 1
    @Published public var valenceValue: Double = 50 // 0..100
    @Published public var interacted: Bool = false
    @Published public var searchText: String = ""
    @Published public var selectedLabels: Set<String> = []
    @Published public var selectedInfluences: Set<MindInfluence> = []
    public let maxLabels = 20
    public let maxInfluences = 5

    public init() {}

    public var valenceSegment: MindValence {
        switch valenceValue {
        case ..<15: return .veryUnpleasant
        case 15..<35: return .unpleasant
        case 35..<50: return .slightlyUnpleasant
        case 50: return .neutral
        case 50..<65: return .slightlyPleasant
        case 65..<85: return .pleasant
        default: return .veryPleasant
        }
    }

    public var revealFraction: Double { min(1.0, abs(valenceValue - 50) / 50.0) }

    public var filteredLabels: [MindLabel] {
        let allowed: Set<MindValenceGroup> = {
            switch valenceSegment {
            case .veryUnpleasant, .unpleasant: return [.unpleasant]
            case .slightlyUnpleasant: return [.unpleasant, .neutral]
            case .neutral: return [.neutral]
            case .slightlyPleasant: return [.pleasant, .neutral]
            case .pleasant, .veryPleasant: return [.pleasant]
            }
        }()
        var base = MindCatalog.labels.filter { allowed.contains($0.group) }
        // 优先强烈负面词在左侧（数组已按优先顺序给出）
        if searchText.isEmpty { return base }
        base = base.filter { Localization.tr($0.key).localizedCaseInsensitiveContains(searchText) }
        return base
    }

    // 由按钮控制进入第二页，避免自动跳页

    public func toggleLabel(_ id: String) {
        if selectedLabels.contains(id) {
            selectedLabels.remove(id)
        } else {
            if selectedLabels.count < maxLabels { selectedLabels.insert(id) }
        }
    }

    public func toggleInfluence(_ inf: MindInfluence) {
        if selectedInfluences.contains(inf) {
            selectedInfluences.remove(inf)
        } else {
            if selectedInfluences.count < maxInfluences { selectedInfluences.insert(inf) }
        }
    }

    public func proceedFromLabels() { step = 3 }
    public func goBack() { if step > 1 { step -= 1 } }

    public struct Result {
        public let valence: MindValence
        public let labels: [String]
        public let influences: [String]
    }

    public func finalize() -> Result {
        let labels = Array(selectedLabels)
        let infl = selectedInfluences.map { $0.rawValue }
        return Result(valence: valenceSegment, labels: labels, influences: infl)
    }
}
