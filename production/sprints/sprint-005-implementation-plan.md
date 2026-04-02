# Sprint 5 实施计划 — 自走棋战斗系统

**Created**: 2026-04-02
**Status**: Planning

---

## 当前状态分析

### 已有系统
- `BattleSystem` — 仅计算胜率，无视觉效果
- `CharacterRenderer` — 渲染静态棋子
- `BoardSystem` — 棋盘坐标和放置逻辑
- `GameState` — 管理游戏阶段（SHOP/BATTLE/RESULT）

### 缺失系统
1. **战斗时间线** — 控制回合顺序、行动节奏
2. **战斗AI** — 棋子自动决策（移动、攻击、技能）
3. **战斗动画** — 移动、攻击的视觉表现
4. **战斗日志** — 事件记录和显示

---

## 架构设计

### 战斗流程状态机

```
[SHOP] → 点击战斗按钮 → [BATTLE_INIT]
                           ↓
                      [BATTLE_TIMELINE] ←→ [BATTLE_ACTION]
                           ↓                      ↓
                      回合结束              执行行动
                           ↓                      ↓
                      [CHECK_VICTORY] ←─────────┘
                           ↓
                    胜负确定 → [RESULT]
```

### 新系统架构

```
BattleSystem (现有，扩展)
    ├── BattleTimelineSystem (新增)
    │   └── 管理回合、行动顺序、时间控制
    │
    ├── BattleAISystem (新增)
    │   ├── 目标选择
    │   ├── 移动决策
    │   └── 技能使用决策
    │
    ├── BattleAnimationSystem (新增)
    │   ├── 移动动画
    │   ├── 攻击动画
    │   └── 技能特效
    │
    └── BattleLogSystem (新增)
        ├── 事件记录
        └── 日志显示UI
```

---

## 详细任务分解

### Phase 1: 设计与基础设施 (Day 1-2)

#### T1.1: 战斗架构设计文档 (0.3 day)
- [ ] 定义战斗状态机
- [ ] 定义行动优先级（速度属性）
- [ ] 定义攻击范围规则
- [ ] 输出: `design/gdd/auto-battle-system.md`

#### T1.2: BattleTimelineSystem 核心 (0.7 day)
- [ ] 创建 `src/gameplay/battle_timeline_system.gd`
- [ ] 实现回合管理
- [ ] 实现行动顺序排序（基于速度）
- [ ] 信号：`turn_started`, `turn_ended`, `battle_ended`

### Phase 2: AI决策系统 (Day 3-4)

#### T2.1: BattleAISystem 核心 (1.0 day)
- [ ] 创建 `src/gameplay/battle_ai_system.gd`
- [ ] 实现目标选择算法
  - 最近敌方优先
  - 最低血量优先
  - 仇恨值系统（可选）
- [ ] 实现移动决策
  - 向目标移动
  - 保持攻击距离
- [ ] 实现攻击决策

#### T2.2: AI行为树简化版 (0.5 day)
- [ ] 决策优先级：
  1. 检查技能是否可用 → 使用技能
  2. 检查攻击范围内是否有敌人 → 攻击
  3. 移动到攻击范围内 → 移动
  4. 等待

### Phase 3: 动画系统 (Day 5-6)

#### T3.1: BattleAnimationSystem 核心 (0.5 day)
- [ ] 创建 `src/gameplay/battle_animation_system.gd`
- [ ] 实现移动动画（格子间移动）
- [ ] 实现攻击动画（闪烁/缩放效果）

#### T3.2: 动画与AI集成 (0.3 day)
- [ ] 连接AI决策与动画执行
- [ ] 实现动画队列
- [ ] 实现动画完成回调

#### T3.3: CharacterRenderer 扩展 (0.2 day)
- [ ] 添加动画状态支持
- [ ] 添加移动中渲染
- [ ] 添加攻击效果渲染

### Phase 4: 日志与UI (Day 6-7)

#### T4.1: BattleLogSystem (0.3 day)
- [ ] 创建 `src/gameplay/battle_log_system.gd`
- [ ] 事件类型：移动、攻击、伤害、技能、死亡
- [ ] 信号：`log_event_added`

#### T4.2: BattleLogPanel UI (0.2 day)
- [ ] 创建 `src/ui/battle_log_panel.gd`
- [ ] 显示最近10条战斗事件
- [ ] 自动滚动

### Phase 5: 集成与优化 (Day 7)

#### T5.1: Game.gd 集成 (0.3 day)
- [ ] 添加新系统节点
- [ ] 连接系统信号
- [ ] 修改战斗流程

#### T5.2: 战斗加速/跳过 (0.2 day)
- [ ] 添加速度控制（1x/2x/4x）
- [ ] 添加跳过按钮

---

## 文件清单

### 新建文件
```
src/gameplay/battle_timeline_system.gd    # 战斗时间线
src/gameplay/battle_ai_system.gd          # 战斗AI
src/gameplay/battle_animation_system.gd   # 战斗动画
src/gameplay/battle_log_system.gd         # 战斗日志
src/ui/battle_log_panel.gd                # 日志UI面板
design/gdd/auto-battle-system.md          # 设计文档
```

### 修改文件
```
src/core/game.gd                          # 集成新系统
src/gameplay/battle_system.gd             # 扩展接口
src/presentation/character_renderer.gd    # 动画支持
scenes/Game.tscn                          # 添加新节点
```

---

## 验收标准

### Must Have
- [ ] 点击"开始战斗"后棋子开始移动
- [ ] 棋子自动选择最近敌方并移动攻击
- [ ] 攻击有视觉反馈（闪烁/效果）
- [ ] 战斗日志显示关键事件
- [ ] 战斗结束后正确判定胜负

### Should Have
- [ ] 战斗加速按钮（2x/4x）
- [ ] 跳过战斗按钮
- [ ] 伤害数字飘字

### Nice to Have
- [ ] 技能特效
- [ ] 战斗音效

---

## 技术要点

### 回合制 vs 实时制
**选择：回合制**
- 每回合所有棋子按速度行动一次
- 行动顺序：速度高者先行动
- 简化实现，便于调试

### 攻击范围
- 近战：相邻格子（六边形6方向）
- 远程：2-3格距离
- 技能：根据技能定义

### 移动规则
- 每回合移动1格
- 不能穿过敌方
- 可以穿过友方

### 伤害计算
- 复用现有 BattleSystem 公式
- 伤害 = 攻击力 × 系数 - 防御力（可选）

---

## 风险与缓解

| 风险 | 缓解措施 |
|------|----------|
| 动画卡顿 | 使用 tween，限制同屏动画数 |
| AI决策复杂 | 从简单规则开始，逐步优化 |
| 战斗太慢 | 默认2x速度，提供跳过 |

---

## 下一步

1. 创建设计文档 `design/gdd/auto-battle-system.md`
2. 实现 BattleTimelineSystem
3. 实现 BattleAISystem
4. 实现 BattleAnimationSystem
5. 集成测试
