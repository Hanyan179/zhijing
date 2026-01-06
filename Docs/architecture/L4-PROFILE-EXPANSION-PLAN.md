# L4 层画像数据扩展规划

> 返回 [文档中心](../INDEX.md) | [数据架构](data-architecture.md)

## 📋 文档说明

本文档规划 L4 核心知识层的用户画像和关系画像的完整数据结构。

**核心设计理念**：
- 采用**三层维度架构 (Life OS)**：Level 1/2 固定，Level 3 由 AI 动态维护
- 使用**通用知识节点 (KnowledgeNode)** 结构，支持多种内容类型
- 支持**多对多关联**：一个维度可关联多条原始数据，一条数据可关联多个维度
- 支持**溯源追踪**：每个知识点都能追溯到原始数据来源
- 支持**置信度机制**：AI 提取的信息有置信度，随时间衰减或增强

**状态**: ⭐ P0 已实现（数据结构）

---

## 🎯 架构方案对比分析

### 方案A：三层维度架构（新设计）

```
┌─────────────────────────────────────────────────────────────┐
│                    Life OS 维度体系                          │
├─────────────────────────────────────────────────────────────┤
│  Level 1 (固定): 7大一级维度                                 │
│  ├── 本体 (Self)                                            │
│  ├── 物质 (Material)                                        │
│  ├── 成就 (Achievements)                                    │
│  ├── 阅历 (Experiences)                                     │
│  ├── 精神 (Spirit)                                          │
│  ├── 关系 (Relationships) [预留]                            │
│  └── AI偏好 (AI_Preferences) [预留]                         │
├─────────────────────────────────────────────────────────────┤
│  Level 2 (固定): 15个二级维度                                │
│  ├── 身份认同、身体状态、性格特质                            │
│  ├── 经济状况、物品与环境、生活保障                          │
│  ├── 事业发展、个人能力、成果展示                            │
│  ├── 文化娱乐、探索足迹、人生历程                            │
│  └── 意识形态、心理状态、思考感悟                            │
├─────────────────────────────────────────────────────────────┤
│  Level 3 (动态): AI维护的细分领域                            │
│  └── 由AI根据用户数据动态创建和维护                          │
└─────────────────────────────────────────────────────────────┘
```

### 方案B：原内核状态设计（现有设计）

```
┌─────────────────────────────────────────────────────────────┐
│                    KnowledgeNode 通用结构                    │
├─────────────────────────────────────────────────────────────┤
│  nodeCategory: common | personal                             │
│  nodeType: 可扩展字符串 (skill, value, goal, trait...)       │
│  + StaticCore (固定字段)                                     │
│  + RecentPortrait (AI生成)                                   │
└─────────────────────────────────────────────────────────────┘
```

### 对比分析

| 维度 | 方案A: 三层维度架构 | 方案B: 原内核状态设计 |
|------|---------------------|----------------------|
| **数据组织** | 层级清晰，有明确的分类体系 | 扁平化，依赖 nodeType 字符串 |
| **扩展性** | Level 3 由 AI 动态扩展 | nodeType 可自由扩展 |
| **AI维护难度** | 低：AI 只需在已知框架内填充 | 高：AI 需要理解整个 nodeType 体系 |
| **用户理解成本** | 低：符合人类认知的分类方式 | 中：需要理解 nodeType 含义 |
| **实现复杂度** | 中：需要维护维度层级关系 | 低：通用结构，无层级 |
| **数据一致性** | 高：有明确的归属路径 | 中：可能出现 nodeType 冲突 |
| **查询效率** | 高：可按层级索引 | 中：需要遍历 nodeType |
| **向后兼容** | 需要迁移映射 | 天然兼容 |

### 设计决策

**推荐方案：混合架构**

结合两种方案的优点：
1. **保留 KnowledgeNode 通用结构**：作为底层数据存储
2. **引入维度层级体系**：作为 nodeType 的组织框架
3. **nodeType 命名规范**：采用层级路径格式 `level1.level2.level3`

```swift
// 示例：nodeType 命名规范
"self.identity.social_roles"      // 本体 > 身份认同 > 社会角色
"material.economy.asset_status"   // 物质 > 经济状况 > 资产概况
"spirit.wisdom.reflections"       // 精神 > 思考感悟 > 反思复盘
```

**设计决策理由**：

1. **符合人类认知**：三层维度架构符合人们对"人生"的自然分类方式
2. **AI友好**：AI 在已知框架内填充数据，比自由创建 nodeType 更可控
3. **向后兼容**：通过 nodeType 命名规范，可以平滑迁移现有数据
4. **查询高效**：可按前缀过滤实现层级查询（如查询所有"本体"相关节点）
5. **扩展灵活**：Level 3 由 AI 动态创建，不受预定义限制

---


## 🌳 Life OS 维度体系定义

### 设计哲学

- **第1层 & 第2层**：标准化、固定，涵盖"正常人的大多数"情况
- **第3层**：预设通用细分领域，由 AI 动态维护、新增或更新
- **7个一级维度体系**：
  - 5个核心维度：本体、物质、成就、阅历、精神
  - 关系维度：独立子系统（本次暂不实现，但需预留接口）
  - AI偏好维度：独立子系统（本次暂不实现，但需预留接口）

### 一级维度 (Level 1) - 7个

| 维度 | 英文标识 | 说明 | 状态 |
|------|----------|------|------|
| 本体 | `self` | 关于"我是谁"的核心自我认知 | ✅ 实现 |
| 物质 | `material` | 物质世界的拥有与保障 | ✅ 实现 |
| 成就 | `achievements` | 事业发展与个人成就 | ✅ 实现 |
| 阅历 | `experiences` | 人生经历与文化体验 | ✅ 实现 |
| 精神 | `spirit` | 精神世界与内心状态 | ✅ 实现 |
| 关系 | `relationships` | 人际关系网络 | ⏳ 预留 |
| AI偏好 | `ai_preferences` | AI交互偏好设置 | ⏳ 预留 |

### 二级维度 (Level 2) - 15个

| 一级维度 | 二级维度 | 英文标识 | 说明 |
|----------|----------|----------|------|
| 本体 | 身份认同 | `identity` | 社会角色、职业身份、外在形象 |
| 本体 | 身体状态 | `physical` | 健康状况、睡眠质量、饮食习惯 |
| 本体 | 性格特质 | `personality` | 自我评价、行为偏好 |
| 物质 | 经济状况 | `economy` | 资产概况、消费行为、负债压力 |
| 物质 | 物品与环境 | `objects_space` | 常用物品、居住环境、收藏爱好 |
| 物质 | 生活保障 | `security` | 保险与风控 |
| 成就 | 事业发展 | `career` | 工作经历、商业活动 |
| 成就 | 个人能力 | `competencies` | 专业技能、学习进修、生活才艺 |
| 成就 | 成果展示 | `outcomes` | 个人作品、荣誉认可 |
| 阅历 | 文化娱乐 | `culture_entertainment` | 阅读体验、视听欣赏、游戏娱乐 |
| 阅历 | 探索足迹 | `exploration` | 旅行见闻、探店体验 |
| 阅历 | 人生历程 | `history` | 重要节点、往事回忆 |
| 精神 | 意识形态 | `ideology` | 价值观、愿景梦想 |
| 精神 | 心理状态 | `mental_state` | 情绪感受、压力来源 |
| 精神 | 思考感悟 | `wisdom` | 观点看法、反思复盘 |

### 三级维度 (Level 3) - 预设列表与范畴界定

三级维度由 AI 动态维护，以下为预设的通用细分领域。每个三级维度包含：
- **范畴界定 (Scope)**: 该维度涵盖的内容边界
- **常见举例 (Examples)**: 典型的知识节点示例
- **内容类型 (ContentType)**: 推荐使用的节点类型

> **注意**: 三级维度可由 AI 动态扩展，以下仅为预设的常见领域。

---

#### 本体维度 (self) 的三级预设

##### self.identity (身份认同)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `social_roles` | 社会角色 | 在家庭、社会中承担的角色身份 | 父亲、丈夫、儿子、女儿、朋友、邻居、志愿者 | ai_tag |
| `professional_identity` | 职业身份 | 职业相关的身份标签和定位 | 软件工程师、产品经理、创业者、自由职业者、学生 | ai_tag |
| `appearance_style` | 外在形象 | 个人形象、穿搭风格、外貌特征 | 商务风、休闲风、运动风、戴眼镜、留胡子 | ai_tag |
| `personal_info` | 个人信息 | 基础个人信息（结构化数据） | 血型A型、狮子座、MBTI-INTJ、身高175cm | subsystem |
| `cultural_identity` | 文化认同 | 民族、地域、文化背景认同 | 客家人、北方人、海归、ABC | ai_tag |
| `online_identity` | 网络身份 | 网络平台上的身份和人设 | B站UP主、微博大V、小红书博主、知乎答主 | ai_tag |

##### self.physical (身体状态)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `health_condition` | 健康状况 | 身体健康相关的状态和问题 | 轻度近视、花粉过敏、高血压、腰椎间盘突出、体检正常 | ai_tag |
| `sleep_quality` | 睡眠质量 | 睡眠习惯、质量、问题 | 早睡早起、夜猫子、失眠困扰、睡眠浅、打呼噜 | ai_tag |
| `dietary_habits` | 饮食习惯 | 饮食偏好、忌口、习惯 | 素食主义、无辣不欢、海鲜过敏、少盐少油、爱喝咖啡 | ai_tag |
| `exercise_habits` | 运动习惯 | 运动频率、类型、习惯 | 每周跑步3次、健身爱好者、久坐不动、瑜伽练习者 | ai_tag |
| `body_metrics` | 身体指标 | 可量化的身体数据 | 体重70kg、BMI 22、血压120/80、心率65 | subsystem |
| `medical_history` | 病史记录 | 重要的医疗历史 | 2020年阑尾炎手术、骨折康复中、长期服药 | ai_tag |

##### self.personality (性格特质)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `self_assessment` | 自我评价 | 对自己性格的认知和评价 | 内向、完美主义、乐观、敏感、有责任心、拖延症 | ai_tag |
| `behavioral_preferences` | 行为偏好 | 日常行为习惯和偏好 | 喜欢独处、决策果断、注重细节、喜欢尝新、风险厌恶 | ai_tag |
| `social_style` | 社交风格 | 与人交往的方式和特点 | 社恐、社牛、慢热型、话痨、倾听者、领导型 | ai_tag |
| `emotional_patterns` | 情绪模式 | 情绪反应的典型模式 | 容易焦虑、情绪稳定、易怒、多愁善感、钝感力强 | ai_tag |
| `cognitive_style` | 思维方式 | 思考和处理信息的方式 | 逻辑思维强、直觉型、发散思维、系统思考者 | ai_tag |

---

#### 物质维度 (material) 的三级预设

##### material.economy (经济状况)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `asset_status` | 资产概况 | 主要资产和财务状况 | 有一套自住房、有车、存款50万、股票投资 | ai_tag |
| `consumption` | 消费行为 | 消费习惯和支出模式 | 理性消费、月光族、品质优先、价格敏感、冲动消费 | ai_tag |
| `debt_pressure` | 负债压力 | 负债情况和还款压力 | 房贷200万、车贷还剩2年、无负债、信用卡分期 | ai_tag |
| `income_sources` | 收入来源 | 主要收入渠道 | 工资收入、副业收入、投资收益、租金收入、自由职业 | ai_tag |
| `financial_goals` | 财务目标 | 财务规划和目标 | 5年内买房、存够养老金、财务自由、还清贷款 | ai_tag |
| `investment_style` | 投资风格 | 投资偏好和风险态度 | 保守型、激进型、定投党、价值投资、不投资 | ai_tag |

##### material.objects_space (物品与环境)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `possessions` | 常用物品 | 重要的个人物品和设备 | MacBook Pro、iPhone、索尼相机、机械键盘、Kindle | ai_tag |
| `living_environment` | 居住环境 | 住房情况和居住条件 | 两室一厅、租房、学区房、装修简约、有阳台 | ai_tag |
| `collections` | 收藏爱好 | 收藏品和爱好物品 | 手办收藏、黑胶唱片、邮票、球鞋、茶具 | ai_tag |
| `vehicles` | 交通工具 | 拥有的交通工具 | 特斯拉Model 3、电动自行车、无车、公共交通 | ai_tag |
| `workspace` | 工作空间 | 工作环境和设备 | 独立书房、站立办公桌、双显示器、远程办公 | ai_tag |
| `digital_assets` | 数字资产 | 数字产品和虚拟资产 | 域名、NFT、游戏账号、数字货币、云存储 | ai_tag |

##### material.security (生活保障)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `insurance_safety` | 保险与风控 | 保险配置和风险管理 | 重疾险、医疗险、意外险、寿险、车险、无保险 | ai_tag |
| `emergency_fund` | 应急储备 | 应急资金和备用方案 | 6个月生活费储备、紧急联系人、备用信用卡 | ai_tag |
| `social_security` | 社会保障 | 社保和公积金情况 | 五险一金齐全、自由职业无社保、补充公积金 | ai_tag |

---

#### 成就维度 (achievements) 的三级预设

##### achievements.career (事业发展)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `work_experience` | 工作经历 | 职业经历和工作历史 | 阿里巴巴P7、腾讯产品经理、创业3年、外企10年 | ai_tag |
| `business_activities` | 商业活动 | 创业、投资、副业等 | 天使投资人、淘宝店主、自媒体创业、咨询顾问 | ai_tag |
| `career_milestones` | 职业里程碑 | 职业生涯重要节点 | 首次晋升、转行成功、创业融资、上市敲钟 | ai_tag |
| `industry_expertise` | 行业专长 | 深耕的行业领域 | 互联网行业、金融科技、医疗健康、教育培训 | ai_tag |
| `professional_network` | 职业人脉 | 职业相关的人脉资源 | 行业大佬、猎头关系、校友网络、行业社群 | entity_ref |

##### achievements.competencies (个人能力)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `professional_skills` | 专业技能 | 工作相关的专业能力 | Swift编程、产品设计、数据分析、项目管理、英语流利 | ai_tag |
| `education_learning` | 学习进修 | 学历和持续学习 | 清华本科、MBA在读、PMP认证、CFA持证 | ai_tag |
| `life_talents` | 生活才艺 | 非职业的个人才能 | 钢琴十级、烹饪达人、摄影爱好者、马拉松完赛 | ai_tag |
| `soft_skills` | 软技能 | 通用能力和素质 | 沟通能力强、领导力、时间管理、演讲能力 | ai_tag |
| `languages` | 语言能力 | 掌握的语言 | 英语流利、日语N1、粤语母语、法语入门 | ai_tag |
| `certifications` | 资质证书 | 专业资格认证 | 注册会计师、律师执照、医师资格、驾照C1 | ai_tag |

##### achievements.outcomes (成果展示)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `personal_creations` | 个人作品 | 创作的作品和项目 | 开源项目、出版书籍、原创音乐、设计作品、专利 | ai_tag |
| `recognition_awards` | 荣誉认可 | 获得的奖项和荣誉 | 优秀员工、行业奖项、学术荣誉、社会表彰 | ai_tag |
| `publications` | 发表作品 | 公开发表的内容 | 学术论文、专栏文章、技术博客、公众号文章 | ai_tag |
| `portfolio` | 作品集 | 代表性作品合集 | 设计作品集、代码仓库、视频作品、摄影集 | nested_list |

---

#### 阅历维度 (experiences) 的三级预设

##### experiences.culture_entertainment (文化娱乐)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `reading` | 阅读体验 | 书籍、文章阅读 | 《三体》震撼、年读50本、偏爱科幻、Kindle重度用户 | ai_tag |
| `movies_music` | 视听欣赏 | 电影、音乐、剧集 | 诺兰粉丝、古典音乐爱好者、美剧迷、演唱会常客 | ai_tag |
| `gaming` | 游戏娱乐 | 游戏、电竞、桌游 | 王者荣耀、Steam玩家、桌游爱好者、主机党 | ai_tag |
| `sports_fitness` | 运动健身 | 运动和健身活动 | 跑步爱好者、健身房会员、篮球、游泳、瑜伽 | ai_tag |
| `arts_crafts` | 艺术手工 | 艺术创作和手工活动 | 绘画、书法、手工皮具、编织、陶艺 | ai_tag |
| `social_activities` | 社交活动 | 社交和聚会活动 | 读书会、行业沙龙、朋友聚餐、线下活动 | ai_tag |

##### experiences.exploration (探索足迹)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `travel_stories` | 旅行见闻 | 旅行经历和感受 | 2023日本之旅、西藏自驾、欧洲蜜月、东南亚背包 | ai_tag |
| `lifestyle_exploration` | 探店体验 | 餐厅、咖啡馆、店铺体验 | 米其林餐厅、网红咖啡馆、独立书店、精酿酒吧 | ai_tag |
| `local_discoveries` | 本地发现 | 居住地的探索发现 | 隐藏小店、城市公园、周末市集、社区活动 | ai_tag |
| `adventure_activities` | 冒险活动 | 户外和冒险体验 | 潜水、滑雪、攀岩、跳伞、徒步穿越 | ai_tag |
| `cultural_experiences` | 文化体验 | 文化活动和体验 | 茶道体验、博物馆参观、音乐节、艺术展 | ai_tag |

##### experiences.history (人生历程)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `milestones` | 重要节点 | 人生重要时刻 | 毕业、结婚、生子、买房、创业、退休 | ai_tag |
| `memories` | 往事回忆 | 重要的人生记忆 | 童年趣事、初恋回忆、难忘旅行、人生低谷 | ai_tag |
| `anniversaries` | 纪念日 | 需要纪念的日期 | 结婚纪念日、生日、入职周年、相识纪念 | subsystem |
| `life_transitions` | 人生转折 | 重大的人生转变 | 转行、移民、离婚、康复、觉醒时刻 | ai_tag |
| `family_history` | 家族历史 | 家庭和家族的历史 | 家族故事、祖辈经历、家庭传统、家谱 | ai_tag |

---

#### 精神维度 (spirit) 的三级预设

##### spirit.ideology (意识形态)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `values` | 价值观 | 核心价值观和人生信条 | 家庭优先、诚信为本、追求自由、终身学习、利他主义 | ai_tag |
| `visions_dreams` | 愿景梦想 | 人生目标和梦想 | 环游世界、财务自由、写一本书、创办公司、退休养老 | ai_tag |
| `beliefs` | 信仰信念 | 宗教、哲学信仰 | 佛教徒、无神论、存在主义、极简主义、环保主义 | ai_tag |
| `principles` | 行事原则 | 做事的原则和底线 | 不撒谎、守时、尊重他人、量力而行、先苦后甜 | ai_tag |
| `worldview` | 世界观 | 对世界的基本看法 | 乐观主义、现实主义、人性本善、科技向善 | ai_tag |

##### spirit.mental_state (心理状态)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `emotions` | 情绪感受 | 当前和近期的情绪状态 | 最近很焦虑、心情愉悦、有些迷茫、充满期待 | ai_tag |
| `stressors` | 压力来源 | 主要的压力和焦虑点 | 工作压力、育儿焦虑、经济压力、健康担忧、人际关系 | ai_tag |
| `mental_health` | 心理健康 | 心理健康状况 | 轻度抑郁、焦虑症、心理咨询中、状态良好 | ai_tag |
| `energy_level` | 精力状态 | 精力和活力水平 | 精力充沛、容易疲惫、需要休息、状态起伏 | ai_tag |
| `satisfaction` | 满意度 | 对生活各方面的满意程度 | 工作满意、家庭幸福、对现状不满、追求更好 | ai_tag |

##### spirit.wisdom (思考感悟)

| L3 维度 | 中文名 | 范畴界定 | 常见举例 | ContentType |
|---------|--------|----------|----------|-------------|
| `opinions` | 观点看法 | 对事物的看法和观点 | 对教育的看法、对婚姻的理解、对工作的态度 | ai_tag |
| `reflections` | 反思复盘 | 人生感悟和经验教训 | 慢即是快、选择比努力重要、健康第一、活在当下 | ai_tag |
| `learnings` | 学习心得 | 学习和成长的收获 | 读书笔记、课程感悟、实践总结、失败教训 | ai_tag |
| `insights` | 洞察发现 | 独特的见解和发现 | 行业洞察、人性观察、生活智慧、思维模型 | ai_tag |
| `questions` | 思考问题 | 正在思考的问题 | 人生意义、职业方向、如何平衡、未来规划 | ai_tag |

---

### Level 3 预设代码定义

```swift
public static let level3Presets: [String: [String]] = [
    // ===== 本体维度 (self) =====
    "self.identity": [
        "social_roles",           // 社会角色
        "professional_identity",  // 职业身份
        "appearance_style",       // 外在形象
        "personal_info",          // 个人信息 (subsystem)
        "cultural_identity",      // 文化认同
        "online_identity"         // 网络身份
    ],
    "self.physical": [
        "health_condition",       // 健康状况
        "sleep_quality",          // 睡眠质量
        "dietary_habits",         // 饮食习惯
        "exercise_habits",        // 运动习惯
        "body_metrics",           // 身体指标 (subsystem)
        "medical_history"         // 病史记录
    ],
    "self.personality": [
        "self_assessment",        // 自我评价
        "behavioral_preferences", // 行为偏好
        "social_style",           // 社交风格
        "emotional_patterns",     // 情绪模式
        "cognitive_style"         // 思维方式
    ],
    
    // ===== 物质维度 (material) =====
    "material.economy": [
        "asset_status",           // 资产概况
        "consumption",            // 消费行为
        "debt_pressure",          // 负债压力
        "income_sources",         // 收入来源
        "financial_goals",        // 财务目标
        "investment_style"        // 投资风格
    ],
    "material.objects_space": [
        "possessions",            // 常用物品
        "living_environment",     // 居住环境
        "collections",            // 收藏爱好
        "vehicles",               // 交通工具
        "workspace",              // 工作空间
        "digital_assets"          // 数字资产
    ],
    "material.security": [
        "insurance_safety",       // 保险与风控
        "emergency_fund",         // 应急储备
        "social_security"         // 社会保障
    ],
    
    // ===== 成就维度 (achievements) =====
    "achievements.career": [
        "work_experience",        // 工作经历
        "business_activities",    // 商业活动
        "career_milestones",      // 职业里程碑
        "industry_expertise",     // 行业专长
        "professional_network"    // 职业人脉 (entity_ref)
    ],
    "achievements.competencies": [
        "professional_skills",    // 专业技能
        "education_learning",     // 学习进修
        "life_talents",           // 生活才艺
        "soft_skills",            // 软技能
        "languages",              // 语言能力
        "certifications"          // 资质证书
    ],
    "achievements.outcomes": [
        "personal_creations",     // 个人作品
        "recognition_awards",     // 荣誉认可
        "publications",           // 发表作品
        "portfolio"               // 作品集 (nested_list)
    ],
    
    // ===== 阅历维度 (experiences) =====
    "experiences.culture_entertainment": [
        "reading",                // 阅读体验
        "movies_music",           // 视听欣赏
        "gaming",                 // 游戏娱乐
        "sports_fitness",         // 运动健身
        "arts_crafts",            // 艺术手工
        "social_activities"       // 社交活动
    ],
    "experiences.exploration": [
        "travel_stories",         // 旅行见闻
        "lifestyle_exploration",  // 探店体验
        "local_discoveries",      // 本地发现
        "adventure_activities",   // 冒险活动
        "cultural_experiences"    // 文化体验
    ],
    "experiences.history": [
        "milestones",             // 重要节点
        "memories",               // 往事回忆
        "anniversaries",          // 纪念日 (subsystem)
        "life_transitions",       // 人生转折
        "family_history"          // 家族历史
    ],
    
    // ===== 精神维度 (spirit) =====
    "spirit.ideology": [
        "values",                 // 价值观
        "visions_dreams",         // 愿景梦想
        "beliefs",                // 信仰信念
        "principles",             // 行事原则
        "worldview"               // 世界观
    ],
    "spirit.mental_state": [
        "emotions",               // 情绪感受
        "stressors",              // 压力来源
        "mental_health",          // 心理健康
        "energy_level",           // 精力状态
        "satisfaction"            // 满意度
    ],
    "spirit.wisdom": [
        "opinions",               // 观点看法
        "reflections",            // 反思复盘
        "learnings",              // 学习心得
        "insights",               // 洞察发现
        "questions"               // 思考问题
    ]
]
```

### 维度完整性验证

#### 人生领域覆盖检查

| 人生领域 | 覆盖维度 | 完整性 |
|----------|----------|--------|
| 个人身份 | 本体 > 身份认同 | ✅ 完整 |
| 身体健康 | 本体 > 身体状态 | ✅ 完整 |
| 性格心理 | 本体 > 性格特质 | ✅ 完整 |
| 财务经济 | 物质 > 经济状况 | ✅ 完整 |
| 生活环境 | 物质 > 物品与环境 | ✅ 完整 |
| 安全保障 | 物质 > 生活保障 | ✅ 完整 |
| 职业发展 | 成就 > 事业发展 | ✅ 完整 |
| 能力技能 | 成就 > 个人能力 | ✅ 完整 |
| 成果荣誉 | 成就 > 成果展示 | ✅ 完整 |
| 文化娱乐 | 阅历 > 文化娱乐 | ✅ 完整 |
| 旅行探索 | 阅历 > 探索足迹 | ✅ 完整 |
| 人生经历 | 阅历 > 人生历程 | ✅ 完整 |
| 价值信仰 | 精神 > 意识形态 | ✅ 完整 |
| 情绪心理 | 精神 > 心理状态 | ✅ 完整 |
| 思考反思 | 精神 > 思考感悟 | ✅ 完整 |
| 人际关系 | 关系 (预留) | ⏳ 预留 |
| AI交互 | AI偏好 (预留) | ⏳ 预留 |

#### 维度归属合理性检查

| 检查项 | 当前归属 | 合理性 | 说明 |
|--------|----------|--------|------|
| 性格特质 | 本体 | ✅ 合理 | 性格是"我是谁"的核心部分 |
| 情绪感受 | 精神 > 心理状态 | ✅ 合理 | 情绪是精神层面的表现 |
| 价值观 | 精神 > 意识形态 | ✅ 合理 | 价值观是精神信仰的核心 |
| 技能 | 成就 > 个人能力 | ✅ 合理 | 技能是能力的具体表现 |
| 负债压力 | 物质 > 经济状况 | ✅ 合理 | 负债是经济状况的一部分 |
| 纪念日 | 阅历 > 人生历程 > 重要节点 | ✅ 合理 | 纪念日是人生重要节点 |

#### 潜在遗漏检查

| 可能遗漏领域 | 建议归属 | 处理方式 |
|--------------|----------|----------|
| 时间管理 | 本体 > 性格特质 > 行为偏好 | Level 3 动态创建 |
| 社交网络 | 关系 (预留子系统) | 后续实现 |
| 宠物/家庭成员 | 关系 (预留子系统) | 后续实现 |
| 宗教信仰 | 精神 > 意识形态 > 价值观 | Level 3 动态创建 |
| 政治倾向 | 精神 > 意识形态 | Level 3 动态创建 |

**结论**：前两层维度已完整覆盖人生主要方面，遗漏项可通过 Level 3 动态创建或预留子系统解决。

---


## 🏗️ 各维度详细结构

### 本体维度 (Self)

关于"我是谁"的核心自我认知。

```
本体 (self)
├── 身份认同 (identity)
│   ├── 社会角色 (social_roles)        # ai_tag: 父亲、丈夫、儿子...
│   ├── 职业身份 (professional_identity) # ai_tag: 软件工程师、创业者...
│   ├── 外在形象 (appearance_style)    # ai_tag: 穿搭风格、形象特点...
│   └── 个人信息 (personal_info)       # subsystem: 血型、星座、MBTI...
├── 身体状态 (physical)
│   ├── 健康状况 (health_condition)    # ai_tag: 慢性病、过敏、体检结果...
│   ├── 睡眠质量 (sleep_quality)       # ai_tag: 睡眠习惯、失眠问题...
│   └── 饮食习惯 (dietary_habits)      # ai_tag: 饮食偏好、忌口...
└── 性格特质 (personality)
    ├── 自我评价 (self_assessment)     # ai_tag: 性格标签、自我认知...
    └── 行为偏好 (behavioral_preferences) # ai_tag: 决策风格、社交偏好...
```

**L3 示例**：
- `self.identity.social_roles`: "父亲"、"技术负责人"
- `self.physical.health_condition`: "轻度近视"、"花粉过敏"
- `self.personality.self_assessment`: "内向"、"完美主义"

### 物质维度 (Material)

物质世界的拥有与保障。

```
物质 (material)
├── 经济状况 (economy)
│   ├── 资产概况 (asset_status)        # ai_tag: 房产、存款、投资...
│   ├── 消费行为 (consumption)         # ai_tag: 消费习惯、支出分布...
│   └── 负债压力 (debt_pressure)       # ai_tag: 房贷、车贷、信用卡...
├── 物品与环境 (objects_space)
│   ├── 常用物品 (possessions)         # ai_tag: 重要物品、设备...
│   ├── 居住环境 (living_environment)  # ai_tag: 住房情况、装修风格...
│   └── 收藏爱好 (collections)         # ai_tag: 收藏品、爱好物品...
└── 生活保障 (security)
    └── 保险与风控 (insurance_safety)  # ai_tag: 保险配置、风险管理...
```

**L3 示例**：
- `material.economy.asset_status`: "有一套自住房"
- `material.objects_space.possessions`: "MacBook Pro"、"索尼相机"
- `material.security.insurance_safety`: "已配置重疾险"

### 成就维度 (Achievements)

事业发展与个人成就。

```
成就 (achievements)
├── 事业发展 (career)
│   ├── 工作经历 (work_experience)     # ai_tag: 公司、职位、项目...
│   └── 商业活动 (business_activities) # ai_tag: 创业、投资、副业...
├── 个人能力 (competencies)
│   ├── 专业技能 (professional_skills) # ai_tag: 编程、设计、管理...
│   ├── 学习进修 (education_learning)  # ai_tag: 学历、证书、课程...
│   └── 生活才艺 (life_talents)        # ai_tag: 烹饪、乐器、运动...
└── 成果展示 (outcomes)
    ├── 个人作品 (personal_creations)  # ai_tag: 项目、文章、作品...
    └── 荣誉认可 (recognition_awards)  # ai_tag: 奖项、荣誉、认证...
```

**L3 示例**：
- `achievements.career.work_experience`: "阿里巴巴 P7"
- `achievements.competencies.professional_skills`: "Swift 编程 (高级)"
- `achievements.outcomes.personal_creations`: "开源项目 XXX"

### 阅历维度 (Experiences)

人生经历与文化体验。

```
阅历 (experiences)
├── 文化娱乐 (culture_entertainment)
│   ├── 阅读体验 (reading)             # ai_tag: 书籍、文章、阅读偏好...
│   ├── 视听欣赏 (movies_music)        # ai_tag: 电影、音乐、剧集...
│   └── 游戏娱乐 (gaming)              # ai_tag: 游戏、电竞、桌游...
├── 探索足迹 (exploration)
│   ├── 旅行见闻 (travel_stories)      # ai_tag: 旅行目的地、体验...
│   └── 探店体验 (lifestyle_exploration) # ai_tag: 餐厅、咖啡馆、店铺...
└── 人生历程 (history)
    ├── 重要节点 (milestones)          # ai_tag: 毕业、结婚、生子...
    └── 往事回忆 (memories)            # ai_tag: 童年记忆、重要经历...
```

**L3 示例**：
- `experiences.culture_entertainment.reading`: "《三体》- 震撼的科幻体验"
- `experiences.exploration.travel_stories`: "2023年日本之旅"
- `experiences.history.milestones`: "2020年结婚"

### 精神维度 (Spirit)

精神世界与内心状态。

```
精神 (spirit)
├── 意识形态 (ideology)
│   ├── 价值观 (values)                # ai_tag: 核心价值观、人生信条...
│   └── 愿景梦想 (visions_dreams)      # ai_tag: 人生目标、梦想...
├── 心理状态 (mental_state)
│   ├── 情绪感受 (emotions)            # ai_tag: 当前情绪、情绪模式...
│   └── 压力来源 (stressors)           # ai_tag: 焦虑点、压力源...
└── 思考感悟 (wisdom)
    ├── 观点看法 (opinions)            # ai_tag: 对事物的看法...
    └── 反思复盘 (reflections)         # ai_tag: 人生感悟、经验教训...
```

**L3 示例**：
- `spirit.ideology.values`: "家庭优先"、"终身学习"
- `spirit.mental_state.stressors`: "工作压力"、"育儿焦虑"
- `spirit.wisdom.reflections`: "慢即是快"

---


## 📦 NodeContentType 和 L3 特异性

### L3 内容类型定义

L3 层需要支持多种不同类型的内容，每种类型有不同的数据结构需求：

| 内容类型 | 英文标识 | 说明 | 数据特点 |
|----------|----------|------|----------|
| AI标签 | `ai_tag` | AI生成的标签 | 只有 name + description + sourceLinks |
| 独立小系统 | `subsystem` | 有固定 schema 的数据 | 有固定 schema（如个人信息：血型、姓名等） |
| 实体引用 | `entity_ref` | 指向关系表中的人物 | 指向关系表中的人物实体 |
| 嵌套列表 | `nested_list` | 下面还有子节点列表 | 有 childNodeIds 指向子节点 |

### 内容类型详解

#### 1. AI标签 (ai_tag)

最常见的类型，AI 从用户数据中提取的标签。

**特点**：
- 只有 `name` + `description` + `sourceLinks`
- 不需要复杂的 `attributes`
- 可以有多个 `sourceLinks` 追溯到原始数据

**使用场景**：
- 技能标签：Swift 编程、项目管理
- 性格标签：内向、完美主义
- 兴趣标签：摄影、咖啡

**示例**：
```json
{
    "id": "node_001",
    "nodeType": "achievements.competencies.professional_skills",
    "contentType": "ai_tag",
    "name": "Swift编程",
    "description": "iOS开发主力语言，熟练程度高",
    "sourceLinks": [
        {"dayId": "2024-01-15", "snippet": "开始学习Swift...", "relatedEntityIds": []},
        {"dayId": "2024-06-10", "snippet": "和小明讨论Swift...", "relatedEntityIds": ["REL_xxx"]}
    ],
    "relatedEntityIds": ["REL_xxx"]
}
```

#### 2. 独立小系统 (subsystem)

有固定 schema 的结构化数据。

**特点**：
- 有固定的 `attributes` 字段定义
- 通常由用户手动输入或系统自动填充
- 不依赖 AI 提取

**使用场景**：
- 个人基础信息：血型、星座、MBTI
- 健康档案：身高、体重、血压
- 财务概况：收入、支出、资产

**示例**：
```json
{
    "id": "node_002",
    "nodeType": "self.identity.personal_info",
    "contentType": "subsystem",
    "name": "个人基础信息",
    "attributes": {
        "blood_type": "A",
        "zodiac": "狮子座",
        "mbti": "INTJ",
        "height": 175
    },
    "sourceLinks": []
}
```

#### 3. 实体引用 (entity_ref)

指向关系表中的人物实体。

**特点**：
- 主要存储 `relatedEntityIds`
- 用于建立与关系子系统的连接
- 支持格式：`[REL_ID:displayName]`

**使用场景**：
- 家庭成员引用
- 重要人物关联
- 共同经历中的人物

**示例**：
```json
{
    "id": "node_003",
    "nodeType": "experiences.history.milestones",
    "contentType": "entity_ref",
    "name": "2020年结婚",
    "description": "与小红结婚",
    "relatedEntityIds": ["REL_wife_001"],
    "sourceLinks": [
        {"dayId": "2020-10-01", "snippet": "今天是我们的婚礼..."}
    ]
}
```

#### 4. 嵌套列表 (nested_list)

有子节点的容器节点。

**特点**：
- 有 `childNodeIds` 指向子节点
- 子节点有 `parentNodeId` 指向父节点
- 用于组织层级结构

**使用场景**：
- 阅读分类：技术书籍、文学作品
- 技能分类：编程语言、框架工具
- 旅行分类：国内旅行、海外旅行

**示例**：
```json
{
    "id": "node_004",
    "nodeType": "experiences.culture_entertainment.reading",
    "contentType": "nested_list",
    "name": "阅读",
    "childNodeIds": ["node_004_1", "node_004_2"]
}
```

子节点示例：
```json
{
    "id": "node_004_1",
    "nodeType": "experiences.culture_entertainment.reading",
    "contentType": "ai_tag",
    "name": "《三体》",
    "description": "刘慈欣的科幻巨作",
    "parentNodeId": "node_004"
}
```

---


## 🗃️ 数据模型定义

### 核心数据结构：KnowledgeNode（重构版）

```swift
/// 通用知识节点 - L4 层的核心数据结构（重构版）
public struct KnowledgeNode: Codable, Identifiable {
    // ===== 基础标识 =====
    public let id: String
    public let nodeType: String               // 层级路径: "achievements.competencies.professional_skills"
    
    // ===== 🆕 内容类型（L3特异性支持） =====
    public let contentType: NodeContentType   // ai_tag | subsystem | entity_ref | nested_list
    
    // ===== 核心内容 =====
    public var name: String                   // 节点名称
    public var description: String?           // 描述（AI生成的解释）
    public var tags: [String]                 // 用户自定义标签
    
    // ===== 动态属性（subsystem类型用） =====
    public var attributes: [String: AttributeValue]
    
    // ===== 🆕 关联关系（多对多支持） =====
    public var sourceLinks: [SourceLink]      // 变化历史/关联原文（从tracking移出）
    public var relatedEntityIds: [String]     // 关联的人物实体ID
    
    // ===== 🆕 嵌套结构支持 =====
    public var childNodeIds: [String]?        // 子节点ID列表（nested_list用）
    public var parentNodeId: String?          // 父节点ID
    
    // ===== 追踪信息（简化） =====
    public var tracking: NodeTracking         // 来源、置信度、验证状态
    
    // ===== 时间戳 =====
    public let createdAt: Date
    public var updatedAt: Date
}
```

### 节点内容类型枚举

```swift
/// 🆕 节点内容类型
public enum NodeContentType: String, Codable {
    case aiTag = "ai_tag"           // AI生成的标签（只有解释+关联原文）
    case subsystem = "subsystem"     // 独立小系统（有固定schema）
    case entityRef = "entity_ref"    // 实体引用（指向关系表）
    case nestedList = "nested_list"  // 嵌套列表（有子节点）
}
```

### SourceLink 重构（支持多对多）

```swift
/// 溯源链接 - 连接 L4 知识节点与 L1 原始数据（重构版）
public struct SourceLink: Codable, Identifiable {
    public let id: String
    
    // ===== L1 来源定位 =====
    public var sourceType: String             // diary | conversation | tracker | mindState
    public var sourceId: String               // 具体记录 ID
    public var dayId: String                  // 所属日期 (YYYY-MM-DD)
    
    // ===== 内容片段 =====
    public var snippet: String?               // 相关文本片段
    public var relevanceScore: Double?        // 相关性评分 0.0 ~ 1.0
    
    // ===== 🆕 关联实体 =====
    public var relatedEntityIds: [String]     // 这条记录中提及的人物实体
    
    // ===== 时间戳 =====
    public var extractedAt: Date
}
```

### NodeTracking 简化

```swift
/// 节点追踪信息（简化版，sourceLinks已移出）
public struct NodeTracking: Codable {
    public var source: NodeSource             // 来源类型 + 置信度
    public var timeline: NodeTimeline         // 时间线
    public var verification: NodeVerification // 验证状态
    public var changeHistory: [NodeChange]    // 变化历史
}

/// 节点来源（简化，extractedFrom已移到节点级别）
public struct NodeSource: Codable {
    public var type: SourceType               // user_input | ai_extracted | ai_inferred
    public var confidence: Double?            // 0.0 ~ 1.0
}
```

### 维度层级定义

```swift
/// 维度层级定义
public struct DimensionHierarchy {
    /// Level 1 维度枚举
    public enum Level1: String, CaseIterable {
        case self_ = "self"
        case material = "material"
        case achievements = "achievements"
        case experiences = "experiences"
        case spirit = "spirit"
        case relationships = "relationships"      // 预留
        case aiPreferences = "ai_preferences"     // 预留
        
        public var isReserved: Bool {
            self == .relationships || self == .aiPreferences
        }
        
        public var displayName: String {
            switch self {
            case .self_: return "本体"
            case .material: return "物质"
            case .achievements: return "成就"
            case .experiences: return "阅历"
            case .spirit: return "精神"
            case .relationships: return "关系"
            case .aiPreferences: return "AI偏好"
            }
        }
    }
    
    /// Level 2 维度定义
    public static let level2Dimensions: [Level1: [String]] = [
        .self_: ["identity", "physical", "personality"],
        .material: ["economy", "objects_space", "security"],
        .achievements: ["career", "competencies", "outcomes"],
        .experiences: ["culture_entertainment", "exploration", "history"],
        .spirit: ["ideology", "mental_state", "wisdom"]
    ]
    
    /// Level 3 预设维度
    public static let level3Presets: [String: [String]] = [
        "self.identity": ["social_roles", "professional_identity", "appearance_style", "personal_info"],
        "self.physical": ["health_condition", "sleep_quality", "dietary_habits"],
        "self.personality": ["self_assessment", "behavioral_preferences"],
        "material.economy": ["asset_status", "consumption", "debt_pressure"],
        "material.objects_space": ["possessions", "living_environment", "collections"],
        "material.security": ["insurance_safety"],
        "achievements.career": ["work_experience", "business_activities"],
        "achievements.competencies": ["professional_skills", "education_learning", "life_talents"],
        "achievements.outcomes": ["personal_creations", "recognition_awards"],
        "experiences.culture_entertainment": ["reading", "movies_music", "gaming"],
        "experiences.exploration": ["travel_stories", "lifestyle_exploration"],
        "experiences.history": ["milestones", "memories"],
        "spirit.ideology": ["values", "visions_dreams"],
        "spirit.mental_state": ["emotions", "stressors"],
        "spirit.wisdom": ["opinions", "reflections"]
    ]
}
```

### NodeTypePath 路径工具

```swift
/// nodeType 路径解析工具
public struct NodeTypePath {
    public let level1: String
    public let level2: String?
    public let level3: String?
    
    public var fullPath: String {
        [level1, level2, level3].compactMap { $0 }.joined(separator: ".")
    }
    
    /// 从 nodeType 字符串解析
    public init?(nodeType: String) {
        let components = nodeType.split(separator: ".").map(String.init)
        guard !components.isEmpty else { return nil }
        self.level1 = components[0]
        self.level2 = components.count > 1 ? components[1] : nil
        self.level3 = components.count > 2 ? components[2] : nil
    }
    
    /// 验证路径是否有效
    public func isValid() -> Bool {
        guard let l1 = DimensionHierarchy.Level1(rawValue: level1) else { return false }
        if let l2 = level2 {
            guard DimensionHierarchy.level2Dimensions[l1]?.contains(l2) == true else { return false }
        }
        return true
    }
}
```

---


## 🔌 预留接口定义

### 关系子系统接口 (RelationshipSubsystemInterface)

关系维度作为独立子系统，本次暂不实现，但需预留接口。

```swift
/// 关系子系统接口（预留）
public protocol RelationshipSubsystemInterface {
    /// 获取所有关系
    func getAllRelationships() -> [NarrativeRelationship]
    
    /// 根据ID获取关系
    func getRelationship(byId id: String) -> NarrativeRelationship?
    
    /// 根据名称匹配关系
    func matchRelationship(name: String) -> NarrativeRelationship?
    
    /// 获取与某关系相关的所有数据
    func getRelatedData(relationshipId: String) -> [SourceLink]
}
```

**接口说明**：
- `getAllRelationships()`: 获取用户的所有关系列表
- `getRelationship(byId:)`: 根据关系ID获取详细信息
- `matchRelationship(name:)`: 根据名称或别名匹配关系（用于 AI 识别）
- `getRelatedData(relationshipId:)`: 获取与某关系相关的所有原始数据

**实体引用格式**：
- KnowledgeNode 可通过 `relatedEntityIds` 引用关系实体
- 格式：`[REL_ID:displayName]`，如 `[REL_wife_001:小红]`

### AI偏好子系统接口 (AIPreferencesSubsystemInterface)

AI偏好维度作为独立子系统，本次暂不实现，但需预留接口。

```swift
/// AI偏好子系统接口（预留）
public protocol AIPreferencesSubsystemInterface {
    /// 获取AI偏好设置
    func getPreferences() -> AIPreferences?
    
    /// 更新AI偏好设置
    func updatePreferences(_ preferences: AIPreferences)
    
    /// 生成系统提示词片段
    func generatePromptSnippet() -> String?
}
```

**接口说明**：
- `getPreferences()`: 获取用户的 AI 偏好设置
- `updatePreferences(_:)`: 更新 AI 偏好设置
- `generatePromptSnippet()`: 根据偏好生成系统提示词片段（用于 AI 对话）

**现有基础**：
- 已有 `AIPreferences` 模型定义在 `AIPreferencesModels.swift`
- 包含风格偏好、回复偏好、话题偏好等

---

## 🔄 迁移策略

### nodeType 迁移映射表

将旧的扁平 nodeType 映射到新的层级路径格式：

```swift
/// 旧 nodeType 到新路径的映射
public let nodeTypeMigrationMap: [String: String] = [
    // 用户画像维度
    "skill": "achievements.competencies.professional_skills",
    "value": "spirit.ideology.values",
    "hobby": "experiences.culture_entertainment",
    "goal": "spirit.ideology.visions_dreams",
    "trait": "self.personality.self_assessment",
    "fear": "spirit.mental_state.stressors",
    "fact": "experiences.history.milestones",
    "lifestyle": "self.physical.dietary_habits",
    "belief": "spirit.ideology.values",
    "preference": "self.personality.behavioral_preferences",
    
    // 关系画像维度
    "relationship_status": "relationships.status",
    "interaction_pattern": "relationships.interaction",
    "emotional_connection": "relationships.emotional",
    "shared_memory": "relationships.memories",
    "health_status": "relationships.health",
    "life_event": "relationships.events"
]
```

### 5 阶段迁移计划

```
Phase 1: 新增类型定义（不影响现有功能）
├── 创建 NodeContentType 枚举
├── 创建 DimensionHierarchy 定义
├── 创建 NodeTypePath 工具
└── 创建 nodeTypeMigrationMap

Phase 2: 重构 KnowledgeNode（向后兼容）
├── 新增 contentType 字段（默认 .aiTag）
├── 新增 sourceLinks 字段（从 tracking.source.extractedFrom 迁移）
├── 新增 relatedEntityIds 字段
├── 新增 childNodeIds, parentNodeId 字段
└── 更新初始化方法和工厂方法

Phase 3: 重构 SourceLink（向后兼容）
├── 新增 relatedEntityIds 字段
└── 更新初始化方法

Phase 4: 更新 nodeType 命名（向后兼容）
├── 更新 userProfileNodeTypes 为层级路径
├── 更新 relationshipNodeTypes 为层级路径
├── 添加迁移逻辑：读取时自动转换旧格式
└── 写入时使用新格式

Phase 5: 清理废弃代码
├── 移除 NodeSource.extractedFrom
├── 评估 NodeCategory 是否保留
└── 更新相关扩展方法
```

### 向后兼容策略

1. **JSON 兼容性**：
   - 旧数据读取时，新字段使用默认值（空数组/nil）
   - 新数据写入时，包含所有字段

2. **nodeType 兼容性**：
   - 读取时自动转换旧格式到新格式
   - 写入时使用新格式
   - 保留迁移映射表用于转换

3. **字段迁移**：
   - `tracking.source.extractedFrom` → `sourceLinks`
   - 迁移时自动复制数据

4. **默认值策略**：
   - `contentType`: 默认 `.aiTag`
   - `sourceLinks`: 默认 `[]`
   - `relatedEntityIds`: 默认 `[]`
   - `childNodeIds`: 默认 `nil`
   - `parentNodeId`: 默认 `nil`

---


## 🔍 与现有代码的差异分析

### 已完成项 ✅

| 项目 | 文件位置 | 状态 |
|------|----------|------|
| KnowledgeNode 基础结构 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| AttributeValue 多类型支持 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| NodeTracking 追踪信息 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| SourceLink 溯源链接 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| NodeRelation 节点关联 | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| AIPreferences 基础结构 | `AIPreferencesModels.swift` | ✅ 完整实现 |
| NarrativeUserProfile 扩展 | `NarrativeProfileModels.swift` | ✅ 已添加 knowledgeNodes, aiPreferences |
| NarrativeRelationship 扩展 | `NarrativeRelationshipModels.swift` | ✅ 已添加 attributes |
| KnowledgeNodeValidator | `KnowledgeNodeModels.swift` | ✅ 完整实现 |
| ExtractedSourceLink (API) | `KnowledgeAPIModels.swift` | ✅ 完整实现 |

### 需重构项 🔄

| 项目 | 当前状态 | 需要修改 |
|------|----------|----------|
| KnowledgeNode.nodeType | 扁平字符串 (skill, value...) | 改为层级路径 (self.personality.trait) |
| KnowledgeNode 结构 | 无 contentType | 新增 contentType 字段 |
| KnowledgeNode 结构 | sourceLinks 在 tracking.source 内 | 移到节点顶层 |
| KnowledgeNode 结构 | 无嵌套支持 | 新增 childNodeIds, parentNodeId |
| KnowledgeNode 结构 | 无实体关联 | 新增 relatedEntityIds |
| SourceLink 结构 | 无实体关联 | 新增 relatedEntityIds |
| NodeSource 结构 | 包含 extractedFrom | 移除（已移到节点级别） |
| NodeCategory | common/personal | 考虑是否废弃或调整含义 |
| userProfileNodeTypes | 10个扁平类型 | 更新为层级路径格式 |
| relationshipNodeTypes | 6个扁平类型 | 更新为层级路径格式 |

### 需新增项 ➕

| 项目 | 说明 | 优先级 |
|------|------|--------|
| NodeContentType | 节点内容类型枚举 (ai_tag, subsystem, entity_ref, nested_list) | P0 |
| DimensionHierarchy | 维度层级定义枚举和静态数据 | P0 |
| NodeTypePath | nodeType 路径解析工具 | P0 |
| nodeTypeMigrationMap | 旧类型到新路径的映射表 | P1 |
| KnowledgeNode 扩展方法 | 按层级查询、嵌套遍历等 | P1 |

### 可废弃项 ⚠️

| 项目 | 说明 | 处理建议 |
|------|------|----------|
| NodeCategory | common/personal 区分 | 可保留但调整含义，或用 contentType 替代 |
| NodeSource.extractedFrom | 已移到节点级别 | 废弃，使用节点级 sourceLinks |

---

## 📈 置信度机制

### 置信度来源

| 来源类型 | 初始置信度 | 说明 |
|----------|-----------|------|
| `user_input` | 1.0 | 用户手动输入，完全可信 |
| `ai_extracted` | 0.6 ~ 0.95 | AI 从原始数据提取，根据证据强度 |
| `ai_inferred` | 0.3 ~ 0.7 | AI 推断得出，需要更多验证 |

### 置信度衰减

AI 提取的信息如果长时间未被确认或更新，置信度会逐渐衰减。

```swift
/// 置信度衰减计算
/// - 衰减周期：180 天
/// - 最大衰减：30%
/// - 用户确认后重置为 1.0
func calculateDecayedConfidence(
    originalConfidence: Double,
    daysSinceLastUpdate: Int
) -> Double {
    // 用户输入不衰减
    guard originalConfidence < 1.0 else { return 1.0 }
    
    // 衰减公式：原始置信度 * (1 - 天数/180 * 0.3)
    let decayFactor = 1.0 - (Double(daysSinceLastUpdate) / 180.0 * 0.3)
    let decayed = originalConfidence * max(decayFactor, 0.7)  // 最低保留 70%
    
    return max(decayed, 0.1)  // 绝对最低 0.1
}
```

### 置信度增强

| 触发条件 | 置信度变化 | 说明 |
|----------|-----------|------|
| 用户确认 | → 1.0 | 用户点击"确认"按钮 |
| 多次提及 | +0.05/次 | 在不同日记/对话中多次提及（上限 0.95） |
| 相关证据 | +0.1 | 发现新的支持证据 |
| 用户编辑 | → 1.0 | 用户修改内容后视为确认 |

### 置信度展示策略

| 置信度范围 | 展示方式 | 用户操作 |
|-----------|---------|---------|
| 0.9 ~ 1.0 | 正常显示 | 无需操作 |
| 0.7 ~ 0.9 | 显示 "AI 推测" 标签 | 可确认或修改 |
| 0.5 ~ 0.7 | 显示 "待确认" 标签 + 黄色高亮 | 建议确认 |
| < 0.5 | 显示 "低置信度" + 灰色 | 强烈建议确认或删除 |

---

## 📝 实现优先级

### P0 - 核心基础 ⭐ 已完成 (2024-12-22)

| 任务 | 说明 | 状态 |
|------|------|------|
| 定义 KnowledgeNode 数据结构 | 创建 `KnowledgeNodeModels.swift` | ⭐ 已完成 |
| 定义 NodeTracking 等辅助结构 | SourceLink, NodeChange, NodeRelation | ⭐ 已完成 |
| 定义 AIPreferences 结构 | 创建 `AIPreferencesModels.swift` | ⭐ 已完成 |
| 扩展 NarrativeUserProfile | 添加 knowledgeNodes, aiPreferences 字段 | ⭐ 已完成 |
| 扩展 NarrativeRelationship | 添加 attributes 字段 | ⭐ 已完成 |
| 更新 Repository | 支持新字段的读写 | ⭐ 已完成 |

### P0.5 - 三层维度架构 🆕

| 任务 | 说明 | 状态 |
|------|------|------|
| 定义 NodeContentType | 节点内容类型枚举 | 🔄 待实现 |
| 定义 DimensionHierarchy | 维度层级定义 | 🔄 待实现 |
| 定义 NodeTypePath | 路径解析工具 | 🔄 待实现 |
| 重构 KnowledgeNode | 新增字段支持 | 🔄 待实现 |
| 重构 SourceLink | 新增 relatedEntityIds | 🔄 待实现 |

### P1 - AI 集成（需要 AI 服务）

| 任务 | 说明 | 依赖 |
|------|------|------|
| AI 自动提取节点 | 从日记/对话中提取知识节点 | P0 完成 + AI 服务 |
| 置信度计算 | 根据证据强度计算初始置信度 | AI 提取 |
| 溯源链接建立 | 建立 L4 节点与 L1 原始数据的关联 | AI 提取 |
| 用户审核流程 | 展示待确认节点，支持确认/修改/删除 | AI 提取 |

### P2 - 高级功能（优化体验）

| 任务 | 说明 | 依赖 |
|------|------|------|
| 置信度衰减机制 | 定时任务计算衰减 | P1 完成 |
| 节点关联关系 | 建立节点之间的关联 | P1 完成 |
| 变化历史追踪 | 记录每次修改的详细历史 | P0 完成 |
| 个人独特维度创建 | 用户/AI 创建新的 nodeType | P1 完成 |
| 属性模板管理 | 管理共有维度的属性模板 | P0 完成 |

### P3 - UI 展示（前端）

| 任务 | 说明 | 依赖 |
|------|------|------|
| 知识节点列表展示 | 在用户画像页展示 knowledgeNodes | P0 完成 |
| 节点详情页 | 展示单个节点的详细信息和溯源 | P0 完成 |
| 节点编辑页 | 支持用户编辑节点内容 | P0 完成 |
| 置信度可视化 | 展示置信度标签和颜色 | P1 完成 |
| 关系画像属性展示 | 在关系详情页展示 attributes | P0 完成 |

---

## 🔗 相关文档

- [数据架构](data-architecture.md) - 四层记忆系统整体设计
- [用户画像模型](../data/user-profile-models.md) - 当前模型文档
- [AI 对话功能](../features/ai-conversation.md) - AI 服务相关
- [个人中心功能](../features/profile.md) - 用户画像 UI

---

## 📎 附录：完整类型定义汇总

### 枚举类型

```swift
// 节点内容类型
enum NodeContentType: String, Codable {
    case aiTag = "ai_tag"
    case subsystem = "subsystem"
    case entityRef = "entity_ref"
    case nestedList = "nested_list"
}

// 节点分类
enum NodeCategory: String, Codable {
    case common     // 共有维度
    case personal   // 个人独特
}

// 来源类型
enum SourceType: String, Codable {
    case userInput      // 用户输入
    case aiExtracted    // AI 提取
    case aiInferred     // AI 推断
}

// 变化类型
enum ChangeType: String, Codable {
    case created, updated, confirmed, deleted
}

// 变化原因
enum ChangeReason: String, Codable {
    case userEdit, aiUpdate, correction, decay, enhancement
}

// 关联类型
enum RelationType: String, Codable {
    case requires, conflictsWith, supports, relatedTo, partOf
}
```

### 一级维度 (Level 1)

| 维度 | 标识 | 状态 |
|------|------|------|
| 本体 | `self` | ✅ 实现 |
| 物质 | `material` | ✅ 实现 |
| 成就 | `achievements` | ✅ 实现 |
| 阅历 | `experiences` | ✅ 实现 |
| 精神 | `spirit` | ✅ 实现 |
| 关系 | `relationships` | ⏳ 预留 |
| AI偏好 | `ai_preferences` | ⏳ 预留 |

### 二级维度 (Level 2)

**本体 (self)**:
- `identity` - 身份认同
- `physical` - 身体状态
- `personality` - 性格特质

**物质 (material)**:
- `economy` - 经济状况
- `objects_space` - 物品与环境
- `security` - 生活保障

**成就 (achievements)**:
- `career` - 事业发展
- `competencies` - 个人能力
- `outcomes` - 成果展示

**阅历 (experiences)**:
- `culture_entertainment` - 文化娱乐
- `exploration` - 探索足迹
- `history` - 人生历程

**精神 (spirit)**:
- `ideology` - 意识形态
- `mental_state` - 心理状态
- `wisdom` - 思考感悟

---
**版本**: v3.0.0  
**作者**: Kiro AI Assistant  
**更新日期**: 2024-12-31  
**状态**: 规划中

**更新记录**:
- v3.0.0 (2024-12-31): 重构为三层维度架构，添加 NodeContentType，支持多对多关联，添加迁移策略
- v2.1.0 (2024-12-22): 完善数据结构定义，添加 Swift 代码示例，详细差异对比，实现优先级
- v2.0.0 (2024-12-22): 重构为通用知识节点设计，添加与当前系统差异对比
- v1.0.0 (2024-12-19): 初始版本
