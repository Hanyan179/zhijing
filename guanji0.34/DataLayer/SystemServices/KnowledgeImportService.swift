import Foundation

// MARK: - Knowledge Import Service

/// Service for importing AI extraction results
/// Parses server response and updates local L4 data
public final class KnowledgeImportService {
    
    public static let shared = KnowledgeImportService()
    
    private let userProfileRepo = NarrativeUserProfileRepository.shared
    private let relationshipRepo = NarrativeRelationshipRepository.shared
    
    private init() {}
    
    // MARK: - Parse Context Request
    
    /// Parse context request JSON from server
    /// - Parameter json: JSON string from server
    /// - Returns: Parsed ContextRequest
    public func parseContextRequest(json: String) throws -> ContextRequest {
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
    
    // MARK: - Parse Extraction Response
    
    /// Parse extraction response JSON from server
    /// - Parameter json: JSON string from server
    /// - Returns: Parsed ExtractionResponse
    public func parseExtractionResponse(json: String) throws -> ExtractionResponse {
        guard let data = json.data(using: .utf8) else {
            throw KnowledgeAPIError.decodingFailed("Invalid UTF-8 string")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ExtractionResponse.self, from: data)
        } catch {
            throw KnowledgeAPIError.decodingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Import Extracted Results
    
    /// Import extracted results and update local data
    /// - Parameter json: JSON string containing ExtractionResponse
    /// - Returns: Import summary
    public func importExtractedResults(json: String) throws -> ImportSummary {
        let response = try parseExtractionResponse(json: json)
        
        guard response.success else {
            let errorMsg = response.error?.message ?? "Unknown error"
            throw KnowledgeAPIError.importFailed(errorMsg)
        }
        
        guard let results = response.results else {
            return ImportSummary(dayId: response.dayId, imported: 0, skipped: 0, errors: [])
        }
        
        var imported = 0
        var skipped = 0
        var errors: [String] = []
        
        for result in results {
            do {
                try importSingleResult(result, dayId: response.dayId)
                imported += 1
            } catch {
                errors.append("Failed to import \(result.type.rawValue): \(error.localizedDescription)")
                skipped += 1
            }
        }
        
        return ImportSummary(
            dayId: response.dayId,
            imported: imported,
            skipped: skipped,
            errors: errors
        )
    }
    
    // MARK: - Import Single Result
    
    private func importSingleResult(_ result: ExtractedResult, dayId: String) throws {
        switch result.type {
        case .knowledgeNode:
            try importKnowledgeNode(result, dayId: dayId)
        case .relationshipAttribute:
            try importRelationshipAttribute(result, dayId: dayId)
        case .profileInsight:
            // Profile insights are informational, no storage needed
            print("KnowledgeImportService: Received profile insight for \(result.target)")
        case .custom:
            // Custom data handling - log for now
            print("KnowledgeImportService: Received custom data for \(result.target)")
        }
    }
    
    // MARK: - Import Knowledge Node
    
    private func importKnowledgeNode(_ result: ExtractedResult, dayId: String) throws {
        guard let nodeType = result.data.nodeType,
              let name = result.data.name else {
            throw KnowledgeAPIError.importFailed("Missing nodeType or name")
        }
        
        // Build source links
        let sourceLinks = (result.data.sourceLinks ?? []).map { link in
            SourceLink(
                sourceType: link.sourceType,
                sourceId: link.sourceId,
                dayId: link.dayId,
                snippet: link.snippet
            )
        }
        
        // Create knowledge node
        let node = KnowledgeNode.createAIExtracted(
            nodeType: nodeType,
            name: name,
            description: result.data.description,
            confidence: result.data.confidence ?? 0.8,
            sourceLinks: sourceLinks
        )
        
        // Determine target
        if result.target == "user" {
            // Add to user profile
            var profile = userProfileRepo.load()
            
            // Check for duplicate
            if !profile.knowledgeNodes.contains(where: { $0.nodeType == nodeType && $0.name == name }) {
                profile.knowledgeNodes.append(node)
                userProfileRepo.save(profile)
            }
        } else {
            // Add to relationship
            let relationshipId = extractRelationshipId(from: result.target)
            guard var relationship = relationshipRepo.load(id: relationshipId) else {
                throw KnowledgeAPIError.relationshipNotFound(relationshipId)
            }
            
            // Check for duplicate
            if !relationship.attributes.contains(where: { $0.nodeType == nodeType && $0.name == name }) {
                relationship.attributes.append(node)
                relationshipRepo.save(relationship)
            }
        }
    }
    
    // MARK: - Import Relationship Attribute
    
    private func importRelationshipAttribute(_ result: ExtractedResult, dayId: String) throws {
        let relationshipId = extractRelationshipId(from: result.target)
        guard var relationship = relationshipRepo.load(id: relationshipId) else {
            throw KnowledgeAPIError.relationshipNotFound(relationshipId)
        }
        
        guard let nodeType = result.data.nodeType,
              let name = result.data.name else {
            throw KnowledgeAPIError.importFailed("Missing nodeType or name for relationship attribute")
        }
        
        // Build source links
        let sourceLinks = (result.data.sourceLinks ?? []).map { link in
            SourceLink(
                sourceType: link.sourceType,
                sourceId: link.sourceId,
                dayId: link.dayId,
                snippet: link.snippet
            )
        }
        
        // Create attribute node
        let node = KnowledgeNode.createAIExtracted(
            nodeType: nodeType,
            name: name,
            description: result.data.description,
            confidence: result.data.confidence ?? 0.8,
            sourceLinks: sourceLinks
        )
        
        // Check for duplicate
        if !relationship.attributes.contains(where: { $0.nodeType == nodeType && $0.name == name }) {
            relationship.attributes.append(node)
            relationshipRepo.save(relationship)
        }
    }
    
    // MARK: - Helpers
    
    /// Extract relationship ID from ref format [REL_xxx:name]
    private func extractRelationshipId(from target: String) -> String {
        // Parse [REL_xxx:name] format
        let pattern = "\\[REL_([^:]+):[^\\]]+\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: target, range: NSRange(target.startIndex..., in: target)),
              let idRange = Range(match.range(at: 1), in: target) else {
            // If not in ref format, assume it's the ID directly
            return target
        }
        return String(target[idRange])
    }
}

// MARK: - Import Summary

/// Summary of import operation
public struct ImportSummary: Codable {
    public let dayId: String
    public let imported: Int
    public let skipped: Int
    public let errors: [String]
    
    public var isSuccess: Bool {
        errors.isEmpty
    }
    
    public var description: String {
        if isSuccess {
            return "成功导入 \(imported) 条数据"
        } else {
            return "导入 \(imported) 条，跳过 \(skipped) 条，\(errors.count) 个错误"
        }
    }
}
