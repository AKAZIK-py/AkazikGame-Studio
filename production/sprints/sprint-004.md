# Sprint 4 -- 战斗系统与UI集成

**Start Date**: 2026-03-28
**End Date**: 2026-04-04 (7 days)

## Sprint Goal

实现战斗系统和UI集成，让玩家能执行战斗并查看结果。

## Capacity

- **Total days**: 7
- **Buffer (20%)**: 1.4 days
- **Available**: 5.6 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T1 | 实现BattleSystem | gameplay-programmer | 1.0 | Sprint 3 | 胜率计算正确，战斗结果存储 |
| T2 | 实现AI敌方阵容池 | gameplay-programmer | 0.5 | T1 | 5个预设阵容，随机选择 |
| T3 | 实现战斗结果UI | ui-programmer | 0.5 | T1 | 显示胜率、结果、继续按钮 |
| T4 | 阶段转换流程 | gameplay-programmer | 0.5 | T3 | SHOP→BATTLE→RESULT循环 |
| T5 | 重置游戏功能 | gameplay-programmer | 0.5 | T4 | 清空棋盘、重置商店、重置回合 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T6 | 羁绊面板UI | ui-programmer | 0.5 | Sprint 3 | 显示所有羁绊状态和进度 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T7 | 战斗日志 | ui-programmer | 0.5 | T3 | 显示战斗过程摘要 |

## Carryover from Previous Sprint

无。

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 胜率计算偏差 | Medium | Medium | 单元测试验证计算结果 |
| UI状态同步 | Low | Medium | 使用信号机制确保同步 |

## Dependencies on External Factors

- 无

## Definition of Done for this Sprint

- [ ] 所有Must Have任务完成
- [ ] 玩家可点击"开始战斗"执行战斗
- [ ] 战斗结果正确显示
- [ ] 游戏阶段正确转换
- [ ] 重置功能正常工作

## Notes

- 战斗系统采用纯数值计算，无实时动画
- 参考 `prototypes/battle-system/` 原型代码

## Next Sprint Preview

- Sprint 5: Polish、优化、测试
