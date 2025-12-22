# 每日数据导出指南

> 返回 [文档中心](INDEX.md)

## 📦 功能概述

每日数据导出功能允许你将某一天的所有数据导出为纯文本格式，方便备份、分享或外部分析。

### 导出内容

导出文件包含以下数据（如果当天有记录）：

1. **时间轴数据** - 场景、旅程、日记条目
2. **AI 对话** - 与 AI 的完整对话记录
3. **问题与思考** - 时间胶囊问题
4. **心境记录** - 情绪状态记录
5. **每日追踪** - 身体能量、心情天气、活动记录

### 不包含的内容

- 图片、视频、音频等媒体文件（仅显示占位符）
- L4 常量数据（地点映射、关系画像等）

---

## 🚀 使用方法

### 方法 1: 代码调用

```swift
import Foundation

// 导出今天的数据
let today = DateUtilities.today
let exportedText = DailyDataExporter.exportDay(today)

// 保存到文件
let fileName = "guanji_export_\(today).txt"
if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
    let fileURL = documentsURL.appendingPathComponent(fileName)
    try? exportedText.write(to: fileURL, atomically: true, encoding: .utf8)
    print("Exported to: \(fileURL.path)")
}

// 或者分享
let activityVC = UIActivityViewController(
    activityItems: [exportedText],
    applicationActivities: nil
)
present(activityVC, animated: true)
```

### 方法 2: 批量导出

```swift
// 导出最近 7 天的数据
let calendar = Calendar.current
for i in 0..<7 {
    if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
        let dayId = DateUtilities.format(date)
        let exported = DailyDataExporter.exportDay(dayId)
        
        // 保存到文件
        let fileName = "guanji_\(dayId).txt"
        // ... 保存逻辑
    }
}
```

### 方法 3: 导出日期范围

```swift
func exportDateRange(from startDate: String, to endDate: String) -> String {
    var allExports = ""
    
    guard let start = DateUtilities.parse(startDate),
          let end = DateUtilities.parse(endDate) else {
        return "Invalid date format"
    }
    
    var currentDate = start
    while currentDate <= end {
        let dayId = DateUtilities.format(currentDate)
        allExports += DailyDataExporter.exportDay(dayId)
        allExports += "\n\n"
        
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
    }
    
    return allExports
}

// 使用
let exports = exportDateRange(from: "2024.12.01", to: "2024.12.31")
```

---

## 📄 导出格式示例

```
============================================================
观己 Guanji - 每日数据导出
Daily Data Export
============================================================
日期 Date: 2024.12.18
导出时间 Exported: 2024.12.18 15:30:45
============================================================

## 📅 时间轴 Timeline

**标题 Title**: 充实的一天
**天气 Weather**: 晴
**标签 Tags**: work, social, health

### 📍 场景 Scene: 家
**时间 Time**: 08:00-09:00

[08:15] [health] [现在 Present] 晨跑 5 公里
[08:45] [life] [现在 Present] 做早餐

### 🚗 旅程 Journey
**起点 From**: 家
**终点 To**: 公司
**方式 Mode**: subway
**时长 Duration**: 30分钟

[09:15] [现在 Present] 地铁上听播客

### 📍 场景 Scene: 公司
**时间 Time**: 09:30-18:00

[10:00] [work] [现在 Present] 完成项目设计文档
[14:30] [work] [现在 Present] 团队会议讨论新功能

## 💬 AI 对话 AI Conversations

### 对话 Conversation: 关于职业规划的讨论

**👤 我 Me** [10:30]
我最近在考虑职业发展方向，有点迷茫

**🤖 AI** [10:31]
我理解你的困惑。让我们一起梳理一下...

_💭 思考过程 Thinking: 用户表达了职业困惑，需要引导其思考..._

----------------------------------------

## ❓ 问题与思考 Questions & Reflections

**问题 Question**: 一年后的自己，你对现在的选择满意吗？
**创建时间 Created**: 2024.12.18
**交付日期 Delivery**: 2025.12.18
**间隔天数 Interval**: 365 天 days

## 🧠 心境记录 Mind State Records

**情绪值 Valence**: 75
**标签 Labels**: 平静, 专注
**影响因素 Influences**: 工作顺利, 天气好
**记录时间 Recorded**: 2024.12.18 20:00:00

## 📊 每日追踪 Daily Tracker

**身体能量 Body Energy**: 70/100
  Level: body_fresh

**心情天气 Mood Weather**: 75/100

**活动记录 Activities**:

- **activity_work**
  陪伴 Companions: companion_alone
  详情 Details: 完成设计文档
  标签 Tags: 2 个 items

- **activity_exercise**
  陪伴 Companions: companion_alone
  详情 Details: 晨跑
  标签 Tags: 1 个 items

============================================================
导出完成 Export Complete
============================================================
```

---

## 🔧 高级用法

### 自定义导出格式

如果需要自定义导出格式，可以修改 `DailyDataExporter.swift` 中的导出函数：

```swift
// 自定义时间轴导出
private static func exportTimeline(_ timeline: DailyTimeline) -> String {
    var output = "## 时间轴\n\n"
    
    // 自定义格式...
    
    return output
}
```

### 导出为 JSON

```swift
// 如果需要 JSON 格式，可以直接序列化模型
let timeline = TimelineRepository.shared.getDailyTimeline(for: dayId)
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
if let jsonData = try? encoder.encode(timeline),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)
}
```

### 导出为 Markdown

```swift
// 修改导出函数，使用 Markdown 格式
// 例如：使用 # ## ### 标题，使用 - 列表等
```

---

## 📱 UI 集成建议

### 在 Profile 页面添加导出按钮

```swift
// ProfileScreen.swift
Button(action: {
    let today = DateUtilities.today
    let exported = DailyDataExporter.exportDay(today)
    
    // 显示分享面板
    let activityVC = UIActivityViewController(
        activityItems: [exported],
        applicationActivities: nil
    )
    
    // 呈现分享面板
    // ...
}) {
    Label("导出今日数据", systemImage: "square.and.arrow.up")
}
```

### 在 History 页面添加导出选项

```swift
// HistoryViewModel.swift
func exportDay(_ dayId: String) {
    let exported = DailyDataExporter.exportDay(dayId)
    
    // 保存或分享
    shareExportedData(exported, for: dayId)
}
```

---

## ⚠️ 注意事项

### 隐私保护

- 导出的文本包含所有个人数据，请妥善保管
- 分享前请确认接收方可信
- 建议加密存储导出文件

### 性能考虑

- 单日导出通常很快（< 100ms）
- 批量导出大量日期时，建议在后台线程执行
- 导出文件大小取决于当天数据量

### 数据完整性

- 导出时会自动过滤空数据
- 媒体文件仅显示占位符，不包含实际文件
- 确保日期格式为 `yyyy.MM.dd`

---

## 🧪 测试

运行测试验证导出功能：

```swift
// 在 Xcode 中运行
DailyDataExporterTests.runAll()

// 或单独测试
DailyDataExporterTests.testExportToday()
DailyDataExporterTests.testExportSpecificDate("2024.12.18")
```

---

## 📚 相关文档

- [数据格式标准](DATA_FORMAT_STANDARD.md)
- [数据架构](architecture/data-architecture.md)
- [Repository 接口](api/repositories.md)

---

**版本**: v1.0.0  
**作者**: Kiro AI  
**更新日期**: 2024-12-18  
**状态**: 已发布
