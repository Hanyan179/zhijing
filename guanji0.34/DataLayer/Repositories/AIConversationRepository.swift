import Foundation

/// Repository for managing AI conversation persistence
/// Uses JSON file storage in Documents/ai_conversations/
public final class AIConversationRepository {
    public static let shared = AIConversationRepository()
    
    // File URLs
    private let conversationsDirectoryURL: URL
    private let indexFileURL: URL
    
    // In-memory cache
    private var conversationCache: [String: AIConversation] = [:] // ID -> Conversation
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        conversationsDirectoryURL = docs.appendingPathComponent("ai_conversations", isDirectory: true)
        indexFileURL = conversationsDirectoryURL.appendingPathComponent("index.json")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: conversationsDirectoryURL, withIntermediateDirectories: true)
        
        loadFromDisk()
    }
    
    // MARK: - Public CRUD API
    
    /// Save a new or existing conversation
    /// - Parameter conversation: The conversation to save
    /// - Requirements: 9.1, 9.2
    public func save(_ conversation: AIConversation) {
        var updatedConversation = conversation
        updatedConversation.updatedAt = Date()
        
        conversationCache[conversation.id] = updatedConversation
        persistConversation(updatedConversation)
        persistIndex()
        
        // Notify observers
        NotificationCenter.default.post(name: Notification.Name("gj_ai_conversation_updated"), object: nil)
    }
    
    /// Load a conversation by ID
    /// - Parameter id: The conversation ID
    /// - Returns: The conversation if found, nil otherwise
    /// - Requirements: 9.3, 9.4
    public func load(id: String) -> AIConversation? {
        if let cached = conversationCache[id] {
            return cached
        }
        
        // Try loading from disk
        let fileURL = conversationFileURL(for: id)
        guard let data = try? Data(contentsOf: fileURL),
              let conversation = try? JSONDecoder().decode(AIConversation.self, from: data) else {
            return nil
        }
        
        conversationCache[id] = conversation
        return conversation
    }

    
    /// Delete a conversation by ID
    /// - Parameter id: The conversation ID to delete
    /// - Requirements: 9.5
    public func delete(id: String) {
        conversationCache.removeValue(forKey: id)
        
        // Delete file from disk
        let fileURL = conversationFileURL(for: id)
        try? FileManager.default.removeItem(at: fileURL)
        
        persistIndex()
        
        // Notify observers
        NotificationCenter.default.post(name: Notification.Name("gj_ai_conversation_updated"), object: nil)
    }
    
    /// Load all conversations
    /// - Returns: Array of all conversations sorted by updatedAt (newest first)
    /// - Requirements: 9.3, 9.4
    public func loadAll() -> [AIConversation] {
        return Array(conversationCache.values).sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// Add a message to a conversation and update day association
    /// - Parameters:
    ///   - message: The message to add
    ///   - conversationId: The conversation ID
    /// - Requirements: 3.3, 7.2, 9.2
    public func addMessage(_ message: AIMessage, to conversationId: String) {
        guard var conversation = load(id: conversationId) else { return }
        
        conversation.addMessage(message)
        save(conversation)
    }
    
    /// Create a new conversation associated with the current day
    /// - Returns: The newly created conversation
    /// - Requirements: 2.5, 7.1
    public func createConversation() -> AIConversation {
        let today = DateUtilities.today
        let conversation = AIConversation(
            id: UUID().uuidString,
            dayId: today,
            associatedDays: [today],
            createdAt: Date(),
            updatedAt: Date()
        )
        save(conversation)
        return conversation
    }
    
    // MARK: - Grouping API
    
    /// Get conversations grouped by day
    /// Multi-day conversations appear in each associated day's group
    /// - Returns: Array of ConversationDayGroup sorted by date (newest first)
    /// - Requirements: 2.1, 2.6, 3.4
    public func getConversationsGroupedByDay() -> [ConversationDayGroup] {
        var dayToConversations: [String: [AIConversation]] = [:]
        
        for conversation in conversationCache.values {
            for day in conversation.associatedDays {
                if dayToConversations[day] == nil {
                    dayToConversations[day] = []
                }
                dayToConversations[day]?.append(conversation)
            }
        }
        
        // Sort conversations within each day by updatedAt (newest first)
        // Sort days by date (newest first)
        return dayToConversations
            .map { day, conversations in
                ConversationDayGroup(
                    date: day,
                    conversations: conversations.sorted { $0.updatedAt > $1.updatedAt }
                )
            }
            .sorted { $0.date > $1.date }
    }
    
    /// Get conversations for a specific day
    /// - Parameter day: The day string in "yyyy.MM.dd" format
    /// - Returns: Array of conversations associated with that day, sorted by creation time (oldest first, newest at bottom)
    /// - Requirements: 3.4
    public func getConversations(for day: String) -> [AIConversation] {
        return conversationCache.values
            .filter { $0.associatedDays.contains(day) }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    // MARK: - Private Persistence Methods
    
    private func conversationFileURL(for id: String) -> URL {
        return conversationsDirectoryURL.appendingPathComponent("\(id).json")
    }
    
    private func loadFromDisk() {
        // Load index to get all conversation IDs
        guard let indexData = try? Data(contentsOf: indexFileURL),
              let ids = try? JSONDecoder().decode([String].self, from: indexData) else {
            return
        }
        
        // Load each conversation
        for id in ids {
            let fileURL = conversationFileURL(for: id)
            if let data = try? Data(contentsOf: fileURL),
               let conversation = try? JSONDecoder().decode(AIConversation.self, from: data) {
                conversationCache[id] = conversation
            }
        }
    }
    
    private func persistConversation(_ conversation: AIConversation) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(conversation)
                try data.write(to: self.conversationFileURL(for: conversation.id))
            } catch {
                print("AI Conversation Persistence Error: \(error)")
            }
        }
    }
    
    private func persistIndex() {
        DispatchQueue.global(qos: .background).async {
            do {
                let ids = Array(self.conversationCache.keys)
                let data = try JSONEncoder().encode(ids)
                try data.write(to: self.indexFileURL)
            } catch {
                print("AI Conversation Index Persistence Error: \(error)")
            }
        }
    }
}
