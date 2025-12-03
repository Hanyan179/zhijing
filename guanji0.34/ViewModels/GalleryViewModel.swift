import Foundation
import SwiftUI
import Combine

final class GalleryViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    private(set) var achievements: [UserAchievement] = [] { didSet { objectWillChange.send() } }
    var query: String = "" { didSet { objectWillChange.send() } }

    init() {
        loadAll()
    }

    func loadAll() { achievements = Array(MockDataService.achievements.values) }

    var filtered: [UserAchievement] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return achievements }
        return achievements.filter { a in
            let zh = a.aiGeneratedTitle?.zh.lowercased() ?? ""
            let en = a.aiGeneratedTitle?.en.lowercased() ?? ""
            return zh.contains(q) || en.contains(q)
        }
    }
}
