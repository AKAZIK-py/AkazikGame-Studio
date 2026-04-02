# Sprint 5 -- 自走棋战斗系统（MVP+）

**Start Date**: 2026-04-02
**End Date**: 2026-04-09 (7 days)

## Sprint Goal

实现真正的"自走"棋战斗系统，让棋盘上的棋子能够移动、攻击、释放技能，玩家可以看到完整的战斗过程而非仅数值结果。

## Capacity

- **Total days**: 7
- **Buffer (20%)**: 1.4 days
- **Available**: 5.6 days

---

## 核心设计决策

### 棋盘规模

当前棋盘：32格（4行×8列），玩家区域和敌方区域各占一半。

**选项A - 扩展现有棋盘**：
- 保持32格，但重新定义战斗逻辑
- 棋子在各自区域内移动
- 跨区域攻击（远程/技能）

**选项B - 双棋盘模式**：
- 布置阶段：32格玩家棋盘
- 战斗阶段：切换到更大的战斗棋盘（如8×16）
- 战斗结束后返回

**选项C - 扩大棋盘**：
- 将棋盘扩展到64格或更大
- 玩家和敌方各占一半

**建议**：选项A（扩展现有逻辑），MVP+保持简单

### 战斗流程

```
[布置阶段] → [战斗阶段] → [结果阶段]
    ↓              ↓             ↓
 32格棋盘     同一棋盘      显示结果
 玩家布阵     棋子自动移动   返回布置
```

### 自走战斗核心系统

1. **BattleTimelineSystem** - 控制战斗节奏、回合顺序
2. **BattleAISystem** - 棋子AI（寻路、目标选择、技能使用）
3. **BattleAnimationSystem** - 移动、攻击、技能动画
4. **BattleLogSystem** - 战斗日志记录和显示

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T1 | 设计自走战斗架构 | game-designer | 0.5 | 无 | 完整的战斗流程、AI逻辑、动画时机文档 |
| T2 | 实现BattleTimelineSystem | gameplay-programmer | 1.0 | T1 | 控制战斗回合、行动顺序 |
| T3 | 实现BattleAISystem | ai-programmer | 1.5 | T2 | 棋子自动寻路、目标选择、攻击决策 |
| T4 | 实现BattleAnimationSystem | gameplay-programmer | 1.0 | T3 | 棋子移动、攻击动画 |
| T5 | 实现BattleLogSystem | ui-programmer | 0.5 | T2 | 记录并显示战斗事件 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T6 | 伤害数字飘字 | ui-programmer | 0.5 | T4 | 伤害/治疗数值实时显示 |
| T7 | 战斗加速/跳过 | ui-programmer | 0.3 | T4 | 玩家可加速或跳过战斗动画 |
| T8 | 角色立绘占位图 | art-director | 0.5 | 无 | 14个角色的基础视觉表现 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T9 | 技能特效 | technical-artist | 0.5 | T4 | 角色技能释放视觉效果 |
| T10 | 战斗音效 | sound-designer | 0.5 | T4 | 攻击、技能、胜利/失败音效 |

---

## 技术设计要点

### BattleTimelineSystem

```gdscript
# 战斗时间线
- 使用"回合制"而非实时
- 每回合：根据速度属性决定行动顺序
- 每个行动：移动 → 攻击/技能 → 等待下一回合
```

### BattleAISystem

```gdscript
# 棋子AI决策树
1. 检查技能是否可用 → 使用技能
2. 寻找最近的敌方目标
3. 移动到攻击范围内
4. 执行攻击
5. 等待下一回合
```

### 战斗区域

- 当前棋盘分为：玩家区域（行2-3）、敌方区域（行0-1）
- 战斗时棋子可在各自区域内移动
- 攻击范围根据角色定位（近战/远程）决定

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 战斗动画性能问题 | Medium | Medium | 限制同屏动画数量，使用对象池 |
| AI决策复杂度高 | Medium | Medium | 从简单AI开始，逐步优化 |
| 战斗节奏太慢 | High | Medium | 添加加速/跳过功能 |
| 棋盘空间不足 | Low | Low | 使用当前棋盘，调整战斗逻辑 |

---

## Dependencies on External Factors

- 无

---

## Definition of Done

- [x] 所有Must Have任务完成
- [x] 玩家点击"开始战斗"后能看到棋子移动
- [x] 棋子能自动选择目标并攻击
- [x] 战斗日志显示关键事件
- [x] 战斗结束后正确显示结果
- [x] 战斗可通过加速/跳过按钮控制

---

## Notes

- 本冲刺聚焦"让棋子动起来"，视觉表现优先级高于完美AI
- 参考云顶之弈的自走战斗体验
- 战斗日志是理解战斗过程的关键反馈

---

## Next Sprint Preview

- Sprint 6: Polish、优化、更多特效
- Sprint 7: 内容扩展（更多角色、羁绊）
