import Foundation

public final class QuestionRepository {
    public static let shared = QuestionRepository()
    private let fileURL: URL
    private var questions: [String: QuestionEntry] = [:]
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("TimelineData", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("questions.json")
        load()
        if questions.isEmpty { seed() }
    }
    
    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let dict = try? JSONDecoder().decode([String: QuestionEntry].self, from: data) {
            questions = dict
        }
    }
    
    private func save() {
        DispatchQueue.global(qos: .background).async {
            if let data = try? JSONEncoder().encode(self.questions) {
                try? data.write(to: self.fileURL)
            }
        }
    }
    
    private func seed() {
        for q in MockDataService.questions {
            questions[q.id] = q
        }
        save()
    }
    
    public func get(id: String) -> QuestionEntry? {
        return questions[id]
    }
    
    public func add(_ question: QuestionEntry) {
        questions[question.id] = question
        save()
    }
    
    public func getAll() -> [QuestionEntry] {
        return Array(questions.values)
    }
}
