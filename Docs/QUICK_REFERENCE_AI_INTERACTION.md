# AI 消息交互快速参考

> 返回 [文档中心](INDEX.md)

## 🎯 用户操作

### 复制消息

**方式 1: 快速按钮**
- 位置：AI 消息时间戳右侧
- 图标：📄 文档图标
- 反馈：点击后显示 ✓ 对勾 2 秒

**方式 2: 长按菜单**
- 操作：长按任意消息
- 选项：复制消息

**方式 3: 文本选择**
- 操作：直接选择文本内容
- 支持：所有文本内容

### 重新生成 AI 回复

**方式 1: 快速按钮**
- 位置：AI 消息时间戳右侧
- 图标：🔄 刷新图标
- 效果：删除该消息及后续消息，重新生成

**方式 2: 长按菜单**
- 操作：长按 AI 消息
- 选项：重新生成

### 复制含思考过程

**条件**: AI 消息包含推理内容

**操作**: 长按 AI 消息 → 选择"复制（含思考过程）"

**格式**:
```
[Thinking]
推理过程内容...

[Response]
最终回复内容...
```

## 🔧 开发者参考

### MessageBubble 使用

```swift
MessageBubble(
    message: aiMessage,
    showThinking: true,
    onRegenerate: {
        // 重新生成回调
        viewModel.regenerateMessage(aiMessage)
    }
)
```

### 参数说明

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `message` | `AIMessage` | ✅ | 要显示的消息 |
| `showThinking` | `Bool` | ❌ | 是否显示思考过程（默认 true） |
| `onRegenerate` | `(() -> Void)?` | ❌ | 重新生成回调（仅 AI 消息需要） |

### ViewModel 方法

```swift
// 重新生成指定消息
viewModel.regenerateMessage(message)

// 重试最后一条失败的消息
viewModel.retryLastMessage()

// 取消当前流式响应
viewModel.cancelStreaming()
```

## 📱 交互设计

### 视觉层次

```
┌─────────────────────────────────┐
│ AI 消息气泡                      │
│                                 │
│ 消息内容...                      │
│                                 │
├─────────────────────────────────┤
│ 10:30  📄 🔄                    │  ← 时间戳 + 操作按钮
└─────────────────────────────────┘
```

### 长按菜单

**用户消息**:
```
┌──────────────────┐
│ 📄 复制消息       │
└──────────────────┘
```

**AI 消息（无思考）**:
```
┌──────────────────┐
│ 📄 复制消息       │
│ 🔄 重新生成       │
└──────────────────┘
```

**AI 消息（有思考）**:
```
┌──────────────────────────┐
│ 📄 复制消息               │
│ 🔄 重新生成               │
│ 📋 复制（含思考过程）      │
└──────────────────────────┘
```

## 🎨 样式规范

### 按钮样式

```swift
// 复制按钮
Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
    .font(.system(size: 12))
    .foregroundColor(showCopied ? Colors.emerald : Colors.slate500)

// 重新生成按钮
Image(systemName: "arrow.clockwise")
    .font(.system(size: 12))
    .foregroundColor(Colors.slate500)
```

### 动画效果

```swift
// 复制反馈动画
withAnimation(.easeInOut(duration: 0.2)) {
    showCopied = true
}

// 2 秒后恢复
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    withAnimation(.easeInOut(duration: 0.2)) {
        showCopied = false
    }
}
```

## 🧪 测试场景

### 功能测试

- [ ] 点击复制按钮，内容复制到剪贴板
- [ ] 复制后显示对勾图标 2 秒
- [ ] 长按消息显示上下文菜单
- [ ] 用户消息只显示复制选项
- [ ] AI 消息显示复制和重新生成选项
- [ ] 有思考的 AI 消息显示复制含思考选项
- [ ] 点击重新生成，删除消息并重新请求
- [ ] 复制含思考包含完整格式

### 边界测试

- [ ] 流式响应中不能重新生成
- [ ] 用户消息不显示重新生成按钮
- [ ] 空消息不能复制
- [ ] 重新生成删除后续所有消息

## 📊 性能考虑

### 优化点

1. **状态管理**: 使用 `@State` 管理临时 UI 状态
2. **回调优化**: 使用可选闭包避免不必要的内存占用
3. **动画性能**: 使用简单的 easeInOut 动画
4. **触觉反馈**: 使用轻量级 light impact

### 内存管理

```swift
// 使用 weak self 避免循环引用
onContentUpdate: { [weak self] content in
    DispatchQueue.main.async {
        self?.streamingContent = content
    }
}
```

## 🔗 相关文档

- [AI 对话模块](features/ai-conversation.md)
- [MessageBubble 组件](components/molecules.md)
- [MVVM 模式](architecture/mvvm-pattern.md)

---

**版本**: v1.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-18  
**状态**: 已发布
