# Implementation Plan: L4 Source Info Redesign

## Overview

本实现计划重构人生回顾功能中的"来源信息"区块，将置信度改为关联原始次数，来源类型改为数据表分布，移除验证状态，并修复详情页编辑交互问题。

## Tasks

- [x] 1. 新增辅助计算属性和图标映射
  - [x] 1.1 在 KnowledgeNode 扩展中添加 mentionCount 和 sourceTypeDistribution 计算属性
    - 添加 mentionCount: Int 返回 sourceLinks.count
    - 添加 sourceTypeDistribution: [String: Int] 返回按 sourceType 分组的计数
    - 添加 hasSourceData: Bool 返回 !sourceLinks.isEmpty
    - _Requirements: 1.2, 2.1_

  - [x] 1.2 创建 DataSourceTypeIcons 辅助结构
    - 添加 icon(for:) 方法返回各来源类型图标
    - 添加 displayName(for:) 方法返回各来源类型中文名称
    - 支持 diary(日记)、conversation(AI对话)、tracker(追踪器)、mindState(心情记录)
    - _Requirements: 2.4_

- [x] 2. 重构 NodeSourceSection 组件
  - [x] 2.1 移除置信度相关视图
    - 删除 confidenceView 及相关计算属性
    - 删除置信度进度条 UI
    - 删除 ConfidenceColors 相关调用
    - _Requirements: 1.1, 1.4, 1.5_

  - [x] 2.2 移除验证状态相关视图
    - 删除 verificationStatusView
    - 删除 isConfirmed、needsReview 相关 UI
    - _Requirements: 3.1, 3.3_

  - [x] 2.3 新增关联原始次数视图
    - 创建 mentionCountView 显示 "关联 X 条原始数据"
    - 使用简洁的数字展示样式
    - _Requirements: 1.2, 1.3_

  - [x] 2.4 重构来源类型分布视图
    - 单条来源时显示单行格式
    - 多条来源时显示分组格式
    - 使用 DataSourceTypeIcons 获取图标和名称
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 2.5 简化时间信息视图
    - 保留创建时间和更新时间
    - 移除确认时间显示
    - _Requirements: 1.1_

- [x] 3. 修复 KnowledgeNodeDetailSheet 编辑交互
  - [x] 3.1 添加编辑 Sheet 状态管理
    - 添加 @State showEditSheet: Bool
    - 添加 .sheet(isPresented:) 修饰符
    - _Requirements: 4.1, 4.2_

  - [x] 3.2 修改编辑按钮行为
    - 点击编辑按钮设置 showEditSheet = true
    - 移除原有的 onEdit 回调方式
    - _Requirements: 4.1, 4.3_

  - [x] 3.3 移除确认按钮
    - 从 actionMenu 中移除确认按钮
    - 移除 canConfirm 计算属性
    - 移除 confirmNode() 方法调用
    - 移除 showConfirmSuccess 状态和覆盖层
    - _Requirements: 3.2_

  - [x] 3.4 处理编辑保存后的 UI 更新
    - 确保 ViewModel 更新后详情页自动刷新
    - _Requirements: 4.4, 4.5_

- [x] 4. Checkpoint - 确保所有修改正常工作
  - 确保编辑交互正常，如有问题请询问用户

- [ ]* 5. 编写属性测试
  - [ ]* 5.1 编写关联次数一致性属性测试
    - **Property 1: Mention Count Equals SourceLinks Count**
    - **Validates: Requirements 1.2**

  - [ ]* 5.2 编写来源分布完整性属性测试
    - **Property 2: Source Type Distribution Accuracy**
    - **Validates: Requirements 2.1**

  - [ ]* 5.3 编写序列化往返属性测试
    - **Property 3: Data Model Serialization Round-Trip**
    - **Validates: Requirements 3.4, 5.2**

- [x] 6. Final Checkpoint - 确保所有测试通过
  - 确保所有测试通过，查看是否有文档需要更新。如有问题请询问用户

## Notes

- 任务标记为 `*` 的为可选测试任务
- 数据模型层面不做修改，只修改 UI 展示
- 确保向后兼容，旧数据能正常显示
