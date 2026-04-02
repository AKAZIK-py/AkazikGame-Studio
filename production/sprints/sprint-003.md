# Sprint 3 -- 羁绊系统与属性计算

**Start Date**: 2026-03-28
**End Date**: 2026-04-04 (7 days)

## Sprint Goal

实现羁绊检测、羁绊效果和属性计算系统，让玩家能看到羁绊激活和属性加成。

## Capacity

- **Total days**: 7
- **Buffer (20%)**: 1.4 days
- **Available**: 5.6 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T1 | 实现SynergyDetectionSystem | gameplay-programmer | 0.5 | Sprint 2 | 正确统计羁绊数量，判断激活等级 |
| T2 | 实现SynergyEffectSystem | gameplay-programmer | 1.0 | T1 | 10个羁绊效果正确应用 |
| T3 | 实现AttributeCalculationSystem | gameplay-programmer | 0.5 | T2 | 基础属性+羁绊加成计算正确 |
| T4 | 实现EOE姐妹组合羁绊 | gameplay-programmer | 0.5 | T2 | 露早+柚恩强化正确触发 |
| T5 | 实现单挂效果（hirro） | gameplay-programmer | 0.5 | T2 | 位置检测正确，效果实时更新 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T6 | 羁绊激活UI反馈 | ui-programmer | 0.5 | T3 | 显示激活羁绊和加成数值 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T7 | 羁绊详情面板 | ui-programmer | 0.5 | T6 | 显示所有羁绊状态和进度 |

## Carryover from Previous Sprint

无。

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 羁绊叠加计算复杂 | Medium | Medium | 单元测试验证各种组合 |
| EOE姐妹强化数值过强 | Low | Medium | 原型已调整，使用1.8/1.5倍率 |

## Dependencies on External Factors

- 无

## Definition of Done for this Sprint

- [ ] 所有Must Have任务完成
- [ ] 羁绊检测正确识别激活羁绊
- [ ] 羁绊效果正确应用到角色
- [ ] 属性计算整合基础属性和羁绊加成
- [ ] 特殊羁绊（狍子、EOE姐妹）正确工作

## Notes

- 参考 `prototypes/synergy-system/` 原型代码
- EOE姐妹强化使用调整后的倍率（攻击×1.8，生命×1.5）

## Next Sprint Preview

- Sprint 4: 战斗系统、UI集成
