# Game Concept: V-Tacit（虚拟羁绊）

*Created: 2026-03-27*
*Status: Draft*

---

## Elevator Pitch

> 一款面向虚拟主播粉丝的自走棋MVP，玩家通过组合喜爱的虚拟主播角色激活羁绊效果，与AI对战验证策略。像云顶之弈，但角色是真实的虚拟主播，羁绊是真实的粉丝梗。

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 自走棋 / 策略 |
| **Platform** | Web (MVP) → PC (完整版) |
| **Target Audience** | 虚拟主播粉丝群体，喜欢策略/收集类游戏 |
| **Player Count** | 单人 (MVP) → 单人/多人 (完整版) |
| **Session Length** | 5-15分钟 (MVP) |
| **Monetization** | 无 (MVP) → 待定 (完整版) |
| **Estimated Scope** | 小型MVP (4-8周) → 中型完整版 |
| **Comparable Titles** | 云顶之弈、金铲铲之战、刀塔自走棋 |

---

## Core Fantasy

让虚拟主播粉丝体验到"追星+策略"的双重满足。玩家可以看到喜爱的虚拟主播角色组合产生独特互动，发现隐藏的羁绊彩蛋，打造"最强应援团"。这是粉丝文化的游戏化表达——每一次羁绊激活都是对虚拟主播"梗"和"设定"的致敬。

---

## Unique Hook

**像云顶之弈，但角色是真实的虚拟主播，羁绊是真实的粉丝梗。**

- 羁绊不是抽象的"法师""战士"，而是"VR""歌手""四喜丸子"等真实团体
- 触发式羁绊——满足条件时触发特殊事件/特效，不仅仅是数值加成
- 粉丝可以在游戏中"组CP"、发现角色间的隐藏互动

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Fantasy** (粉丝幻想) | 1 (Primary) | 真实虚拟主播角色，羁绊对应真实团体/梗 |
| **Challenge** (策略挑战) | 2 | 羁绊组合深度，胜率计算，最优配队探索 |
| **Discovery** (发现乐趣) | 3 | 隐藏羁绊效果，角色组合彩蛋 |
| **Sensation** (感官体验) | 4 | 羁绊激活特效，BGM变化 |
| **Submission** (轻松体验) | 5 | 短局时，低压力，可随时暂停 |
| **Narrative** | N/A | MVP不包含 |
| **Fellowship** | N/A | MVP不包含多人 |
| **Expression** | Supporting | 阵容搭配的自我表达 |

### Key Dynamics (Emergent player behaviors)

- 玩家会主动尝试不同羁绊组合，寻找"最强配队"
- 玩家会分享发现的隐藏羁绊效果和彩蛋
- 玩家会对特定角色产生"本命"情感，即使强度不高也想使用

### Core Mechanics (Systems we build)

1. **蜂窝式棋盘** — 六边形格子，拖放棋子，位置策略
2. **商店系统** — 刷新卡牌，从卡池抽取角色
3. **羁绊系统** — 触发式，满足条件激活特效/事件
4. **战斗计算** — 纯数值计算胜率（基于属性+羁绊加成）
5. **角色系统** — 10个初始角色，各有定位/技能/羁绊标签

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (自由选择) | 选择阵容、羁绊组合、站位策略 | Core |
| **Competence** (技能成长) | 发现最优配队、理解羁绊机制、提升胜率 | Core |
| **Relatedness** (情感连接) | 与喜爱的虚拟主播角色互动，粉丝社区分享 | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (成就者) — 收集角色，发现最强羁绊组合，追求高胜率
- [x] **Explorers** (探索者) — 发现隐藏羁绊效果，尝试冷门组合
- [ ] **Socializers** — MVP阶段不包含社交功能
- [ ] **Killers/Competitors** — MVP阶段不包含PVP

### Flow State Design

- **Onboarding curve**: 简单拖放操作，羁绊提示明显，首次游戏5分钟内理解核心玩法
- **Difficulty scaling**: AI强度可调，玩家可自选挑战等级
- **Feedback clarity**: 羁绊激活立即显示视觉反馈，胜率计算过程可视化
- **Recovery from failure**: 失败后可立即重试，无惩罚，鼓励实验

---

## Core Loop

### Moment-to-Moment (30 seconds)

1. 查看商店卡牌
2. 点击刷新（如需要）
3. 选择棋子拖放到棋盘
4. 观察羁绊激活反馈

*满足感来源*：羁绊激活的视觉特效 + 策划"最强组合"的思考乐趣

### Short-Term (5-15 minutes)

1. 开始游戏 → 商店刷新 → 选择棋子组成阵容
2. 确认阵容 → 点击"对战"
3. 系统计算胜率 → 显示结果 + 羁绊激活效果
4. 重置 → 尝试新组合

*"One more turn"来源*：想试试另一个羁绊组合会不会更强

### Session-Level (单次游戏)

- MVP阶段：5-15分钟完整体验
- 尝试3-5种不同羁绊组合
- 发现1-2个隐藏羁绊效果

### Long-Term Progression (完整版规划)

- 解锁新角色
- 角色升星/养成
- 解锁羁绊皮肤/特效
- 排位系统

### Retention Hooks

- **Curiosity**: 有哪些隐藏羁绊？特定组合会触发什么特效？
- **Investment**: 喜爱的角色，想要"培养"的情感
- **Mastery**: 理解羁绊机制，提升策略水平

---

## Game Pillars

### Pillar 1: 粉丝幻想

让玩家看到喜爱的虚拟主播组合产生独特互动。每个羁绊都是真实的粉丝梗。

*Design test*: 如果一个功能不能强化"角色是真实虚拟主播"的感觉，砍掉。

### Pillar 2: 策略发现

羁绊组合有深度，玩家能发现"最强配队"。没有明显的唯一最优解。

*Design test*: 如果一个羁绊组合明显碾压其他所有选择，需要调整平衡。

### Pillar 3: 快速反馈

每次操作都有视觉/音效响应。羁绊激活立即显示效果。

*Design test*: 如果一个操作超过3秒无反馈，需要优化。

### Anti-Pillars (What This Game Is NOT)

- **NOT 实时战斗** — MVP阶段纯数值计算，不渲染战斗动画
- **NOT 经济系统** — MVP阶段无金币/利息，商店刷新免费或有次数限制
- **NOT 多人对战** — MVP仅AI对战，验证核心玩法
- **NOT 完整养成** — MVP无等级/升星/装备系统

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| 云顶之弈 | 自走棋核心玩法，羁绊系统 | 角色是真实虚拟主播，羁绊是真实团体 | 验证了自走棋+羁绊的市场吸引力 |
| 金铲铲之战 | 移动端适配，简化操作 | Web优先，更轻量 | 证明轻度自走棋可行 |
| 虚拟主播二创 | 角色设定，粉丝梗，CP文化 | 游戏化表达 | 核心受众的真实需求 |

**Non-game inspirations**: 虚拟主播直播文化、粉丝二创社区、B站弹幕文化

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16-30 |
| **Gaming experience** | Mid-core（玩过云顶之弈/原神等） |
| **Time availability** | 碎片时间，5-15分钟一局 |
| **Platform preference** | Web浏览器（上班/上学摸鱼）、PC（完整版） |
| **Current games they play** | 云顶之弈、原神、虚拟主播直播 |
| **What they're looking for** | 与喜爱虚拟主播互动的新方式 |
| **What would turn them away** | 太复杂、角色不是他们认识的虚拟主播 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4 — Web导出成熟，GDScript简单，适合单人开发，免费开源 |
| **Key Technical Challenges** | 六边形棋盘逻辑、羁绊触发系统、Web性能优化 |
| **Art Style** | 2D，AI生成角色立绘 + 简洁UI |
| **Art Pipeline Complexity** | Low — AI生成 + 简单UI设计 |
| **Audio Needs** | Moderate — 羁绊激活音效，背景音乐 |
| **Networking** | None (MVP) — 纯本地计算 |
| **Content Volume** | MVP: 10角色，10+羁绊，1个棋盘 |
| **Procedural Systems** | 无 |

---

## Risks and Open Questions

### Design Risks

- 羁绊平衡可能存在"最优解"，破坏策略多样性
- 角色池小，组合深度可能不足
- 纯数值战斗可能缺乏"爽感"

### Technical Risks

- 无程序背景，Godot学习曲线
- Web导出性能和兼容性
- 羁绊系统复杂度可能超出预期

### Market Risks

- 虚拟主播粉丝群体是否足够大
- 是否有版权/肖像权问题
- 二创游戏接受度

### Scope Risks

- 角色美术工作量大（即使AI生成）
- 羁绊特效设计工作量大
- 功能蔓延风险

### Open Questions

- **羁绊触发机制具体怎么设计？** — 需要原型验证
- **胜率计算公式如何设计？** — 需要数值策划
- **AI生成美术的质量如何保证？** — 需要测试nano banana2

---

## MVP Definition

**Core hypothesis**: 虚拟主播粉丝会觉得羁绊组合玩法有趣，愿意尝试多种配队。

**Required for MVP**:
1. 蜂窝式棋盘（六边形格子，拖放棋子）
2. 商店系统（刷新、卡池，无经济）
3. 羁绊系统（触发式，满足条件激活效果）
4. 战斗计算（纯数值计算胜率）
5. 10个初始角色（含属性、技能、羁绊标签）
6. 基础UI（商店、棋盘、结果展示）

**Explicitly NOT in MVP**:
- 实时战斗动画
- 经济系统（金币、利息、升级）
- 多人对战/PVP
- 角色养成（升星、装备、皮肤）
- 音效/BGM（可选，时间允许再加）

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 10角色，基础棋盘 | 核心循环 | 4-8周 |
| **MVP+** | 15角色，特效音效 | 羁绊特效，BGM | +2周 |
| **Alpha** | 20角色，完整战斗 | 简化战斗动画 | +4周 |
| **Full Vision** | 扩展角色池 | 养成、PVP、排位 | 长期迭代 |

---

## Initial Character Roster (10 Characters)

| 角色 | 羁绊标签 | 定位 | 星级 | 攻击 | 生命 | 技能 |
|------|----------|------|------|------|------|------|
| 阿梓 | VR / 歌手 / 萌音 | 输出 | 4 | 65 | 750 | 每6次攻击生成分身协同攻击，并周期释放音波造成范围魔法伤害 |
| 七海 | VR / 偶像 / 初代目 | 输出 | 4 | 70 | 800 | 技能对单体造成高额法伤，并召唤扇宝协助作战 |
| 小可 | VR / 歌手 / 上海KTV | 辅助 | 1 | 40 | 500 | 周期释放音浪，对随机敌人造成伤害并降低治疗效果 |
| 恬豆 | VR / 偶像 / 四喜丸子 / 初代目 | 核心 | 5 | 85 | 1000 | 战斗开始提供全队随机增益，技能造成高额范围法伤 |
| 东爱璃 | VR / 偶像 / A-SOUL / PSP | 坦克 | 5 | 60 | 1200 | 开局召唤应援团吸收伤害，自身获得减伤与护盾 |
| 沐霂 | VR / 四喜丸子 / 糖朝 | 战士 | 3 | 55 | 850 | 技能强化自身属性并造成范围伤害，随星级提升成长 |
| 梨安 | VR / 偶像 / 四喜丸子 | 辅助 | 2 | 45 | 650 | 提供团队增益，提升队伍整体输出能力 |
| 雪糕 | 枪手 / 上海KTV / 个人势 | 输出 | 4 | 75 | 800 | 高攻速射击并附带额外伤害，周期触发群体削弱效果 |
| 栞栞 | VR / 枪手 / 萌音 | 输出 | 1 | 50 | 550 | 普攻附带音波伤害，持续叠加输出能力 |
| 乃琳 | 偶像 / A-SOUL | 法师 | 3 | 60 | 700 | 技能对范围敌人造成法术伤害，并强化友军输出 |

### Initial Synergy Set

| 羁绊 | 所需数量 | 效果 |
|------|----------|------|
| VR | 2/4 | 全队攻击力+15%/+30% |
| 歌手 | 2/4 | 歌手标签角色技能伤害+15%/+30% |
| 偶像 | 2/4/6 | 偶像标签角色生命+12%/+25%/+40% |
| 萌音 | 2 | 技能有30%几率造成额外音波伤害 |
| 四喜丸子 | 2/4 | 战斗开始时，四喜丸子成员获得护盾 |
| A-SOUL | 2/3 | A-SOUL成员技能冷却减少 |
| 上海KTV | 2 | 上海KTV成员攻击附带音浪效果 |
| 枪手 | 2/4 | 普攻有概率触发额外射击 |
| 初代目 | 2 | 战斗开始时提供全队增益 |
| 糖朝 | 2/3 | 糖标签角色攻速+15%/+30% |
| PSP | 1 | 单个PSP成员获得额外属性 |
| 个人势 | 1 | 单个个人势成员获得随机增益 |

---

## Next Steps

- [ ] 运行 `/setup-engine godot 4` 配置引擎
- [ ] 使用 `/design-review design/gdd/game-concept.md` 验证概念文档完整性
- [ ] 使用 `/map-systems` 分解概念为独立系统
- [ ] 使用 `/design-system` 编写各系统的GDD
- [ ] 原型核心循环 `/prototype 羁绊系统`
- [ ] 规划第一个冲刺 `/sprint-plan new`
