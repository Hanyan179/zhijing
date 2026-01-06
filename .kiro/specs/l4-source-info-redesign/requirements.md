# Requirements Document

## Introduction

本文档定义人生回顾功能中"来源信息"区块的重新设计需求。核心问题：
1. **置信度概念不合理**：当前的"AI推测置信度"对用户没有实际意义，应改为"关联原始次数"
2. **来源类型定义错误**：当前是 AI 相关分类（用户输入/AI提取/AI推断），应改为数据来源表类型（日记/AI聊天），并显示具体条数
3. **验证状态冗余**：既然用户可以编辑所有内容，验证状态就失去了意义
4. **编辑交互问题**：在详情页点击编辑按钮没有反应，需要关闭详情页后编辑才出来

## Glossary

- **KnowledgeNode**: 知识节点，存储用户画像维度数据的通用结构
- **SourceLink**: 溯源链接，连接 L4 知识节点与 L1 原始数据
- **NodeSourceSection**: 来源信息展示组件，显示节点的来源和统计信息
- **SourceType**: 来源类型，标识数据来自哪个内部数据表（日记/AI聊天等）
- **MentionCount**: 关联原始次数，统计该知识点关联的原始数据条数

## Requirements

### Requirement 1: 置信度改为关联原始次数

**User Story:** As a 用户, I want 看到知识点关联了多少条原始数据, so that 我能直观了解这个知识点的数据支撑。

#### Acceptance Criteria

1. THE NodeSourceSection SHALL display "关联原始次数" instead of "置信度"
2. THE MentionCount SHALL be calculated from the count of sourceLinks
3. THE System SHALL display the count as a simple number (e.g., "关联 5 条原始数据")
4. THE System SHALL remove the confidence progress bar UI
5. THE System SHALL remove confidence-related color coding (green/yellow/red)

### Requirement 2: 来源类型显示为数据表条数

**User Story:** As a 用户, I want 看到知识点来自几条日记、几条AI对话, so that 我能了解数据来源分布。

#### Acceptance Criteria

1. THE SourceType SHALL display as data table types with counts: "日记 X 条"、"AI对话 X 条"
2. WHEN only one source link exists, THE System SHALL display single line format (e.g., "来源：日记 1 条")
3. WHEN multiple source links exist, THE System SHALL display grouped format with proper UI layout
4. THE System SHALL use appropriate icons for each source type (日记、AI对话、追踪器、心情记录)
5. THE UI design SHALL be clean and not cluttered when displaying multiple source types

### Requirement 3: 移除验证状态

**User Story:** As a 用户, I want 不再看到验证状态, so that 界面更简洁且不会产生困惑。

#### Acceptance Criteria

1. THE NodeSourceSection SHALL NOT display verification status (已确认/待审核/未确认)
2. THE System SHALL remove the "确认" action button from node detail sheet
3. THE System SHALL remove needsReview flag from UI display
4. THE NodeVerification struct MAY be kept in data model for backward compatibility but SHALL NOT be displayed

### Requirement 4: 修复详情页编辑交互

**User Story:** As a 用户, I want 在详情页点击编辑按钮能直接打开编辑页面, so that 操作流程符合用户习惯。

#### Acceptance Criteria

1. WHEN user taps edit button in detail sheet, THE System SHALL open edit sheet immediately
2. THE Edit sheet SHALL appear as a new sheet on top of detail sheet (sheet over sheet)
3. THE System SHALL NOT require closing detail sheet before editing
4. WHEN edit is saved, THE System SHALL update the detail sheet content automatically
5. WHEN edit is cancelled, THE System SHALL return to detail sheet without changes

### Requirement 5: 数据模型向后兼容

**User Story:** As a 开发者, I want 保持数据模型向后兼容, so that 现有数据不会丢失。

#### Acceptance Criteria

1. THE NodeSource struct SHALL keep existing fields for backward compatibility
2. THE System SHALL NOT break existing data serialization/deserialization
3. THE System SHALL gracefully handle old data format during migration
4. THE SourceLink.sourceType SHALL continue to use existing values (diary, conversation, tracker, mindState)

