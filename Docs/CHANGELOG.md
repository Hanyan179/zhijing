# 变更日志 (Changelog)

> 返回 [文档中心](INDEX.md)

本文档记录观己(Guanji)文档体系的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范。

## [2.0.0] - 2024-12-17

### 新增 (Added)
- 完成文档体系规范化
  - 所有功能模块文档 (8 个)
  - 所有 UI 组件文档 (Atoms/Molecules/Organisms)
  - 所有数据模型文档 (18 个模型)
  - 所有 API 接口文档 (12 个 Repository + 7 个 Service)
- 创建属性测试套件 `DocumentFormatTests.swift`
  - Property 1: 文档格式一致性测试
  - Property 4: 代码覆盖完整性测试
  - Property 5: 链接完整性测试
- 创建文档验证脚本 `validate_docs.sh`
- 添加开发工作流程指南到文档中心

### 变更 (Changed)
- 更新文档中心 README，添加开发工作流程说明
- 优化属性测试的路径配置，支持相对路径

### 移除 (Removed)
- 清理 Docs 目录下的过时文档

---

## [1.2.0] - 2024-12-17

### 新增 (Added)
- 创建架构文档 (architecture/)
  - `system-architecture.md` - 系统架构，描述 MVVM 架构、分层结构、模块职责
  - `data-architecture.md` - 数据架构，描述三层数据模型关系和持久化策略
  - `mvvm-pattern.md` - MVVM 模式说明，描述 ViewModel 和 View 的职责划分

---

## [1.1.0] - 2024-12-17

### 新增 (Added)
- 创建概述文档 (overview/)
  - `product-overview.md` - 产品概述，包含功能介绍和技术栈
  - `feature-map.md` - 功能地图，使用 Mermaid 图展示 8 个功能模块关系
  - `user-journey.md` - 用户旅程，描述 6 个核心用户场景
- 创建文档格式一致性属性测试 `DocumentFormatTests.swift`
  - 验证文档导航链接
  - 验证文档元数据 (版本、作者、更新日期、状态)

---

## [1.0.0] - 2024-12-17

### 新增 (Added)
- 建立统一的文档目录结构
  - `overview/` - 概述文档
  - `architecture/` - 架构文档
  - `features/` - 功能模块文档
  - `components/` - UI 组件文档
  - `data/` - 数据模型文档
  - `api/` - API 接口文档
- 创建文档中心入口 `INDEX.md`
  - 分类导航
  - 文档索引
  - 标签筛选
- 创建变更日志 `CHANGELOG.md`
- 定义文档模板规范
  - 技术文档模板
  - 产品文档模板
  - 架构文档模板

### 变更 (Changed)
- 无

### 废弃 (Deprecated)
- 原有 Docs 目录下的过时文档将在后续版本中清理

### 移除 (Removed)
- 无

### 修复 (Fixed)
- 无

### 安全 (Security)
- 无

---

## 版本说明

- **MAJOR**: 文档结构重大变更，可能影响现有链接
- **MINOR**: 新增文档或章节
- **PATCH**: 文档内容修正或小幅更新

---
**版本**: v2.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-17  
**状态**: 已发布
