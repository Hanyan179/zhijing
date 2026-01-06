# Requirements Document

## Introduction

本文档定义 L4 核心知识层代码重构的需求。基于已完成的架构设计文档（L4-PROFILE-EXPANSION-PLAN.md）和差异分析文档（GAP-ANALYSIS.md），进行实际代码修改。

**重构目标**：
1. 完成 Phase 1 剩余工作：NodeTypePath 路径解析工具、nodeTypeMigrationMap 迁移映射
2. 执行 Phase 2：重构 KnowledgeNode 结构
3. 执行 Phase 3：重构 SourceLink 结构
4. 执行 Phase 4：更新 nodeType 命名规范
5. 执行 Phase 5：清理废弃代码

**参考文档**：
- #[[file:Docs/architecture/L4-PROFILE-EXPANSION-PLAN.md]]
- #[[file:Docs/architecture/GAP-ANALYSIS.md]]

## Glossary

- **KnowledgeNode**: 知识节点，L4 层核心数据结构
- **NodeTypePath**: nodeType 路径解析工具，解析 "level1.level2.level3" 格式
- **nodeTypeMigrationMap**: 旧 nodeType 到新层级路径的映射表
- **SourceLink**: 溯源链接，连接 L4 知识节点与 L1 原始数据
- **NodeContentType**: 节点内容类型枚举（ai_tag, subsystem, entity_ref, nested_list）
- **DimensionHierarchy**: 维度层级定义结构

## Requirements

### Requirement 1: NodeTypePath 路径解析工具

**User Story:** As a 开发者, I want 解析和验证 nodeType 路径, so that 能正确处理层级维度格式。

#### Acceptance Criteria

1. THE NodeTypePath SHALL parse nodeType strings in format "level1.level2.level3"
2. THE NodeTypePath SHALL extract level1, level2, level3 components from the path
3. THE NodeTypePath SHALL provide a fullPath property that reconstructs the original string
4. THE NodeTypePath SHALL validate if the path is valid against DimensionHierarchy
5. THE NodeTypePath SHALL return nil for empty or invalid input strings
6. FOR ALL valid nodeType paths, parsing then reconstructing fullPath SHALL produce the original string

### Requirement 2: nodeType 迁移映射表

**User Story:** As a 开发者, I want 将旧的扁平 nodeType 映射到新的层级路径, so that 能平滑迁移现有数据。

#### Acceptance Criteria

1. THE nodeTypeMigrationMap SHALL map all 10 userProfileNodeTypes to new hierarchical paths
2. THE nodeTypeMigrationMap SHALL map all 6 relationshipNodeTypes to new hierarchical paths
3. THE System SHALL provide a migrateNodeType function that converts old format to new format
4. WHEN an unknown nodeType is provided, THE migrateNodeType function SHALL return the original value

### Requirement 3: KnowledgeNode 结构重构

**User Story:** As a 开发者, I want 扩展 KnowledgeNode 结构, so that 支持三层维度架构的新功能。

#### Acceptance Criteria

1. THE KnowledgeNode SHALL include a contentType field of type NodeContentType with default value .aiTag
2. THE KnowledgeNode SHALL include a sourceLinks field of type [SourceLink] with default value []
3. THE KnowledgeNode SHALL include a relatedEntityIds field of type [String] with default value []
4. THE KnowledgeNode SHALL include an optional childNodeIds field of type [String]?
5. THE KnowledgeNode SHALL include an optional parentNodeId field of type String?
6. THE KnowledgeNode init method SHALL accept all new fields with appropriate default values
7. THE KnowledgeNode Codable implementation SHALL maintain backward compatibility with existing data
8. FOR ALL KnowledgeNode instances, serializing then deserializing SHALL produce an equivalent object

### Requirement 4: SourceLink 结构重构

**User Story:** As a 开发者, I want 扩展 SourceLink 结构, so that 支持实体关联。

#### Acceptance Criteria

1. THE SourceLink SHALL include a relatedEntityIds field of type [String] with default value []
2. THE SourceLink init method SHALL accept relatedEntityIds parameter with default value []
3. THE SourceLink Codable implementation SHALL maintain backward compatibility with existing data

### Requirement 5: KnowledgeNode 扩展方法

**User Story:** As a 开发者, I want KnowledgeNode 提供便捷的维度访问方法, so that 能方便地按层级查询节点。

#### Acceptance Criteria

1. THE KnowledgeNode SHALL provide a typePath computed property that returns NodeTypePath?
2. THE KnowledgeNode SHALL provide a level1Dimension computed property that returns DimensionHierarchy.Level1?
3. THE KnowledgeNode SHALL provide a hasValidDimensionPath computed property that returns Bool
4. THE KnowledgeNode SHALL provide a matchesLevel1 method that checks if nodeType starts with given Level1
5. THE KnowledgeNode SHALL provide a matchesLevel2 method that checks if nodeType matches Level1 and Level2

### Requirement 6: 工厂方法更新

**User Story:** As a 开发者, I want 更新 KnowledgeNode 工厂方法, so that 支持新字段。

#### Acceptance Criteria

1. THE createUserInput factory method SHALL accept contentType parameter with default .aiTag
2. THE createAIExtracted factory method SHALL set sourceLinks at node level instead of tracking.source.extractedFrom
3. THE createPersonal factory method SHALL accept contentType parameter with default .aiTag
4. THE factory methods SHALL support relatedEntityIds, childNodeIds, parentNodeId parameters

### Requirement 7: nodeType 常量更新

**User Story:** As a 开发者, I want 更新 nodeType 常量为层级路径格式, so that 新代码使用新格式。

#### Acceptance Criteria

1. THE userProfileNodeTypes SHALL be updated to hierarchical path format
2. THE relationshipNodeTypes SHALL be updated to hierarchical path format
3. THE convenience accessors (skills, values, goals, etc.) SHALL use prefix matching for new format

### Requirement 8: NodeSource 结构简化

**User Story:** As a 开发者, I want 简化 NodeSource 结构, so that 移除已迁移到节点级别的字段。

#### Acceptance Criteria

1. THE NodeSource.extractedFrom field SHALL be deprecated (marked with @available)
2. THE NodeSource Codable implementation SHALL maintain backward compatibility during transition
3. WHEN decoding old data with extractedFrom, THE System SHALL migrate data to node-level sourceLinks

### Requirement 9: 向后兼容性

**User Story:** As a 开发者, I want 确保重构后的代码向后兼容, so that 现有数据能正常读取。

#### Acceptance Criteria

1. WHEN decoding KnowledgeNode without new fields, THE System SHALL use default values
2. WHEN decoding SourceLink without relatedEntityIds, THE System SHALL use empty array
3. WHEN reading old nodeType format, THE System SHALL automatically migrate to new format
4. THE System SHALL preserve all existing data during migration

### Requirement 10: UI 展示 - 节点详情页

**User Story:** As a 用户, I want 在节点详情页查看 sourceLinks 和关联实体, so that 能追溯知识节点的来源。

#### Acceptance Criteria

1. THE 节点详情页 SHALL display sourceLinks list with dayId, snippet, and relevanceScore
2. THE 节点详情页 SHALL support clicking sourceLink to navigate to original source (diary/conversation)
3. THE 节点详情页 SHALL display relatedEntityIds as a list of related entities
4. THE 节点详情页 SHALL support clicking related entity to navigate to entity detail page

### Requirement 11: UI 展示 - 嵌套节点结构

**User Story:** As a 用户, I want 查看和操作嵌套节点结构, so that 能浏览层级化的知识节点。

#### Acceptance Criteria

1. FOR nodes with contentType = nested_list, THE UI SHALL display childNodeIds as expandable child nodes
2. THE UI SHALL support collapse/expand nested nodes
3. THE child nodes SHALL display parentNodeId association
4. THE UI SHALL display appropriate icons based on contentType (ai_tag, subsystem, entity_ref, nested_list)

### Requirement 12: UI 展示 - 置信度可视化

**User Story:** As a 用户, I want 直观地看到知识节点的置信度, so that 能判断信息的可靠性。

#### Acceptance Criteria

1. FOR confidence 0.9~1.0, THE UI SHALL display normally without special indicators
2. FOR confidence 0.7~0.9, THE UI SHALL display "AI 推测" label
3. FOR confidence 0.5~0.7, THE UI SHALL display "待确认" label with yellow highlight
4. FOR confidence < 0.5, THE UI SHALL display "低置信度" label with gray color

### Requirement 13: UI 展示 - 关系画像属性

**User Story:** As a 用户, I want 在关系详情页查看关系属性, so that 能了解与他人关系的详细信息。

#### Acceptance Criteria

1. THE 关系详情页 SHALL display attributes (KnowledgeNode array) from NarrativeRelationship
2. THE UI SHALL group attributes by dimension (Level 1 or Level 2)
3. THE UI SHALL support expanding attribute details to view sourceLinks and relatedEntityIds

