# Implementation Plan: Swift Warnings Cleanup

## Overview

系统性清理 Xcode 编译警告，按文件分组进行修复，每组修复后验证编译。

## Tasks

- [x] 1.
 修复 TimelineViewModel 未使用变量警告
  - [x] 1.1 移除第 153 行未使用的 `ts` 变量
    - 将 `let ts = entry.timestamp` 改为 `_ = entry.timestamp` 或直接删除
    - _Requirements: 6.2_
  - [x] 1.2 移除第 216 行未使用的 `j` 变量
    - 将 `let j` 改为 `_` 或直接删除
    - _Requirements: 6.3_

- [x] 2. 修复 KnowledgeNodeModels 弃用 API 警告
  - [x] 2.1 重构 KnowledgeNode 解码器中的迁移逻辑
    - 避免直接访问 `tracking.source.extractedFrom`
    - 使用临时变量或重构解码顺序
    - _Requirements: 2.1, 2.2_
  - [x] 2.2 修复 NodeSource 初始化器调用
    - 在第 937 行避免传递 extractedFrom 参数
    - _Requirements: 2.3_
  - [x] 2.3 编写属性测试验证向后兼容解码
    - **Property 1: KnowledgeNode 向后兼容解码**
    - **Validates: Requirements 2.2**

- [x] 3. Checkpoint - 验证编译
  - 确保 TimelineViewModel 和 KnowledgeNodeModels 警告已消除
  - 运行现有测试确保功能正常

- [x] 4. 修复 InsightViewModel Swift 6 并发警告
  - [x] 4.1 修复 computeOverview 方法的 actor 隔离问题
    - 移除 nonisolated 标记或重构内部方法
    - 修复第 170-175, 183 行的 MainActor 调用警告
    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 4.2 修复 computeFeatureUsage 方法的 actor 隔离问题
    - 修复第 304-311, 323 行的 MainActor 调用警告
    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 4.3 修复 computeDataInsight 方法的 actor 隔离问题
    - 修复第 419-425, 434 行的 MainActor 调用警告
    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 4.4 移除不可达的 catch 块
    - 删除第 212, 232, 249, 280, 339, 352, 363, 388, 398, 409, 474, 495, 512, 547, 563, 655 行的不可达 catch 块
    - _Requirements: 3.4, 7.1, 7.2_
  - [x] 4.5 修复第 63 行缺少 await 的警告
    - 添加 await 关键字
    - _Requirements: 3.1_

- [x] 5. Checkpoint - 验证 InsightViewModel 修复
  - 确保 InsightViewModel 所有警告已消除
  - 运行 Insight 相关功能测试

- [x] 6. 修复 AIService/AIConversationRepository 编码警告
  - [x] 6.1 修复 AIConversationRepository 第 181 行 Encodable 警告
    - 确保 AIConversation 的 Encodable 实现不依赖 MainActor
    - _Requirements: 4.1_
  - [x] 6.2 修复 AIService 第 124, 133 行 Decodable 警告
    - 确保 APIErrorResponse 和 ChatCompletionResponse 的 Decodable 实现不依赖 MainActor
    - _Requirements: 4.2_

- [x] 7. 修复 MessageBubble MarkdownParser 警告
  - [x] 7.1 修复第 147 行 MainActor-isolated 静态方法调用
    - 确保 MarkdownParser.parse 是 nonisolated
    - 或在调用处使用正确的 actor 上下文
    - _Requirements: 5.1, 5.2_

- [x] 8. 修复 LocationService UI 阻塞警告
  - [x] 8.1 检查并修复第 48 行授权状态检查
    - 确保使用 manager.authorizationStatus 实例属性
    - 如果警告仍存在，检查 CLLocationManager.locationServicesEnabled() 调用
    - _Requirements: 1.1, 1.2_

- [x] 9. Final Checkpoint - 完整验证
  - 清理构建目录并重新编译
  - 确保所有目标警告已消除
  - 运行完整测试套件验证功能正常

## Notes

- 任务按依赖关系和复杂度排序，简单的先做
- 每个 Checkpoint 后验证编译和功能
- 所有任务都必须完成
- Swift 6 并发警告修复可能需要根据实际代码调整方案
