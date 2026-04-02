# Sprint 2 -- 商店系统与卡池管理

**Start Date**: 2026-03-28
**End Date**: 2026-04-04 (7 days)

## Sprint Goal

实现商店系统和卡池管理，让玩家可以刷新商店、选择角色。

## Capacity

- **Total days**: 7
- **Buffer (20%)**: 1.4 days
- **Available**: 5.6 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T1 | 实现CardPoolManager | gameplay-programmer | 0.5 | Sprint 1 | 抽卡概率符合设计，可抽取指定数量 |
| T2 | 实现ShopSystem | gameplay-programmer | 0.5 | T1 | 刷新显示5张卡，选择角色后卡槽变空 |
| T3 | 实现商店UI框架 | ui-programmer | 1.0 | T2 | 商店UI显示5个卡槽，可点击选择 |
| T4 | 连接拖放交互 | gameplay-programmer | 0.5 | T3 | 商店卡牌可拖放到棋盘 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T5 | 卡牌视觉反馈 | ui-programmer | 0.5 | T3 | 悬停高亮，选中效果 |
| T6 | 商店刷新按钮 | ui-programmer | 0.5 | T3 | 点击刷新商店 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T7 | 卡池统计显示 | ui-programmer | 0.5 | T1 | 显示各费用剩余数量 |

## Carryover from Previous Sprint

无。

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 概率计算不准确 | Low | Medium | 单元测试验证概率分布 |
| UI拖放事件冲突 | Medium | Medium | 参考原型验证的交互模式 |

## Dependencies on External Factors

- 无

## Definition of Done for this Sprint

- [ ] 所有Must Have任务完成
- [ ] 商店可刷新，显示5张卡
- [ ] 卡牌可选择，选择后可拖放到棋盘
- [ ] 抽卡概率符合设计
- [ ] 商店状态与GameState同步

## Notes

- 参考原型 `prototypes/shop-system/` 和 `prototypes/drag-drop-interaction/`
- MVP阶段无经济系统，刷新免费

## Next Sprint Preview

- Sprint 3: 羁绊检测、羁绊效果、属性计算
