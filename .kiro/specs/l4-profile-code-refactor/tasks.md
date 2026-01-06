# Implementation Plan: L4 Profile Code Refactor

## Overview

基于已完成的架构设计文档，执行 Phase 1 剩余工作和 Phase 2-5 的代码重构。

**参考文档**：
- #[[file:Docs/architecture/L4-PROFILE-EXPANSION-PLAN.md]]
- #[[file:Docs/architecture/GAP-ANALYSIS.md]]

## Tasks

- [x] 1. Phase 1 完成：新增路径工具和迁移映射
  - [x] 1.1 在 DimensionHierarchyModels.swift 中添加 NodeTypePath 结构
    - 实现 init?(nodeType:) 解析方法
    - 实现 fullPath 计算属性
    - 实现 isValid() 验证方法
    - 实现 level1Dimension 计算属性
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 1.2 在 DimensionHierarchyModels.swift 中添加 nodeTypeMigrationMap
    - 添加 10 个 userProfileNodeTypes 映射
    - 添加 6 个 relationshipNodeTypes 映射
    - 添加 migrateNodeType() 函数
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ]* 1.3 编写 NodeTypePath 单元测试
    - 测试有效路径解析
    - 测试无效路径处理
    - 测试 fullPath 重构
    - 测试 isValid 验证
    - _Requirements: 1.6_

- [x] 2. Phase 2：重构 KnowledgeNode 结构
  - [x] 2.1 在 KnowledgeNode 中添加新字段
    - 添加 contentType: NodeContentType 字段（默认 .aiTag）
    - 添加 sourceLinks: [SourceLink] 字段（默认 []）
    - 添加 relatedEntityIds: [String] 字段（默认 []）
    - 添加 childNodeIds: [String]? 字段（默认 nil）
    - 添加 parentNodeId: String? 字段（默认 nil）
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 2.2 更新 KnowledgeNode init 方法
    - 添加所有新字段参数
    - 设置适当的默认值
    - _Requirements: 3.6_

  - [x] 2.3 实现 KnowledgeNode 自定义 Codable
    - 实现 init(from decoder:) 支持向后兼容
    - 新字段缺失时使用默认值
    - 自动迁移 tracking.source.extractedFrom 到 sourceLinks
    - _Requirements: 3.7, 9.1, 9.3_

  - [ ]* 2.4 编写 KnowledgeNode 序列化测试
    - 测试新字段序列化/反序列化
    - 测试向后兼容（旧数据解码）
    - **Property 2: KnowledgeNode Serialization Round-Trip**
    - **Validates: Requirements 3.8**

- [x] 3. Phase 3：重构 SourceLink 结构
  - [x] 3.1 在 SourceLink 中添加 relatedEntityIds 字段
    - 添加 relatedEntityIds: [String] 字段（默认 []）
    - 更新 init 方法
    - _Requirements: 4.1, 4.2_

  - [x] 3.2 实现 SourceLink 自定义 Codable
    - 实现向后兼容解码
    - relatedEntityIds 缺失时使用空数组
    - _Requirements: 4.3, 9.2_

- [x] 4. Checkpoint - Phase 1-3 完成 ✅ (2024-12-31 验证通过)
  - ✅ Phase 1: NodeTypePath 和 nodeTypeMigrationMap 已实现
  - ✅ Phase 2: KnowledgeNode 新增 contentType, sourceLinks, relatedEntityIds, childNodeIds, parentNodeId
  - ✅ Phase 2: KnowledgeNode 自定义 Codable 实现向后兼容（自动迁移 tracking.source.extractedFrom）
  - ✅ Phase 3: SourceLink 新增 relatedEntityIds，自定义 Codable 实现向后兼容

- [x] 5. Phase 4：更新 nodeType 命名和扩展方法
  - [x] 5.1 添加 KnowledgeNode 扩展方法
    - 添加 typePath 计算属性
    - 添加 level1Dimension 计算属性
    - 添加 hasValidDimensionPath 计算属性
    - 添加 matchesLevel1() 方法
    - 添加 matchesLevel2() 方法
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 5.2 更新工厂方法
    - 更新 createUserInput 支持 contentType 参数
    - 更新 createAIExtracted 使用节点级 sourceLinks
    - 更新 createPersonal 支持 contentType 参数
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 5.3 更新 nodeType 常量（可选，保持兼容）
    - 添加新的层级路径格式常量
    - 保留旧常量用于迁移
    - _Requirements: 7.1, 7.2_

  - [x] 5.4 更新便捷访问器
    - 更新 skills, values, goals 等使用前缀匹配
    - 支持新旧两种格式
    - _Requirements: 7.3_

  - [ ]* 5.5 编写 NodeTypePath 属性测试
    - **Property 1: NodeTypePath Round-Trip**
    - **Validates: Requirements 1.6**

- [x] 6. Phase 5：清理和优化
  - [x] 6.1 标记 NodeSource.extractedFrom 为废弃
    - 添加 @available(*, deprecated) 标记
    - 添加迁移说明注释
    - _Requirements: 8.1, 8.2_

  - [x] 6.2 更新相关文档注释
    - 更新 KnowledgeNode 文档
    - 更新 SourceLink 文档
    - 添加迁移指南注释

- [x] 7. Final Checkpoint - 重构完成 ✅ (2024-12-31 验证通过)
  - ✅ 所有模型文件无编译错误
  - ✅ 向后兼容性已实现（Codable 自动迁移旧数据）
  - ✅ Phase 1-5 全部完成

- [x] 8. Phase 6：删除旧画像页面
  - [x] 8.1 删除旧的用户画像页面文件 ✅ (2024-12-31 完成)
    - ✅ 删除 `NarrativeUserProfileScreen.swift`
    - ✅ 删除 `NarrativeUserProfileViewModel.swift`
    - ✅ 临时注释 DataMaintenanceScreen.swift 中的导航入口（待 Task 9.1 创建 DimensionProfileScreen 后恢复）
    - _说明: 旧页面基于 StaticCore + SelfTags + RecentPortrait 结构，与新的三层维度架构不兼容_

- [x] 9. Phase 7：创建新的维度画像页面 ✅ (2024-12-31 完成)
  - [x] 9.1 创建 DimensionProfileScreen.swift（主画像页面）✅
    - 按 5 大一级维度（本体、物质、成就、阅历、精神）展示卡片
    - 每个维度卡片显示：图标、名称、节点数量、最近更新时间
    - 点击维度卡片进入二级维度列表
    - 顶部显示用户基础信息摘要（从 self.identity.personal_info 读取）
    - _Requirements: 设计文档 Life OS 维度体系_

  - [x] 9.2 创建 DimensionProfileViewModel.swift ✅
    - 从 NarrativeUserProfile.knowledgeNodes 加载数据
    - 按 nodeType 前缀分组节点到各维度
    - 提供维度统计信息（节点数、最近更新）
    - 支持按维度过滤和搜索
    - _Requirements: 设计文档 数据模型定义_

  - [x] 9.3 创建 Level2DimensionScreen.swift（二级维度列表页）✅
    - 显示选中一级维度下的所有二级维度
    - 每个二级维度显示：名称、节点数量
    - 点击进入三级维度/节点列表
    - _Requirements: 设计文档 二级维度定义_

  - [x] 9.4 创建 KnowledgeNodeListScreen.swift（节点列表页）✅
    - 显示指定维度路径下的所有 KnowledgeNode
    - 支持按 contentType 分组显示（ai_tag、subsystem、entity_ref、nested_list）
    - 显示节点名称、描述、置信度标签
    - 支持嵌套节点展开/折叠
    - _Requirements: 设计文档 NodeContentType_

  - [x] 9.5 创建 KnowledgeNodeDetailScreen.swift（节点详情页）✅
    - 显示节点完整信息：name、description、tags、attributes
    - 显示 sourceLinks 溯源列表（dayId、snippet、relevanceScore）
    - 显示 relatedEntityIds 关联人物
    - 支持点击 sourceLink 跳转原始来源
    - 支持点击关联人物跳转关系详情
    - 置信度可视化（颜色标签）
    - _Requirements: 设计文档 SourceLink、置信度机制_

- [x] 10. Phase 8：创建维度 UI 组件 ✅ (2024-12-31 完成)
  - [x] 10.1 创建 DimensionCard.swift（维度卡片组件）✅
    - 显示维度图标、名称、节点数量
    - 支持 Level1 和 Level2 两种样式
    - 使用 DimensionHierarchy 获取显示名称和图标
    - _Requirements: 设计文档 DimensionHierarchy_

  - [x] 10.2 创建 KnowledgeNodeRow.swift（节点行组件）✅
    - 显示节点名称、contentType 图标、置信度标签
    - ai_tag: sparkles 图标
    - subsystem: gearshape 图标
    - entity_ref: person.fill 图标
    - nested_list: list.bullet 图标
    - _Requirements: 设计文档 NodeContentType_

  - [x] 10.3 创建 ConfidenceBadge.swift（置信度标签组件）✅
    - 0.9~1.0: 无标签（正常显示）
    - 0.7~0.9: "AI 推测" 蓝色标签
    - 0.5~0.7: "待确认" 黄色标签
    - < 0.5: "低置信度" 灰色标签
    - _Requirements: 设计文档 置信度展示策略_

  - [x] 10.4 创建 SourceLinkRow.swift（溯源链接行组件）✅
    - 显示 dayId（日期）、snippet（摘要）、relevanceScore（相关度）
    - 支持点击跳转到原始来源
    - _Requirements: 设计文档 SourceLink_

- [x] 11. Phase 9：更新导航和入口
  - [x] 11.1 更新 DataMaintenanceScreen.swift ✅
    - 将"我的画像"入口从 NarrativeUserProfileScreen 改为 DimensionProfileScreen
    - _文件: guanji0.34/Features/Profile/DataMaintenanceScreen.swift_

  - [x] 11.2 更新 ProfileScreen.swift（如有直接入口）✅
    - 检查是否有直接跳转到旧画像页面的入口
    - ProfileScreen.swift 通过 DataMaintenanceScreen 导航，无需额外修改
    - _文件: guanji0.34/Features/Profile/ProfileScreen.swift_

- [x] 12. Checkpoint - 画像页面重构完成 ✅ (2024-12-31 完成)
  - ✅ 新页面正常显示
  - ✅ 导航跳转正确
  - ✅ 数据加载正常
  - ✅ 所有 UI 组件无编译错误

## Notes

- 所有修改保持向后兼容，旧数据能正常读取
- 测试任务标记为可选（带 `*`），但建议执行以确保正确性
- Phase 5 的废弃标记是软废弃，不会立即移除代码
- 重构完成后，新代码应使用新格式，旧数据读取时自动迁移
- Phase 6-9 是画像页面全新设计，完全替换旧页面

## 新增 UI 文件清单

**删除文件**:
- `guanji0.34/Features/Profile/NarrativeUserProfileScreen.swift` - 旧画像页面
- `guanji0.34/Features/Profile/NarrativeUserProfileViewModel.swift` - 旧 ViewModel

**新增文件**:
- `guanji0.34/Features/Profile/DimensionProfileScreen.swift` - 新主画像页面
- `guanji0.34/Features/Profile/DimensionProfileViewModel.swift` - 新 ViewModel
- `guanji0.34/Features/Profile/Level2DimensionScreen.swift` - 二级维度列表
- `guanji0.34/Features/Profile/KnowledgeNodeListScreen.swift` - 节点列表
- `guanji0.34/Features/Profile/KnowledgeNodeDetailScreen.swift` - 节点详情
- `guanji0.34/Features/Profile/Components/DimensionCard.swift` - 维度卡片组件
- `guanji0.34/Features/Profile/Components/KnowledgeNodeRow.swift` - 节点行组件
- `guanji0.34/Features/Profile/Components/ConfidenceBadge.swift` - 置信度标签
- `guanji0.34/Features/Profile/Components/SourceLinkRow.swift` - 溯源链接行

**修改文件**:
- `guanji0.34/Features/Profile/DataMaintenanceScreen.swift` - 更新导航入口
- `guanji0.34/Features/Profile/ProfileScreen.swift` - 更新导航入口（如有）

## 页面结构预览

```
DimensionProfileScreen (主画像页面)
├── 用户基础信息摘要
└── 5 大维度卡片
    ├── 本体 (Self) → Level2DimensionScreen
    │   ├── 身份认同 → KnowledgeNodeListScreen → KnowledgeNodeDetailScreen
    │   ├── 身体状态 → ...
    │   └── 性格特质 → ...
    ├── 物质 (Material) → ...
    ├── 成就 (Achievements) → ...
    ├── 阅历 (Experiences) → ...
    └── 精神 (Spirit) → ...
```

