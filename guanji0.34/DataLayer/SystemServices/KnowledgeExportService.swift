import Foundation

// MARK: - Knowledge Export Service

/// Service for exporting data for AI knowledge extraction
/// Handles daily package export and context export
public final class KnowledgeExportService {
    
    public static let shared = KnowledgeExportService()
    
    private let dailyExtractionService = DailyExtractionService.shared
    private let contextBuilder = ContextBuilder.shared
    
    private init() {}
    
    // MARK: - Export Daily Package
    
    /// Export daily package as JSON string
    /// - Parameter dayId: Date in yyyy.MM.dd format
    /// - Returns: JSON string of DailyExtractionPackage
    public func exportDailyPackage(for dayId: String) async throws -> String {
        let package = try await dailyExtractionService.extractDailyPackage(for: dayId)
        return try encodeToJSON(package)
    }
    
    /// Export daily package as structured data
    public func getDailyPackage(for dayId: String) async throws -> DailyExtractionPackage {
        return try await dailyExtractionService.extractDailyPackage(for: dayId)
    }
    
    // MARK: - Export Context
    
    /// Export context based on server's context request
    /// - Parameter request: Context request from server (parsed from JSON)
    /// - Returns: JSON string of SanitizedContext
    public func exportContext(for request: ContextRequest) throws -> String {
        let context = contextBuilder.buildContext(for: request)
        return try encodeToJSON(context)
    }
    
    /// Export context as structured data
    public func getContext(for request: ContextRequest) -> SanitizedContext {
        return contextBuilder.buildContext(for: request)
    }
    
    /// Export full context (user profile + all relationships)
    public func exportFullContext() throws -> String {
        let userProfile = contextBuilder.buildUserProfile()
        let relationships = contextBuilder.buildAllRelationships()
        let context = SanitizedContext(userProfile: userProfile, relationships: relationships)
        return try encodeToJSON(context)
    }
    
    // MARK: - Export Combined Package (Round 2)
    
    /// Export combined package for round 2 (daily data + context)
    /// - Parameters:
    ///   - dayId: Date in yyyy.MM.dd format
    ///   - contextRequest: Context request from server
    /// - Returns: JSON string containing both daily data and context
    public func exportCombinedPackage(
        for dayId: String,
        contextRequest: ContextRequest
    ) async throws -> String {
        let dailyPackage = try await dailyExtractionService.extractDailyPackage(for: dayId)
        let context = contextBuilder.buildContext(for: contextRequest)
        
        let combined = CombinedExportPackage(
            dayId: dayId,
            extractedAt: dailyPackage.extractedAt,
            dailyData: DailyDataSection(
                journalEntries: dailyPackage.journalEntries,
                trackerRecord: dailyPackage.trackerRecord,
                loveLogs: dailyPackage.loveLogs,
                aiConversations: dailyPackage.aiConversations,
                questions: dailyPackage.questions
            ),
            context: context
        )
        
        return try encodeToJSON(combined)
    }
    
    // MARK: - Parse Context Request
    
    /// Parse context request from JSON string
    /// - Parameter json: JSON string from server
    /// - Returns: Parsed ContextRequest
    public func parseContextRequest(from json: String) throws -> ContextRequest {
        guard let data = json.data(using: .utf8) else {
            throw KnowledgeAPIError.decodingFailed("Invalid UTF-8 string")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ContextRequest.self, from: data)
        } catch {
            throw KnowledgeAPIError.decodingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Helpers
    
    private func encodeToJSON<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(value)
            guard let json = String(data: data, encoding: .utf8) else {
                throw KnowledgeAPIError.encodingFailed("Failed to convert data to UTF-8 string")
            }
            return json
        } catch let error as KnowledgeAPIError {
            throw error
        } catch {
            throw KnowledgeAPIError.encodingFailed(error.localizedDescription)
        }
    }
}

// MARK: - Combined Export Package

/// Combined package for round 2 export
public struct CombinedExportPackage: Codable {
    public let dayId: String
    public let extractedAt: Date
    public let dailyData: DailyDataSection
    public let context: SanitizedContext
}

/// Daily data section
public struct DailyDataSection: Codable {
    public let journalEntries: [SanitizedJournalEntry]
    public let trackerRecord: SanitizedTrackerRecord?
    public let loveLogs: [SanitizedLoveLog]
    public let aiConversations: [AIConversationSummary]
    public let questions: [SanitizedQuestion]
}
