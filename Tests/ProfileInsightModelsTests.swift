//
//  ProfileInsightModelsTests.swift
//  guanji0.34
//
//  Created by Kiro on 2024-12-17.
//

import XCTest
@testable import guanji0_34

final class ProfileInsightModelsTests: XCTestCase {
    
    // MARK: - ProfileInsight Codable Tests
    
    func testProfileInsightCodableWithNarrative() throws {
        // Given
        let insight = ProfileInsight(
            userId: "user123",
            dimension: .personality,
            insightType: .narrative,
            content: .narrative("A curious and reflective person"),
            sourceType: .diaryExtraction,
            sourceId: "diary456",
            confidence: 0.85
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(insight)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProfileInsight.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.id, insight.id)
        XCTAssertEqual(decoded.userId, insight.userId)
        XCTAssertEqual(decoded.dimension, insight.dimension)
        XCTAssertEqual(decoded.insightType, insight.insightType)
        XCTAssertEqual(decoded.sourceType, insight.sourceType)
        XCTAssertEqual(decoded.sourceId, insight.sourceId)
        XCTAssertEqual(decoded.confidence, insight.confidence)
        
        if case .narrative(let text) = decoded.content {
            XCTAssertEqual(text, "A curious and reflective person")
        } else {
            XCTFail("Expected narrative content")
        }
    }
    
    func testProfileInsightCodableWithTags() throws {
        // Given
        let insight = ProfileInsight(
            userId: "user123",
            dimension: .lifestyle,
            insightType: .tags,
            content: .tags(["coffee", "reading", "running"]),
            sourceType: .dailyTracker
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(insight)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProfileInsight.self, from: data)
        
        // Then
        if case .tags(let tags) = decoded.content {
            XCTAssertEqual(tags, ["coffee", "reading", "running"])
        } else {
            XCTFail("Expected tags content")
        }
    }
    
    func testProfileInsightCodableWithCategoricalEnum() throws {
        // Given
        let insight = ProfileInsight(
            userId: "user123",
            dimension: .identity,
            insightType: .categoricalEnum,
            content: .categoricalEnum(category: "gender", value: "male"),
            sourceType: .manualInput
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(insight)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProfileInsight.self, from: data)
        
        // Then
        if case .categoricalEnum(let category, let value) = decoded.content {
            XCTAssertEqual(category, "gender")
            XCTAssertEqual(value, "male")
        } else {
            XCTFail("Expected categoricalEnum content")
        }
    }
    
    func testProfileInsightCodableWithFactualDate() throws {
        // Given
        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01
        let insight = ProfileInsight(
            userId: "user123",
            dimension: .relationshipFacts,
            insightType: .factualDate,
            content: .factualDate(date),
            sourceType: .manualInput
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(insight)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProfileInsight.self, from: data)
        
        // Then
        if case .factualDate(let decodedDate) = decoded.content {
            XCTAssertEqual(decodedDate.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("Expected factualDate content")
        }
    }
    
    func testProfileInsightCodableWithMention() throws {
        // Given
        let insight = ProfileInsight(
            userId: "user123",
            dimension: .relationshipHistory,
            insightType: .mention,
            content: .mention(context: "diary_entry", snippet: "Had coffee with Alice today"),
            sourceType: .diaryExtraction,
            sourceId: "diary789"
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(insight)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProfileInsight.self, from: data)
        
        // Then
        if case .mention(let context, let snippet) = decoded.content {
            XCTAssertEqual(context, "diary_entry")
            XCTAssertEqual(snippet, "Had coffee with Alice today")
        } else {
            XCTFail("Expected mention content")
        }
    }
    
    // MARK: - InsightContent displayText Tests
    
    func testInsightContentDisplayTextNarrative() {
        // Given
        let content = InsightContent.narrative("A thoughtful person")
        
        // When
        let displayText = content.displayText
        
        // Then
        XCTAssertEqual(displayText, "A thoughtful person")
    }
    
    func testInsightContentDisplayTextTags() {
        // Given
        let content = InsightContent.tags(["curious", "disciplined", "empathetic"])
        
        // When
        let displayText = content.displayText
        
        // Then
        XCTAssertEqual(displayText, "curious, disciplined, empathetic")
    }
    
    func testInsightContentDisplayTextCategoricalEnum() {
        // Given
        let content = InsightContent.categoricalEnum(category: "occupation", value: "Software Engineer")
        
        // When
        let displayText = content.displayText
        
        // Then
        XCTAssertEqual(displayText, "Software Engineer")
    }
    
    func testInsightContentDisplayTextFactualDate() {
        // Given
        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01
        let content = InsightContent.factualDate(date)
        
        // When
        let displayText = content.displayText
        
        // Then
        XCTAssertFalse(displayText.isEmpty)
        // Note: Exact format depends on locale, so we just check it's not empty
    }
    
    func testInsightContentDisplayTextFactualText() {
        // Given
        let content = InsightContent.factualText("Beijing")
        
        // When
        let displayText = content.displayText
        
        // Then
        XCTAssertEqual(displayText, "Beijing")
    }
    
    func testInsightContentDisplayTextMention() {
        // Given
        let content = InsightContent.mention(context: "diary", snippet: "Met with Bob for lunch")
        
        // When
        let displayText = content.displayText
        
        // Then
        XCTAssertEqual(displayText, "Met with Bob for lunch")
    }
    
    // MARK: - ProfileDimension Tests
    
    func testProfileDimensionLocalizedKeys() {
        // Test all predefined dimensions have localized keys
        XCTAssertEqual(ProfileDimension.identity.localizedKey, "Dimension.Identity")
        XCTAssertEqual(ProfileDimension.personality.localizedKey, "Dimension.Personality")
        XCTAssertEqual(ProfileDimension.social.localizedKey, "Dimension.Social")
        XCTAssertEqual(ProfileDimension.competence.localizedKey, "Dimension.Competence")
        XCTAssertEqual(ProfileDimension.lifestyle.localizedKey, "Dimension.Lifestyle")
        XCTAssertEqual(ProfileDimension.relationshipBasic.localizedKey, "Dimension.RelationshipBasic")
        XCTAssertEqual(ProfileDimension.relationshipNature.localizedKey, "Dimension.RelationshipNature")
        XCTAssertEqual(ProfileDimension.relationshipHistory.localizedKey, "Dimension.RelationshipHistory")
        XCTAssertEqual(ProfileDimension.relationshipFacts.localizedKey, "Dimension.RelationshipFacts")
    }
    
    func testProfileDimensionIcons() {
        // Test all predefined dimensions have icons
        XCTAssertEqual(ProfileDimension.identity.icon, "person.fill")
        XCTAssertEqual(ProfileDimension.personality.icon, "brain.head.profile")
        XCTAssertEqual(ProfileDimension.social.icon, "person.2.fill")
        XCTAssertEqual(ProfileDimension.competence.icon, "briefcase.fill")
        XCTAssertEqual(ProfileDimension.lifestyle.icon, "house.fill")
        XCTAssertEqual(ProfileDimension.relationshipBasic.icon, "person.crop.circle")
        XCTAssertEqual(ProfileDimension.relationshipNature.icon, "heart.fill")
        XCTAssertEqual(ProfileDimension.relationshipHistory.icon, "clock.fill")
        XCTAssertEqual(ProfileDimension.relationshipFacts.icon, "pin.fill")
    }
    
    func testProfileDimensionCustom() {
        // Given
        let customDimension = ProfileDimension.custom("hobbies")
        
        // Then
        XCTAssertEqual(customDimension.localizedKey, "Dimension.Custom.hobbies")
        XCTAssertEqual(customDimension.icon, "star.fill")
    }
    
    func testProfileDimensionCodable() throws {
        // Test standard dimension
        let dimension1 = ProfileDimension.personality
        let encoder = JSONEncoder()
        let data1 = try encoder.encode(dimension1)
        let decoder = JSONDecoder()
        let decoded1 = try decoder.decode(ProfileDimension.self, from: data1)
        XCTAssertEqual(decoded1, dimension1)
        
        // Test custom dimension
        let dimension2 = ProfileDimension.custom("interests")
        let data2 = try encoder.encode(dimension2)
        let decoded2 = try decoder.decode(ProfileDimension.self, from: data2)
        XCTAssertEqual(decoded2, dimension2)
    }
    
    // MARK: - SourceType Tests
    
    func testSourceTypeLocalizedKeys() {
        XCTAssertEqual(SourceType.manualInput.localizedKey, "SourceType.ManualInput")
        XCTAssertEqual(SourceType.diaryExtraction.localizedKey, "SourceType.DiaryExtraction")
        XCTAssertEqual(SourceType.aiConversation.localizedKey, "SourceType.AIConversation")
        XCTAssertEqual(SourceType.dailyTracker.localizedKey, "SourceType.DailyTracker")
        XCTAssertEqual(SourceType.migration.localizedKey, "SourceType.Migration")
        XCTAssertEqual(SourceType.aiGenerated.localizedKey, "SourceType.AIGenerated")
    }
    
    // MARK: - DimensionAggregation Tests
    
    func testDimensionAggregationInitialization() {
        // Given
        let insight1 = ProfileInsight(
            userId: "user123",
            dimension: .personality,
            insightType: .narrative,
            content: .narrative("Test narrative"),
            sourceType: .diaryExtraction
        )
        
        let tagGroup = TagGroup(tag: "curious", occurrences: 5)
        
        // When
        let aggregation = DimensionAggregation(
            dimension: .personality,
            narratives: [insight1],
            tagGroups: [tagGroup],
            totalInsights: 6,
            sourceCount: 3
        )
        
        // Then
        XCTAssertEqual(aggregation.dimension, .personality)
        XCTAssertEqual(aggregation.narratives.count, 1)
        XCTAssertEqual(aggregation.tagGroups.count, 1)
        XCTAssertEqual(aggregation.tagGroups.first?.tag, "curious")
        XCTAssertEqual(aggregation.tagGroups.first?.occurrences, 5)
        XCTAssertEqual(aggregation.totalInsights, 6)
        XCTAssertEqual(aggregation.sourceCount, 3)
    }
    
    func testDimensionAggregationCodable() throws {
        // Given
        let aggregation = DimensionAggregation(
            dimension: .lifestyle,
            tagGroups: [
                TagGroup(tag: "coffee", occurrences: 10, trend: .increasing),
                TagGroup(tag: "reading", occurrences: 8, trend: .stable)
            ],
            totalInsights: 18,
            sourceCount: 12
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(aggregation)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DimensionAggregation.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.dimension, aggregation.dimension)
        XCTAssertEqual(decoded.tagGroups.count, 2)
        XCTAssertEqual(decoded.totalInsights, 18)
        XCTAssertEqual(decoded.sourceCount, 12)
    }
    
    // MARK: - TagGroup Tests
    
    func testTagGroupWithTrend() {
        // Given
        let tagGroup = TagGroup(
            tag: "exercise",
            occurrences: 15,
            trend: .increasing
        )
        
        // Then
        XCTAssertEqual(tagGroup.tag, "exercise")
        XCTAssertEqual(tagGroup.occurrences, 15)
        XCTAssertEqual(tagGroup.trend, .increasing)
    }
    
    // MARK: - CategoricalValue Tests
    
    func testCategoricalValue() {
        // Given
        let insight = ProfileInsight(
            userId: "user123",
            dimension: .identity,
            insightType: .categoricalEnum,
            content: .categoricalEnum(category: "occupation", value: "Engineer"),
            sourceType: .manualInput
        )
        
        let categoricalValue = CategoricalValue(
            category: "occupation",
            value: "Engineer",
            insights: [insight]
        )
        
        // Then
        XCTAssertEqual(categoricalValue.category, "occupation")
        XCTAssertEqual(categoricalValue.value, "Engineer")
        XCTAssertEqual(categoricalValue.insights.count, 1)
    }
    
    // MARK: - TrendDirection Tests
    
    func testTrendDirectionRawValues() {
        XCTAssertEqual(TrendDirection.increasing.rawValue, "increasing")
        XCTAssertEqual(TrendDirection.stable.rawValue, "stable")
        XCTAssertEqual(TrendDirection.decreasing.rawValue, "decreasing")
    }
}
