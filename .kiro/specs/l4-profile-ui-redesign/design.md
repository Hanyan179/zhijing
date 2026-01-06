# Profile UI Redesign - Design Document

## Overview

本设计文档描述 L4 用户画像界面的 UI 重构方案。核心目标：

1. **沉浸式人生回顾** - 流畅的滚动体验，像翻阅人生故事
2. **快速搜索定位** - 随着数据增多，用户能快速找到想要的内容
3. **总览 + 细节分离** - 主页展示概览，点击按钮进入维度详情

## Architecture

### UI 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Profile UI 双模式架构                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  模式一: 沉浸式总览 (LifeStoryView)                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  📖 人生故事流                                           │    │
│  │  ├── 用户头像 + 基本信息                                 │    │
│  │  ├── 搜索栏 (全局搜索)                                   │    │
│  │  ├── 维度概览卡片 (5个L1维度，显示节点数量)              │    │
│  │  │   └── 点击 → 进入维度详情                             │    │
│  │  └── 精选内容流 (最近更新/高置信度节点)                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  模式二: 维度详情 (DimensionDetailView)                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  🔍 维度深入查看                                         │    │
│  │  ├── L2 分组标签 (横向滚动切换)                          │    │
│  │  ├── L3 节点列表 (按类型差异化展示)                      │    │
│  │  └── 节点详情 (Sheet 弹出)                               │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 导航结构

```
重构后 (2层 + 搜索):

LifeStoryView (总览)
    │
    ├── 搜索 → SearchResultsView → NodeDetailSheet
    │
    └── 点击维度卡片 → DimensionDetailView → NodeDetailSheet
                            │
                            └── L2 标签切换 (同页面内)
```

---

## Components

### 1. LifeReviewScreen (主页面)

替代现有的 `DimensionProfileScreen`，在单一可滚动视图中展示所有有数据的维度。

```swift
/// 人生回顾主页面 - 沉浸式展示所有维度数据
public struct LifeReviewScreen: View {
    @StateObject private var viewModel = LifeReviewViewModel()
    @State private var selectedNode: KnowledgeNode?
    @State private var scrollTarget: String?
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                        // 用户头部信息
                        UserHeaderSection(profile: viewModel.userProfile)
                        
                        // 维度快速导航
                        DimensionQuickNav(
                            dimensions: viewModel.populatedDimensions,
                            onSelect: { scrollTarget = $0 }
                        )
                        
                        // 各维度内容区块
                        ForEach(viewModel.populatedDimensions) { dimension in
                            DimensionSectionView(
                                dimension: dimension,
                                onNodeTap: { selectedNode = $0 }
                            )
                            .id(dimension.level1.rawValue)
                        }
                        
                        // 空状态
                        if viewModel.populatedDimensions.isEmpty {
                            EmptyStateView()
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: scrollTarget) { target in
                    if let target {
                        withAnimation { proxy.scrollTo(target, anchor: .top) }
                    }
                }
            }
            .sheet(item: $selectedNode) { node in
                KnowledgeNodeDetailSheet(node: node, viewModel: viewModel)
            }
        }
    }
}
```

### 2. DimensionSectionView (维度区块)

展示单个 L1 维度及其所有 L2/L3 内容。

```swift
/// 维度区块 - 展示 L1 维度下的所有内容
public struct DimensionSectionView: View {
    let dimension: PopulatedDimension
    let onNodeTap: (KnowledgeNode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // L1 维度标题 (Sticky Header)
            DimensionHeader(
                level1: dimension.level1,
                nodeCount: dimension.totalNodeCount
            )
            
            // L2 分组
            ForEach(dimension.level2Groups) { group in
                Level2GroupView(
                    group: group,
                    color: dimension.color,
                    onNodeTap: onNodeTap
                )
            }
        }
        .padding(.vertical, 8)
    }
}
```

### 3. Level2GroupView (L2 分组)

展示 L2 维度下的所有节点，按 L3 细分。

```swift
/// L2 分组视图
public struct Level2GroupView: View {
    let group: Level2Group
    let color: Color
    let onNodeTap: (KnowledgeNode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // L2 标题
            Text(group.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            // 节点列表 (按 ContentType 差异化展示)
            FlowLayout(spacing: 8) {
                ForEach(group.nodes) { node in
                    KnowledgeNodeCard(
                        node: node,
                        color: color,
                        onTap: { onNodeTap(node) }
                    )
                }
            }
        }
    }
}
```

### 4. KnowledgeNodeCard (节点卡片)

根据 `NodeContentType` 差异化展示节点。

```swift
/// 知识节点卡片 - 根据 ContentType 差异化展示
public struct KnowledgeNodeCard: View {
    let node: KnowledgeNode
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            content
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var content: some View {
        switch node.contentType {
        case .aiTag:
            AITagCardStyle(node: node, color: color)
        case .subsystem:
            SubsystemCardStyle(node: node, color: color)
        case .entityRef:
            EntityRefCardStyle(node: node, color: color)
        case .nestedList:
            NestedListCardStyle(node: node, color: color)
        }
    }
}

/// AI 标签样式 - 紧凑标签
private struct AITagCardStyle: View {
    let node: KnowledgeNode
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(node.name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let confidence = node.tracking.source.confidence, confidence < 0.8 {
                ConfidenceIndicator(confidence: confidence)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}
```

### 5. KnowledgeNodeDetailSheet (节点详情)

以 Sheet 形式展示节点详情，支持溯源和编辑。

```swift
/// 节点详情 Sheet
public struct KnowledgeNodeDetailSheet: View {
    let node: KnowledgeNode
    @ObservedObject var viewModel: LifeReviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息
                    NodeBasicInfoSection(node: node)
                    
                    // 置信度与来源
                    NodeSourceSection(node: node)
                    
                    // 溯源链接
                    if !node.sourceLinks.isEmpty {
                        SourceLinksSection(sourceLinks: node.sourceLinks)
                    }
                    
                    // 关联人物
                    if !node.relatedEntityIds.isEmpty {
                        RelatedEntitiesSection(entityIds: node.relatedEntityIds)
                    }
                    
                    // 子节点 (nested_list)
                    if let childIds = node.childNodeIds, !childIds.isEmpty {
                        ChildNodesSection(
                            childIds: childIds,
                            viewModel: viewModel
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(node.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("编辑", systemImage: "pencil") { }
                        Button("确认", systemImage: "checkmark") { }
                        Button("删除", systemImage: "trash", role: .destructive) { }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
```

### 6. TestDataGenerator (测试数据生成器)

生成覆盖所有维度和 ContentType 的测试数据。

```swift
/// 测试数据生成器
public struct TestDataGenerator {
    
    /// 生成完整测试数据集
    public static func generateTestProfile() -> NarrativeUserProfile {
        var profile = NarrativeUserProfile.empty
        profile.knowledgeNodes = generateTestNodes()
        profile.staticCore = generateTestStaticCore()
        return profile
    }
    
    /// 生成测试节点 (覆盖所有维度和 ContentType)
    private static func generateTestNodes() -> [KnowledgeNode] {
        var nodes: [KnowledgeNode] = []
        
        // 为每个 L1 维度生成节点
        for level1 in DimensionHierarchy.coreDimensions {
            nodes.append(contentsOf: generateNodesForLevel1(level1))
        }
        
        return nodes
    }
    
    private static func generateNodesForLevel1(_ level1: DimensionHierarchy.Level1) -> [KnowledgeNode] {
        // 实现详见 tasks.md
    }
}
```

---

## Interfaces

### LifeReviewViewModel

```swift
@MainActor
public final class LifeReviewViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 用户画像数据
    @Published public var userProfile: NarrativeUserProfile?
    
    /// 有数据的维度列表 (已过滤空维度)
    @Published public var populatedDimensions: [PopulatedDimension] = []
    
    /// 加载状态
    @Published public var isLoading: Bool = false
    
    /// 搜索文本
    @Published public var searchText: String = ""
    
    // MARK: - Public Methods
    
    /// 加载数据
    func loadData()
    
    /// 刷新数据
    func refresh()
    
    /// 获取节点详情
    func getNode(id: String) -> KnowledgeNode?
    
    /// 获取子节点
    func getChildNodes(parentId: String) -> [KnowledgeNode]
    
    /// 搜索节点
    func searchNodes(query: String) -> [KnowledgeNode]
    
    /// 导入测试数据
    func importTestData()
}
```

### Data Models

```swift
/// 有数据的维度 (用于 UI 展示)
public struct PopulatedDimension: Identifiable {
    public let id: String
    public let level1: DimensionHierarchy.Level1
    public let level2Groups: [Level2Group]
    public let totalNodeCount: Int
    public let color: Color
    public let icon: String
}

/// L2 分组
public struct Level2Group: Identifiable {
    public let id: String
    public let level2: String
    public let displayName: String
    public let nodes: [KnowledgeNode]
}
```

---

## Data Models

### 现有模型复用

本设计复用以下现有数据模型：

| 模型 | 文件位置 | 用途 |
|------|----------|------|
| `KnowledgeNode` | `KnowledgeNodeModels.swift` | 知识节点核心结构 |
| `NodeContentType` | `DimensionHierarchyModels.swift` | 节点内容类型 |
| `DimensionHierarchy` | `DimensionHierarchyModels.swift` | 维度层级定义 |
| `SourceLink` | `KnowledgeNodeModels.swift` | 溯源链接 |
| `NarrativeUserProfile` | `NarrativeProfileModels.swift` | 用户画像 |

### 新增 UI 模型

```swift
/// 维度颜色配置
public struct DimensionColors {
    public static let colors: [DimensionHierarchy.Level1: Color] = [
        .self_: Color.indigo,
        .material: Color.green,
        .achievements: Color.orange,
        .experiences: Color.blue,
        .spirit: Color.purple
    ]
    
    public static func color(for level1: DimensionHierarchy.Level1) -> Color {
        colors[level1] ?? .gray
    }
}

/// 维度图标配置
public struct DimensionIcons {
    public static let icons: [DimensionHierarchy.Level1: String] = [
        .self_: "person.fill",
        .material: "dollarsign.circle.fill",
        .achievements: "star.fill",
        .experiences: "airplane",
        .spirit: "brain.head.profile"
    ]
    
    public static func icon(for level1: DimensionHierarchy.Level1) -> String {
        icons[level1] ?? "folder.fill"
    }
}
```

---

## Correctness Properties

### 数据完整性

1. **空维度过滤**: 只有包含至少一个 KnowledgeNode 的维度才会显示
2. **层级路径验证**: 所有节点的 nodeType 必须符合 `level1.level2.level3` 格式
3. **ContentType 一致性**: 节点的 contentType 必须与其数据结构匹配

### UI 状态一致性

1. **选中状态**: 同一时间只能有一个节点处于详情展示状态
2. **滚动位置**: 锚点跳转后，目标维度应可见于视口顶部
3. **加载状态**: isLoading 为 true 时，UI 应显示加载指示器

### 性能约束

1. **懒加载**: 使用 LazyVStack 确保只渲染可见内容
2. **节点数量**: 单个维度最多显示 100 个节点，超出时分页
3. **图片缓存**: 头像等图片资源应使用缓存机制

---

## Error Handling

### 数据加载错误

```swift
enum ProfileLoadError: LocalizedError {
    case repositoryUnavailable
    case dataCorrupted
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
        case .repositoryUnavailable:
            return "无法访问数据存储"
        case .dataCorrupted:
            return "数据文件损坏"
        case .parseError(let detail):
            return "数据解析失败: \(detail)"
        }
    }
}
```

### 错误处理策略

| 错误类型 | 处理方式 | 用户提示 |
|----------|----------|----------|
| 数据加载失败 | 显示空状态 + 重试按钮 | "加载失败，点击重试" |
| 节点详情加载失败 | 关闭 Sheet + Toast | "无法加载详情" |
| 测试数据导入失败 | Alert 提示 | "导入失败，请重试" |
| 无效的 nodeType | 跳过该节点 | 无 (静默处理) |

### 错误恢复

```swift
extension LifeReviewViewModel {
    func handleLoadError(_ error: ProfileLoadError) {
        isLoading = false
        
        switch error {
        case .repositoryUnavailable:
            // 尝试重新初始化 Repository
            retryAfterDelay(seconds: 2)
        case .dataCorrupted:
            // 提示用户数据损坏，提供重置选项
            showDataCorruptedAlert = true
        case .parseError:
            // 记录日志，显示部分数据
            loadPartialData()
        }
    }
}
```

---

## Testing Strategy

### 单元测试

| 测试目标 | 测试内容 | 文件 |
|----------|----------|------|
| LifeReviewViewModel | 数据加载、过滤、搜索 | `LifeReviewViewModelTests.swift` |
| TestDataGenerator | 测试数据生成完整性 | `TestDataGeneratorTests.swift` |
| PopulatedDimension | 维度分组逻辑 | `PopulatedDimensionTests.swift` |

### UI 测试

| 测试场景 | 验证点 |
|----------|--------|
| 空状态 | 显示引导提示 |
| 有数据 | 正确显示所有有数据的维度 |
| 节点点击 | Sheet 正确弹出 |
| 锚点跳转 | 滚动到目标位置 |
| 测试数据导入 | 数据正确显示 |

### 测试数据覆盖

测试数据必须覆盖：

- [ ] 5 个核心 L1 维度
- [ ] 15 个 L2 维度
- [ ] 4 种 NodeContentType
- [ ] 不同置信度 (0.3, 0.5, 0.7, 0.9, 1.0)
- [ ] 有/无 sourceLinks
- [ ] 有/无 relatedEntityIds
- [ ] 有/无 childNodeIds

---

## File Structure

```
guanji0.34/Features/Profile/
├── LifeReview/                          # 新增目录
│   ├── LifeReviewScreen.swift           # 主页面
│   ├── LifeReviewViewModel.swift        # ViewModel
│   ├── Components/
│   │   ├── UserHeaderSection.swift      # 用户头部
│   │   ├── DimensionQuickNav.swift      # 快速导航
│   │   ├── DimensionSectionView.swift   # 维度区块
│   │   ├── Level2GroupView.swift        # L2 分组
│   │   ├── KnowledgeNodeCard.swift      # 节点卡片
│   │   ├── ConfidenceIndicator.swift    # 置信度指示器
│   │   ├── EmptyStateView.swift         # 空状态
│   │   └── FlowLayout.swift             # 流式布局
│   └── Detail/
│       ├── KnowledgeNodeDetailSheet.swift  # 详情 Sheet
│       ├── NodeBasicInfoSection.swift      # 基本信息
│       ├── NodeSourceSection.swift         # 来源信息
│       ├── SourceLinksSection.swift        # 溯源链接
│       ├── RelatedEntitiesSection.swift    # 关联人物
│       └── ChildNodesSection.swift         # 子节点
├── TestData/                            # 新增目录
│   └── TestDataGenerator.swift          # 测试数据生成
├── Models/
│   ├── PopulatedDimension.swift         # UI 数据模型
│   └── DimensionColors.swift            # 颜色配置
└── (现有文件保留，后续可废弃)
    ├── DimensionProfileScreen.swift
    ├── DimensionProfileViewModel.swift
    └── ...
```

---

## Migration Plan

### Phase 1: 新增组件 (不影响现有功能)

1. 创建 `LifeReview/` 目录结构
2. 实现 `LifeReviewViewModel`
3. 实现基础 UI 组件
4. 实现 `TestDataGenerator`

### Phase 2: 集成测试

1. 在 DataMaintenanceScreen 添加入口
2. 测试数据导入功能
3. 验证所有 ContentType 展示

### Phase 3: 替换入口

1. 更新导航入口指向 `LifeReviewScreen`
2. 保留旧页面作为备份
3. 收集用户反馈

### Phase 4: 清理

1. 移除旧的 Profile 页面
2. 更新文档
3. 完成迁移

---

## Dependencies

### 现有依赖

- `NarrativeUserProfileRepository` - 数据存储
- `KnowledgeNode` / `DimensionHierarchy` - 数据模型
- `Colors` - 设计系统颜色

### 新增依赖

无外部依赖，全部使用 SwiftUI 原生组件。

---

## Accessibility

### VoiceOver 支持

```swift
// 示例：节点卡片无障碍
KnowledgeNodeCard(node: node, color: color, onTap: onTap)
    .accessibilityLabel("\(node.name), \(node.contentType.displayName)")
    .accessibilityHint("双击查看详情")
    .accessibilityAddTraits(.isButton)
```

### 动态字体

所有文本使用系统字体，支持 Dynamic Type：

```swift
Text(node.name)
    .font(.subheadline)  // 自动适配 Dynamic Type
```

### 颜色对比度

- 所有文本颜色与背景对比度 ≥ 4.5:1
- 使用系统语义颜色 (Color.primary, Color.secondary)
- 支持 Dark Mode

---

## Performance Considerations

### 懒加载

```swift
LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
    // 只渲染可见内容
}
```

### 数据预处理

```swift
// 在 ViewModel 中预处理数据，避免 View 中计算
func buildPopulatedDimensions() {
    // 一次性计算，缓存结果
    populatedDimensions = allNodes
        .grouped(by: \.level1Dimension)
        .filter { !$0.value.isEmpty }
        .map { PopulatedDimension(...) }
}
```

### 图片优化

- 使用 Asset Catalog 管理图片
- 支持 @2x/@3x 分辨率
- 头像使用圆形裁剪，减少渲染复杂度
