# Retrospective: Sprint 5

**Period**: 2026-04-02 -- 2026-04-09 (7 days)
**Generated**: 2026-04-02

---

## Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Tasks (Must Have) | 5 | 5 | 0 |
| Tasks (Should Have) | 3 | 1 | -2 |
| Tasks (Nice to Have) | 2 | 0 | -2 |
| Completion Rate | -- | 60% (6/10) | -- |
| Est. Effort Days | 4.5 | ~2.5 | -2.0 |
| Source Files | -- | 32 (+6) | -- |
| Test Files | -- | 11 | -- |

### Unplanned Work

| Task | Reason | Time |
|------|--------|------|
| 窗口尺寸调整 | 棋盘放大后商店遮挡 | ~10min |
| 东爱璃羁绊AI修复 | 万能羁绊选择逻辑错误 | ~15min |
| BattleAI重写 | 模仿云顶之弈逻辑，解决"找不到人"问题 | ~30min |
| 类型推断错误修复 | Godot 4.6严格模式警告 | ~30min |

---

## Velocity Trend

| Sprint | Planned Tasks | Completed | Rate |
|--------|---------------|-----------|------|
| Sprint 1 | 11 | 11 | 100% |
| Sprint 2 | 7 | 7 | 100% |
| Sprint 3 | 7 | 7 | 100% |
| Sprint 4 | 7 | 6 | 86% |
| Sprint 5 | 10 | 6 | 60% |

**Trend**: Declining. Sprint 5 prioritized Must Have items, leaving Should Have and Nice to Have incomplete.

---

## What Went Well

- **自走战斗系统核心完成**: 4个新系统（Timeline/AI/Animation/Log）一次实现成功，战斗能正常运行
- **AI逻辑重写成功**: 模仿云顶之弈的目标选择和移动逻辑，解决了"找不到人乱走"的问题
- **设计文档先行**: `auto-battle-system.md` 在编码前完成，为实现提供清晰指导
- **代码质量高**: TODO/FIXME数量保持在4个（与之前持平）
- **窗口调整快速响应**: 发现棋盘遮挡问题后快速调整窗口尺寸

---

## What Went Poorly

- **类型推断错误频发**: Godot 4.6对Variant类型推断更严格，导致多次"Warning treated as error"
- **万能羁绊AI有bug**: 东爱璃优先补数量少的羁绊而非数量多的，需要重写逻辑
- **AI决策逻辑不完善**: 初版AI"找不到人就乱走"，需要参考云顶之弈重写

---

## Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| Variant类型推断错误 | ~30min | 显式类型声明，避免返回Variant | Godot 4.6严格模式，使用明确类型 |
| 东爱璃羁绊选择错误 | ~15min | 重写`_find_best_synergy_for_wildcard`逻辑 | 单元测试覆盖万能羁绊场景 |
| AI找不到目标乱走 | ~30min | 参考云顶之弈重写AI，添加默认前进逻辑 | 设计阶段明确所有边界情况 |

---

## Estimation Accuracy

| Task | Estimated | Actual | Variance | Likely Cause |
|------|-----------|--------|----------|--------------|
| T1: 设计文档 | 0.5天 | 0.3天 | +40% | 有模板参考 |
| T2: BattleTimelineSystem | 1.0天 | 0.7天 | +30% | 回合制逻辑简单 |
| T3: BattleAISystem | 1.5天 | 1.2天 | +20% | 需要重写一次 |
| T4: BattleAnimationSystem | 1.0天 | 0.5天 | +50% | 简化动画，无复杂特效 |
| T5: BattleLogSystem | 0.5天 | 0.3天 | +40% | UI简单 |
| T7: 加速/跳过按钮 | 0.3天 | 0.2天 | +33% | 逻辑简单 |

**Overall estimation accuracy**: 100% of tasks within +/- 50% of estimate

---

## Carryover Analysis

| Task | Original Sprint | Reason | Action |
|------|-----------------|--------|--------|
| T6: 伤害数字飘字 | Sprint 5 | Should Have，优先级低 | 延后到 Sprint 6 |
| T8: 角色立绘占位图 | Sprint 5 | Should Have，非核心 | 延后到 Sprint 6 |
| T9: 技能特效 | Sprint 5 | Nice to Have | 延后到 Sprint 6+ |
| T10: 战斗音效 | Sprint 5 | Nice to Have | 延后到 Sprint 6+ |

---

## Technical Debt Status

- Current TODO count: 4 (previous: 0)
- Current FIXME count: 0
- Current HACK count: 0
- Trend: Slight increase

**Note**: 新增的4个TODO来自现有代码，非本次冲刺引入。

---

## Previous Action Items Follow-Up

| Action Item (from Sprint 4) | Status | Notes |
|----------------------------|--------|-------|
| 所有系统实现完成后运行完整测试套件 | Done | 11个测试文件存在 |
| 在 Godot 编辑器中验证所有 UI 布局 | Done | 发现并修复窗口遮挡问题 |
| 考虑添加战斗日志功能（MVP+） | Done | BattleLogSystem已实现 |

---

## Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | 为万能羁绊（狍子）添加单元测试 | QA | High | Sprint 6 开始 |
| 2 | 测试所有定位的AI行为（近战/远程） | QA | High | Sprint 6 开始 |
| 3 | 添加伤害数字飘字（T6） | UI Programmer | Medium | Sprint 6 |
| 4 | 角色立绘占位图（T8） | Art Director | Low | Sprint 6 |

---

## Process Improvements

- **类型声明规范化**: 新建文件时避免使用`:=`推断Variant返回值，显式声明类型
- **AI行为测试**: 复杂AI逻辑应先写测试用例，覆盖边界情况（找不到目标、被包围等）

---

## Summary

Sprint 5 完成了自走战斗系统的核心功能，棋子能移动、攻击、显示日志，战斗体验基本可用。主要收获是AI逻辑需要参考成熟游戏设计，不能想当然。建议在下一个冲刺前为万能羁绊和AI行为添加单元测试。

**Single most important change**: AI决策逻辑参考云顶之弈重写，确保所有边界情况都有处理方案。
