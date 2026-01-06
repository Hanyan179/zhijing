# Design Document

## Overview

本设计文档描述个人中心（ProfileScreen）的完整重设计方案，包括：
1. 按照 iOS 最佳实践重新组织菜单布局（6个分组）
2. 添加 iOS 产品必备功能入口（占位页面）
3. 统一所有图标使用 Colors.indigo 紫色风格
4. 优化语言选择器的视觉一致性

## Architecture

### 现有架构
ProfileScreen 使用 SwiftUI 的 `List` 和 `Section` 组件构建，采用 MVVM 模式：
- View: `ProfileScreen.swift`
- ViewModel: `ProfileViewModel.swift`
- 子视图: `LanguagePickerSheet`

### 修改范围
- 主要修改: `ProfileScreen.swift`
- 新增占位页面: `ProfileEditScreen.swift`, `AppearanceSettingsScreen.swift`, `PrivacyPolicyScreen.swift`, `HelpCenterScreen.swift`, `FeedbackScreen.swift`

## Components and Interfaces

### ProfileScreen 新组件结构

```
ProfileScreen
├── Section: 用户信息 (无标题)
│   └── UserHeaderRow: 头像 + 昵称 + 箭头
│
├── Section: 功能与服务 (Profile.Section.Features)
│   ├── NavigationLink: 人生回顾 (brain.head.profile)
│   ├── Button: 数据统计 (chart.bar.fill)
│   └── NavigationLink: 会员计划 (crown.fill)
│
├── Section: 偏好设置 (Profile.Section.Preferences)
│   ├── Button: AI设置 (sparkles)
│   ├── Picker: 默认模式 (rectangle.stack)
│   ├── NavigationLink: 通知 (bell.badge.fill)
│   ├── Button: 语言 (globe)
│   └── NavigationLink: 外观 (circle.lefthalf.filled)
│
├── Section: 隐私与安全 (Profile.Section.Privacy)
│   ├── HStack: 数据同步 (arrow.triangle.2.circlepath)
│   ├── NavigationLink: 数据维护 (externaldrive.fill)
│   └── NavigationLink: 隐私政策 (hand.raised.fill)
│
├── Section: 支持与反馈 (Profile.Section.Support)
│   ├── NavigationLink: 帮助中心 (questionmark.circle)
│   ├── NavigationLink: 意见反馈 (envelope.fill)
│   └── Button: 给我们评分 (star.fill)
│
└── Section: 关于 (Profile.Section.About)
    ├── NavigationLink: 关于 (info.circle)
    ├── NavigationLink: 订阅信息 (doc.text.fill)
    └── NavigationLink: 组件库 (square.stack.3d.up.fill) [开发者]
```

### 用户头部组件

```swift
struct UserHeaderRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // 头像占位
            Circle()
                .fill(Colors.slateLight)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(Colors.indigo)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("设置昵称")
                    .font(.headline)
                Text("点击编辑个人资料")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}
```

### 图标颜色统一方案

使用 `symbolRenderingMode(.hierarchical)` 配合 `foregroundStyle(Colors.indigo)` 实现统一的紫色图标：

```swift
// 统一的菜单项 Label 样式
Label(title, systemImage: iconName)
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(Colors.indigo)
```

### 新增占位页面

```swift
// 通用占位页面模板
struct PlaceholderScreen: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Colors.indigo)
            Text(description)
                .foregroundStyle(.secondary)
        }
        .navigationTitle(title)
    }
}
```

## Data Models

### 新增本地化键

```
// Localizable.strings 新增
"Profile.Section.Features" = "功能与服务";
"Profile.Section.Preferences" = "偏好设置";
"Profile.Section.Privacy" = "隐私与安全";
"Profile.Section.Support" = "支持与反馈";
"Profile.Section.About" = "关于";
"Profile.EditProfile" = "编辑资料";
"Profile.SetNickname" = "设置昵称";
"Profile.Appearance" = "外观";
"Profile.PrivacyPolicy" = "隐私政策";
"Profile.HelpCenter" = "帮助中心";
"Profile.Feedback" = "意见反馈";
"Profile.RateUs" = "给我们评分";
"Profile.ComingSoon" = "功能开发中...";
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do.*

### Property 1: Icon Color Consistency

*For any* menu item Label in ProfileScreen and its sub-sheets, the icon foreground color should be Colors.indigo.

**Validates: Requirements 3.1, 3.2, 4.2**

## Error Handling

无特殊错误处理需求，本次修改仅涉及 UI 布局和样式。

新增的占位页面应显示友好的"功能开发中"提示。

## Testing Strategy

### Unit Tests
- 验证 LanguagePickerSheet 中 checkmark 使用 Colors.indigo
- 验证各 Section 包含正确的菜单项

### Visual Testing
- 手动验证所有图标颜色为紫色
- 验证语言选择器样式一致性
- 验证用户头部区域显示正确

### Property-Based Testing
由于本次修改主要是 UI 样式调整，property-based testing 的适用性有限。主要通过 UI 快照测试或手动验证确保一致性。
