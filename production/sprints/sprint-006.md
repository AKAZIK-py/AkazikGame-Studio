# Sprint 6 -- 测试覆盖与Polish

**Start Date**: 2026-04-02
**End Date**: 2026-04-09 (7 days)

## Sprint Goal

为自走战斗系统和羁绊系统添加测试覆盖，确保核心功能稳定可靠。同时完成遗留的视觉Polish任务。

## Capacity

- **Total days**: 7
- **Buffer (20%)**: 1.4 days
- **Available**: 5.6 days

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T1 | 万能羁绊单元测试 | qa-tester | 0.5 | 无 | 覆盖东爱璃各种场景 |
| T2 | AI行为单元测试 | qa-tester | 0.8 | 无 | 覆盖所有定位的决策逻辑 |
| T3 | 战斗系统集成测试 | qa-tester | 0.5 | T1, T2 | 端到端战斗流程测试 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T4 | 伤害数字飘字 | ui-programmer | 0.5 | 无 | 显示伤害/治疗数值 |
| T5 | 角色立绘占位图 | art-director | 0.5 | 无 | 14个角色占位图 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T6 | 技能特效 | technical-artist | 0.5 | T4 | 角色技能视觉效果 |
| T7 | 战斗音效 | sound-designer | 0.5 | 无 | 攻击/胜利/失败音效 |

---

## Test Coverage Goals

### 万能羁绊测试用例

1. **基础场景**: 东爱璃单独在场，应选择数量最多的羁绊
2. **升级优先**: +1能触发升级时，优先选择该羁绊
3. **同等条件**: 多个羁绊都能升级时，选择数量多的
4. **无其他羁绊**: 只有东爱璃在场，应不激活任何羁绊
5. **多个狍子**: 两个东爱璃在场，应分配到不同羁绊

### AI行为测试用例

1. **近战(output/tank/warrior)**:
   - 攻击范围内有敌人 → 攻击
   - 范围外有敌人 → 移动靠近
   - 无敌人 → 向前移动

2. **远程(core/support/mage)**:
   - 攻击范围内有敌人 → 攻击
   - 太近 → 保持距离
   - 太远 → 移动到最佳距离

3. **目标选择**:
   - 低血量优先
   - 最近优先（support）
   - 边界情况：找不到目标

---

## Definition of Done

- [x] 万能羁绊测试用例全部通过
- [x] AI行为测试用例全部通过
- [ ] 无回归问题（现有测试全部通过）
- [ ] 测试覆盖率 > 80%（核心系统）

---

## Next Sprint Preview

- Sprint 7: 内容扩展（更多角色、羁绊）
- Sprint 8: 整体优化和发布准备
