# Implementation Plan: Profile Layout Redesign

## Overview

按照 iOS 最佳实践重新设计个人中心布局，统一图标颜色，并添加必备功能入口占位页面。

## Tasks

- [x] 1. 添加本地化字符串
  - 在 Localizable.strings 中添加新的 Section 标题和菜单项文本
  - 包括中文和英文版本
  - _Requirements: 2.1_

- [x] 2. 创建用户头部组件
  - [x] 2.1 创建 UserHeaderRow 组件
    - 实现头像占位圆形 + 昵称文本 + 箭头
    - 使用 Colors.indigo 作为图标颜色
    - _Requirements: 1.1, 1.2, 1.3_

- [x] 3. 创建占位页面
  - [x] 3.1 创建 ProfileEditScreen 占位页面
    - 显示"功能开发中"提示
    - _Requirements: 1.4_
  - [x] 3.2 创建 AppearanceSettingsScreen 占位页面
    - 显示外观设置选项（浅色/深色/跟随系统）
    - _Requirements: 5.5_
  - [x] 3.3 创建 PrivacyPolicyScreen 占位页面
    - 显示隐私政策占位内容
    - _Requirements: 5.1_
  - [x] 3.4 创建 HelpCenterScreen 占位页面
    - 显示帮助中心占位内容
    - _Requirements: 5.2_
  - [x] 3.5 创建 FeedbackScreen 占位页面
    - 显示意见反馈占位内容
    - _Requirements: 5.3_

- [x] 4. 重构 ProfileScreen 布局
  - [x] 4.1 重新组织 Section 顺序
    - 按照设计文档的 6 个分组重新排列
    - _Requirements: 2.1_
  - [x] 4.2 实现"功能与服务"分组
    - 包含人生回顾、数据统计、会员计划
    - _Requirements: 2.2_
  - [x] 4.3 实现"偏好设置"分组
    - 包含 AI设置、默认模式、通知、语言、外观
    - _Requirements: 2.3_
  - [x] 4.4 实现"隐私与安全"分组
    - 包含数据同步、数据维护、隐私政策
    - _Requirements: 2.4_
  - [x] 4.5 实现"支持与反馈"分组
    - 包含帮助中心、意见反馈、给我们评分
    - _Requirements: 2.5_
  - [x] 4.6 实现"关于"分组
    - 包含关于、订阅信息、组件库
    - _Requirements: 2.6_

- [x] 5. 统一图标颜色
  - [x] 5.1 为所有 Label 添加 Colors.indigo 前景色
    - 使用 symbolRenderingMode(.hierarchical) + foregroundStyle(Colors.indigo)
    - _Requirements: 3.1, 3.2_
  - [x] 5.2 修复数据统计按钮图标颜色
    - _Requirements: 3.1_
  - [x] 5.3 修复 AI 设置按钮图标颜色
    - _Requirements: 3.1_

- [x] 6. 优化 LanguagePickerSheet 样式
  - [x] 6.1 添加 List tint 颜色
    - 使用 Colors.indigo
    - _Requirements: 4.3_
  - [x] 6.2 确保 checkmark 使用 Colors.indigo
    - _Requirements: 4.2_

- [x] 7. 实现 App Store 评分功能
  - 使用 StoreKit 的 requestReview API
  - _Requirements: 5.4_

- [x] 8. Checkpoint - 验证布局和样式
  - 确保所有 Section 按正确顺序显示
  - 确保所有图标颜色为紫色
  - 确保语言选择器样式一致
  - 询问用户是否有问题

## Notes

- 新增的占位页面后续会逐个实现完整功能
- 图标颜色统一使用 Colors.indigo
- 用户头部区域暂时使用占位头像，后续可扩展为真实用户数据
