# 观己 (Guanji) 更新日志

## [v1.1.0] - 2024-12-18

### AI 对话模块增强

#### 新增功能

**消息交互增强**
- ✅ 长按消息显示上下文菜单
  - 复制消息内容
  - 重新生成 AI 回复（仅 AI 消息）
  - 复制含思考过程（仅带推理的 AI 消息）
  
- ✅ 消息底部快速操作按钮
  - 复制按钮（带视觉反馈）
  - 重新生成按钮（仅 AI 消息）
  
- ✅ 触觉反馈
  - 复制操作时提供轻触觉反馈
  - 增强用户体验

**重新生成机制**
- 删除选定消息及之后的所有消息
- 自动重新请求 AI 响应
- 保持对话上下文连贯性

#### 技术改进

**MessageBubble 组件**
- 新增 `onRegenerate` 回调参数
- 新增 `showCopied` 状态管理
- 实现上下文菜单 `contextMenu`
- 实现消息操作视图 `messageActionsView`
- 新增复制方法：`copyMessage()`, `copyWithThinking()`

**AIConversationViewModel**
- 新增 `regenerateMessage(_ message: AIMessage)` 方法
- 支持删除消息范围并重新生成

**本地化字符串**
- `AI.Message.Copy` - 复制消息
- `AI.Message.Regenerate` - 重新生成
- `AI.Message.CopyWithThinking` - 复制（含思考过程）

#### 测试覆盖

**新增测试文件**
- `Tests/MessageBubbleTests.swift`
  - 复制功能测试
  - 上下文菜单测试
  - 重新生成回调测试
  - 消息操作可见性测试

#### 文档更新

**更新文档**
- `Docs/features/ai-conversation.md`
  - 新增"消息交互增强"章节
  - 更新 ViewModel 方法列表
  - 新增本地化字符串说明
  - 新增测试覆盖说明

#### 参考实现

借鉴业界最佳实践：
- ChatGPT: 长按消息显示操作菜单
- Claude: 消息底部操作按钮
- Gemini: 重新生成功能
- Perplexity: 复制含思考过程

---

## [v1.0.0] - 2024-12-17

### 初始版本

- 完整的 AI 对话功能
- 流式响应支持
- 思考模式
- 富文本渲染
- 对话历史管理

---

**文档版本**: v2.0.0  
**最后更新**: 2024-12-18
