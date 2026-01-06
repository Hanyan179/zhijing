# Implementation Plan: L4 Profile Redesign

## Overview

本实现计划分两阶段：
1. **Phase 1 (当前)**: 完成架构设计文档，定义三层维度体系
2. **Phase 2 (后续)**: 基于文档进行代码重构

## Tasks

- [x] 1. 更新 L4-PROFILE-EXPANSION-PLAN.md 文档
  - [x] 1.1 重写架构概述
    - 替换"通用节点 + 共有/个人维度"为"三层维度架构"
    - 添加架构方案对比分析（三层维度 vs 原内核状态）
    - 记录设计决策和理由
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 1.2 添加 Life OS 维度体系定义
    - 定义 7 个一级维度（含 2 个预留）
    - 定义 15 个二级维度
    - 定义 Level 3 预设维度列表
    - 添加维度完整性验证结果
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [x] 1.3 添加各维度详细结构
    - 本体维度 (Self): 身份认同、身体状态、性格特质
    - 物质维度 (Material): 经济状况、物品与环境、生活保障
    - 成就维度 (Achievements): 事业发展、个人能力、成果展示
    - 阅历维度 (Experiences): 文化娱乐、探索足迹、人生历程
    - 精神维度 (Spirit): 意识形态、心理状态、思考感悟
    - _Requirements: 4.1-4.5, 5.1-5.4, 6.1-6.4, 7.1-7.4, 8.1-8.4_

  - [x] 1.4 添加 NodeContentType 和 L3 特异性说明
    - 定义 4 种内容类型: ai_tag, subsystem, entity_ref, nested_list
    - 说明每种类型的数据特点和使用场景
    - 添加使用示例
    - _Requirements: 4.2-4.5, 5.2-5.4, 6.2-6.4, 7.2-7.4, 8.2-8.4_

  - [x] 1.5 更新数据模型定义
    - 更新 KnowledgeNode 结构（新增 contentType, sourceLinks, relatedEntityIds, childNodeIds, parentNodeId）
    - 更新 SourceLink 结构（新增 relatedEntityIds）
    - 更新 NodeTracking 结构（简化，移除 extractedFrom）
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 9.3, 9.4_

  - [x] 1.6 添加预留接口定义
    - 关系子系统接口 (RelationshipSubsystemInterface)
    - AI偏好子系统接口 (AIPreferencesSubsystemInterface)
    - _Requirements: 9.1, 9.2, 9.5, 10.1, 10.2, 10.3_

  - [x] 1.7 添加迁移策略
    - nodeType 迁移映射表
    - 5 阶段迁移计划
    - 向后兼容策略
    - _Requirements: 12.4_

- [x] 2. 创建 GAP-ANALYSIS.md 差异分析文档
  - [x] 2.1 整理已完成项清单
    - 列出现有代码中已实现的功能
    - 标注文件位置
    - _Requirements: 12.1, 12.2_

  - [x] 2.2 整理需重构项清单
    - 列出需要修改的现有代码
    - 说明具体修改内容
    - _Requirements: 12.2, 12.3_

  - [x] 2.3 整理需新增项清单
    - 列出需要新增的类型和方法
    - 标注优先级
    - _Requirements: 12.3_

  - [x] 2.4 整理可废弃项清单
    - 列出可以废弃的代码
    - 提供处理建议
    - _Requirements: 12.3_

  - [x] 2.5 制定迁移计划时间线
    - 5 阶段迁移计划详细说明
    - _Requirements: 12.4_

- [x] 3. Checkpoint - 文档完成
  - 确保文档完整，如有问题请询问用户

## Notes

- 当前阶段聚焦于文档定义，不涉及代码修改
- 测试任务标记为可选（带 `*`），后续代码实现阶段再执行
- 文档完成后可作为后续代码重构的指导
