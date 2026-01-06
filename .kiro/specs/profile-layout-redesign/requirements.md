# Requirements Document

## Introduction

本文档定义了个人中心（Profile）页面的完整重设计需求。目标是：
1. 按照 iOS 最佳实践重新组织菜单布局
2. 添加 iOS 产品必备但目前缺失的功能入口
3. 统一所有图标使用紫色（indigo）风格

## Glossary

- **Profile_Screen**: 个人中心主屏幕，包含用户设置和功能入口
- **Section**: 列表中的分组区域
- **Icon_Color**: 图标的前景色，应统一为 Colors.indigo
- **Language_Picker**: 语言选择器弹窗
- **User_Header**: 用户信息头部区域（头像、昵称等）

## Requirements

### Requirement 1: 用户信息头部区域（新增）

**User Story:** 作为用户，我希望在个人中心顶部看到我的个人信息，以便快速识别当前账户。

#### Acceptance Criteria

1. THE Profile_Screen SHALL display a user header section at the top of the list
2. WHEN displaying the user header, THE Profile_Screen SHALL show a user avatar placeholder
3. WHEN displaying the user header, THE Profile_Screen SHALL show a user nickname or "设置昵称" prompt
4. WHEN the user taps the header, THE Profile_Screen SHALL navigate to a profile edit screen (placeholder)

### Requirement 2: 菜单分组重新排序（iOS 最佳实践）

**User Story:** 作为用户，我希望个人中心的菜单按照 iOS 标准设置页面的逻辑分组排列。

#### Acceptance Criteria

1. THE Profile_Screen SHALL display sections in the following order: 用户信息 → 功能与服务 → 偏好设置 → 隐私与安全 → 支持与反馈 → 关于
2. WHEN displaying the "功能与服务" section, THE Profile_Screen SHALL include: 人生回顾、数据统计、会员计划
3. WHEN displaying the "偏好设置" section, THE Profile_Screen SHALL include: AI设置、默认模式、通知、语言、外观（新增）
4. WHEN displaying the "隐私与安全" section, THE Profile_Screen SHALL include: 数据同步、数据维护、隐私政策（新增）
5. WHEN displaying the "支持与反馈" section, THE Profile_Screen SHALL include: 帮助中心（新增）、意见反馈（新增）、给我们评分（新增）
6. WHEN displaying the "关于" section, THE Profile_Screen SHALL include: 关于、订阅信息、组件库（开发者选项）

### Requirement 3: 图标颜色统一化

**User Story:** 作为用户，我希望个人中心的所有图标颜色风格一致，以获得更好的视觉体验。

#### Acceptance Criteria

1. THE Profile_Screen SHALL apply Colors.indigo to all menu item icons
2. WHEN a Label with systemImage is displayed, THE icon SHALL use Colors.indigo as foreground color
3. THE Profile_Screen SHALL NOT use default system icon colors for menu items

### Requirement 4: 语言选择器样式优化

**User Story:** 作为用户，我希望语言选择器的样式与整体紫色风格保持一致。

#### Acceptance Criteria

1. WHEN the Language_Picker is displayed, THE list items SHALL use consistent styling
2. WHEN a language is selected, THE checkmark icon SHALL use Colors.indigo
3. THE Language_Picker SHALL apply Colors.indigo tint to the navigation bar and list

### Requirement 5: 新增功能入口（占位）

**User Story:** 作为用户，我希望能够访问隐私政策、帮助中心、意见反馈等 iOS 产品必备功能。

#### Acceptance Criteria

1. WHEN the user taps "隐私政策", THE Profile_Screen SHALL navigate to a privacy policy screen (placeholder)
2. WHEN the user taps "帮助中心", THE Profile_Screen SHALL navigate to a help center screen (placeholder)
3. WHEN the user taps "意见反馈", THE Profile_Screen SHALL navigate to a feedback screen (placeholder)
4. WHEN the user taps "给我们评分", THE Profile_Screen SHALL open the App Store review prompt
5. WHEN the user taps "外观", THE Profile_Screen SHALL show appearance settings (light/dark/system)

### Requirement 6: 视觉一致性

**User Story:** 作为用户，我希望所有菜单项的视觉样式保持一致。

#### Acceptance Criteria

1. THE Profile_Screen SHALL use consistent row height for all menu items
2. THE Profile_Screen SHALL use consistent chevron style for all navigable items
3. THE Profile_Screen SHALL use consistent secondary text style for status indicators
