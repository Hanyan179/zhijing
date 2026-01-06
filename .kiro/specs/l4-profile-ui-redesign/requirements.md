# Profile UI Redesign Requirements

## Overview
重新设计 L4 用户画像界面，解决当前 UI 的核心问题：视觉效果不佳、导航层级过深、缺乏人生审视的沉浸感。

## Reference Documents
- #[[file:Docs/architecture/L4-PROFILE-EXPANSION-PLAN.md]]
- #[[file:Docs/architecture/GAP-ANALYSIS.md]]

## Current Problems
1. **UI不好看** - 当前卡片式设计缺乏视觉吸引力
2. **级别跳的太多了** - L1 → L2 → L3 → Node Detail 四层导航过于繁琐
3. **没有用户查看自己人生的审视感与沉浸流畅感** - 缺乏人生回顾的沉浸式体验
4. **空维度显示** - 没有数据的维度也显示，造成界面杂乱
5. **缺少测试数据** - 无法快速验证 UI 效果

---

## Requirements

### REQ-1: Flattened Navigation Structure
**ID**: REQ-UI-001  
**Priority**: P0  
**Type**: Functional

**EARS Pattern**: 
WHEN the user opens the profile screen, THE SYSTEM SHALL display all populated dimensions in a single scrollable view, reducing navigation from 4 levels to maximum 2 levels (main view → node detail).

**Acceptance Criteria**:
- [ ] AC1: 主画像页面直接展示所有有数据的 L1/L2/L3 维度内容
- [ ] AC2: 点击任意知识节点直接进入详情页，无需中间层级
- [ ] AC3: 导航层级从 4 层减少到 2 层（主视图 → 节点详情）
- [ ] AC4: 支持在主视图中快速定位到特定维度（锚点跳转）

---

### REQ-2: Immersive Life Review Experience
**ID**: REQ-UI-002  
**Priority**: P0  
**Type**: Non-Functional (UX)

**EARS Pattern**:
WHEN the user scrolls through the profile, THE SYSTEM SHALL present content in a flowing, narrative style that creates a sense of reviewing one's life journey.

**Acceptance Criteria**:
- [ ] AC1: 采用时间线或故事流的视觉布局
- [ ] AC2: 维度之间有自然的视觉过渡，而非硬性分割
- [ ] AC3: 支持平滑滚动，内容连贯展示
- [ ] AC4: 使用温暖、个人化的视觉风格（颜色、字体、间距）
- [ ] AC5: 知识节点展示包含来源片段（sourceLinks.snippet），增强真实感

---

### REQ-3: Conditional Display (Data-Driven)
**ID**: REQ-UI-003  
**Priority**: P0  
**Type**: Functional

**EARS Pattern**:
IF a dimension (L1/L2/L3) has no knowledge nodes, THEN THE SYSTEM SHALL NOT display that dimension in the profile view.

**Acceptance Criteria**:
- [ ] AC1: 空的 L1 维度不显示
- [ ] AC2: 空的 L2 维度不显示
- [ ] AC3: 空的 L3 维度不显示
- [ ] AC4: 当所有维度都为空时，显示引导用户添加数据的提示
- [ ] AC5: 维度显示顺序按数据量或最近更新时间排序

---

### REQ-4: Visual Design Improvement
**ID**: REQ-UI-004  
**Priority**: P1  
**Type**: Non-Functional (UI)

**EARS Pattern**:
THE SYSTEM SHALL use a modern, visually appealing design that reflects the personal nature of life data.

**Acceptance Criteria**:
- [ ] AC1: 使用渐变色或主题色区分不同 L1 维度
- [ ] AC2: 知识节点卡片设计简洁美观，突出核心信息
- [ ] AC3: 置信度使用直观的视觉指示器（颜色/图标）
- [ ] AC4: 支持不同 NodeContentType 的差异化展示：
  - `.aiTag`: 标签样式，紧凑展示
  - `.subsystem`: 结构化表格/列表
  - `.entityRef`: 人物卡片样式
  - `.nestedList`: 可展开的层级列表
- [ ] AC5: 响应式设计，适配不同屏幕尺寸

---

### REQ-5: Test Data Import Feature
**ID**: REQ-UI-005  
**Priority**: P1  
**Type**: Functional

**EARS Pattern**:
WHEN the user is in development/debug mode, THE SYSTEM SHALL provide a "Import Test Data" button that populates the profile with comprehensive test data.

**Acceptance Criteria**:
- [ ] AC1: 在 DataMaintenanceScreen 或 ProfileScreen 添加"导入测试数据"按钮
- [ ] AC2: 按钮仅在 DEBUG 模式下显示
- [ ] AC3: 点击后导入预定义的测试数据集
- [ ] AC4: 导入前提示用户确认（会覆盖现有数据）
- [ ] AC5: 导入完成后自动刷新界面

---

### REQ-6: Comprehensive Test Data Set
**ID**: REQ-UI-006  
**Priority**: P1  
**Type**: Functional

**EARS Pattern**:
THE SYSTEM SHALL include a comprehensive test data set that covers all data formats and dimensions for UI testing.

**Acceptance Criteria**:
- [ ] AC1: 覆盖所有 5 个核心 L1 维度（self, material, achievements, experiences, spirit）
- [ ] AC2: 覆盖所有 15 个 L2 维度
- [ ] AC3: 覆盖所有 4 种 NodeContentType：
  - `.aiTag`: 至少 10 个 AI 标签节点
  - `.subsystem`: 至少 2 个子系统节点（如个人信息）
  - `.entityRef`: 至少 3 个实体引用节点
  - `.nestedList`: 至少 2 个嵌套列表节点
- [ ] AC4: 包含不同置信度的节点（0.3, 0.5, 0.7, 0.9, 1.0）
- [ ] AC5: 包含有 sourceLinks 的节点（用于展示溯源信息）
- [ ] AC6: 包含有 relatedEntityIds 的节点（用于展示关联人物）
- [ ] AC7: 测试数据内容真实可信，便于演示

---

### REQ-7: Node Detail Enhancement
**ID**: REQ-UI-007  
**Priority**: P2  
**Type**: Functional

**EARS Pattern**:
WHEN the user views a knowledge node detail, THE SYSTEM SHALL display comprehensive information including source links, related entities, and confidence indicators.

**Acceptance Criteria**:
- [ ] AC1: 显示节点基本信息（name, description, tags）
- [ ] AC2: 显示置信度和来源类型
- [ ] AC3: 显示 sourceLinks 列表，支持点击跳转到原始数据
- [ ] AC4: 显示 relatedEntityIds 关联的人物
- [ ] AC5: 对于 nestedList 类型，显示子节点列表
- [ ] AC6: 支持编辑和确认操作

---

## Data Structures Reference

### NodeContentType
```swift
public enum NodeContentType: String, Codable {
    case aiTag = "ai_tag"           // AI生成的标签
    case subsystem = "subsystem"     // 独立小系统
    case entityRef = "entity_ref"    // 实体引用
    case nestedList = "nested_list"  // 嵌套列表
}
```

### DimensionHierarchy.Level1
```swift
public enum Level1: String, CaseIterable {
    case self_ = "self"              // 本体
    case material = "material"        // 物质
    case achievements = "achievements" // 成就
    case experiences = "experiences"   // 阅历
    case spirit = "spirit"            // 精神
    case relationships = "relationships" // 关系 [预留]
    case aiPreferences = "ai_preferences" // AI偏好 [预留]
}
```

### Level 2 Dimensions (15个)
- **本体**: identity, physical, personality
- **物质**: economy, objects_space, security
- **成就**: career, competencies, outcomes
- **阅历**: culture_entertainment, exploration, history
- **精神**: ideology, mental_state, wisdom

---

### REQ-8: iOS Best Practices Compliance
**ID**: REQ-UI-008  
**Priority**: P0  
**Type**: Non-Functional (Technical)

**EARS Pattern**:
THE SYSTEM SHALL follow iOS development best practices and Apple Human Interface Guidelines to ensure a native, performant, and accessible user experience.

**Acceptance Criteria**:
- [ ] AC1: 使用 SwiftUI 原生组件和修饰符，避免 UIKit 桥接（除非必要）
- [ ] AC2: 遵循 Apple Human Interface Guidelines (HIG) 的设计规范：
  - 使用系统字体 (SF Pro) 和动态字体大小
  - 支持 Dark Mode 和 Light Mode
  - 使用系统颜色 (Color.primary, Color.secondary 等)
  - 遵循安全区域 (Safe Area) 布局
- [ ] AC3: 支持 VoiceOver 无障碍访问：
  - 所有交互元素有 accessibilityLabel
  - 图片有 accessibilityDescription
  - 正确的 accessibilityTraits
- [ ] AC4: 使用 @StateObject, @ObservedObject, @EnvironmentObject 正确管理状态
- [ ] AC5: 列表使用 LazyVStack/LazyHStack 实现懒加载，优化大数据量性能
- [ ] AC6: 图片和资源使用 Asset Catalog 管理，支持 @2x/@3x 分辨率
- [ ] AC7: 动画使用 SwiftUI 原生动画 API (withAnimation, .animation modifier)
- [ ] AC8: 导航使用 NavigationStack (iOS 16+) 或 NavigationView 的正确模式
- [ ] AC9: 错误处理使用 Swift 的 Result 类型或 async/await 模式
- [ ] AC10: 代码组织遵循 MVVM 架构，View/ViewModel/Model 职责分离

---

## Out of Scope
- 关系维度 (relationships) 和 AI偏好维度 (ai_preferences) 的实现
- AI 自动提取知识节点功能
- 数据同步和云存储功能

---

## Success Metrics
1. 导航层级从 4 层减少到 2 层
2. 用户可以在单一视图中浏览所有有数据的维度
3. 测试数据覆盖所有 NodeContentType 和核心维度
4. UI 视觉效果获得用户正面反馈
