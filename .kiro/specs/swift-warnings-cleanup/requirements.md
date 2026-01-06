# Requirements Document

## Introduction

本文档定义了系统性清理 Xcode 编译警告的需求，包括 Swift 6 并发安全警告、弃用 API 警告、UI 线程阻塞警告以及代码质量警告。目标是消除所有紫色和黄色警告，提升代码质量和未来兼容性。

## Glossary

- **Main_Actor**: Swift 并发模型中用于标记必须在主线程执行的代码的属性
- **Nonisolated_Context**: 不属于任何 actor 隔离的代码上下文
- **Deprecated_API**: 已被标记为弃用的 API，建议使用新的替代方案
- **Unreachable_Code**: 永远不会被执行的代码块

## Requirements

### Requirement 1: 修复 LocationService UI 阻塞警告

**User Story:** As a developer, I want to fix the LocationService authorization check, so that the app doesn't cause UI unresponsiveness on the main thread.

#### Acceptance Criteria

1. WHEN LocationService checks authorization status, THE LocationService SHALL use the instance property `manager.authorizationStatus` instead of the class method
2. WHEN authorization status changes, THE LocationService SHALL rely on the `locationManagerDidChangeAuthorization` callback to update status

### Requirement 2: 修复 KnowledgeNodeModels 弃用警告

**User Story:** As a developer, I want to migrate from deprecated `extractedFrom` field, so that the codebase uses the recommended `sourceLinks` API.

#### Acceptance Criteria

1. WHEN accessing source information, THE KnowledgeNode SHALL use `sourceLinks` instead of `extractedFrom`
2. WHEN migrating existing code, THE System SHALL maintain backward compatibility during the transition period
3. WHEN all usages are migrated, THE System SHALL remove references to the deprecated `extractedFrom` field

### Requirement 3: 修复 InsightViewModel Swift 6 并发警告

**User Story:** As a developer, I want to fix actor isolation issues in InsightViewModel, so that the code is compatible with Swift 6 language mode.

#### Acceptance Criteria

1. WHEN calling MainActor-isolated methods from nonisolated context, THE InsightViewModel SHALL properly await or use MainActor.run
2. WHEN computing stats in background tasks, THE InsightViewModel SHALL ensure proper actor isolation for all method calls
3. WHEN initializers are MainActor-isolated, THE InsightViewModel SHALL call them from appropriate actor context
4. WHEN do blocks don't throw errors, THE InsightViewModel SHALL remove unnecessary catch blocks

### Requirement 4: 修复 AIService/AIConversationRepository 编码警告

**User Story:** As a developer, I want to fix Encodable/Decodable conformance issues, so that JSON encoding works correctly in nonisolated contexts.

#### Acceptance Criteria

1. WHEN encoding AIConversation in background thread, THE AIConversationRepository SHALL ensure Encodable conformance is not MainActor-isolated
2. WHEN decoding API responses, THE AIService SHALL ensure Decodable conformance is not MainActor-isolated

### Requirement 5: 修复 MessageBubble 静态方法警告

**User Story:** As a developer, I want to fix the MarkdownParser.parse actor isolation issue, so that parsing can be called from any context.

#### Acceptance Criteria

1. WHEN parsing markdown content, THE MessageBubble SHALL call MarkdownParser.parse from appropriate actor context
2. IF MarkdownParser.parse is MainActor-isolated, THEN THE System SHALL either make it nonisolated or call it with proper await

### Requirement 6: 修复 TimelineViewModel 未使用变量警告

**User Story:** As a developer, I want to remove unused variables, so that the code is clean and warning-free.

#### Acceptance Criteria

1. WHEN a variable is declared but never used, THE TimelineViewModel SHALL replace it with `_` or remove it entirely
2. THE TimelineViewModel SHALL remove the unused `ts` variable at line 153
3. THE TimelineViewModel SHALL remove the unused `j` variable at line 216

### Requirement 7: 修复 InsightViewModel 不可达 catch 块

**User Story:** As a developer, I want to remove unreachable catch blocks, so that the code accurately reflects error handling behavior.

#### Acceptance Criteria

1. WHEN a do block contains no throwing expressions, THE InsightViewModel SHALL remove the unnecessary try-catch structure
2. THE InsightViewModel SHALL preserve error handling only where actual errors can be thrown
