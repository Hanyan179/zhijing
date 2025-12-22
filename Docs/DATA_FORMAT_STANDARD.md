# 观己数据格式标准

> 返回 [文档中心](INDEX.md)

## 📅 日期格式标准

**统一格式**: `yyyy.MM.dd`

### 为什么选择这个格式？

1. **可读性**: 点号分隔比短横线更清晰
2. **排序友好**: 字符串排序 = 时间排序
3. **国际化**: 年-月-日顺序符合 ISO 8601 逻辑顺序
4. **一致性**: 整个系统使用同一格式

### 示例

```swift
"2024.12.18"  // ✅ 正确
"2024-12-18"  // ❌ 错误
"12/18/2024"  // ❌ 错误
"18.12.2024"  // ❌ 错误
```

---

## 🗂️ 所有模型的日期字段

### L1 流水数据

| 模型 | 日期字段 | 格式 | 说明 |
|------|---------|------|------|
| **DailyTimeline** | `date` | yyyy.MM.dd | 每日索引 |
| **AIConversation** | `dayId` | yyyy.MM.dd | 对话主日期 |
| **AIConversation** | `associatedDays` | yyyy.MM.dd[] | 跨天对话的所有日期 |
| **QuestionEntry** | `dayId` | yyyy.MM.dd | 问题创建日期 |
| **QuestionEntry** | `created_at` | yyyy.MM.dd | 创建时间 |
| **QuestionEntry** | `delivery_date` | yyyy.MM.dd | 交付日期 |
| **MindStateRecord** | `date` | yyyy.MM.dd | 心境记录日期 |
| **DailyTrackerRecord** | `date` | yyyy.MM.dd | 追踪记录日期 |

### 时间戳字段

对于精确到时分秒的时间，使用 `Date` 类型或 ISO 8601 字符串：

| 模型 | 时间戳字段 | 类型 | 说明 |
|------|-----------|------|------|
| **DailyTimeline** | `createdAt`, `updatedAt` | Date | Swift Date 对象 |
| **AIConversation** | `createdAt`, `updatedAt` | Date | Swift Date 对象 |
| **AIMessage** | `timestamp` | Date | 消息时间 |
| **JournalEntry** | `timestamp` | String | HH:mm 格式 |
| **MindStateRecord** | `createdAt` | Date | Swift Date 对象 |
| **DailyTrackerRecord** | `createdAt`, `updatedAt` | Date | Swift Date 对象 |

---

## 🛠️ 工具函数

### DateUtilities

```swift
// 获取今天的日期字符串
let today = DateUtilities.today  // "2024.12.18"

// Date 转字符串
let dateString = DateUtilities.format(someDate)  // "2024.12.18"

// 字符串转 Date
if let date = DateUtilities.parse("2024.12.18") {
    // 使用 date
}
```

### 日期比较

```swift
// 字符串可以直接比较（因为格式统一）
if dayId1 > dayId2 {
    // dayId1 是更晚的日期
}

// 排序
let sortedDays = days.sorted()  // 自动按时间顺序排序
```

---

## ⚠️ 迁移注意事项

### 从旧格式迁移

如果你的数据使用了旧格式（如 `YYYY-MM-DD`），需要进行迁移：

```swift
// 迁移函数
func migrateDateFormat(_ oldDate: String) -> String {
    // "2024-12-18" → "2024.12.18"
    return oldDate.replacingOccurrences(of: "-", with: ".")
}

// 批量迁移
func migrateAllRecords() {
    var records = loadAllRecords()
    for i in 0..<records.count {
        records[i].date = migrateDateFormat(records[i].date)
    }
    saveAllRecords(records)
}
```

### 兼容性处理

在读取数据时，可以添加兼容性处理：

```swift
func normalizeDate(_ date: String) -> String {
    // 支持两种格式
    if date.contains("-") {
        return date.replacingOccurrences(of: "-", with: ".")
    }
    return date
}
```

---

## 📋 检查清单

在添加新模型或修改现有模型时，请确认：

- [ ] 所有日期字段使用 `yyyy.MM.dd` 格式
- [ ] 使用 `DateUtilities.today` 获取当前日期
- [ ] 使用 `DateUtilities.format()` 转换 Date 对象
- [ ] 使用 `DateUtilities.parse()` 解析日期字符串
- [ ] 更新相关文档说明日期格式
- [ ] 添加单元测试验证日期格式

---

## 🔍 验证方法

### 单元测试

```swift
func testDateFormat() {
    let today = DateUtilities.today
    
    // 验证格式
    let pattern = #"^\d{4}\.\d{2}\.\d{2}$"#
    XCTAssertTrue(today.range(of: pattern, options: .regularExpression) != nil)
    
    // 验证可解析
    XCTAssertNotNil(DateUtilities.parse(today))
}
```

### 代码审查

使用 grep 搜索可能的格式不一致：

```bash
# 搜索可能使用了错误格式的地方
grep -r "YYYY-MM-DD" guanji0.34/
grep -r "yyyy-MM-dd" guanji0.34/
grep -r 'replacingOccurrences.*"-".*"."' guanji0.34/
```

---

**版本**: v1.0.0  
**作者**: Kiro AI  
**更新日期**: 2024-12-18  
**状态**: 已发布
