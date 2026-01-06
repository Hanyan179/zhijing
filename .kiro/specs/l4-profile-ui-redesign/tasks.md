# Implementation Plan: L4 Profile UI Redesign

## Overview

本实现计划将 Profile UI 从 4 层导航重构为 2 层沉浸式体验。采用渐进式开发，先搭建基础组件，再组装完整页面，最后集成测试数据。

## Tasks

- [x] 1. 创建目录结构和 UI 数据模型
  - [x] 1.1 创建 LifeReview 目录结构
    - 创建 `guanji0.34/Features/Profile/LifeReview/` 目录
    - 创建 `Components/` 和 `Detail/` 子目录
    - _Requirements: REQ-1, REQ-8_

  - [x] 1.2 创建 PopulatedDimension 数据模型
    - 创建 `guanji0.34/Features/Profile/LifeReview/Models/PopulatedDimension.swift`
    - 实现 `PopulatedDimension` 结构体（id, level1, level2Groups, totalNodeCount, color, icon）
    - 实现 `Level2Group` 结构体（id, level2, displayName, nodes）
    - _Requirements: REQ-1.1, REQ-3_

  - [x] 1.3 创建 DimensionColors 和 DimensionIcons 配置
    - 创建 `guanji0.34/Features/Profile/LifeReview/Models/DimensionConfig.swift`
    - 为 5 个核心 L1 维度配置颜色和图标
    - _Requirements: REQ-4.1_

- [x] 2. 实现 LifeReviewViewModel
  - [x] 2.1 创建 LifeReviewViewModel 基础结构
    - 创建 `guanji0.34/Features/Profile/LifeReview/LifeReviewViewModel.swift`
    - 实现 @Published 属性：userProfile, populatedDimensions, isLoading, searchText
    - 注入 NarrativeUserProfileRepository 依赖
    - _Requirements: REQ-8.4, REQ-8.9_

  - [x] 2.2 实现数据加载和维度分组逻辑
    - 实现 `loadData()` 方法从 Repository 加载数据
    - 实现 `buildPopulatedDimensions()` 方法，按 L1/L2 分组节点
    - 过滤空维度，只保留有数据的维度
    - _Requirements: REQ-3.1, REQ-3.2, REQ-3.3_

  - [x] 2.3 实现搜索功能
    - 实现 `searchNodes(query:)` 方法
    - 支持按 name, description, tags 搜索
    - _Requirements: REQ-1.4_

- [x] 3. 实现基础 UI 组件
  - [x] 3.1 创建 DimensionHeader 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/DimensionHeader.swift`
    - 显示 L1 维度图标、名称、节点数量
    - 使用维度主题色
    - _Requirements: REQ-4.1, REQ-8.1_

  - [x] 3.2 创建 Level2GroupView 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/Level2GroupView.swift`
    - 显示 L2 标题和节点列表
    - 使用 FlowLayout 布局节点卡片
    - _Requirements: REQ-2.2, REQ-4_

  - [x] 3.3 创建 KnowledgeNodeCard 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/KnowledgeNodeCard.swift`
    - 根据 ContentType 差异化展示：
      - `.aiTag`: 紧凑标签样式
      - `.subsystem`: 带描述的卡片
      - `.entityRef`: 带头像的卡片
      - `.nestedList`: 可展开样式
    - 显示置信度指示器（低于 0.8 时）
    - _Requirements: REQ-4.2, REQ-4.3, REQ-4.4_

  - [x] 3.4 创建 ConfidenceIndicator 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/ConfidenceIndicator.swift`
    - 使用颜色和图标直观展示置信度
    - _Requirements: REQ-4.3_

  - [x] 3.5 创建 FlowLayout 布局组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/FlowLayout.swift`
    - 实现自适应流式布局，标签自动换行
    - _Requirements: REQ-4.5, REQ-8.1_

  - [x] 3.6 创建 EmptyStateView 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/EmptyStateView.swift`
    - 显示引导用户添加数据的提示
    - 包含"开始对话"按钮
    - _Requirements: REQ-3.4_

- [x] 4. 实现维度区块视图
  - [x] 4.1 创建 DimensionSectionView 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/DimensionSectionView.swift`
    - 组合 DimensionHeader 和 Level2GroupView
    - 支持节点点击回调
    - _Requirements: REQ-1.1, REQ-2.2_

  - [x] 4.2 创建 UserHeaderSection 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/UserHeaderSection.swift`
    - 显示用户头像和基本信息
    - 显示节点总数统计
    - _Requirements: REQ-2.4_

  - [x] 4.3 创建 DimensionQuickNav 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Components/DimensionQuickNav.swift`
    - 显示维度概览卡片网格（2x3 布局）
    - 只显示有数据的维度
    - 支持点击进入维度详情
    - _Requirements: REQ-1.4, REQ-3_

- [x] 5. Checkpoint - 基础组件完成
  - [x] 确保所有基础组件可以独立编译
  - [x] 在 Preview 中验证各组件显示效果
  - [x] 如有问题请询问用户

- [x] 6. 实现节点详情 Sheet
  - [x] 6.1 创建 NodeBasicInfoSection 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Detail/NodeBasicInfoSection.swift`
    - 显示节点名称、描述、标签
    - 显示维度路径
    - _Requirements: REQ-7.1_

  - [x] 6.2 创建 NodeSourceSection 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Detail/NodeSourceSection.swift`
    - 显示置信度进度条
    - 显示来源类型（用户输入/AI提取/AI推断）
    - _Requirements: REQ-7.2_

  - [x] 6.3 创建 SourceLinksSection 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Detail/SourceLinksSection.swift`
    - 显示溯源链接列表
    - 显示 snippet 文本片段
    - 支持点击跳转到原始数据
    - _Requirements: REQ-7.3, REQ-2.5_

  - [x] 6.4 创建 RelatedEntitiesSection 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Detail/RelatedEntitiesSection.swift`
    - 显示关联人物列表
    - _Requirements: REQ-7.4_

  - [x] 6.5 创建 ChildNodesSection 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Detail/ChildNodesSection.swift`
    - 显示嵌套列表的子节点
    - _Requirements: REQ-7.5_

  - [x] 6.6 创建 KnowledgeNodeDetailSheet 组件
    - 创建 `guanji0.34/Features/Profile/LifeReview/Detail/KnowledgeNodeDetailSheet.swift`
    - 组合所有详情 Section
    - 使用 `.presentationDetents([.medium, .large])`
    - 添加编辑、确认、删除操作按钮
    - _Requirements: REQ-7, REQ-1.2_

- [x] 7. 实现主页面
  - [x] 7.1 创建 LifeReviewScreen 主页面
    - 创建 `guanji0.34/Features/Profile/LifeReview/LifeReviewScreen.swift`
    - 使用 NavigationStack 包装
    - 使用 ScrollViewReader 支持锚点跳转
    - 使用 LazyVStack 实现懒加载
    - 组合 UserHeaderSection、DimensionQuickNav、DimensionSectionView
    - 使用 `.sheet(item:)` 展示节点详情
    - _Requirements: REQ-1, REQ-2, REQ-8.5, REQ-8.8_

  - [x] 7.2 实现搜索功能 UI
    - 添加搜索栏
    - 实现 SearchResultsView
    - 高亮匹配关键词
    - _Requirements: REQ-1.4_

  - [x] 7.3 添加下拉刷新
    - 使用 `.refreshable` modifier
    - 调用 ViewModel 的 refresh 方法
    - _Requirements: REQ-8.1_

- [x] 8. Checkpoint - 主页面完成
  - 确保主页面可以正常显示
  - 验证导航流程：主页 → 节点详情
  - 验证搜索功能
  - 如有问题请询问用户

- [x] 9. 实现测试数据生成器
  - [x] 9.1 创建 TestDataGenerator 基础结构
    - 创建 `guanji0.34/Features/Profile/TestData/TestDataGenerator.swift`
    - 实现 `generateTestProfile()` 静态方法
    - _Requirements: REQ-6_

  - [x] 9.2 实现各维度测试数据生成
    - 为 5 个核心 L1 维度生成测试节点
    - 覆盖所有 15 个 L2 维度
    - 覆盖 4 种 NodeContentType
    - _Requirements: REQ-6.1, REQ-6.2, REQ-6.3_

  - [x] 9.3 实现不同置信度和关联数据
    - 生成不同置信度的节点（0.3, 0.5, 0.7, 0.9, 1.0）
    - 生成带 sourceLinks 的节点
    - 生成带 relatedEntityIds 的节点
    - _Requirements: REQ-6.4, REQ-6.5, REQ-6.6_

  - [x] 9.4 添加测试数据导入按钮
    - 在 LifeReviewScreen 添加 DEBUG 模式下的导入按钮
    - 实现导入确认弹窗
    - 导入后自动刷新界面
    - _Requirements: REQ-5.1, REQ-5.2, REQ-5.3, REQ-5.4, REQ-5.5_

- [x] 10. 添加无障碍支持
  - [x] 10.1 为所有交互组件添加 accessibilityLabel
    - KnowledgeNodeCard 添加节点名称和类型描述
    - DimensionHeader 添加维度名称和节点数量
    - 操作按钮添加功能描述
    - _Requirements: REQ-8.3_

  - [x] 10.2 添加 accessibilityHint 和 accessibilityTraits
    - 可点击元素添加 `.isButton` trait
    - 添加操作提示（如"双击查看详情"）
    - _Requirements: REQ-8.3_

- [x] 11. 集成和导航入口更新
  - [x] 11.1 更新导航入口
    - 在 ContentView 或相关入口添加 LifeReviewScreen 导航
    - 保留旧页面作为备份（可选）
    - _Requirements: REQ-1.3_

  - [x] 11.2 验证 Dark Mode 支持
    - 确保所有颜色使用系统语义颜色或支持 Dark Mode
    - 测试 Light/Dark 模式切换
    - _Requirements: REQ-8.2_

- [x] 12. Final Checkpoint - 功能完成
  - 确保所有测试通过
  - 验证完整用户流程
  - 验证测试数据导入功能
  - 如有问题请询问用户

## Notes

- 任务按依赖顺序排列，建议按顺序执行
- 每个 Checkpoint 是验证点，确保阶段性成果正确
- 测试数据生成器是验证 UI 效果的关键，优先级较高
- 无障碍支持是 iOS 最佳实践的重要部分，不应跳过
