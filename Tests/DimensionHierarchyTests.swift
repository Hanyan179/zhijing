import Foundation

// MARK: - Unit Tests for Dimension Hierarchy Models
// Tests for NodeContentType and DimensionHierarchy structures
// **Feature: l4-profile-redesign**

/// Unit tests for DimensionHierarchy and NodeContentType
enum DimensionHierarchyTests {
    
    // MARK: - Level 1 Dimension Tests
    
    /// Test that Level1 has exactly 7 dimensions
    /// **Validates: Requirements 3.1**
    static func testLevel1HasSevenDimensions() -> (passed: Bool, message: String) {
        let count = DimensionHierarchy.Level1.allCases.count
        if count == 7 {
            return (true, "Level1 has exactly 7 dimensions")
        } else {
            return (false, "Level1 has \(count) dimensions, expected 7")
        }
    }
    
    /// Test that Level1 contains all expected dimensions
    /// **Validates: Requirements 3.1**
    static func testLevel1ContainsExpectedDimensions() -> (passed: Bool, message: String) {
        let expectedDimensions: Set<String> = [
            "self", "material", "achievements", "experiences", "spirit",
            "relationships", "ai_preferences"
        ]
        
        let actualDimensions = Set(DimensionHierarchy.Level1.allCases.map { $0.rawValue })
        
        if actualDimensions == expectedDimensions {
            return (true, "Level1 contains all expected dimensions")
        } else {
            let missing = expectedDimensions.subtracting(actualDimensions)
            let extra = actualDimensions.subtracting(expectedDimensions)
            return (false, "Missing: \(missing), Extra: \(extra)")
        }
    }
    
    // MARK: - Reserved Dimension Tests
    
    /// Test that relationships and aiPreferences are marked as reserved
    /// **Validates: Requirements 3.2, 3.3**
    static func testReservedDimensionsMarkedCorrectly() -> (passed: Bool, message: String) {
        let relationships = DimensionHierarchy.Level1.relationships
        let aiPreferences = DimensionHierarchy.Level1.aiPreferences
        
        guard relationships.isReserved else {
            return (false, "relationships should be marked as reserved")
        }
        
        guard aiPreferences.isReserved else {
            return (false, "aiPreferences should be marked as reserved")
        }
        
        return (true, "Reserved dimensions are correctly marked")
    }
    
    /// Test that core dimensions are NOT marked as reserved
    /// **Validates: Requirements 3.4**
    static func testCoreDimensionsNotReserved() -> (passed: Bool, message: String) {
        let coreDimensions: [DimensionHierarchy.Level1] = [
            .self_, .material, .achievements, .experiences, .spirit
        ]
        
        for dimension in coreDimensions {
            if dimension.isReserved {
                return (false, "\(dimension.rawValue) should NOT be marked as reserved")
            }
        }
        
        return (true, "All 5 core dimensions are not reserved")
    }
    
    /// Test that coreDimensions helper returns exactly 5 dimensions
    /// **Validates: Requirements 3.4**
    static func testCoreDimensionsCount() -> (passed: Bool, message: String) {
        let count = DimensionHierarchy.coreDimensions.count
        if count == 5 {
            return (true, "coreDimensions returns exactly 5 dimensions")
        } else {
            return (false, "coreDimensions returns \(count) dimensions, expected 5")
        }
    }
    
    /// Test that reservedDimensions helper returns exactly 2 dimensions
    /// **Validates: Requirements 3.2, 3.3**
    static func testReservedDimensionsCount() -> (passed: Bool, message: String) {
        let count = DimensionHierarchy.reservedDimensions.count
        if count == 2 {
            return (true, "reservedDimensions returns exactly 2 dimensions")
        } else {
            return (false, "reservedDimensions returns \(count) dimensions, expected 2")
        }
    }
    
    // MARK: - Level 2 Dimension Tests
    
    /// Test that each core Level1 dimension has exactly 3 Level2 dimensions
    /// **Validates: Requirements 4.1, 5.1, 6.1, 7.1, 8.1**
    static func testEachCoreDimensionHasThreeLevel2() -> (passed: Bool, message: String) {
        let coreDimensions: [DimensionHierarchy.Level1] = [
            .self_, .material, .achievements, .experiences, .spirit
        ]
        
        for dimension in coreDimensions {
            let level2 = DimensionHierarchy.getLevel2Dimensions(for: dimension)
            if level2.count != 3 {
                return (false, "\(dimension.rawValue) has \(level2.count) Level2 dimensions, expected 3")
            }
        }
        
        return (true, "All 5 core dimensions have exactly 3 Level2 dimensions each")
    }
    
    /// Test that total Level2 count is 15 (5 core dimensions × 3 each)
    /// **Validates: Requirements 4.1, 5.1, 6.1, 7.1, 8.1**
    static func testTotalLevel2Count() -> (passed: Bool, message: String) {
        let count = DimensionHierarchy.totalLevel2Count
        if count == 15 {
            return (true, "Total Level2 count is 15")
        } else {
            return (false, "Total Level2 count is \(count), expected 15")
        }
    }
    
    /// Test Level2 dimensions for Self (本体)
    /// **Validates: Requirements 4.1**
    static func testSelfLevel2Dimensions() -> (passed: Bool, message: String) {
        let expected: Set<String> = ["identity", "physical", "personality"]
        let actual = Set(DimensionHierarchy.getLevel2Dimensions(for: .self_))
        
        if actual == expected {
            return (true, "Self dimension has correct Level2: identity, physical, personality")
        } else {
            return (false, "Self Level2 mismatch. Expected: \(expected), Got: \(actual)")
        }
    }
    
    /// Test Level2 dimensions for Material (物质)
    /// **Validates: Requirements 5.1**
    static func testMaterialLevel2Dimensions() -> (passed: Bool, message: String) {
        let expected: Set<String> = ["economy", "objects_space", "security"]
        let actual = Set(DimensionHierarchy.getLevel2Dimensions(for: .material))
        
        if actual == expected {
            return (true, "Material dimension has correct Level2: economy, objects_space, security")
        } else {
            return (false, "Material Level2 mismatch. Expected: \(expected), Got: \(actual)")
        }
    }
    
    /// Test Level2 dimensions for Achievements (成就)
    /// **Validates: Requirements 6.1**
    static func testAchievementsLevel2Dimensions() -> (passed: Bool, message: String) {
        let expected: Set<String> = ["career", "competencies", "outcomes"]
        let actual = Set(DimensionHierarchy.getLevel2Dimensions(for: .achievements))
        
        if actual == expected {
            return (true, "Achievements dimension has correct Level2: career, competencies, outcomes")
        } else {
            return (false, "Achievements Level2 mismatch. Expected: \(expected), Got: \(actual)")
        }
    }
    
    /// Test Level2 dimensions for Experiences (阅历)
    /// **Validates: Requirements 7.1**
    static func testExperiencesLevel2Dimensions() -> (passed: Bool, message: String) {
        let expected: Set<String> = ["culture_entertainment", "exploration", "history"]
        let actual = Set(DimensionHierarchy.getLevel2Dimensions(for: .experiences))
        
        if actual == expected {
            return (true, "Experiences dimension has correct Level2: culture_entertainment, exploration, history")
        } else {
            return (false, "Experiences Level2 mismatch. Expected: \(expected), Got: \(actual)")
        }
    }
    
    /// Test Level2 dimensions for Spirit (精神)
    /// **Validates: Requirements 8.1**
    static func testSpiritLevel2Dimensions() -> (passed: Bool, message: String) {
        let expected: Set<String> = ["ideology", "mental_state", "wisdom"]
        let actual = Set(DimensionHierarchy.getLevel2Dimensions(for: .spirit))
        
        if actual == expected {
            return (true, "Spirit dimension has correct Level2: ideology, mental_state, wisdom")
        } else {
            return (false, "Spirit Level2 mismatch. Expected: \(expected), Got: \(actual)")
        }
    }
    
    /// Test that reserved dimensions have no Level2 defined
    /// **Validates: Requirements 9.1, 10.1**
    static func testReservedDimensionsHaveNoLevel2() -> (passed: Bool, message: String) {
        let relationshipsLevel2 = DimensionHierarchy.getLevel2Dimensions(for: .relationships)
        let aiPreferencesLevel2 = DimensionHierarchy.getLevel2Dimensions(for: .aiPreferences)
        
        if !relationshipsLevel2.isEmpty {
            return (false, "relationships should have no Level2 defined, but has: \(relationshipsLevel2)")
        }
        
        if !aiPreferencesLevel2.isEmpty {
            return (false, "aiPreferences should have no Level2 defined, but has: \(aiPreferencesLevel2)")
        }
        
        return (true, "Reserved dimensions have no Level2 defined")
    }
    
    // MARK: - Display Name Tests
    
    /// Test that all Level1 dimensions have Chinese display names
    /// **Validates: Requirements 3.1**
    static func testLevel1DisplayNames() -> (passed: Bool, message: String) {
        let expectedNames: [DimensionHierarchy.Level1: String] = [
            .self_: "本体",
            .material: "物质",
            .achievements: "成就",
            .experiences: "阅历",
            .spirit: "精神",
            .relationships: "关系",
            .aiPreferences: "AI偏好"
        ]
        
        for (dimension, expectedName) in expectedNames {
            if dimension.displayName != expectedName {
                return (false, "\(dimension.rawValue) displayName is '\(dimension.displayName)', expected '\(expectedName)'")
            }
        }
        
        return (true, "All Level1 dimensions have correct Chinese display names")
    }
    
    /// Test that all Level2 dimensions have Chinese display names
    /// **Validates: Requirements 4.1, 5.1, 6.1, 7.1, 8.1**
    static func testLevel2DisplayNames() -> (passed: Bool, message: String) {
        // Check a sample of Level2 display names
        let testCases: [(String, String)] = [
            ("identity", "身份认同"),
            ("physical", "身体状态"),
            ("personality", "性格特质"),
            ("economy", "经济状况"),
            ("career", "事业发展"),
            ("ideology", "意识形态")
        ]
        
        for (level2, expectedName) in testCases {
            let actualName = DimensionHierarchy.getLevel2DisplayName(level2)
            if actualName != expectedName {
                return (false, "\(level2) displayName is '\(actualName)', expected '\(expectedName)'")
            }
        }
        
        return (true, "Level2 dimensions have correct Chinese display names")
    }
    
    // MARK: - NodeContentType Tests
    
    /// Test that NodeContentType has exactly 4 cases
    /// **Validates: Requirements 4.2-4.5**
    static func testNodeContentTypeHasFourCases() -> (passed: Bool, message: String) {
        let count = NodeContentType.allCases.count
        if count == 4 {
            return (true, "NodeContentType has exactly 4 cases")
        } else {
            return (false, "NodeContentType has \(count) cases, expected 4")
        }
    }
    
    /// Test that NodeContentType contains all expected types
    /// **Validates: Requirements 4.2-4.5**
    static func testNodeContentTypeContainsExpectedTypes() -> (passed: Bool, message: String) {
        let expectedTypes: Set<String> = ["ai_tag", "subsystem", "entity_ref", "nested_list"]
        let actualTypes = Set(NodeContentType.allCases.map { $0.rawValue })
        
        if actualTypes == expectedTypes {
            return (true, "NodeContentType contains all expected types")
        } else {
            let missing = expectedTypes.subtracting(actualTypes)
            let extra = actualTypes.subtracting(expectedTypes)
            return (false, "Missing: \(missing), Extra: \(extra)")
        }
    }
    
    /// Test NodeContentType Codable support
    /// **Validates: Requirements 4.2-4.5**
    static func testNodeContentTypeCodable() -> (passed: Bool, message: String) {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for contentType in NodeContentType.allCases {
            do {
                let encoded = try encoder.encode(contentType)
                let decoded = try decoder.decode(NodeContentType.self, from: encoded)
                
                if decoded != contentType {
                    return (false, "Round-trip failed for \(contentType.rawValue): got \(decoded.rawValue)")
                }
            } catch {
                return (false, "Codable error for \(contentType.rawValue): \(error)")
            }
        }
        
        return (true, "NodeContentType Codable support works correctly")
    }
    
    /// Test NodeContentType display names
    /// **Validates: Requirements 4.2-4.5**
    static func testNodeContentTypeDisplayNames() -> (passed: Bool, message: String) {
        let expectedNames: [NodeContentType: String] = [
            .aiTag: "AI标签",
            .subsystem: "独立子系统",
            .entityRef: "实体引用",
            .nestedList: "嵌套列表"
        ]
        
        for (contentType, expectedName) in expectedNames {
            if contentType.displayName != expectedName {
                return (false, "\(contentType.rawValue) displayName is '\(contentType.displayName)', expected '\(expectedName)'")
            }
        }
        
        return (true, "NodeContentType display names are correct")
    }
    
    // MARK: - Level2 Validation Tests
    
    /// Test isValidLevel2 helper method
    /// **Validates: Requirements 4.1, 5.1, 6.1, 7.1, 8.1**
    static func testIsValidLevel2() -> (passed: Bool, message: String) {
        // Valid cases
        if !DimensionHierarchy.isValidLevel2("identity", for: .self_) {
            return (false, "identity should be valid for self")
        }
        if !DimensionHierarchy.isValidLevel2("economy", for: .material) {
            return (false, "economy should be valid for material")
        }
        
        // Invalid cases
        if DimensionHierarchy.isValidLevel2("identity", for: .material) {
            return (false, "identity should NOT be valid for material")
        }
        if DimensionHierarchy.isValidLevel2("nonexistent", for: .self_) {
            return (false, "nonexistent should NOT be valid for self")
        }
        
        return (true, "isValidLevel2 works correctly")
    }
    
    // MARK: - Run All Tests
    
    static func runAllTests() {
        print("Running Dimension Hierarchy Unit Tests...")
        print("=" * 60)
        
        let tests: [(String, () -> (passed: Bool, message: String))] = [
            // Level 1 tests
            ("Level1 has 7 dimensions", testLevel1HasSevenDimensions),
            ("Level1 contains expected dimensions", testLevel1ContainsExpectedDimensions),
            
            // Reserved dimension tests
            ("Reserved dimensions marked correctly", testReservedDimensionsMarkedCorrectly),
            ("Core dimensions not reserved", testCoreDimensionsNotReserved),
            ("coreDimensions count is 5", testCoreDimensionsCount),
            ("reservedDimensions count is 2", testReservedDimensionsCount),
            
            // Level 2 tests
            ("Each core dimension has 3 Level2", testEachCoreDimensionHasThreeLevel2),
            ("Total Level2 count is 15", testTotalLevel2Count),
            ("Self Level2 dimensions", testSelfLevel2Dimensions),
            ("Material Level2 dimensions", testMaterialLevel2Dimensions),
            ("Achievements Level2 dimensions", testAchievementsLevel2Dimensions),
            ("Experiences Level2 dimensions", testExperiencesLevel2Dimensions),
            ("Spirit Level2 dimensions", testSpiritLevel2Dimensions),
            ("Reserved dimensions have no Level2", testReservedDimensionsHaveNoLevel2),
            
            // Display name tests
            ("Level1 display names", testLevel1DisplayNames),
            ("Level2 display names", testLevel2DisplayNames),
            
            // NodeContentType tests
            ("NodeContentType has 4 cases", testNodeContentTypeHasFourCases),
            ("NodeContentType contains expected types", testNodeContentTypeContainsExpectedTypes),
            ("NodeContentType Codable support", testNodeContentTypeCodable),
            ("NodeContentType display names", testNodeContentTypeDisplayNames),
            
            // Validation tests
            ("isValidLevel2 helper", testIsValidLevel2)
        ]
        
        var passedCount = 0
        var failedCount = 0
        
        for (name, test) in tests {
            let result = test()
            if result.passed {
                print("✅ \(name): PASSED")
                passedCount += 1
            } else {
                print("❌ \(name): FAILED - \(result.message)")
                failedCount += 1
            }
        }
        
        print("=" * 60)
        print("Results: \(passedCount) passed, \(failedCount) failed")
        print("=" * 60)
    }
}

// Helper extension for string repetition
private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
